from sqlalchemy import Boolean, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class VirtualGift(Base, IdMixin, TimestampMixin):
    __tablename__ = "virtual_gifts"
    name: Mapped[str] = mapped_column(String(80), unique=True)
    icon: Mapped[str] = mapped_column(String(120))
    animation_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    coin_price: Mapped[int] = mapped_column(Integer)
    creator_earning_value: Mapped[int] = mapped_column(Integer)
    active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)


class GiftTransaction(Base, IdMixin, TimestampMixin):
    __tablename__ = "gift_transactions"
    gift_id: Mapped[str] = mapped_column(String(36), index=True)
    sender_id: Mapped[str] = mapped_column(String(36), index=True)
    creator_id: Mapped[str] = mapped_column(String(36), index=True)
    target_type: Mapped[str] = mapped_column(String(30))
    target_id: Mapped[str] = mapped_column(String(36), index=True)
    coin_amount: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="successful", index=True)


class RatingReview(Base, IdMixin, TimestampMixin):
    __tablename__ = "rating_reviews"
    session_id: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    creator_id: Mapped[str] = mapped_column(String(36), index=True)
    reviewer_id: Mapped[str] = mapped_column(String(36), index=True)
    overall_rating: Mapped[int] = mapped_column(Integer)
    conversation_quality: Mapped[int] = mapped_column(Integer)
    behaviour: Mapped[int] = mapped_column(Integer)
    helpfulness: Mapped[int] = mapped_column(Integer)
    media_quality: Mapped[int] = mapped_column(Integer)
    review: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[str] = mapped_column(String(20), default="published", index=True)
