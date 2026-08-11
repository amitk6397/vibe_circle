from sqlalchemy import select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.communities.service import membership
from app.modules.feed.models import Post


def post_or_404(db: Session, post_id: str) -> Post:
    item = db.get(Post, post_id)
    if not item or item.status != "active":
        raise AppError(404, "post_not_found", "Post not found.")
    return item


def ensure_can_post(db: Session, community_id: str | None, user_id: str):
    if community_id and not membership(db, community_id, user_id):
        raise AppError(403, "membership_required", "Join the community before posting.")

