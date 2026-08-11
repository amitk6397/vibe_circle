from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class User(Base, IdMixin, TimestampMixin):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    name: Mapped[str] = mapped_column(String(80))
    age: Mapped[int] = mapped_column(Integer)
    username: Mapped[str | None] = mapped_column(String(40), unique=True, nullable=True)
    bio: Mapped[str] = mapped_column(Text, default="")
    city: Mapped[str] = mapped_column(String(80), default="")
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    languages: Mapped[list[str]] = mapped_column(JSON, default=list)
    interests: Mapped[list[str]] = mapped_column(JSON, default=list)
    conversation_topics: Mapped[list[str]] = mapped_column(JSON, default=list)
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(40), nullable=True)
    preferred_language: Mapped[str | None] = mapped_column(String(60), nullable=True)
    purposes: Mapped[list[str]] = mapped_column(JSON, default=list)
    privacy: Mapped[dict] = mapped_column(
        JSON,
        default=lambda: {
            "profileVisibility": "Everyone",
            "showOnline": True,
            "readReceipts": True,
            "allowCalls": True,
            "messagesFrom": "Everyone",
        },
    )
    notification_preferences: Mapped[dict] = mapped_column(JSON, default=dict)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[str] = mapped_column(String(20), default="active", index=True)
    role: Mapped[str] = mapped_column(String(20), default="user")
    last_active_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    vibe_status: Mapped[str | None] = mapped_column(String(40), nullable=True)
    vibe_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Referral system
    referral_code: Mapped[str | None] = mapped_column(String(16), unique=True, nullable=True, index=True)
    referred_by: Mapped[str | None] = mapped_column(String(36), nullable=True)


class Connection(Base, IdMixin, TimestampMixin):
    __tablename__ = "connections"

    requester_id: Mapped[str] = mapped_column(String(36), index=True)
    receiver_id: Mapped[str] = mapped_column(String(36), index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending")
