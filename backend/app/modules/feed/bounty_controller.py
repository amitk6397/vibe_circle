"""Post Bounty (Ask & Earn) Controller.

Handles awarding bounty from the author of a question to the chosen reply/comment,
as well as retrieving bounty status.
"""
from datetime import UTC, datetime, timedelta
from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.feed.models import Post, Comment
from app.modules.feed.dtos import BountyAwardRequest
from app.modules.commerce import service as commerce_service
from app.modules.creators import service as creator_service
from app.modules.notifications.service import create_notification
from app.modules.users.models import User
from app.core.config import settings


def award_bounty(post_id: str, payload: BountyAwardRequest, db: DbSession, user: CurrentUser):
    post = db.get(Post, post_id)
    if not post or post.status != "active":
        raise AppError(404, "post_not_found", "Post not found.")

    if post.author_id != user.id:
        raise AppError(403, "not_post_author", "Only the author of the question can award the bounty.")

    if post.bounty_status != "open":
        raise AppError(400, "bounty_not_open", "This bounty is not open or has already been settled.")

    comment = db.get(Comment, payload.comment_id)
    if not comment or comment.post_id != post_id or comment.status != "active":
        raise AppError(404, "comment_not_found", "The comment was not found on this post.")

    if comment.author_id == user.id:
        raise AppError(400, "cannot_award_self", "You cannot award the bounty to your own comment.")

    # Settle/Capture held coins from the author
    commerce_service.settle_hold(
        db,
        user.id,
        post.bounty_amount,
        post.bounty_held_bonus,
        post.bounty_held_purchased,
        post.bounty_amount,  # capture full amount
        "bounty_payout",
        comment.id,
    )

    # Credit earnings to the commenter
    commission = post.bounty_amount * settings.platform_commission_percent // 100
    creator_service.credit_earning(
        db,
        comment.author_id,
        post.bounty_amount,
        commission,
        "bounty_earnings",
        comment.id,
        datetime.now(UTC) + timedelta(days=settings.creator_settlement_days),
    )

    # Update post bounty status
    post.bounty_status = "awarded"
    post.bounty_winner_comment_id = comment.id

    # Notify the winner
    winner = db.get(User, comment.author_id)
    if winner:
        create_notification(
            db,
            comment.author_id,
            "bounty_received",
            "Bounty Won! 🏆",
            f"Your answer to '{post.body[:30]}...' won the bounty of {post.bounty_amount} coins!",
            {"screen": "PostDetails", "postId": post.id},
        )

    db.commit()
    return {
        "status": post.bounty_status,
        "winner_id": comment.author_id,
        "winner_name": winner.name if winner else "Member",
        "bounty_winner_comment_id": comment.id,
    }


def get_bounty_status(post_id: str, db: DbSession, user: CurrentUser):
    post = db.get(Post, post_id)
    if not post or post.status != "active":
        raise AppError(404, "post_not_found", "Post not found.")

    winner = None
    if post.bounty_winner_comment_id:
        comment = db.get(Comment, post.bounty_winner_comment_id)
        if comment:
            winner_user = db.get(User, comment.author_id)
            winner = {
                "user_id": comment.author_id,
                "user_name": winner_user.name if winner_user else "Member",
                "comment_id": comment.id,
                "comment_body": comment.body,
            }

    return {
        "postId": post.id,
        "bountyAmount": post.bounty_amount,
        "bountyStatus": post.bounty_status,
        "winner": winner,
    }
