"""Post Boosting Controller.

Allows authors to pin/boost their post to the top of community or main feed
for 24 hours by spending coins.
"""
from datetime import UTC, datetime, timedelta
from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.feed.models import Post
from app.modules.commerce import service as commerce_service
from app.core.config import settings


def boost_post(post_id: str, db: DbSession, user: CurrentUser):
    post = db.get(Post, post_id)
    if not post or post.status != "active":
        raise AppError(404, "post_not_found", "Post not found.")

    if post.author_id != user.id:
        raise AppError(403, "not_post_author", "Only the author can boost this post.")

    now = datetime.now(UTC)
    if post.is_boosted and post.boosted_until:
        boosted_until = (
            post.boosted_until
            if post.boosted_until.tzinfo
            else post.boosted_until.replace(tzinfo=UTC)
        )
        if boosted_until > now:
            raise AppError(400, "post_already_boosted", "This post is already boosted.")

    boost_cost = settings.post_boost_coins

    try:
        commerce_service.spend_coins(
            db,
            user.id,
            boost_cost,
            "post_boost",
            "posts",
            post.id,
        )
    except Exception as exc:
        raise AppError(
            402,
            "insufficient_coins_for_boost",
            "You do not have enough coins to boost this post.",
        ) from exc

    post.is_boosted = True
    post.boost_cost = boost_cost
    post.boosted_until = now + timedelta(hours=settings.post_boost_hours)

    db.commit()
    return {
        "is_boosted": post.is_boosted,
        "boosted_until": post.boosted_until,
        "boost_cost": post.boost_cost,
    }
