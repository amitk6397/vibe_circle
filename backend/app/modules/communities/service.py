from sqlalchemy import select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.communities.models import Community, CommunityBan, CommunityMember


def community_or_404(db: Session, community_id: str) -> Community:
    item = db.get(Community, community_id)
    if not item or item.status != "active":
        raise AppError(404, "community_not_found", "Community not found.")
    return item


def membership(db: Session, community_id: str, user_id: str) -> CommunityMember | None:
    return db.scalar(select(CommunityMember).where(CommunityMember.community_id == community_id, CommunityMember.user_id == user_id))


def ensure_not_banned(db: Session, community_id: str, user_id: str):
    if db.scalar(select(CommunityBan.id).where(CommunityBan.community_id == community_id, CommunityBan.user_id == user_id)):
        raise AppError(403, "community_banned", "You are blocked from this community.")


def require_role(db: Session, community_id: str, user_id: str, roles: set[str]):
    member = membership(db, community_id, user_id)
    if not member or member.role not in roles:
        raise AppError(403, "community_permission_denied", "You do not have permission for this action.")
    return member
