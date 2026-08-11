from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.core.config import settings
from app.modules.calls.models import CallSession
from app.modules.commerce import service as commerce_service
from app.modules.creators import service as creator_service
from app.modules.engagement.dtos import GiftSend, RatingCreate
from app.modules.engagement.models import GiftTransaction, RatingReview, VirtualGift
from app.modules.notifications.service import create_notification


def gifts(db: DbSession):
    return list(db.scalars(select(VirtualGift).where(VirtualGift.active.is_(True)).order_by(VirtualGift.coin_price)))


def send_gift(payload: GiftSend, db: DbSession, user: CurrentUser):
    gift = db.get(VirtualGift, payload.gift_id)
    recipient = creator_service.profile_for(db, payload.recipient_id)
    if not gift or not gift.active or recipient.user_id == user.id:
        raise AppError(404, "gift_unavailable", "Gift or recipient is unavailable.")
    item = GiftTransaction(gift_id=gift.id, sender_id=user.id, creator_id=recipient.user_id, target_type=payload.target_type, target_id=payload.target_id, coin_amount=gift.coin_price)
    db.add(item); db.flush()
    commerce_service.spend_coins(db, user.id, gift.coin_price, "gift_sent", "gift", item.id)
    commission = max(0, gift.coin_price - gift.creator_earning_value)
    creator_service.credit_earning(db, recipient.user_id, gift.coin_price, commission, "gift", item.id, datetime.now(UTC) + timedelta(days=settings.creator_settlement_days))
    create_notification(db, recipient.user_id, "gift_received", "Gift received", f"You received {gift.name}.", {"screen": "EarningsWallet", "giftId": gift.id})
    db.commit(); db.refresh(item); return item


def submit_rating(payload: RatingCreate, db: DbSession, user: CurrentUser):
    session = db.get(CallSession, payload.session_id)
    if session:
        if session.status != "ended" or user.id not in {session.caller_id, session.recipient_id}:
            raise AppError(403, "completed_session_required", "Only completed-session participants can review.")
        reviewed_user_id = session.recipient_id if user.id == session.caller_id else session.caller_id
    else:
        from app.modules.chat.models import Conversation, MessageRequest

        conversation = db.get(Conversation, payload.session_id)
        paid_request = db.scalar(select(MessageRequest).where(
            MessageRequest.conversation_id == payload.session_id,
            MessageRequest.status == "accepted",
            MessageRequest.charged_at.is_not(None),
        ))
        if not conversation or not paid_request or user.id not in conversation.member_ids:
            raise AppError(403, "paid_chat_required", "Only paid-chat participants can review this conversation.")
        reviewed_user_id = next(member_id for member_id in conversation.member_ids if member_id != user.id)
    if db.scalar(select(RatingReview.id).where(RatingReview.session_id == payload.session_id)):
        raise AppError(409, "review_exists", "This session has already been reviewed.")
    item = RatingReview(creator_id=reviewed_user_id, reviewer_id=user.id, **payload.model_dump())
    profile = creator_service.profile_for(db, reviewed_user_id)
    profile.rating_total += payload.overall_rating
    profile.rating_count += 1
    if not session:
        profile.completed_sessions += 1
    db.add(item); db.commit(); db.refresh(item); return item


def user_reviews(user_id: str, db: DbSession, before: str | None = None, limit: int = 30):
    creator_service.profile_for(db, user_id)
    stmt = select(RatingReview).where(RatingReview.creator_id == user_id, RatingReview.status == "published")
    if before and (marker := db.get(RatingReview, before)): stmt = stmt.where(RatingReview.created_at < marker.created_at)
    return list(db.scalars(stmt.order_by(RatingReview.created_at.desc()).limit(min(limit, 100))))


def gift_history(db: DbSession, user: CurrentUser, direction: str = "all", before: str | None = None, limit: int = 30):
    """Return paginated gift transaction history for the current user.

    direction: 'sent' | 'received' | 'all'
    """
    if direction not in {"sent", "received", "all"}:
        from app.common.errors import AppError
        raise AppError(422, "invalid_direction", "direction must be 'sent', 'received', or 'all'.")

    stmt = select(GiftTransaction)
    if direction == "sent":
        stmt = stmt.where(GiftTransaction.sender_id == user.id)
    elif direction == "received":
        stmt = stmt.where(GiftTransaction.creator_id == user.id)
    else:
        from sqlalchemy import or_
        stmt = stmt.where(or_(GiftTransaction.sender_id == user.id, GiftTransaction.creator_id == user.id))

    if before and (marker := db.get(GiftTransaction, before)):
        stmt = stmt.where(GiftTransaction.created_at < marker.created_at)

    items = list(db.scalars(stmt.order_by(GiftTransaction.created_at.desc()).limit(min(limit, 50))))
    result = []
    for item in items:
        gift = db.get(VirtualGift, item.gift_id)
        result.append({
            "id": item.id,
            "gift_id": item.gift_id,
            "gift_name": gift.name if gift else "Unknown",
            "gift_icon": gift.icon if gift else "",
            "gift_animation_url": gift.animation_url if gift else None,
            "coin_amount": item.coin_amount,
            "sender_id": item.sender_id,
            "creator_id": item.creator_id,
            "target_type": item.target_type,
            "target_id": item.target_id,
            "direction": "sent" if item.sender_id == user.id else "received",
            "status": item.status,
            "created_at": item.created_at,
        })
    return result
