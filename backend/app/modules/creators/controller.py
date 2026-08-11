from datetime import UTC, datetime

from sqlalchemy import func, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.creators import service
from app.modules.creators.dtos import CreatorProfileUpdate, WithdrawalCreate
from app.modules.creators.models import CreatorTransaction, WithdrawalRequest
from app.modules.users.models import Connection, User
from app.modules.calls.models import CallSession
from app.modules.chat.models import MessageRequest
from app.modules.notifications.service import create_notification

def public_profile(user_id: str, db: DbSession):
    item = service.profile_for(db, user_id)
    user = db.get(User, user_id)
    from app.core.config import settings
    return {"id": item.id, "userId": user_id, "name": user.name, "avatarUrl": user.avatar_url, "verified": item.verified, "category": item.category, "topics": item.topics, "languages": item.languages, "introduction": item.introduction, "rating": item.rating_total / item.rating_count if item.rating_count else 0, "totalCompletedSessions": item.completed_sessions, "responseRate": round(item.response_count * 100 / item.request_count) if item.request_count else 100, "averageResponseSeconds": item.average_response_seconds, "availabilityStatus": "available", "chatAvailable": True, "audioAvailable": True, "videoAvailable": True, "chatPrice": settings.chat_coins_per_minute, "audioPricePerMinute": settings.audio_coins_per_minute, "videoPricePerMinute": settings.video_coins_per_minute, "schedule": {}, "maximumDailySessions": 0}


def my_profile(db: DbSession, user: CurrentUser):
    return public_profile(user.id, db)


def update_profile(payload: CreatorProfileUpdate, db: DbSession, user: CurrentUser):
    item = service.profile_for(db, user.id)
    for key, value in payload.model_dump(exclude_unset=True).items(): setattr(item, key, value)
    db.commit(); db.refresh(item)
    return public_profile(user.id, db)


def dashboard(db: DbSession, user: CurrentUser):
    profile = service.profile_for(db, user.id)
    wallet = service.settle_due(db, user.id); db.commit()
    today = datetime.now(UTC).date()
    today_earnings = db.scalar(select(func.coalesce(func.sum(CreatorTransaction.creator_amount), 0)).where(CreatorTransaction.creator_id == user.id, func.date(CreatorTransaction.created_at) == today)) or 0
    calls = list(db.scalars(select(CallSession).where(CallSession.recipient_id == user.id)))
    chat_sessions = db.scalar(select(func.count()).select_from(CreatorTransaction).where(CreatorTransaction.creator_id == user.id, CreatorTransaction.reference_type == "paid_chat")) or 0
    followers = db.scalar(select(func.count()).select_from(Connection).where(Connection.receiver_id == user.id, Connection.status == "accepted")) or 0
    upcoming_calls = sum(1 for call in calls if call.status == "ringing")
    upcoming_chats = db.scalar(select(func.count()).select_from(MessageRequest).where(MessageRequest.recipient_id == user.id, MessageRequest.status == "pending")) or 0
    return {"todayEarnings": today_earnings, "pendingEarnings": wallet.pending_earnings, "availableBalance": wallet.available_earnings, "totalEarnings": wallet.pending_earnings + wallet.available_earnings + wallet.withdrawn_earnings, "totalSessions": len(calls) + chat_sessions, "completedSessions": profile.completed_sessions, "cancelledSessions": sum(1 for call in calls if call.status in {"rejected", "missed"}), "chatSessions": chat_sessions, "audioSessions": sum(1 for call in calls if call.call_type == "audio" and call.status == "ended"), "videoSessions": sum(1 for call in calls if call.call_type == "video" and call.status == "ended"), "upcomingRequests": upcoming_calls + upcoming_chats, "followers": followers, "rating": profile.rating_total / profile.rating_count if profile.rating_count else 0, "responseRate": round(profile.response_count * 100 / profile.request_count) if profile.request_count else 100}


def earnings(db: DbSession, user: CurrentUser, before: str | None = None, limit: int = 30):
    service.profile_for(db, user.id); service.settle_due(db, user.id)
    stmt = select(CreatorTransaction).where(CreatorTransaction.creator_id == user.id)
    if before and (marker := db.get(CreatorTransaction, before)): stmt = stmt.where(CreatorTransaction.created_at < marker.created_at)
    db.commit(); return list(db.scalars(stmt.order_by(CreatorTransaction.created_at.desc()).limit(min(limit, 100))))


def request_withdrawal(payload: WithdrawalCreate, db: DbSession, user: CurrentUser):
    service.profile_for(db, user.id); wallet = service.settle_due(db, user.id)
    if wallet.available_earnings < payload.amount: raise AppError(402, "insufficient_earnings", "Available earnings are insufficient.")
    wallet.available_earnings -= payload.amount
    item = WithdrawalRequest(creator_id=user.id, amount=payload.amount, payout_account_reference=payload.payout_account_reference)
    db.add(item); db.commit(); db.refresh(item); return item


def withdrawals(db: DbSession, user: CurrentUser):
    service.profile_for(db, user.id)
    return list(db.scalars(select(WithdrawalRequest).where(WithdrawalRequest.creator_id == user.id).order_by(WithdrawalRequest.created_at.desc())))

