from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class Conversation(Base, IdMixin, TimestampMixin):
    __tablename__ = "conversations"

    type: Mapped[str] = mapped_column(String(20), default="private")
    member_ids: Mapped[list[str]] = mapped_column(JSON, default=list)
    muted_by: Mapped[list[str]] = mapped_column(JSON, default=list)
    archived_by: Mapped[list[str]] = mapped_column(JSON, default=list)
    last_message: Mapped[str] = mapped_column(String(300), default="")


class Message(Base, IdMixin, TimestampMixin):
    __tablename__ = "messages"

    conversation_id: Mapped[str] = mapped_column(String(36), index=True)
    sender_id: Mapped[str] = mapped_column(String(36), index=True)
    type: Mapped[str] = mapped_column(String(20), default="text")
    text: Mapped[str] = mapped_column(Text, default="")
    media_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    media_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    mime_type: Mapped[str | None] = mapped_column(String(120), nullable=True)
    reply_to_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    reactions: Mapped[dict] = mapped_column(JSON, default=dict)
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False)
    safety_flags: Mapped[list[str]] = mapped_column(JSON, default=list)


class MessageRequest(Base, IdMixin, TimestampMixin):
    __tablename__ = "message_requests"

    sender_id: Mapped[str] = mapped_column(String(36), index=True)
    recipient_id: Mapped[str] = mapped_column(String(36), index=True)
    introduction: Mapped[str] = mapped_column(String(300))
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)
    conversation_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    creator_chat_price: Mapped[int] = mapped_column(Integer, default=0)
    charged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    held_bonus_coins: Mapped[int] = mapped_column(Integer, default=0)
    held_purchased_coins: Mapped[int] = mapped_column(Integer, default=0)
    reserved_minutes: Mapped[int] = mapped_column(Integer, default=10)
    price_per_minute: Mapped[int] = mapped_column(Integer, default=0)
