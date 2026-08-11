from datetime import datetime

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class CallSession(Base, IdMixin, TimestampMixin):
    __tablename__ = "call_sessions"

    conversation_id: Mapped[str] = mapped_column(String(36), index=True)
    caller_id: Mapped[str] = mapped_column(String(36), index=True)
    recipient_id: Mapped[str] = mapped_column(String(36), index=True)
    call_type: Mapped[str] = mapped_column(String(10))
    status: Mapped[str] = mapped_column(String(20), default="ringing", index=True)
    answered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    reserved_minutes: Mapped[int] = mapped_column(Integer, default=0)
    price_per_minute: Mapped[int] = mapped_column(Integer, default=0)
    held_coins: Mapped[int] = mapped_column(Integer, default=0)
    held_bonus_coins: Mapped[int] = mapped_column(Integer, default=0)
    held_purchased_coins: Mapped[int] = mapped_column(Integer, default=0)
    charged_coins: Mapped[int] = mapped_column(Integer, default=0)
    held_credit_minutes: Mapped[int] = mapped_column(Integer, default=0)
    used_credit_minutes: Mapped[int] = mapped_column(Integer, default=0)
    caller_joined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    recipient_joined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # How the call ended: 'user_ended', 'grace_timeout', 'recipient_rejected', 'missed', 'admin_ended'
    end_reason: Mapped[str | None] = mapped_column(String(30), nullable=True)
