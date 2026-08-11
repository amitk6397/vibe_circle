from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.modules.communities.models import Community
from app.modules.feed.models import Post
from app.modules.moderation.models import Block
from app.modules.users.models import User
from app.modules.creators.models import CreatorProfile


def blocked_ids(db: Session, user_id: str) -> set[str]:
    rows = db.scalars(select(Block).where(or_(Block.blocker_id == user_id, Block.blocked_id == user_id)))
    return {row.blocked_id if row.blocker_id == user_id else row.blocker_id for row in rows}


def users(db: Session, current_id: str, query: str = "", min_age: int = 18, max_age: int = 99, online_only: bool = False, purpose: str | None = None, gender: str | None = None, city: str | None = None, languages: str | None = None):
    stmt = select(User).where(User.id != current_id, User.status == "active", User.age.between(min_age, max_age))
    excluded = blocked_ids(db, current_id)
    if excluded:
        stmt = stmt.where(User.id.not_in(excluded))
    if query:
        pattern = f"%{query.lower()}%"
        stmt = stmt.where(or_(func.lower(User.name).like(pattern), func.lower(User.username).like(pattern)))
    if online_only:
        stmt = stmt.where(User.is_online.is_(True))
    candidates = list(db.scalars(stmt.order_by(User.is_online.desc(), User.created_at.desc()).limit(100)))
    if purpose:
        normalized = purpose.casefold()
        candidates = [
            candidate for candidate in candidates
            if not candidate.purposes or normalized in {item.casefold() for item in candidate.purposes}
        ]
    if gender and gender.lower() != "any":
        candidates = [c for c in candidates if c.gender and c.gender.lower() == gender.lower()]
    if city:
        city_lower = city.lower()
        candidates = [c for c in candidates if c.city and city_lower in c.city.lower()]
    if languages:
        lang_lower = languages.lower()
        candidates = [c for c in candidates if c.languages and any(lang_lower == l.lower() for l in c.languages)]
    return candidates[:50]


def with_performance(db: Session, candidates: list[User]) -> list[User]:
    if not candidates:
        return candidates
    profiles = {
        profile.user_id: profile
        for profile in db.scalars(
            select(CreatorProfile).where(CreatorProfile.user_id.in_([item.id for item in candidates]))
        )
    }
    for candidate in candidates:
        profile = profiles.get(candidate.id)
        rating = profile.rating_total / profile.rating_count if profile and profile.rating_count else 0
        candidate.performance_rating = round(rating, 1)
        candidate.review_count = profile.rating_count if profile else 0
        candidate.completed_sessions = profile.completed_sessions if profile else 0
        candidate.performance_tier = (
            "top_performer"
            if candidate.review_count >= 3 and rating >= 4.5
            else "recommended"
            if candidate.review_count
            else "new"
        )
    return candidates


def recommended_people(db: Session, current: User, limit: int = 30):
    candidates = with_performance(db, users(db, current.id))
    interests = {item.casefold() for item in current.interests}
    topics = {item.casefold() for item in current.conversation_topics}
    languages = {item.casefold() for item in current.languages}

    def score(candidate: User):
        common_interests = len(interests & {item.casefold() for item in candidate.interests})
        common_topics = len(topics & {item.casefold() for item in candidate.conversation_topics})
        common_languages = len(languages & {item.casefold() for item in candidate.languages})
        return (
            common_interests * 5
            + common_topics * 6
            + common_languages * 3
            + int(bool(current.city and candidate.city.casefold() == current.city.casefold())) * 2
            + int(candidate.is_online) * 4
            + int(candidate.performance_rating * min(candidate.review_count, 5) * 2)
            + min(candidate.completed_sessions, 20)
        )

    return sorted(candidates, key=lambda candidate: (score(candidate), candidate.created_at), reverse=True)[:min(limit, 50)]


def all_results(db: Session, current_id: str, query: str):
    pattern = f"%{query.lower()}%"
    return {
        "users": users(db, current_id, query),
        "communities": list(db.scalars(select(Community).where(func.lower(Community.name).like(pattern), Community.status == "active").limit(20))),
        "posts": list(db.scalars(select(Post).where(func.lower(Post.body).like(pattern), Post.status == "active").limit(20))),
    }
