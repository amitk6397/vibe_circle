from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class SubscriptionPlan(Base, IdMixin, TimestampMixin):
    __tablename__ = "subscription_plans"
    name: Mapped[str] = mapped_column(String(80), unique=True)
    description: Mapped[str] = mapped_column(Text, default="")
    price_minor: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(8), default="INR")
    interval: Mapped[str] = mapped_column(String(20), default="month")
    features: Mapped[list[str]] = mapped_column(JSON, default=list)
    chat_allowance: Mapped[int | None] = mapped_column(Integer, nullable=True)
    audio_credits: Mapped[int] = mapped_column(Integer, default=0)
    video_credits: Mapped[int] = mapped_column(Integer, default=0)
    highlighted: Mapped[bool] = mapped_column(Boolean, default=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)


class UserSubscription(Base, IdMixin, TimestampMixin):
    __tablename__ = "user_subscriptions"
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    plan_id: Mapped[str] = mapped_column(String(36), index=True)
    status: Mapped[str] = mapped_column(String(20), default="active", index=True)
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    auto_renews: Mapped[bool] = mapped_column(Boolean, default=False)
    provider: Mapped[str] = mapped_column(String(30), default="dummy")
    provider_reference: Mapped[str] = mapped_column(String(120), unique=True)


class CoinPackage(Base, IdMixin, TimestampMixin):
    __tablename__ = "coin_packages"
    name: Mapped[str] = mapped_column(String(80))
    purchased_coins: Mapped[int] = mapped_column(Integer)
    bonus_coins: Mapped[int] = mapped_column(Integer, default=0)
    price_minor: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(8), default="INR")
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)


class UserWallet(Base, IdMixin, TimestampMixin):
    __tablename__ = "user_wallets"
    user_id: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    purchased_coins: Mapped[int] = mapped_column(Integer, default=0)
    bonus_coins: Mapped[int] = mapped_column(Integer, default=0)
    held_coins: Mapped[int] = mapped_column(Integer, default=0)
    chat_credits: Mapped[int] = mapped_column(Integer, default=0)
    audio_call_credits: Mapped[int] = mapped_column(Integer, default=0)
    video_call_credits: Mapped[int] = mapped_column(Integer, default=0)
    # Daily login reward tracking
    login_streak: Mapped[int] = mapped_column(Integer, default=0)
    last_login_reward_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class WalletTransaction(Base, IdMixin, TimestampMixin):
    __tablename__ = "wallet_transactions"
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    transaction_type: Mapped[str] = mapped_column(String(40), index=True)
    balance_type: Mapped[str] = mapped_column(String(30))
    amount: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="successful", index=True)
    reference_type: Mapped[str | None] = mapped_column(String(40), nullable=True)
    reference_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    payment_method: Mapped[str | None] = mapped_column(String(30), nullable=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(120), nullable=True, unique=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)


class ConversationUnlock(Base, IdMixin, TimestampMixin):
    __tablename__ = "conversation_unlocks"
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    conversation_id: Mapped[str] = mapped_column(String(36), index=True)
    message_allowance: Mapped[int] = mapped_column(Integer)
