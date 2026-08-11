from typing import Literal
from pydantic import BaseModel, Field


class CreatorProfileUpdate(BaseModel):
    category: str | None = Field(default=None, max_length=80)
    topics: list[str] | None = None
    languages: list[str] | None = None
    introduction: str | None = Field(default=None, max_length=1000)
    chat_available: bool | None = None
    audio_available: bool | None = None
    video_available: bool | None = None
    chat_price: int | None = Field(default=None, ge=0, le=100000)
    audio_price_per_minute: int | None = Field(default=None, ge=0, le=10000)
    video_price_per_minute: int | None = Field(default=None, ge=0, le=10000)
    availability_status: Literal["available", "busy", "offline"] | None = None
    schedule: dict | None = None
    maximum_daily_sessions: int | None = Field(default=None, ge=1, le=100)


class WithdrawalCreate(BaseModel):
    amount: int = Field(gt=0)
    payout_account_reference: str = Field(min_length=3, max_length=120)

