from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.modules.chat import service as chat_service
from app.modules.chat.dtos import MessageCreate
from app.modules.chat.models import Conversation, MessageRequest
from app.modules.feed import service
from app.modules.discovery.service import blocked_ids
from app.modules.feed.dtos import (
    CommentCreate,
    PostCreate,
    PostUpdate,
    ShareCreate,
    StoryCreate,
    StoryReactionCreate,
    StoryReplyCreate,
    VoteCreate,
)
from app.modules.feed.models import Comment, Post, PostReaction, PostUnlock, SavedPost, Story, StoryMute
from app.modules.users.models import Connection, User
from app.modules.communities.models import Community, CommunityMember
from app.modules.engagement.models import GiftTransaction, VirtualGift
from app.modules.notifications.service import create_notification
from app.modules.commerce import service as commerce_service
from app.modules.creators import service as earning_service
from app.core.config import settings


def _post_response(db: DbSession, item: Post, user: CurrentUser):
    author = db.get(User, item.author_id)
    community = db.get(Community, item.community_id) if item.community_id else None
    liked = db.scalar(select(PostReaction.id).where(PostReaction.post_id == item.id, PostReaction.user_id == user.id)) is not None
    saved = db.scalar(select(SavedPost.id).where(SavedPost.post_id == item.id, SavedPost.user_id == user.id)) is not None
    poll_results = {option: 0 for option in item.poll_options}
    for selected_option in item.poll_votes.values():
        if selected_option in poll_results:
            poll_results[selected_option] += 1
    unlocked = item.author_id == user.id or item.visibility == "public" or db.scalar(
        select(PostUnlock.id).where(PostUnlock.post_id == item.id, PostUnlock.user_id == user.id)
    ) is not None

    post_gifts = []
    gifts_stmt = select(GiftTransaction, VirtualGift.name, VirtualGift.icon, VirtualGift.coin_price).join(
        VirtualGift, GiftTransaction.gift_id == VirtualGift.id
    ).where(
        GiftTransaction.target_type == "post",
        GiftTransaction.target_id == item.id
    )
    for tx, g_name, g_icon, g_price in db.execute(gifts_stmt):
        post_gifts.append({
            "id": tx.id,
            "gift_id": tx.gift_id,
            "name": g_name,
            "icon": g_icon,
            "coin_price": g_price,
            "sender_id": tx.sender_id
        })

    return {
        "id": item.id, "author_id": item.author_id, "mine": item.author_id == user.id,
        "author_name": "Anonymous member" if item.anonymous else (author.name if author else "Member"),
        "author_username": "anonymous" if item.anonymous else (author.username if author else None),
        "community_id": item.community_id, "community_name": community.name if community else "Discover",
        "type": item.type, "body": item.body if unlocked else "Private post · Unlock to view the full content.", "anonymous": item.anonymous,
        "media_url": item.media_url if unlocked else None, "poll_options": item.poll_options if unlocked else [],
        "poll_results": poll_results if unlocked else {}, "my_vote": item.poll_votes.get(user.id) if unlocked else None,
        "like_count": item.like_count, "comment_count": item.comment_count,
        "liked": liked, "saved": saved, "created_at": item.created_at,
        "visibility": item.visibility, "coin_price": item.coin_price, "locked": not unlocked,
        # Tipping
        "tip_count": item.tip_count,
        "tip_total": item.tip_total,
        # Boosting
        "is_boosted": item.is_boosted,
        "boosted_until": item.boosted_until.isoformat() if item.boosted_until else None,
        "boost_cost": item.boost_cost,
        # Bounty
        "bounty_amount": item.bounty_amount,
        "bounty_status": item.bounty_status,
        "bounty_winner_comment_id": item.bounty_winner_comment_id,
        # Gifts list
        "gifts": post_gifts,
    }


def _require_post_access(db: DbSession, item: Post, user_id: str):
    if item.community_id:
        community = db.get(Community, item.community_id)
        if community and community.privacy in {"private", "premium"} and community.owner_id != user_id and not db.scalar(
            select(CommunityMember.id).where(CommunityMember.community_id == community.id, CommunityMember.user_id == user_id)
        ):
            raise AppError(402, "community_unlock_required", "Unlock this private community first.")
    if item.visibility == "private" and item.author_id != user_id and not db.scalar(
        select(PostUnlock.id).where(PostUnlock.post_id == item.id, PostUnlock.user_id == user_id)
    ):
        raise AppError(402, "post_unlock_required", "Unlock this private post with coins first.")


def list_posts(db: DbSession, user: CurrentUser, community_id: str | None = None, before: str | None = None, limit: int = 30):
    from sqlalchemy import case
    now = datetime.now(UTC)
    active_boost_expr = case(
        (Post.is_boosted & (Post.boosted_until > now), 1),
        else_=0
    ).desc()

    stmt = select(Post).where(Post.status == "active", Post.author_id.not_in(blocked_ids(db, user.id)))
    if community_id:
        community = db.get(Community, community_id)
        if community and community.privacy in {"private", "premium"} and community.owner_id != user.id and not db.scalar(
            select(CommunityMember.id).where(CommunityMember.community_id == community_id, CommunityMember.user_id == user.id)
        ):
            raise AppError(402, "community_unlock_required", "Unlock this private community first.")
        stmt = stmt.where(Post.community_id == community_id)
    else:
        # Community content belongs to its own feed. The global/home feed only
        # contains posts created without a community context.
        stmt = stmt.where(Post.community_id.is_(None))
    if before:
        marker = db.get(Post, before)
        if marker:
            stmt = stmt.where(Post.created_at < marker.created_at)
    return [_post_response(db, item, user) for item in db.scalars(stmt.order_by(active_boost_expr, Post.created_at.desc()).limit(min(limit, 100)))]


def create(payload: PostCreate, db: DbSession, user: CurrentUser):
    service.ensure_can_post(db, payload.community_id, user.id)
    values = payload.model_dump()
    if payload.visibility == "private":
        if payload.coin_price is not None:
            # Use creator's price clamped to admin-configured limits
            values["coin_price"] = max(
                settings.post_price_min_coins,
                min(settings.post_price_max_coins, payload.coin_price),
            )
        else:
            # Fall back to the platform default
            values["coin_price"] = settings.private_post_coin_price
    else:
        values["coin_price"] = 0

    # Pop bounty_amount to handle it separately
    bounty_amount = values.pop("bounty_amount", None)
    bounty_status = "none"
    if bounty_amount is not None and bounty_amount > 0:
        if bounty_amount < settings.bounty_min_coins:
            raise AppError(400, "bounty_too_low", f"Bounty must be at least {settings.bounty_min_coins} coins.")
        bounty_status = "open"

    item = Post(
        author_id=user.id,
        bounty_amount=bounty_amount or 0,
        bounty_status=bounty_status,
        **values
    )
    db.add(item)
    db.flush()

    if bounty_amount is not None and bounty_amount > 0:
        try:
            held_bonus, held_purchased = commerce_service.hold_coins(
                db,
                user.id,
                bounty_amount,
                "post_bounty",
                item.id
            )
            item.bounty_held_bonus = held_bonus
            item.bounty_held_purchased = held_purchased
        except Exception as exc:
            db.rollback()
            raise AppError(402, "insufficient_coins_for_bounty", "You do not have enough coins for this bounty.") from exc

    db.commit()
    db.refresh(item)
    return item


def details(post_id: str, db: DbSession, user: CurrentUser):
    item = service.post_or_404(db, post_id)
    _require_post_access(db, item, user.id)
    return _post_response(db, item, user)


def unlock_post(post_id: str, db: DbSession, user: CurrentUser):
    item = service.post_or_404(db, post_id)
    if item.community_id:
        community = db.get(Community, item.community_id)
        if community and community.privacy in {"private", "premium"} and community.owner_id != user.id and not db.scalar(
            select(CommunityMember.id).where(CommunityMember.community_id == community.id, CommunityMember.user_id == user.id)
        ):
            raise AppError(402, "community_unlock_required", "Unlock this private community first.")
    if item.visibility != "private" or item.author_id == user.id:
        return _post_response(db, item, user)
    existing = db.scalar(select(PostUnlock).where(PostUnlock.post_id == item.id, PostUnlock.user_id == user.id))
    if not existing:
        existing = PostUnlock(post_id=item.id, user_id=user.id, coin_amount=item.coin_price)
        db.add(existing)
        db.flush()
        commerce_service.spend_coins(db, user.id, item.coin_price, "private_post_unlock", "post", item.id)
        commission = item.coin_price * settings.platform_commission_percent // 100
        earning_service.credit_earning(db, item.author_id, item.coin_price, commission, "private_post", existing.id, datetime.now(UTC) + timedelta(days=settings.creator_settlement_days))
        create_notification(db, item.author_id, "post_earning", "Private post unlocked", f"You earned {item.coin_price - commission} coins from a private post.", {"screen": "Wallet", "postId": item.id})
        db.commit()
    return _post_response(db, item, user)


def update(post_id: str, payload: PostUpdate, db: DbSession, user: CurrentUser):
    item = service.post_or_404(db, post_id)
    if item.author_id != user.id:
        raise AppError(403, "post_permission_denied", "Only the author can edit this post.")
    item.body = payload.body
    db.commit()
    db.refresh(item)
    return _post_response(db, item, user)


def delete(post_id: str, db: DbSession, user: CurrentUser):
    item = service.post_or_404(db, post_id)
    # Author can always delete their own post; community owner/moderator can also delete posts
    from app.modules.communities import service as community_service
    is_community_mod = (
        item.community_id is not None
        and community_service.membership(db, item.community_id, user.id) is not None
        and community_service.membership(db, item.community_id, user.id).role in {"owner", "moderator"}
    )
    if item.author_id != user.id and not is_community_mod:
        raise AppError(403, "post_permission_denied", "Only the author or community moderator can delete this post.")
    item.status = "deleted"
    db.commit()
    return ApiMessage(message="Post deleted.")


def comments(post_id: str, db: DbSession, user: CurrentUser):
    post = service.post_or_404(db, post_id)
    _require_post_access(db, post, user.id)
    items = list(db.scalars(select(Comment).where(Comment.post_id == post_id, Comment.status == "active").order_by(Comment.created_at)))
    res = []
    for item in items:
        author = db.get(User, item.author_id)
        res.append({
            "id": item.id,
            "post_id": item.post_id,
            "author_id": item.author_id,
            "mine": item.author_id == user.id,
            "author_name": author.name if author else "Member",
            "author_username": author.username if author else None,
            "body": item.body,
            "parent_id": item.parent_id,
            "created_at": item.created_at,
            "like_count": db.scalar(select(func.count()).select_from(PostReaction).where(PostReaction.post_id == item.id, PostReaction.kind == "comment_like")) or 0,
            "liked": db.scalar(select(PostReaction.id).where(PostReaction.post_id == item.id, PostReaction.user_id == user.id, PostReaction.kind == "comment_like")) is not None
        })
    return res


def comment(post_id: str, payload: CommentCreate, db: DbSession, user: CurrentUser):
    post = service.post_or_404(db, post_id)
    _require_post_access(db, post, user.id)
    if payload.parent_id:
        parent = db.get(Comment, payload.parent_id)
        if not parent or parent.post_id != post_id:
            raise AppError(422, "invalid_parent_comment", "Parent comment is invalid.")
    item = Comment(post_id=post_id, author_id=user.id, **payload.model_dump())
    post.comment_count += 1
    db.add(item)
    target_id = parent.author_id if payload.parent_id and (parent := db.get(Comment, payload.parent_id)) else post.author_id
    if target_id != user.id:
        create_notification(
            db,
            target_id,
            "post_comment",
            "New comment",
            f"{user.name} commented on your post.",
            {"screen": "PostDetails", "postId": post.id},
        )
    db.commit()
    db.refresh(item)
    return item


def delete_comment(comment_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Comment, comment_id)
    if not item or item.status != "active" or item.author_id != user.id:
        raise AppError(404, "comment_not_found", "Comment not found.")
    post = db.get(Post, item.post_id)
    item.status = "deleted"
    if post:
        post.comment_count = max(0, post.comment_count - 1)
    db.commit()
    return ApiMessage(message="Comment deleted.")


def toggle_like(post_id: str, db: DbSession, user: CurrentUser):
    post = service.post_or_404(db, post_id)
    _require_post_access(db, post, user.id)
    item = db.scalar(select(PostReaction).where(PostReaction.post_id == post_id, PostReaction.user_id == user.id))
    if item:
        db.delete(item)
        post.like_count = max(0, post.like_count - 1)
        liked = False
    else:
        db.add(PostReaction(post_id=post_id, user_id=user.id))
        post.like_count += 1
        liked = True
        if post.author_id != user.id:
            create_notification(
                db,
                post.author_id,
                "post_like",
                "New like",
                f"{user.name} liked your post.",
                {"screen": "PostDetails", "postId": post.id},
            )
    db.commit()
    return {"liked": liked, "like_count": post.like_count}


def toggle_save(post_id: str, db: DbSession, user: CurrentUser):
    service.post_or_404(db, post_id)
    item = db.scalar(select(SavedPost).where(SavedPost.post_id == post_id, SavedPost.user_id == user.id))
    if item:
        db.delete(item)
        saved = False
    else:
        db.add(SavedPost(post_id=post_id, user_id=user.id))
        saved = True
    db.commit()
    return {"saved": saved}


def toggle_comment_like(comment_id: str, db: DbSession, user: CurrentUser):
    comment = db.get(Comment, comment_id)
    if not comment or comment.status != "active":
        raise AppError(404, "comment_not_found", "Comment not found.")
    item = db.scalar(select(PostReaction).where(PostReaction.post_id == comment_id, PostReaction.user_id == user.id, PostReaction.kind == "comment_like"))
    if item:
        db.delete(item)
        liked = False
    else:
        db.add(PostReaction(post_id=comment_id, user_id=user.id, kind="comment_like"))
        liked = True
        if comment.author_id != user.id:
            create_notification(
                db,
                comment.author_id,
                "comment_like",
                "New comment like",
                f"{user.name} liked your comment.",
                {"screen": "PostDetails", "postId": comment.post_id},
            )
    db.commit()
    count = db.scalar(select(func.count()).select_from(PostReaction).where(PostReaction.post_id == comment_id, PostReaction.kind == "comment_like")) or 0
    return {"liked": liked, "like_count": count}


def vote(post_id: str, payload: VoteCreate, db: DbSession, user: CurrentUser):
    post = service.post_or_404(db, post_id)
    _require_post_access(db, post, user.id)
    if post.type != "poll" or payload.option not in post.poll_options:
        raise AppError(422, "invalid_poll_option", "Poll option is invalid.")
    post.poll_votes = {**post.poll_votes, user.id: payload.option}
    db.commit()
    results = {option: 0 for option in post.poll_options}
    for selected_option in post.poll_votes.values():
        if selected_option in results:
            results[selected_option] += 1
    return {"option": payload.option, "poll_results": results, "total_votes": sum(results.values())}


def share_post(post_id: str, payload: ShareCreate, db: DbSession, user: CurrentUser):
    """Share a post to selected connections via DM."""
    from sqlalchemy import select as sa_select
    from app.modules.chat.models import Conversation
    from app.modules.chat import service as chat_service
    from app.modules.chat.dtos import MessageCreate

    post = service.post_or_404(db, post_id)
    _require_post_access(db, post, user.id)
    author = db.get(User, post.author_id)
    community = db.get(Community, post.community_id) if post.community_id else None
    author_name = "Anonymous member" if post.anonymous else (author.name if author else "Member")
    share_text = f"\U0001f4dd Shared a post from {author_name}:\n\n{post.body}"
    if community:
        share_text += f"\n\nPosted in: {community.name}"

    media_url = post.media_url
    msg_type = "image" if media_url else "text"

    sent_count = 0
    for target_user_id in payload.user_ids[:20]:
        if target_user_id == user.id:
            continue
        target = db.get(User, target_user_id)
        if not target or target.status != "active":
            continue
        conversations = list(db.scalars(sa_select(Conversation).where(Conversation.type == "private")))
        conversation = next(
            (conv for conv in conversations if set(conv.member_ids) == {user.id, target_user_id}),
            None,
        )
        if not conversation:
            conversation = Conversation(member_ids=[user.id, target_user_id])
            db.add(conversation)
            db.commit()
            db.refresh(conversation)
        try:
            chat_service.send(
                db,
                conversation,
                user.id,
                MessageCreate(
                    text=share_text,
                    type=msg_type,
                    media_url=media_url,
                    media_name="Shared Image" if media_url else None,
                    mime_type="image/jpeg" if media_url else None,
                ),
            )
            sent_count += 1
        except Exception:
            pass
    return {"sent": sent_count}


def _story_response(db: DbSession, story: Story, user: CurrentUser):
    author = db.get(User, story.author_id)
    viewers = []
    if story.author_id == user.id:
        for viewer_id in story.viewed_by:
            viewer = db.get(User, viewer_id)
            if viewer:
                viewers.append(
                    {"id": viewer.id, "name": viewer.name, "avatar_url": viewer.avatar_url}
                )
    return {
        "id": story.id,
        "author_id": story.author_id,
        "author_name": author.name if author else "Member",
        "author_avatar_url": author.avatar_url if author else None,
        "media_url": story.media_url,
        "created_at": story.created_at,
        "expires_at": story.expires_at,
        "viewed": user.id in story.viewed_by,
        "mine": story.author_id == user.id,
        "view_count": len(story.viewed_by) if story.author_id == user.id else None,
        "viewers": viewers,
        "reaction_counts": {
            emoji: sum(1 for reaction in story.reactions if reaction["emoji"] == emoji)
            for emoji in {reaction["emoji"] for reaction in story.reactions}
        },
        "replies": story.replies if story.author_id == user.id else [],
        "audience": story.audience,
        "replies_enabled": story.replies_enabled,
    }


def _can_view_story(db: DbSession, story: Story, user_id: str) -> bool:
    if story.author_id == user_id or story.audience == "public": return True
    if story.audience == "selected_users": return user_id in (story.selected_user_ids or [])
    if story.audience == "community_members":
        return bool(story.audience_community_id and db.scalar(select(CommunityMember.id).where(CommunityMember.community_id == story.audience_community_id, CommunityMember.user_id == user_id)))
    if story.audience == "paid_supporters":
        return db.scalar(select(GiftTransaction.id).where(GiftTransaction.sender_id == user_id, GiftTransaction.creator_id == story.author_id, GiftTransaction.status == "successful")) is not None
    follows = db.scalar(select(Connection.id).where(Connection.requester_id == user_id, Connection.receiver_id == story.author_id, Connection.status == "accepted")) is not None
    if story.audience == "followers": return follows
    if story.audience == "close_circle":
        reverse = db.scalar(select(Connection.id).where(Connection.requester_id == story.author_id, Connection.receiver_id == user_id, Connection.status == "accepted")) is not None
        return follows and reverse
    return False


def stories(db: DbSession, user: CurrentUser):
    excluded = blocked_ids(db, user.id)
    excluded |= set(db.scalars(select(StoryMute.muted_user_id).where(StoryMute.user_id == user.id)))
    items = db.scalars(
        select(Story)
        .where(Story.expires_at > datetime.now(UTC), Story.author_id.not_in(excluded))
        .order_by(Story.created_at.desc())
        .limit(100)
    )
    return [_story_response(db, item, user) for item in items if _can_view_story(db, item, user.id)]


def create_story(payload: StoryCreate, db: DbSession, user: CurrentUser):
    item = Story(author_id=user.id, expires_at=datetime.now(UTC) + timedelta(hours=24), **payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return _story_response(db, item, user)


def _available_story(db: DbSession, story_id: str, user: CurrentUser):
    item = db.get(Story, story_id)
    expires_at = (
        item.expires_at
        if item and item.expires_at.tzinfo
        else (item.expires_at.replace(tzinfo=UTC) if item else None)
    )
    if (
        not item
        or not expires_at
        or expires_at <= datetime.now(UTC)
        or item.author_id in blocked_ids(db, user.id)
        or not _can_view_story(db, item, user.id)
    ):
        raise AppError(404, "story_not_found", "Story is no longer available.")
    return item


def view_story(story_id: str, db: DbSession, user: CurrentUser):
    item = _available_story(db, story_id, user)
    if user.id not in item.viewed_by:
        item.viewed_by = [*item.viewed_by, user.id]
        db.commit()
    return {"viewed": True}


def delete_story(story_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Story, story_id)
    if not item or item.author_id != user.id:
        raise AppError(404, "story_not_found", "Story not found.")
    db.delete(item)
    db.commit()
    return ApiMessage(message="Story deleted.")


def _send_story_chat(db: DbSession, story: Story, sender: User, text: str):
    if story.author_id == sender.id:
        return None
    conversations = db.scalars(select(Conversation).where(Conversation.type == "private"))
    conversation = next(
        (item for item in conversations if set(item.member_ids) == {sender.id, story.author_id}),
        None,
    )
    if not conversation:
        request = db.scalar(select(MessageRequest).where(MessageRequest.sender_id == sender.id, MessageRequest.recipient_id == story.author_id, MessageRequest.status == "pending"))
        if not request:
            db.add(MessageRequest(sender_id=sender.id, recipient_id=story.author_id, introduction=text[:300]))
            db.commit()
        return None
    chat_service.send(
        db,
        conversation,
        sender.id,
        MessageCreate(
            text=text,
            type="image",
            media_url=story.media_url,
            media_name="Story photo",
            mime_type="image/jpeg",
        ),
    )
    return conversation.id


def react_story(story_id: str, payload: StoryReactionCreate, db: DbSession, user: CurrentUser):
    item = _available_story(db, story_id, user)
    existing = [reaction for reaction in item.reactions if reaction["user_id"] != user.id]
    item.reactions = [*existing, {"user_id": user.id, "emoji": payload.emoji}]
    db.commit()
    conversation_id = _send_story_chat(db, item, user, f"Reacted {payload.emoji} to your story")
    return {
        "reacted": True,
        "emoji": payload.emoji,
        "reaction_counts": {
            emoji: sum(1 for reaction in item.reactions if reaction["emoji"] == emoji)
            for emoji in {reaction["emoji"] for reaction in item.reactions}
        },
        "conversation_id": conversation_id,
    }


def reply_story(story_id: str, payload: StoryReplyCreate, db: DbSession, user: CurrentUser):
    item = _available_story(db, story_id, user)
    if not item.replies_enabled:
        raise AppError(403, "story_replies_disabled", "Replies are disabled for this story.")
    item.replies = [
        *item.replies,
        {
            "user_id": user.id,
            "user_name": user.name,
            "text": payload.text,
            "created_at": datetime.now(UTC).isoformat(),
        },
    ]
    db.commit()
    conversation_id = _send_story_chat(db, item, user, f"Replied to your story: {payload.text}")
    return {"sent": True, "conversation_id": conversation_id}


def mute_story_author(story_id: str, db: DbSession, user: CurrentUser):
    item = _available_story(db, story_id, user)
    if item.author_id != user.id and not db.scalar(select(StoryMute.id).where(StoryMute.user_id == user.id, StoryMute.muted_user_id == item.author_id)):
        db.add(StoryMute(user_id=user.id, muted_user_id=item.author_id)); db.commit()
    return ApiMessage(message="Stories muted.")


def archive_story(story_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Story, story_id)
    if not item or item.author_id != user.id: raise AppError(404, "story_not_found", "Story not found.")
    item.archived = True; db.commit(); return ApiMessage(message="Story archived.")


def story_archive(db: DbSession, user: CurrentUser):
    return [_story_response(db, item, user) for item in db.scalars(select(Story).where(Story.author_id == user.id, Story.archived.is_(True)).order_by(Story.created_at.desc()))]
