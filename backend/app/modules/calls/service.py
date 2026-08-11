from datetime import UTC, datetime, timedelta

from agora_token_builder import RtcTokenBuilder
from agora_token_builder.RtcTokenBuilder import Role_Publisher
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.core.config import settings
from app.modules.calls.models import CallSession


def _aware(value: datetime) -> datetime:
    return value if value.tzinfo else value.replace(tzinfo=UTC)


def call_for(db: Session, call_id: str, user_id: str) -> CallSession:
    item = db.get(CallSession, call_id)
    if not item or user_id not in {item.caller_id, item.recipient_id}:
        raise AppError(404, "call_not_found", "Call not found.")
    if item.status == "ringing" and _aware(item.expires_at) <= datetime.now(UTC):
        item.status = "missed"
        item.ended_at = datetime.now(UTC)
        db.commit()
    return item


def channel_name(item: CallSession) -> str:
    return f"call_{item.id.replace('-', '')}"


def rtc_credentials(item: CallSession, user_id: str) -> dict:
    if not settings.agora_app_id or not settings.agora_app_certificate:
        raise AppError(503, "agora_not_configured", "Calling service is not configured.")
    if item.status not in {"ringing", "accepted"}:
        raise AppError(409, "call_finished", "This call has already finished.")
    expires_at = datetime.now(UTC) + timedelta(seconds=settings.agora_token_ttl_seconds)
    token = RtcTokenBuilder.buildTokenWithAccount(
        settings.agora_app_id,
        settings.agora_app_certificate,
        channel_name(item),
        user_id,
        Role_Publisher,
        int(expires_at.timestamp()),
    )
    return {
        "appId": settings.agora_app_id,
        "channel": channel_name(item),
        "userAccount": user_id,
        "token": token,
        "expiresAt": expires_at.isoformat(),
    }


def response(item: CallSession, user_id: str, include_rtc: bool = False) -> dict:
    value = {
        "id": item.id,
        "conversationId": item.conversation_id,
        "callerId": item.caller_id,
        "recipientId": item.recipient_id,
        "callType": item.call_type,
        "status": item.status,
        "answeredAt": item.answered_at,
        "endedAt": item.ended_at,
        "expiresAt": item.expires_at,
        "reservedMinutes": item.reserved_minutes,
        "pricePerMinute": item.price_per_minute,
        "heldCoins": item.held_coins,
        "chargedCoins": item.charged_coins,
        "heldCreditMinutes": item.held_credit_minutes,
        "usedCreditMinutes": item.used_credit_minutes,
        "callerJoinedAt": item.caller_joined_at,
        "recipientJoinedAt": item.recipient_joined_at,
        "startedAt": item.started_at,
    }
    if include_rtc:
        value["rtc"] = rtc_credentials(item, user_id)
    return value
