from datetime import UTC, datetime, timedelta

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.discovery.service import blocked_ids
from app.modules.matching.dtos import MatchStart
from app.modules.matching.models import Match
from app.modules.notifications.service import create_notification
from app.modules.users.models import User


def score(current: User, candidate: User, payload: MatchStart) -> int:
    value = 35 if payload.purpose in candidate.purposes else 0
    value += 20 if payload.language in candidate.languages else 0
    value += min(15, len(set(current.interests) & set(candidate.interests)) * 5)
    value += 10 if payload.min_age <= candidate.age <= payload.max_age else 0
    value += 5 if candidate.is_online else 0
    availability_active = bool(
        candidate.vibe_status
        and candidate.vibe_status != "Do not disturb"
        and candidate.vibe_expires_at
        and candidate.vibe_expires_at.replace(tzinfo=UTC) > datetime.now(UTC)
    )
    value += 10 if availability_active else 0
    value += 10 if candidate.status == "active" else 0
    return min(100, value)


def start(db: Session, current: User, payload: MatchStart) -> Match:
    excluded = blocked_ids(db, current.id)
    now = datetime.now(UTC)
    active = db.scalar(
        select(Match)
        .where(
            or_(Match.requester_id == current.id, Match.candidate_id == current.id),
            Match.status.in_(["searching", "found", "waiting"]),
        )
        .order_by(Match.created_at.desc())
    )
    if active and (not active.expires_at or active.expires_at.replace(tzinfo=UTC) > now):
        return active
    previous = list(
        db.scalars(
            select(Match).where(
                or_(Match.requester_id == current.id, Match.candidate_id == current.id)
            )
        )
    )
    recent_ids = {
        other_id
        for item in previous[-30:]
        for other_id in [
            item.candidate_id if item.requester_id == current.id else item.requester_id
        ]
        if other_id
    }
    waiting = list(
        db.scalars(
            select(Match).where(
                Match.status == "searching",
                Match.candidate_id.is_(None),
                Match.requester_id != current.id,
                Match.created_at >= now - timedelta(seconds=90),
            )
        )
    )
    compatible: list[tuple[int, Match, User]] = []
    for item in waiting:
        requester = db.get(User, item.requester_id)
        if (
            not requester
            or requester.id in excluded
            or requester.id in recent_ids
            or item.purpose != payload.purpose
            or item.language.lower() != payload.language.lower()
            or item.anonymous != payload.anonymous
            or item.session_minutes != payload.session_minutes
            or current.vibe_status == "Do not disturb"
            or requester.vibe_status == "Do not disturb"
            or not item.min_age <= current.age <= item.max_age
            or not payload.min_age <= requester.age <= payload.max_age
        ):
            continue
        compatible.append((score(current, requester, payload), item, requester))
    if compatible:
        match_score, item, _ = max(compatible, key=lambda value: value[0])
        item.candidate_id = current.id
        item.candidate_preferences = payload.model_dump()
        item.score = match_score
        item.status = "found"
        item.expires_at = now + timedelta(seconds=45)
        db.commit()
        db.refresh(item)
        create_notification(
            db,
            item.requester_id,
            "match_found",
            "A suggested connection is ready",
            "Someone relevant is ready to connect.",
            {"screen": "Connect", "matchId": item.id},
        )
        db.commit()
        return item
    item = Match(
        requester_id=current.id,
        candidate_id=None,
        score=0,
        status="searching",
        expires_at=now + timedelta(seconds=90),
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def owned(db: Session, match_id: str, user_id: str) -> Match:
    item = db.get(Match, match_id)
    if not item or user_id not in {item.requester_id, item.candidate_id}:
        raise AppError(404, "connection_not_found", "Suggested connection not found.")
    return item
