"""SQLAlchemy models for the Live Streaming module."""
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin, utcnow
from app.core.database import Base


class LiveStream(Base, IdMixin, TimestampMixin):
    """Represents a live stream session hosted by a user."""
    __tablename__ = "live_streams"

    host_id: Mapped[str] = mapped_column(String(36), index=True)
    title: Mapped[str] = mapped_column(String(200), default="Live Stream")
    description: Mapped[str] = mapped_column(Text, default="")
    # Status: 'live' | 'ended'
    status: Mapped[str] = mapped_column(String(20), default="live", index=True)
    # Agora channel name (unique per stream)
    channel_name: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    # Peak viewer count
    peak_viewers: Mapped[int] = mapped_column(Integer, default=0)
    # Current viewer count
    current_viewers: Mapped[int] = mapped_column(Integer, default=0)
    # Total coins/gifts received
    total_gifts_received: Mapped[int] = mapped_column(Integer, default=0)
    # Stream category tag
    category: Mapped[str] = mapped_column(String(50), default="General")
    # Thumbnail url (optional)
    thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Whether stream was forcefully ended by admin
    force_ended: Mapped[bool] = mapped_column(Boolean, default=False)


class StreamViewer(Base, IdMixin, TimestampMixin):
    """Tracks who is currently viewing a live stream."""
    __tablename__ = "stream_viewers"

    stream_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    left_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class StreamGift(Base, IdMixin, TimestampMixin):
    """Records a gift sent to a streamer during a live stream."""
    __tablename__ = "stream_gifts"

    stream_id: Mapped[str] = mapped_column(String(36), index=True)
    sender_id: Mapped[str] = mapped_column(String(36), index=True)
    host_id: Mapped[str] = mapped_column(String(36), index=True)
    gift_name: Mapped[str] = mapped_column(String(80))
    gift_emoji: Mapped[str] = mapped_column(String(10), default="🎁")
    coins_spent: Mapped[int] = mapped_column(Integer)
    coins_earned: Mapped[int] = mapped_column(Integer)  # after platform cut
