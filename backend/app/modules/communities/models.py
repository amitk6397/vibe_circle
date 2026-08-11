from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class Community(Base, IdMixin, TimestampMixin):
    __tablename__ = "communities"

    owner_id: Mapped[str] = mapped_column(String(36), index=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    category: Mapped[str] = mapped_column(String(60), index=True)
    description: Mapped[str] = mapped_column(Text)
    privacy: Mapped[str] = mapped_column(String(30), default="public")
    rules: Mapped[list[str]] = mapped_column(JSON, default=list)
    color: Mapped[str] = mapped_column(String(10), default="#5B5CE2")
    logo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    cover_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    tags: Mapped[list[str]] = mapped_column(JSON, default=list)
    location: Mapped[str | None] = mapped_column(String(100), nullable=True)
    language: Mapped[str | None] = mapped_column(String(60), nullable=True)
    member_count: Mapped[int] = mapped_column(Integer, default=1)
    status: Mapped[str] = mapped_column(String(20), default="active")
    kind: Mapped[str] = mapped_column(String(20), default="community", index=True)
    max_members: Mapped[int] = mapped_column(Integer, default=500)
    premium_price: Mapped[int] = mapped_column(Integer, default=0)


class CommunityMember(Base, IdMixin, TimestampMixin):
    __tablename__ = "community_members"

    community_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    role: Mapped[str] = mapped_column(String(20), default="member")
    muted: Mapped[bool] = mapped_column(Boolean, default=False)


class CommunityMessage(Base, IdMixin, TimestampMixin):
    __tablename__ = "community_messages"

    community_id: Mapped[str] = mapped_column(String(36), index=True)
    author_id: Mapped[str] = mapped_column(String(36), index=True)
    text: Mapped[str] = mapped_column(Text, default="")
    media_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    media_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    mime_type: Mapped[str | None] = mapped_column(String(120), nullable=True)


class CommunityJoinRequest(Base, IdMixin, TimestampMixin):
    __tablename__ = "community_join_requests"

    community_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)


class CommunityInvite(Base, IdMixin, TimestampMixin):
    __tablename__ = "community_invites"

    community_id: Mapped[str] = mapped_column(String(36), index=True)
    inviter_id: Mapped[str] = mapped_column(String(36), index=True)
    invited_user_id: Mapped[str] = mapped_column(String(36), index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)


class CommunitySubscription(Base, IdMixin, TimestampMixin):
    __tablename__ = "community_subscriptions"
    community_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    coin_amount: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="active", index=True)
    # Subscription expiry for monthly renewals
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)


class CommunityBan(Base, IdMixin, TimestampMixin):
    __tablename__ = "community_bans"
    community_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    banned_by: Mapped[str] = mapped_column(String(36))
    reason: Mapped[str] = mapped_column(String(200), default="")
