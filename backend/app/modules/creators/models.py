from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class CreatorApplication(Base, IdMixin, TimestampMixin):
    __tablename__ = "creator_applications"
    user_id: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    languages: Mapped[list[str]] = mapped_column(JSON, default=list)
    topics: Mapped[list[str]] = mapped_column(JSON, default=list)
    experience: Mapped[str] = mapped_column(Text, default="")
    introduction: Mapped[str] = mapped_column(Text, default="")
    chat_available: Mapped[bool] = mapped_column(Boolean, default=True)
    audio_available: Mapped[bool] = mapped_column(Boolean, default=False)
    video_available: Mapped[bool] = mapped_column(Boolean, default=False)
    preferred_pricing: Mapped[dict] = mapped_column(JSON, default=dict)
    identity_document_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    selfie_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    payout_account_reference: Mapped[str | None] = mapped_column(String(120), nullable=True)
    terms_accepted: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[str] = mapped_column(String(20), default="draft", index=True)
    review_note: Mapped[str] = mapped_column(Text, default="")
    reviewed_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class CreatorProfile(Base, IdMixin, TimestampMixin):
    __tablename__ = "creator_profiles"
    user_id: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    category: Mapped[str] = mapped_column(String(80), default="Community member")
    topics: Mapped[list[str]] = mapped_column(JSON, default=list)
    languages: Mapped[list[str]] = mapped_column(JSON, default=list)
    introduction: Mapped[str] = mapped_column(Text, default="")
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[str] = mapped_column(String(20), default="active", index=True)
    rating_total: Mapped[int] = mapped_column(Integer, default=0)
    rating_count: Mapped[int] = mapped_column(Integer, default=0)
    completed_sessions: Mapped[int] = mapped_column(Integer, default=0)
    response_count: Mapped[int] = mapped_column(Integer, default=0)
    request_count: Mapped[int] = mapped_column(Integer, default=0)
    average_response_seconds: Mapped[int] = mapped_column(Integer, default=0)
    availability_status: Mapped[str] = mapped_column(String(20), default="offline")
    chat_available: Mapped[bool] = mapped_column(Boolean, default=True)
    audio_available: Mapped[bool] = mapped_column(Boolean, default=True)
    video_available: Mapped[bool] = mapped_column(Boolean, default=True)
    chat_price: Mapped[int] = mapped_column(Integer, default=10)
    audio_price_per_minute: Mapped[int] = mapped_column(Integer, default=5)
    video_price_per_minute: Mapped[int] = mapped_column(Integer, default=10)
    schedule: Mapped[dict] = mapped_column(JSON, default=dict)
    maximum_daily_sessions: Mapped[int] = mapped_column(Integer, default=10)


class CreatorWallet(Base, IdMixin, TimestampMixin):
    __tablename__ = "creator_wallets"
    creator_id: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    pending_earnings: Mapped[int] = mapped_column(Integer, default=0)
    available_earnings: Mapped[int] = mapped_column(Integer, default=0)
    withdrawn_earnings: Mapped[int] = mapped_column(Integer, default=0)
    refunded_earnings: Mapped[int] = mapped_column(Integer, default=0)


class CreatorTransaction(Base, IdMixin, TimestampMixin):
    __tablename__ = "creator_transactions"
    creator_id: Mapped[str] = mapped_column(String(36), index=True)
    transaction_type: Mapped[str] = mapped_column(String(40), index=True)
    gross_amount: Mapped[int] = mapped_column(Integer)
    commission_amount: Mapped[int] = mapped_column(Integer, default=0)
    creator_amount: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), index=True)
    reference_type: Mapped[str] = mapped_column(String(40))
    reference_id: Mapped[str] = mapped_column(String(36), index=True)
    settles_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class WithdrawalRequest(Base, IdMixin, TimestampMixin):
    __tablename__ = "withdrawal_requests"
    creator_id: Mapped[str] = mapped_column(String(36), index=True)
    amount: Mapped[int] = mapped_column(Integer)
    payout_account_reference: Mapped[str] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)
    failure_reason: Mapped[str] = mapped_column(Text, default="")
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
