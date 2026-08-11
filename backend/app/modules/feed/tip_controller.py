"""Post Tipping Controller.

Validates tip amount, deducts coins from tipper, credits creator,
and increments counters on the post.
"""
from datetime import UTC, datetime, timedelta
from sqlalchemy import select
from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.feed.models import Post, PostTip
from app.modules.feed.dtos import PostTipRequest
from app.modules.commerce import service as commerce_service
from app.modules.creators import service as creator_service
from app.modules.notifications.service import create_notification
from app.modules.users.models import User
from app.core.config import settings


def tip_post(post_id: str, payload: PostTipRequest, db: DbSession, user: CurrentUser):
    post = db.get(Post, post_id)
    if not post or post.status != "active":
        raise AppError(404, "post_not_found", "Post not found.")

    if post.author_id == user.id:
        raise AppError(400, "self_tip_not_allowed", "You cannot tip your own post.")

    amount = payload.amount

    # Create the tip record
    tip = PostTip(
        post_id=post.id,
        tipper_id=user.id,
        coin_amount=amount,
        message=payload.message,
    )
    db.add(tip)
    db.flush()

    # Deduct coins from tipper
    try:
        commerce_service.spend_coins(
            db,
            user.id,
            amount,
            "post_tip",
            "post_tips",
            tip.id,
        )
    except Exception as exc:
        raise AppError(402, "insufficient_coins_for_tip", "You do not have enough coins to tip.") from exc

    # Credit creator
    commission = amount * settings.platform_commission_percent // 100
    creator_service.credit_earning(
        db,
        post.author_id,
        amount,
        commission,
        "post_tip",
        tip.id,
        datetime.now(UTC) + timedelta(days=settings.creator_settlement_days),
    )

    # Increment counters on post
    post.tip_count += 1
    post.tip_total += amount

    # Notify author
    create_notification(
        db,
        post.author_id,
        "post_tip_received",
        "Received a Super Like! 💖",
        f"{user.name} tipped your post with {amount} coins.",
        {"screen": "PostDetails", "postId": post.id},
    )

    db.commit()
    return {
        "tip_count": post.tip_count,
        "tip_total": post.tip_total,
        "credited_amount": amount - commission,
    }


def get_post_tips(post_id: str, db: DbSession, user: CurrentUser):
    tips = list(
        db.scalars(
            select(PostTip)
            .where(PostTip.post_id == post_id)
            .order_by(PostTip.created_at.desc())
            .limit(20)
        )
    )

    results = []
    for tip in tips:
        tipper = db.get(User, tip.tipper_id)
        results.append(
            {
                "id": tip.id,
                "tipper_name": tipper.name if tipper else "Anonymous member",
                "tipper_avatar": tipper.avatar_url if tipper else None,
                "amount": tip.coin_amount,
                "message": tip.message,
                "created_at": tip.created_at,
            }
        )
    return results
