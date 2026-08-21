from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.modules.chat import service
from app.modules.chat.dtos import ConversationCreate, ConversationSettings, MessageCreate, MessageEdit, MessageRequestAction, MessageRequestCreate, ReactionCreate
from app.modules.chat.models import Conversation, Message, MessageRequest
from app.modules.moderation.models import Block
from app.modules.notifications.service import create_notification
from app.modules.commerce import service as commerce_service
from app.modules.commerce.models import ConversationUnlock, SubscriptionPlan
from app.modules.moderation.service import scan_text
from app.core.config import settings as app_settings
from app.modules.users.models import Connection, User
from app.modules.creators import service as creator_service


def conversations(db: DbSession, user: CurrentUser, folder: str = "active"):
    if folder not in {"active", "archived", "paid"}:
        raise AppError(422, "invalid_chat_folder", "Unsupported chat folder.")
    items = list(db.scalars(select(Conversation).order_by(Conversation.updated_at.desc())))
    visible = [
        item
        for item in items
        if user.id in item.member_ids
        and ((folder == "archived" and user.id in item.archived_by) or (folder != "archived" and user.id not in item.archived_by))
        and (
            item.type not in {"private", "match_anonymous"}
            or not service.users_are_blocked(
                db,
                user.id,
                next((member_id for member_id in item.member_ids if member_id != user.id), ""),
            )
        )
    ]
    if folder == "paid":
        paid_conversation_ids = set(db.scalars(select(MessageRequest.conversation_id).where(MessageRequest.creator_chat_price > 0, MessageRequest.status == "accepted")))
        from app.modules.calls.models import CallSession
        paid_conversation_ids |= set(db.scalars(select(CallSession.conversation_id).where((CallSession.price_per_minute > 0) | (CallSession.used_credit_minutes > 0))))
        visible = [item for item in visible if item.id in paid_conversation_ids]
    return [
        {
            "id": item.id,
            "type": item.type,
            "member_ids": item.member_ids,
            "last_message": item.last_message,
            "updated_at": item.updated_at,
            "muted": user.id in item.muted_by,
            "unread_count": db.scalar(
                select(func.count()).select_from(Message).where(
                    Message.conversation_id == item.id,
                    Message.sender_id != user.id,
                    Message.read_at.is_(None),
                )
            ) or 0,
        }
        for item in visible
    ]


def create_conversation(payload: ConversationCreate, db: DbSession, user: CurrentUser):
    if payload.member_id == user.id or not db.get(User, payload.member_id):
        raise AppError(404, "user_not_found", "User not found.")
    if service.users_are_blocked(db, user.id, payload.member_id):
        raise AppError(403, "messaging_blocked", "Messaging is unavailable between these users.")
    items = list(db.scalars(select(Conversation).where(Conversation.type == "private")))
    for item in items:
        if set(item.member_ids) == {user.id, payload.member_id}:
            return item
    recipient = db.get(User, payload.member_id)
    permission = (recipient.privacy or {}).get("messagesFrom", "Everyone")
    follows_recipient = db.scalar(
        select(Connection.id).where(
            Connection.requester_id == user.id,
            Connection.receiver_id == recipient.id,
            Connection.status == "accepted",
        )
    ) is not None
    if permission == "Nobody" or (permission == "Followers" and not follows_recipient):
        raise AppError(
            403,
            "message_request_denied",
            "This user only accepts messages from approved followers.",
        )
    approved_request = db.scalar(select(MessageRequest.id).where(
        MessageRequest.status == "accepted",
        ((MessageRequest.sender_id == user.id) & (MessageRequest.recipient_id == payload.member_id))
        | ((MessageRequest.sender_id == payload.member_id) & (MessageRequest.recipient_id == user.id)),
    ))
    approved_connection = db.scalar(select(Connection.id).where(
        Connection.status == "accepted",
        ((Connection.requester_id == user.id) & (Connection.receiver_id == payload.member_id))
        | ((Connection.requester_id == payload.member_id) & (Connection.receiver_id == user.id)),
    ))
    # Allow if: permission is Everyone, or user is a follower, or already connected.
    # No message-request gate is needed — direct conversation is the primary flow.
    item = Conversation(member_ids=[user.id, payload.member_id])
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def _request_json(db: DbSession, item: MessageRequest):
    sender = db.get(User, item.sender_id)
    accepted_at = item.accepted_at if item.accepted_at and item.accepted_at.tzinfo else (item.accepted_at.replace(tzinfo=UTC) if item.accepted_at else None)
    return {
        "id": item.id,
        "senderId": item.sender_id,
        "senderName": sender.name if sender else "Member",
        "recipientId": item.recipient_id,
        "introduction": item.introduction,
        "status": item.status,
        "conversationId": item.conversation_id,
        "createdAt": item.created_at,
        "chatPrice": item.creator_chat_price,
        "chatPricePerMinute": item.price_per_minute,
        "reservedMinutes": item.reserved_minutes,
        "sessionEndsAt": accepted_at + timedelta(minutes=item.reserved_minutes) if accepted_at else None,
        "paid": item.charged_at is not None,
    }


def _expire_message_requests(db: DbSession, *, sender_id: str | None = None, recipient_id: str | None = None):
    cutoff = datetime.now(UTC) - timedelta(hours=app_settings.message_request_expiry_hours)
    stmt = select(MessageRequest).where(MessageRequest.status == "pending", MessageRequest.created_at < cutoff)
    if sender_id: stmt = stmt.where(MessageRequest.sender_id == sender_id)
    if recipient_id: stmt = stmt.where(MessageRequest.recipient_id == recipient_id)
    changed = False
    for item in db.scalars(stmt):
        if item.creator_chat_price and (item.held_bonus_coins or item.held_purchased_coins):
            commerce_service.settle_hold(db, item.sender_id, item.creator_chat_price, item.held_bonus_coins, item.held_purchased_coins, 0, "message_request", item.id)
        item.status = "expired"; changed = True
    if changed: db.commit()


def message_requests(db: DbSession, user: CurrentUser):
    _expire_message_requests(db, recipient_id=user.id)
    items = db.scalars(
        select(MessageRequest).where(MessageRequest.recipient_id == user.id).order_by(MessageRequest.created_at.desc())
    )
    return [_request_json(db, item) for item in items]


def create_message_request(payload: MessageRequestCreate, db: DbSession, user: CurrentUser):
    if payload.duration_minutes not in app_settings.paid_chat_duration_options:
        raise AppError(422, "invalid_chat_duration", "Choose one of the configured paid-chat durations.")
    _expire_message_requests(db, sender_id=user.id)
    scan_text(payload.introduction, allow_contact_details=False)
    recipient = db.get(User, payload.recipient_id)
    if not recipient or recipient.id == user.id or service.users_are_blocked(db, user.id, recipient.id):
        raise AppError(404, "user_not_found", "User not found.")
    permission = (recipient.privacy or {}).get("message", (recipient.privacy or {}).get("messagesFrom", "Everyone"))
    follows = db.scalar(select(Connection.id).where(Connection.requester_id == user.id, Connection.receiver_id == recipient.id, Connection.status == "accepted")) is not None
    if permission == "Nobody" or (permission in {"Followers", "Approved connections"} and not follows):
        raise AppError(403, "message_request_denied", "This user is not accepting your message requests.")
    since = datetime.now(UTC) - timedelta(days=1)
    sent_today = db.scalar(select(func.count()).select_from(MessageRequest).where(
        MessageRequest.sender_id == user.id, MessageRequest.created_at >= since
    )) or 0
    if sent_today >= app_settings.message_requests_per_day:
        raise AppError(429, "message_request_limit", "Daily message request limit reached.")
    existing = db.scalar(select(MessageRequest).where(
        MessageRequest.sender_id == user.id,
        MessageRequest.recipient_id == recipient.id,
        MessageRequest.status == "pending",
    ))
    if existing:
        return _request_json(db, existing)
    creator = creator_service.profile_for(db, recipient.id, False)
    price_per_minute = app_settings.chat_coins_per_minute
    creator_chat_price = price_per_minute * payload.duration_minutes
    if creator_chat_price:
        wallet = commerce_service.wallet_for(db, user.id)
        if wallet.bonus_coins + wallet.purchased_coins < creator_chat_price:
            raise AppError(402, "insufficient_coins", "Add coins before requesting this paid chat.")
    if creator:
        creator.request_count += 1
    item = MessageRequest(sender_id=user.id, recipient_id=recipient.id, introduction=payload.introduction.strip(), creator_chat_price=creator_chat_price, reserved_minutes=payload.duration_minutes, price_per_minute=price_per_minute)
    db.add(item)
    db.flush()
    if creator_chat_price:
        item.held_bonus_coins, item.held_purchased_coins = commerce_service.hold_coins(db, user.id, creator_chat_price, "message_request", item.id)
    create_notification(db, recipient.id, "message_request", "New message request", f"{user.name} sent an introduction.", {"screen": "MessageRequests", "requestId": item.id})
    db.commit()
    db.refresh(item)
    return _request_json(db, item)


def message_request_action(request_id: str, payload: MessageRequestAction, db: DbSession, user: CurrentUser):
    item = db.get(MessageRequest, request_id)
    if not item or item.recipient_id != user.id or item.status != "pending":
        raise AppError(404, "message_request_not_found", "Message request not found.")
    recipient_creator = creator_service.profile_for(db, user.id, False)
    if recipient_creator:
        response_seconds = max(0, int((datetime.now(UTC) - (item.created_at if item.created_at.tzinfo else item.created_at.replace(tzinfo=UTC))).total_seconds()))
        total_seconds = recipient_creator.average_response_seconds * recipient_creator.response_count
        recipient_creator.response_count += 1
        recipient_creator.average_response_seconds = (total_seconds + response_seconds) // recipient_creator.response_count
    if payload.action in {"block", "reject"} and item.creator_chat_price and (item.held_bonus_coins or item.held_purchased_coins):
        commerce_service.settle_hold(db, item.sender_id, item.creator_chat_price, item.held_bonus_coins, item.held_purchased_coins, 0, "message_request", item.id)
    if payload.action == "block":
        if not db.scalar(select(Block.id).where(Block.blocker_id == user.id, Block.blocked_id == item.sender_id)):
            db.add(Block(blocker_id=user.id, blocked_id=item.sender_id))
        item.status = "blocked"
    elif payload.action == "reject":
        item.status = "rejected"
    else:
        if item.creator_chat_price and not item.charged_at:
            if item.held_bonus_coins or item.held_purchased_coins:
                commerce_service.settle_hold(db, item.sender_id, item.creator_chat_price, item.held_bonus_coins, item.held_purchased_coins, item.creator_chat_price, "message_request", item.id)
            else:
                commerce_service.spend_coins(db, item.sender_id, item.creator_chat_price, "paid_chat", "message_request", item.id)
            commission = item.creator_chat_price * app_settings.platform_commission_percent // 100
            creator_service.credit_earning(db, item.recipient_id, item.creator_chat_price, commission, "paid_chat", item.id, datetime.now(UTC) + timedelta(days=app_settings.creator_settlement_days))
            item.charged_at = datetime.now(UTC)
            create_notification(db, item.recipient_id, "earnings_received", "Paid chat accepted", f"{item.creator_chat_price - commission} coins were added to pending earnings.", {"screen": "EarningsWallet", "requestId": item.id})
        conversation = next((row for row in db.scalars(select(Conversation).where(Conversation.type == "private")) if set(row.member_ids) == {item.sender_id, item.recipient_id}), None)
        if not conversation:
            conversation = Conversation(member_ids=[item.sender_id, item.recipient_id])
            db.add(conversation)
            db.flush()
        item.status = "accepted"
        item.accepted_at = datetime.now(UTC)
        item.conversation_id = conversation.id
        create_notification(db, item.sender_id, "message_request_accepted", "Message request accepted", f"{user.name} accepted your introduction.", {"screen": "PrivateChat", "chatId": conversation.id, "personId": user.id, "name": user.name, "sessionEndsAt": (item.accepted_at + timedelta(minutes=item.reserved_minutes)).isoformat()})
    db.commit()
    db.refresh(item)
    return _request_json(db, item)


def chat_limits(db: DbSession, user: CurrentUser, conversation_id: str | None = None):
    week_start = datetime.now(UTC) - timedelta(days=7)
    used = db.scalar(select(func.count()).select_from(MessageRequest).where(
        MessageRequest.sender_id == user.id, MessageRequest.status == "accepted", MessageRequest.accepted_at >= week_start
    )) or 0
    message_used = 0
    if conversation_id:
        service.conversation_for(db, conversation_id, user.id)
        message_used = db.scalar(select(func.count()).select_from(Message).where(
            Message.conversation_id == conversation_id, Message.sender_id == user.id, Message.is_deleted.is_(False)
        )) or 0
    subscription = commerce_service.active_subscription(db, user.id)
    wallet = commerce_service.wallet_for(db, user.id)
    db.commit()
    return {
        "weeklyConversationLimit": app_settings.free_conversations_per_week,
        "weeklyConversationUsed": used,
        "messagesPerConversation": app_settings.free_messages_per_conversation,
        "conversationMessageUsed": message_used,
        "subscriptionActive": subscription is not None,
        "canUseChatCredit": wallet.chat_credits > 0,
        "resetAt": datetime.now(UTC) + timedelta(days=7),
        "coinsPerMinute": app_settings.chat_coins_per_minute,
        "durationOptions": app_settings.paid_chat_duration_options,
        "chatCoinsPerMessage": app_settings.chat_coins_per_message,
        "chatMessageDeductionInterval": app_settings.chat_message_deduction_interval,
    }


def unlock_conversation(conversation_id: str, db: DbSession, user: CurrentUser):
    raise AppError(410, "chat_credits_retired", "Chat credits are no longer used. Buy coins to start a paid chat.")


def messages(conversation_id: str, db: DbSession, user: CurrentUser, before: str | None = None, limit: int = 30):
    service.conversation_for(db, conversation_id, user.id)
    stmt = select(Message).where(Message.conversation_id == conversation_id)
    if before:
        marker = db.get(Message, before)
        if marker:
            stmt = stmt.where(Message.created_at < marker.created_at)
    return list(reversed(list(db.scalars(stmt.order_by(Message.created_at.desc()).limit(min(limit, 100))))))


def send_message(conversation_id: str, payload: MessageCreate, db: DbSession, user: CurrentUser):
    return service.send(db, service.conversation_for(db, conversation_id, user.id), user.id, payload)


def read_messages(conversation_id: str, db: DbSession, user: CurrentUser):
    service.conversation_for(db, conversation_id, user.id)
    if not (user.privacy or {}).get("readReceipts", True):
        return ApiMessage(message="Read receipts are disabled.")
    items = db.scalars(select(Message).where(Message.conversation_id == conversation_id, Message.sender_id != user.id, Message.read_at.is_(None)))
    now = datetime.now(UTC)
    for item in items:
        item.read_at = now
    db.commit()
    return ApiMessage(message="Messages marked as read.")


def react(message_id: str, payload: ReactionCreate, db: DbSession, user: CurrentUser):
    item = db.get(Message, message_id)
    if not item:
        raise AppError(404, "message_not_found", "Message not found.")
    service.conversation_for(db, item.conversation_id, user.id)
    item.reactions = {**item.reactions, user.id: payload.emoji}
    db.commit()
    db.refresh(item)
    return item


def delete_message(message_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Message, message_id)
    if not item or item.sender_id != user.id:
        raise AppError(404, "message_not_found", "Message not found.")
    item.text = ""
    item.media_url = None
    item.is_deleted = True
    db.commit()
    return ApiMessage(message="Message deleted.")


def edit_message(message_id: str, payload: MessageEdit, db: DbSession, user: CurrentUser):
    item = db.get(Message, message_id)
    if not item or item.sender_id != user.id:
        raise AppError(404, "message_not_found", "Message not found.")
    if item.is_deleted:
        raise AppError(400, "cannot_edit_deleted", "Cannot edit a deleted message.")
    new_text = payload.text.strip()
    if not new_text:
        raise AppError(400, "empty_text", "Message text cannot be empty.")
    item.text = new_text
    db.commit()
    db.refresh(item)
    return item


def settings(conversation_id: str, payload: ConversationSettings, db: DbSession, user: CurrentUser):
    item = service.conversation_for(db, conversation_id, user.id)
    if payload.muted is not None:
        item.muted_by = list(set(item.muted_by + [user.id])) if payload.muted else [x for x in item.muted_by if x != user.id]
    if payload.archived is not None:
        item.archived_by = list(set(item.archived_by + [user.id])) if payload.archived else [x for x in item.archived_by if x != user.id]
    db.commit()
    return item


def clear(conversation_id: str, db: DbSession, user: CurrentUser):
    service.conversation_for(db, conversation_id, user.id)
    # A production multi-user clear uses per-member visibility rows; current local API hard-deletes only own messages.
    for item in db.scalars(select(Message).where(Message.conversation_id == conversation_id, Message.sender_id == user.id)):
        item.is_deleted = True
        item.text = ""
        item.media_url = None
    db.commit()
    return ApiMessage(message="Your messages were cleared.")


def deduct_chat_minute(conversation_id: str, db: DbSession, user: CurrentUser):
    from app.modules.creators.models import CreatorProfile
    
    # Verify access
    conversation = service.conversation_for(db, conversation_id, user.id)
    recipient_id = next((uid for uid in conversation.member_ids if uid != user.id), None)
    if not recipient_id:
        raise AppError(400, "no_recipient", "Cannot deduct for self-chats.")
    
    # Check if recipient is a creator (they are eligible to receive coins)
    creator = db.scalar(select(CreatorProfile).where(CreatorProfile.user_id == recipient_id))
    rate = app_settings.chat_coins_per_minute
    
    if creator and rate > 0:
        wallet = commerce_service.wallet_for(db, user.id)
        if wallet.bonus_coins + wallet.purchased_coins < rate:
            raise AppError(402, "insufficient_coins", "Add coins to continue chatting.")
        
        # Deduct coins from user
        commerce_service.spend_coins(db, user.id, rate, "paid_chat_minute", "conversation", conversation.id)
        
        # Calculate platform share and credit creator
        commission = rate * app_settings.platform_commission_percent // 100
        creator_service.credit_earning(
            db,
            recipient_id,
            rate,
            commission,
            "paid_chat_minute",
            conversation.id,
            datetime.now(UTC) + timedelta(days=app_settings.creator_settlement_days)
        )
        db.commit()
        db.refresh(wallet)
        
        return {
            "coinsDeducted": rate,
            "currentBalance": wallet.bonus_coins + wallet.purchased_coins,
            "message": f"Deducted {rate} coins for chat minute."
        }
    
    return {
        "coinsDeducted": 0,
        "currentBalance": 0,
        "message": "Free conversation."
    }

