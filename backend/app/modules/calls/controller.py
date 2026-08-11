from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.core.config import settings
from app.modules.calls import service
from app.modules.calls.dtos import CallCreate, CallExtension
from app.modules.calls.models import CallSession
from app.modules.chat import service as chat_service
from app.modules.notifications.service import create_notification
from app.modules.creators import service as creator_service
from app.modules.commerce import service as commerce_service


def create_call(payload: CallCreate, db: DbSession, user: CurrentUser):
    if payload.duration_minutes not in settings.call_duration_options:
        raise AppError(422, "invalid_call_duration", "Choose one of the configured call durations.")
    if payload.conversation_id:
        conversation = chat_service.conversation_for(db, payload.conversation_id, user.id)
        recipient_id = next((member for member in conversation.member_ids if member != user.id), None)
    else:
        from app.modules.chat.models import Conversation
        recipient_id = payload.recipient_id
        creator_service.profile_for(db, recipient_id)
        conversation = next((row for row in db.scalars(select(Conversation).where(Conversation.type == "private")) if set(row.member_ids) == {user.id, recipient_id}), None)
        if not conversation:
            conversation = Conversation(member_ids=[user.id, recipient_id])
            db.add(conversation); db.flush()
    if not recipient_id:
        raise AppError(422, "call_recipient_missing", "Call recipient is unavailable.")
    creator = creator_service.profile_for(db, recipient_id, False)
    if creator:
        creator.request_count += 1
    price_per_minute = settings.audio_coins_per_minute if payload.call_type == "audio" else settings.video_coins_per_minute
    wallet = commerce_service.wallet_for(db, user.id)
    if wallet.bonus_coins + wallet.purchased_coins < price_per_minute * payload.duration_minutes:
        raise AppError(402, "insufficient_coins", "Add coins before requesting this session.")
    active = next(
        (
            call
            for call in db.scalars(
                select(CallSession).where(CallSession.status.in_(["ringing", "accepted"]))
            )
            if {call.caller_id, call.recipient_id} & {user.id, recipient_id}
        ),
        None,
    )
    if active:
        service.call_for(db, active.id, user.id)
        if active.status in {"ringing", "accepted"}:
            raise AppError(409, "call_in_progress", "A call is already active for this chat.")
    item = CallSession(
        conversation_id=conversation.id,
        caller_id=user.id,
        recipient_id=recipient_id,
        call_type=payload.call_type,
        expires_at=datetime.now(UTC) + timedelta(seconds=settings.call_ring_timeout_seconds),
        reserved_minutes=payload.duration_minutes,
        price_per_minute=price_per_minute,
    )
    db.add(item)
    db.flush()
    create_notification(
        db,
        recipient_id,
        "incoming_call",
        f"Incoming {payload.call_type} call",
        f"{user.name} is calling you.",
        {
            "screen": "IncomingCall",
            "callId": item.id,
            "chatId": conversation.id,
            "personId": user.id,
            "name": user.name,
            "callType": payload.call_type,
        },
    )
    db.commit()
    db.refresh(item)
    return service.response(item, user.id, include_rtc=True)


def get_call(call_id: str, db: DbSession, user: CurrentUser):
    item = service.call_for(db, call_id, user.id)
    expires_at = item.expires_at if item.expires_at.tzinfo else item.expires_at.replace(tzinfo=UTC)
    if item.status == "accepted" and expires_at <= datetime.now(UTC):
        return call_action(call_id, "end", db, user)
    return service.response(item, user.id)


def call_history(db: DbSession, user: CurrentUser, before: str | None = None, limit: int = 30):
    stmt = select(CallSession).where((CallSession.caller_id == user.id) | (CallSession.recipient_id == user.id))
    if before and (marker := db.get(CallSession, before)):
        stmt = stmt.where(CallSession.created_at < marker.created_at)
    return [service.response(item, user.id) for item in db.scalars(stmt.order_by(CallSession.created_at.desc()).limit(min(limit, 100)))]


def rtc_token(call_id: str, db: DbSession, user: CurrentUser):
    item = service.call_for(db, call_id, user.id)
    expires_at = item.expires_at if item.expires_at.tzinfo else item.expires_at.replace(tzinfo=UTC)
    if item.status == "accepted" and expires_at <= datetime.now(UTC):
        call_action(call_id, "end", db, user)
        raise AppError(409, "call_finished", "This call has already finished.")
    if user.id == item.recipient_id and item.status != "accepted":
        raise AppError(403, "call_not_accepted", "Accept the call before joining.")
    return service.rtc_credentials(item, user.id)


def call_action(call_id: str, action: str, db: DbSession, user: CurrentUser):
    item = service.call_for(db, call_id, user.id)
    if action not in {"accept", "reject", "end"}:
        raise AppError(400, "invalid_call_action", "Unsupported call action.")
    if action in {"accept", "reject"} and user.id != item.recipient_id:
        raise AppError(403, "call_action_forbidden", "Only the recipient can answer this call.")
    if item.status not in {"ringing", "accepted"}:
        raise AppError(409, "call_finished", "This call has already finished.")
    if action in {"accept", "reject"} and (creator := creator_service.profile_for(db, item.recipient_id, False)):
        response_seconds = max(0, int((datetime.now(UTC) - (item.created_at if item.created_at.tzinfo else item.created_at.replace(tzinfo=UTC))).total_seconds()))
        total_seconds = creator.average_response_seconds * creator.response_count
        creator.response_count += 1
        creator.average_response_seconds = (total_seconds + response_seconds) // creator.response_count
    now = datetime.now(UTC)
    item.status = {"accept": "accepted", "reject": "rejected", "end": "ended"}[action]
    if action == "accept":
        if item.price_per_minute and not item.held_coins:
            item.held_coins = item.price_per_minute * item.reserved_minutes
            item.held_bonus_coins, item.held_purchased_coins = commerce_service.hold_coins(db, item.caller_id, item.held_coins, "call", item.id)
        item.answered_at = now
        item.expires_at = now + timedelta(seconds=settings.call_join_timeout_seconds)
    else:
        item.ended_at = now
        if action == "end" and item.held_coins:
            started = item.started_at if item.started_at and item.started_at.tzinfo else (item.started_at.replace(tzinfo=UTC) if item.started_at else None)
            elapsed_seconds = max(0, int((now - started).total_seconds())) if started else 0
            billed_minutes = min(item.reserved_minutes, max(1, (elapsed_seconds + 59) // 60)) if started else 0
            item.used_credit_minutes = 0
            item.charged_coins = min(item.held_coins, billed_minutes * item.price_per_minute)
            if item.held_coins:
                commerce_service.settle_hold(db, item.caller_id, item.held_coins, item.held_bonus_coins, item.held_purchased_coins, item.charged_coins, "call", item.id)
            creator = creator_service.profile_for(db, item.recipient_id, False)
            if creator and item.charged_coins:
                creator_gross = item.charged_coins
                commission = creator_gross * settings.platform_commission_percent // 100
                creator_service.credit_earning(db, creator.user_id, creator_gross, commission, "call", item.id, now + timedelta(days=settings.creator_settlement_days))
                creator.completed_sessions += 1
    target_id = item.caller_id if user.id == item.recipient_id else item.recipient_id
    create_notification(
        db,
        target_id,
        f"call_{item.status}",
        "Call update",
        f"{user.name} {item.status} the call.",
        {
            "callId": item.id,
            "chatId": item.conversation_id,
            "callType": item.call_type,
            "status": item.status,
        },
    )
    db.commit()
    db.refresh(item)
    return service.response(item, user.id, include_rtc=action == "accept")


def call_config():
    return {"durationOptions": settings.call_duration_options, "audioCoinsPerMinute": settings.audio_coins_per_minute, "videoCoinsPerMinute": settings.video_coins_per_minute}


def join_call(call_id: str, db: DbSession, user: CurrentUser):
    item = service.call_for(db, call_id, user.id)
    if item.status not in {"ringing", "accepted"}:
        raise AppError(409, "call_finished", "This call has already finished.")
    now = datetime.now(UTC)
    if user.id == item.caller_id and not item.caller_joined_at:
        item.caller_joined_at = now
    if user.id == item.recipient_id:
        if item.status != "accepted": raise AppError(403, "call_not_accepted", "Accept the call before joining.")
        if not item.recipient_joined_at: item.recipient_joined_at = now
    if item.status == "accepted" and item.caller_joined_at and item.recipient_joined_at and not item.started_at:
        item.started_at = now
        item.expires_at = now + timedelta(minutes=item.reserved_minutes)
    db.commit(); db.refresh(item)
    return service.response(item, user.id)


def extend_call(call_id: str, payload: CallExtension, db: DbSession, user: CurrentUser):
    if payload.duration_minutes not in settings.call_duration_options:
        raise AppError(422, "invalid_call_duration", "Choose one of the configured call durations.")
    item = service.call_for(db, call_id, user.id)
    if item.status != "accepted" or user.id != item.caller_id:
        raise AppError(409, "call_extension_unavailable", "Only the paying caller can extend an active session.")
    extra_coins = payload.duration_minutes * item.price_per_minute
    bonus, purchased = commerce_service.hold_coins(db, item.caller_id, extra_coins, "call", item.id)
    item.held_coins += extra_coins
    item.held_bonus_coins += bonus
    item.held_purchased_coins += purchased
    item.reserved_minutes += payload.duration_minutes
    item.expires_at = item.expires_at + timedelta(minutes=payload.duration_minutes)
    db.commit(); db.refresh(item)
    return service.response(item, user.id)
