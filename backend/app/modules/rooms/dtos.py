from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class RoomCreate(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    type: Literal["text", "voice"] = "text"
    scheduled_at: datetime | None = None
    participant_limit: int = Field(default=50, ge=2, le=500)
    rules: list[str] = Field(default_factory=list, max_length=20)


class ParticipantAction(BaseModel):
    action: Literal["request_mic", "approve_speaker", "mute", "remove"]

