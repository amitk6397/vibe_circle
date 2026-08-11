from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class Match(Base, IdMixin, TimestampMixin):
    __tablename__ = "matches"

    requester_id: Mapped[str] = mapped_column(String(36), index=True)
    candidate_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    purpose: Mapped[str] = mapped_column(String(30))
    language: Mapped[str] = mapped_column(String(40))
    min_age: Mapped[int] = mapped_column(Integer, default=18)
    max_age: Mapped[int] = mapped_column(Integer, default=99)
    anonymous: Mapped[bool] = mapped_column(Boolean, default=False)
    score: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(20), default="searching")
    feedback: Mapped[dict] = mapped_column(JSON, default=dict)
    candidate_preferences: Mapped[dict] = mapped_column(JSON, default=dict)
    accepted_by: Mapped[list[str]] = mapped_column(JSON, default=list)
    conversation_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    session_minutes: Mapped[int] = mapped_column(Integer, default=10)
    session_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
