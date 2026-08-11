from sqlalchemy import select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.modules.communities import service
from app.modules.communities.dtos import CommunityCreate, CommunityInviteAction, CommunityInviteCreate, CommunityMessageCreate, CommunityUpdate, JoinRequestAction, MemberModerationUpdate, MemberRoleUpdate, ShareCreate
from app.modules.communities.models import Community, CommunityBan, CommunityInvite, CommunityJoinRequest, CommunityMember, CommunityMessage, CommunitySubscription
from app.modules.notifications.service import create_notification
from app.modules.users.models import User
from app.modules.creators import service as creator_service
from app.modules.commerce import service as commerce_service
from app.core.config import settings
from datetime import UTC, datetime, timedelta


def list_communities(db: DbSession, user: CurrentUser):
    items = list(db.scalars(select(Community).where(Community.status == "active").order_by(Community.member_count.desc())))
    joined_ids = set(db.scalars(select(CommunityMember.community_id).where(CommunityMember.user_id == user.id)))
    # Only show private circles to their members/owner; public/request communities are always visible
    items = [
        item for item in items
        if not (item.kind == "circle" and item.privacy == "private" and item.id not in joined_ids and item.owner_id != user.id)
        and (item.kind != "circle" or item.privacy != "private" or item.id in joined_ids or item.owner_id == user.id)
    ]
    pending_ids = set(db.scalars(select(CommunityJoinRequest.community_id).where(CommunityJoinRequest.user_id == user.id, CommunityJoinRequest.status == "pending")))
    return [{"id": item.id, "name": item.name, "category": item.category, "description": item.description, "member_count": item.member_count, "color": item.color, "privacy": item.privacy, "premium_price": item.premium_price, "rules": item.rules, "logo_url": item.logo_url, "cover_url": item.cover_url, "tags": item.tags, "location": item.location, "language": item.language, "kind": item.kind, "max_members": item.max_members, "joined": item.id in joined_ids or item.owner_id == user.id, "is_owner": item.owner_id == user.id, "join_pending": item.id in pending_ids} for item in items]


def create(payload: CommunityCreate, db: DbSession, user: CurrentUser):
    values = payload.model_dump()
    if payload.kind == "community" and payload.privacy in {"private", "premium"}:
        values["privacy"] = "private"
        if payload.premium_price and payload.premium_price > 0:
            # Creator sets their own price, clamped to admin limits
            values["premium_price"] = max(
                settings.community_price_min_coins,
                min(settings.community_price_max_coins, payload.premium_price),
            )
        else:
            values["premium_price"] = settings.private_community_coin_price
    item = Community(owner_id=user.id, **values)
    db.add(item)
    db.flush()
    db.add(CommunityMember(community_id=item.id, user_id=user.id, role="owner"))
    db.commit()
    db.refresh(item)
    return item


def details(community_id: str, db: DbSession, _: CurrentUser):
    return service.community_or_404(db, community_id)


def update(community_id: str, payload: CommunityUpdate, db: DbSession, user: CurrentUser):
    item = service.community_or_404(db, community_id)
    service.require_role(db, community_id, user.id, {"owner", "admin", "moderator"})
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


def join(community_id: str, db: DbSession, user: CurrentUser):
    item = service.community_or_404(db, community_id)
    service.ensure_not_banned(db, community_id, user.id)
    if item.owner_id == user.id:
        member = service.membership(db, community_id, user.id)
        if not member:
            member = CommunityMember(community_id=community_id, user_id=user.id, role="owner")
            db.add(member)
            db.commit()
        return member
    member = service.membership(db, community_id, user.id)
    if item.privacy in {"private", "premium"} and item.kind == "community" and not member:
        # Check if there is an active (non-expired) subscription
        now = datetime.now(UTC)
        subscription = db.scalar(
            select(CommunitySubscription).where(
                CommunitySubscription.community_id == item.id,
                CommunitySubscription.user_id == user.id,
                CommunitySubscription.status == "active",
            ).order_by(CommunitySubscription.created_at.desc())
        )
        # Treat subscription as invalid if it's expired
        if subscription and subscription.expires_at:
            sub_expires = subscription.expires_at if subscription.expires_at.tzinfo else subscription.expires_at.replace(tzinfo=UTC)
            if sub_expires < now:
                subscription.status = "expired"
                db.commit()
                subscription = None

        if not subscription:
            # Create new subscription and charge coins
            expires_at = now + timedelta(days=settings.community_subscription_days)
            subscription = CommunitySubscription(
                community_id=item.id,
                user_id=user.id,
                coin_amount=item.premium_price,
                expires_at=expires_at,
            )
            db.add(subscription)
            db.flush()
            commerce_service.spend_coins(db, user.id, item.premium_price, "premium_community_join", "community", item.id)
            commission = item.premium_price * settings.platform_commission_percent // 100
            creator_service.credit_earning(db, item.owner_id, item.premium_price, commission, "premium_community", subscription.id, now + timedelta(days=settings.creator_settlement_days))
            create_notification(db, user.id, "premium_community_payment", "VIP Community Unlocked! 🔓", f"You unlocked {item.name} for {item.premium_price} coins. Access expires in {settings.community_subscription_days} days.", {"screen": "CommunityDetails", "communityId": item.id})
            create_notification(db, item.owner_id, "earnings_received", "New VIP Member! 💎", f"A member unlocked {item.name} for {item.premium_price} coins.", {"screen": "EarningsWallet", "communityId": item.id})
        member = CommunityMember(community_id=community_id, user_id=user.id)
        item.member_count += 1
        db.add(member)
        db.commit()
        return member
    if item.privacy == "private" and item.kind == "circle":
        raise AppError(403, "invite_required", "This community is invite-only.")
    if item.privacy == "request" and not member:
        request = db.scalar(select(CommunityJoinRequest).where(CommunityJoinRequest.community_id == community_id, CommunityJoinRequest.user_id == user.id, CommunityJoinRequest.status == "pending"))
        if not request:
            request = CommunityJoinRequest(community_id=community_id, user_id=user.id)
            db.add(request)
            create_notification(db, item.owner_id, "community_join_request", "New join request", f"{user.name} wants to join {item.name}.", {"community_id": community_id, "request_id": request.id})
            db.commit()
        return {"status": "pending", "request_id": request.id}
    if not member:
        member = CommunityMember(community_id=community_id, user_id=user.id)
        item.member_count += 1
        db.add(member)
        db.commit()
    return member


def subscription_status(community_id: str, db: DbSession, user: CurrentUser):
    """Return VIP subscription status for the current user in a premium community."""
    item = service.community_or_404(db, community_id)
    now = datetime.now(UTC)
    subscription = db.scalar(
        select(CommunitySubscription).where(
            CommunitySubscription.community_id == community_id,
            CommunitySubscription.user_id == user.id,
            CommunitySubscription.status == "active",
        ).order_by(CommunitySubscription.created_at.desc())
    )
    is_subscribed = False
    expires_at = None
    if subscription:
        if subscription.expires_at:
            exp = subscription.expires_at if subscription.expires_at.tzinfo else subscription.expires_at.replace(tzinfo=UTC)
            if exp > now:
                is_subscribed = True
                expires_at = exp.isoformat()
            else:
                subscription.status = "expired"
                db.commit()
        else:
            # Legacy subscriptions without expiry treated as active
            is_subscribed = True
    return {
        "communityId": community_id,
        "communityName": item.name,
        "isPremium": item.premium_price > 0,
        "premiumPrice": item.premium_price,
        "isSubscribed": is_subscribed or item.owner_id == user.id,
        "expiresAt": expires_at,
        "renewalDays": settings.community_subscription_days,
    }


def join_requests(community_id: str, db: DbSession, user: CurrentUser):
    service.require_role(db, community_id, user.id, {"owner", "admin", "moderator"})
    rows = list(db.scalars(select(CommunityJoinRequest).where(CommunityJoinRequest.community_id == community_id, CommunityJoinRequest.status == "pending").order_by(CommunityJoinRequest.created_at)))
    users = {item.id: item for item in db.scalars(select(User).where(User.id.in_([row.user_id for row in rows])))} if rows else {}
    return [{"id": row.id, "user_id": row.user_id, "user_name": users[row.user_id].name if row.user_id in users else "Member", "created_at": row.created_at} for row in rows]


def respond_join_request(community_id: str, request_id: str, payload: JoinRequestAction, db: DbSession, user: CurrentUser):
    service.require_role(db, community_id, user.id, {"owner", "admin", "moderator"})
    request = db.get(CommunityJoinRequest, request_id)
    if not request or request.community_id != community_id or request.status != "pending":
        raise AppError(404, "join_request_not_found", "Join request not found.")
    item = service.community_or_404(db, community_id)
    request.status = "accepted" if payload.action == "accept" else "rejected"
    if payload.action == "accept" and not service.membership(db, community_id, request.user_id):
        db.add(CommunityMember(community_id=community_id, user_id=request.user_id))
        item.member_count += 1
    create_notification(db, request.user_id, "community_join_response", f"Join request {request.status}", f"Your request to join {item.name} was {request.status}.", {"community_id": community_id})
    db.commit()
    return {"status": request.status}


def invite_member(community_id: str, payload: CommunityInviteCreate, db: DbSession, user: CurrentUser):
    item = service.community_or_404(db, community_id)
    service.require_role(db, community_id, user.id, {"owner", "admin", "moderator"})
    if item.kind != "circle":
        raise AppError(422, "circle_required", "Invitations are only used for private circles.")
    if item.member_count >= item.max_members:
        raise AppError(409, "circle_full", "This circle has reached its member limit.")
    invited = db.get(User, payload.user_id)
    if not invited or invited.id == user.id:
        raise AppError(404, "user_not_found", "User not found.")
    if service.membership(db, community_id, invited.id):
        raise AppError(409, "already_member", "This user is already in the circle.")
    existing = db.scalar(select(CommunityInvite).where(CommunityInvite.community_id == community_id, CommunityInvite.invited_user_id == invited.id, CommunityInvite.status == "pending"))
    if existing:
        return existing
    invite = CommunityInvite(community_id=community_id, inviter_id=user.id, invited_user_id=invited.id)
    db.add(invite)
    db.flush()
    create_notification(db, invited.id, "circle_invite", "Private circle invitation", f"{user.name} invited you to {item.name}.", {"community_id": item.id, "invite_id": invite.id})
    db.commit()
    db.refresh(invite)
    return invite


def my_invitations(db: DbSession, user: CurrentUser):
    invites = list(db.scalars(select(CommunityInvite).where(CommunityInvite.invited_user_id == user.id, CommunityInvite.status == "pending").order_by(CommunityInvite.created_at.desc())))
    communities = {item.id: item for item in db.scalars(select(Community).where(Community.id.in_([invite.community_id for invite in invites])))} if invites else {}
    inviters = {item.id: item for item in db.scalars(select(User).where(User.id.in_([invite.inviter_id for invite in invites])))} if invites else {}
    return [{"id": invite.id, "community_id": invite.community_id, "community_name": communities[invite.community_id].name if invite.community_id in communities else "Private circle", "inviter_name": inviters[invite.inviter_id].name if invite.inviter_id in inviters else "Member", "created_at": invite.created_at} for invite in invites]


def respond_invitation(invite_id: str, payload: CommunityInviteAction, db: DbSession, user: CurrentUser):
    invite = db.get(CommunityInvite, invite_id)
    if not invite or invite.invited_user_id != user.id or invite.status != "pending":
        raise AppError(404, "invite_not_found", "Invitation not found.")
    item = service.community_or_404(db, invite.community_id)
    invite.status = "accepted" if payload.action == "accept" else "rejected"
    if payload.action == "accept":
        if item.member_count >= item.max_members:
            raise AppError(409, "circle_full", "This circle is full.")
        if not service.membership(db, item.id, user.id):
            db.add(CommunityMember(community_id=item.id, user_id=user.id))
            item.member_count += 1
    db.commit()
    return {"status": invite.status, "community_id": item.id}


def leave(community_id: str, db: DbSession, user: CurrentUser):
    item = service.community_or_404(db, community_id)
    member = service.membership(db, community_id, user.id)
    if not member:
        return ApiMessage(message="You are not a member.")
    if member.role == "owner":
        raise AppError(409, "owner_cannot_leave", "Transfer ownership before leaving.")
    db.delete(member)
    item.member_count = max(0, item.member_count - 1)
    db.commit()
    return ApiMessage(message="You left the community.")


def members(community_id: str, db: DbSession, _: CurrentUser):
    service.community_or_404(db, community_id)
    rows = list(db.scalars(select(CommunityMember).where(CommunityMember.community_id == community_id)))
    users = {item.id: item for item in db.scalars(select(User).where(User.id.in_([row.user_id for row in rows])))}
    return [{"membership": row, "user": users.get(row.user_id)} for row in rows]


def update_role(community_id: str, member_id: str, payload: MemberRoleUpdate, db: DbSession, user: CurrentUser):
    service.require_role(db, community_id, user.id, {"owner"})
    member = db.get(CommunityMember, member_id)
    if not member or member.community_id != community_id:
        raise AppError(404, "member_not_found", "Member not found.")
    member.role = payload.role
    db.commit()
    return member


def moderate_member(community_id: str, member_id: str, payload: MemberModerationUpdate, db: DbSession, user: CurrentUser):
    service.require_role(db, community_id, user.id, {"owner", "admin", "moderator"})
    member = db.get(CommunityMember, member_id)
    if not member or member.community_id != community_id or member.role == "owner": raise AppError(404, "member_not_found", "Member not found.")
    if payload.action == "mute": member.muted = True
    elif payload.action == "unmute": member.muted = False
    else:
        if not db.scalar(select(CommunityBan.id).where(CommunityBan.community_id == community_id, CommunityBan.user_id == member.user_id)):
            db.add(CommunityBan(community_id=community_id, user_id=member.user_id, banned_by=user.id, reason=payload.reason))
        db.delete(member)
    db.commit(); return {"status": payload.action}


def remove_member(community_id: str, member_id: str, db: DbSession, user: CurrentUser):
    service.require_role(db, community_id, user.id, {"owner", "moderator"})
    member = db.get(CommunityMember, member_id)
    if not member or member.community_id != community_id or member.role == "owner":
        raise AppError(404, "member_not_found", "Member not found.")
    db.delete(member)
    db.commit()
    return ApiMessage(message="Member removed.")


def messages(community_id: str, db: DbSession, user: CurrentUser, limit: int = 50):
    service.community_or_404(db, community_id)
    if not service.membership(db, community_id, user.id):
        raise AppError(403, "membership_required", "Join the community to view its chat.")
    return list(db.scalars(select(CommunityMessage).where(CommunityMessage.community_id == community_id).order_by(CommunityMessage.created_at.desc()).limit(min(limit, 100))))[::-1]


def send_message(community_id: str, payload: CommunityMessageCreate, db: DbSession, user: CurrentUser):
    member = service.membership(db, community_id, user.id)
    if not member or member.muted:
        raise AppError(403, "community_chat_unavailable", "You cannot send messages in this community.")
    if not payload.text.strip() and not payload.media_url:
        raise AppError(422, "empty_message", "A message or attachment is required.")
    item = CommunityMessage(community_id=community_id, author_id=user.id, **payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def delete_community(community_id: str, db: DbSession, user: CurrentUser):
    """Allow the community owner to permanently delete their community."""
    item = service.community_or_404(db, community_id)
    if item.owner_id != user.id:
        raise AppError(403, "community_permission_denied", "Only the owner can delete this community.")
    # Soft-delete community and all its messages
    item.status = "deleted"
    db.query(CommunityMessage).where(CommunityMessage.community_id == community_id).delete()
    db.query(CommunityMember).where(CommunityMember.community_id == community_id).delete()
    db.query(CommunityJoinRequest).where(CommunityJoinRequest.community_id == community_id).delete()
    db.query(CommunityInvite).where(CommunityInvite.community_id == community_id).delete()
    # Soft-delete all posts belonging to this community
    from app.modules.feed.models import Post
    db.query(Post).where(Post.community_id == community_id, Post.status == "active").update({"status": "deleted"})
    db.commit()
    return ApiMessage(message="Community deleted successfully.")


def share_community(community_id: str, payload: ShareCreate, db: DbSession, user: CurrentUser):
    """Share a community with connected users via DM."""
    from sqlalchemy import or_, select as sa_select
    from app.modules.chat.models import Conversation, Message as ChatMessage
    from app.modules.chat import service as chat_service
    from app.modules.chat.dtos import MessageCreate
    from app.modules.users.models import Connection

    item = service.community_or_404(db, community_id)
    share_text = f"\U0001f465 Check out this community: *{item.name}*\n{item.description}\n\nCategory: {item.category} · {item.member_count} members"

    media_url = item.cover_url or item.logo_url
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
                    media_name="Shared Community Image" if media_url else None,
                    mime_type="image/jpeg" if media_url else None,
                ),
            )
            sent_count += 1
        except Exception:
            pass
    return {"sent": sent_count}
