from datetime import UTC, datetime, timedelta

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.chat.dtos import MessageCreate
from app.modules.chat.models import Conversation, Message
from app.modules.moderation.models import Block
from app.modules.notifications.service import create_notification
from app.modules.users.models import User
from app.core.config import settings
from app.modules.commerce import service as commerce_service
from app.modules.commerce.models import ConversationUnlock, SubscriptionPlan
from app.modules.creators import service as creator_service
from sqlalchemy import func
from app.modules.moderation.service import scan_text


def users_are_blocked(db: Session, first_id: str, second_id: str) -> bool:
    return db.scalar(
        select(Block.id).where(
            or_(
                (Block.blocker_id == first_id) & (Block.blocked_id == second_id),
                (Block.blocker_id == second_id) & (Block.blocked_id == first_id),
            )
        )
    ) is not None


def conversation_for(db: Session, conversation_id: str, user_id: str) -> Conversation:
    item = db.get(Conversation, conversation_id)
    if not item or user_id not in item.member_ids:
        raise AppError(404, "conversation_not_found", "Conversation not found.")
    if item.type in {"private", "match_anonymous"}:
        other_id = next((member_id for member_id in item.member_ids if member_id != user_id), None)
        if other_id and users_are_blocked(db, user_id, other_id):
            raise AppError(403, "messaging_blocked", "Messaging is unavailable between these users.")
    return item


def send(db: Session, conversation: Conversation, sender_id: str, payload: MessageCreate) -> Message:
    from app.modules.matching.models import Match

    timed_match = db.scalar(select(Match).where(Match.conversation_id == conversation.id))
    if timed_match and timed_match.session_ends_at and timed_match.session_ends_at.replace(tzinfo=UTC) <= datetime.now(UTC):
        timed_match.status = "session_ended"
        db.commit()
        raise AppError(410, "connect_session_ended", "This timed Connect session has ended.")
    if not payload.text.strip() and not payload.media_url:
        raise AppError(422, "empty_message", "A message or attachment is required.")
    safety_flags = scan_text(payload.text) if payload.text else []

    # --- Paid chat session check + per-message coin deduction ---
    if conversation.type == "private":
        from app.modules.creators.models import CreatorProfile
        recipient_id = next((uid for uid in conversation.member_ids if uid != sender_id), None)
        if recipient_id:
            creator = db.scalar(select(CreatorProfile).where(CreatorProfile.user_id == recipient_id))
            if creator:
                interval = settings.chat_message_deduction_interval
                cost = settings.chat_coins_per_message
                if interval > 0 and cost > 0:
                    from app.modules.chat.models import Message as DbMessage
                    sent_count = db.scalar(
                        select(func.count(DbMessage.id)).where(
                            DbMessage.conversation_id == conversation.id,
                            DbMessage.sender_id == sender_id,
                            DbMessage.is_deleted.is_(False),
                        )
                    ) or 0
                    if (sent_count + 1) % interval == 0:
                        try:
                            commerce_service.spend_coins(
                                db,
                                sender_id,
                                cost,
                                "chat_message",
                                "conversation",
                                conversation.id,
                            )
                            # Calculate platform share and credit creator
                            commission = cost * settings.platform_commission_percent // 100
                            creator_service.credit_earning(
                                db,
                                recipient_id,
                                cost,
                                commission,
                                "chat_message",
                                conversation.id,
                                datetime.now(UTC) + timedelta(days=settings.creator_settlement_days)
                            )
                            db.flush()
                        except Exception:
                            raise AppError(402, "insufficient_coins_for_message", f"You don't have enough coins ({cost} coins needed) to send this message.")

    item = Message(
        conversation_id=conversation.id,
        sender_id=sender_id,
        delivered_at=datetime.now(UTC),
        safety_flags=safety_flags,
        **payload.model_dump(),
    )
    conversation.last_message = payload.text.strip() or payload.media_name or "Attachment"
    db.add(item)
    db.commit()
    db.refresh(item)
    recipient_id = next((member_id for member_id in conversation.member_ids if member_id != sender_id), None)
    if recipient_id and recipient_id not in conversation.muted_by:
        sender = db.get(User, sender_id)
        preview = payload.text.strip() if payload.text else f"Sent a {payload.type} message"
        create_notification(
            db,
            recipient_id,
            "message",
            sender.name if sender else "New message",
            preview[:180],
            {
                "screen": "PrivateChat",
                "chatId": conversation.id,
                "personId": sender_id,
                "name": sender.name if sender else "Member",
            },
        )
        db.commit()
    return item
