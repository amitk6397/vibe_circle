from datetime import UTC, datetime, timedelta

from sqlalchemy import or_, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.schemas import ApiMessage
from app.modules.chat.models import Conversation
from app.modules.matching import service
from app.modules.matching.dtos import MatchFeedback, MatchStart
from app.modules.matching.models import Match
from app.modules.notifications.service import create_notification
from app.modules.users.models import User


def response(db: DbSession, item: Match, user_id: str):
    other_id = item.candidate_id if item.requester_id == user_id else item.requester_id
    current = db.get(User, user_id)
    other = db.get(User, other_id) if other_id else None
    reasons = []
    if other:
        reasons.append("Same purpose")
        if item.language in other.languages:
            reasons.append(f"Speaks {item.language}")
        shared = list(set(current.interests) & set(other.interests))[:3]
        reasons.extend(shared)
        if other.is_online:
            reasons.append("Available now")
        if other.vibe_status and other.vibe_status != "Do not disturb":
            reasons.append(other.vibe_status)
    return {
        "id": item.id,
        "requester_id": item.requester_id,
        "candidate_id": item.candidate_id,
        "other_user_id": other_id,
        "purpose": item.purpose,
        "language": item.language,
        "anonymous": item.anonymous,
        "score": item.score,
        "reasons": reasons,
        "status": item.status,
        "accepted_by": item.accepted_by,
        "conversation_id": item.conversation_id,
        "expires_at": item.expires_at,
        "session_minutes": item.session_minutes,
        "session_ends_at": item.session_ends_at,
    }


def start(payload: MatchStart, db: DbSession, user: CurrentUser):
    return response(db, service.start(db, user, payload), user.id)


def status(db: DbSession, user: CurrentUser):
    item = db.scalar(select(Match).where(or_(Match.requester_id == user.id, Match.candidate_id == user.id)).order_by(Match.created_at.desc()))
    if not item:
        return None
    now = datetime.now(UTC)
    if item.status in {"searching", "found", "waiting"} and item.expires_at and item.expires_at.replace(tzinfo=UTC) <= now:
        item.status = "expired"
        db.commit()
    if item.status == "accepted" and item.session_ends_at and item.session_ends_at.replace(tzinfo=UTC) <= now:
        item.status = "session_ended"
        db.commit()
    return response(db, item, user.id)


def action(match_id: str, action: str, db: DbSession, user: CurrentUser):
    item = service.owned(db, match_id, user.id)
    if action not in {"accept", "reject", "skip", "cancel"}:
        from app.common.errors import AppError
        raise AppError(400, "invalid_connection_action", "Unsupported connection action.")
    if action == "accept":
        if not item.candidate_id:
            from app.common.errors import AppError
            raise AppError(409, "candidate_not_ready", "Wait for another user to join the conversation.")
        item.accepted_by = list(set([*item.accepted_by, user.id]))
        if {item.requester_id, item.candidate_id}.issubset(set(item.accepted_by)):
            existing = next((conversation for conversation in db.scalars(select(Conversation).where(Conversation.type == "private")) if set(conversation.member_ids) == {item.requester_id, item.candidate_id}), None)
            conversation = existing or Conversation(
                member_ids=[item.requester_id, item.candidate_id],
                type="match_anonymous" if item.anonymous else "private",
            )
            if not existing:
                db.add(conversation)
                db.flush()
            item.conversation_id = conversation.id
            item.status = "accepted"
            item.session_ends_at = datetime.now(UTC) + timedelta(minutes=item.session_minutes)
        else:
            item.status = "waiting"
    else:
        item.status = {"reject": "rejected", "skip": "skipped", "cancel": "cancelled"}[action]
    other_id = item.candidate_id if item.requester_id == user.id else item.requester_id
    if other_id and action == "accept":
        create_notification(
            db,
            other_id,
            "match_accepted" if item.status == "accepted" else "match_waiting",
            "Connect update",
            f"{user.name} accepted your connection.",
            {"screen": "Connect", "matchId": item.id},
        )
    db.commit()
    db.refresh(item)
    return response(db, item, user.id)


def feedback(match_id: str, payload: MatchFeedback, db: DbSession, user: CurrentUser):
    item = service.owned(db, match_id, user.id)
    item.feedback = payload.model_dump()
    db.commit()
    return ApiMessage(message="Feedback saved.")
