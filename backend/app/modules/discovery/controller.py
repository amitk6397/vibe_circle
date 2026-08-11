from sqlalchemy import select

from app.common.dependencies import CurrentUser, DbSession
from app.modules.communities.models import Community
from app.modules.discovery import service
from app.modules.feed.models import Post


def search(q: str, db: DbSession, user: CurrentUser):
    return service.all_results(db, user.id, q.strip())


def discover_users(db: DbSession, user: CurrentUser, q: str = "", min_age: int = 18, max_age: int = 99, online_only: bool = False, purpose: str | None = None, gender: str | None = None, city: str | None = None, languages: str | None = None):
    items = service.users(db, user.id, q, min_age, max_age, online_only, purpose, gender, city, languages)
    return service.with_performance(db, items)


def recommended_people(db: DbSession, user: CurrentUser, limit: int = 30):
    return service.recommended_people(db, user, limit)


def discover_communities(db: DbSession, _: CurrentUser, category: str | None = None):
    stmt = select(Community).where(Community.status == "active")
    if category:
        stmt = stmt.where(Community.category == category)
    return list(db.scalars(stmt.order_by(Community.member_count.desc()).limit(50)))


def discover_posts(db: DbSession, _: CurrentUser):
    return list(db.scalars(select(Post).where(Post.status == "active").order_by(Post.created_at.desc()).limit(50)))
