from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from app.common.schemas import ORMModel


class PublicUser(ORMModel):
    id: str
    name: str
    age: int
    username: str | None
    bio: str
    city: str
    avatar_url: str | None
    languages: list[str]
    interests: list[str]
    conversation_topics: list[str] = []
    date_of_birth: date | None = None
    gender: str | None = None
    preferred_language: str | None = None
    performance_rating: float = 0
    review_count: int = 0
    completed_sessions: int = 0
    performance_tier: Literal["top_performer", "recommended", "new"] = "new"
    purposes: list[str]
    is_online: bool
    vibe_status: str | None = None
    vibe_expires_at: datetime | None = None


class PrivateUser(PublicUser):
    email: str
    is_verified: bool
    privacy: dict
    notification_preferences: dict
    status: str
    role: str = "user"


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=80)
    username: str | None = Field(default=None, min_length=3, max_length=40, pattern=r"^[a-zA-Z0-9._]+$")
    bio: str | None = Field(default=None, max_length=500)
    city: str | None = Field(default=None, max_length=80)
    avatar_url: str | None = Field(default=None, max_length=500)
    date_of_birth: date | None = None
    gender: str | None = Field(default=None, max_length=40)
    preferred_language: str | None = Field(default=None, max_length=60)


class PreferencesUpdate(BaseModel):
    interests: list[str] | None = None
    languages: list[str] | None = None
    purposes: list[str] | None = None
    conversation_topics: list[str] | None = None

    @field_validator("interests", "languages", "purposes", "conversation_topics")
    @classmethod
    def limit_values(cls, value: list[str] | None) -> list[str] | None:
        if value is not None and len(value) > 20:
            raise ValueError("A maximum of 20 values is allowed")
        return value


class NotificationPreferencesUpdate(BaseModel):
    messages: bool | None = None
    connections: bool | None = None
    communities: bool | None = None
    calls: bool | None = None
    system: bool | None = None


class ConnectionCreate(BaseModel):
    user_id: str


class ConnectionAction(BaseModel):
    action: Literal["accept", "reject"]


class AvailabilityUpdate(BaseModel):
    status: Literal[
        "Free to talk",
        "Need advice",
        "Study together",
        "Feeling low",
        "Explore locally",
        "Do not disturb",
    ]
    duration_minutes: int = Field(default=60, ge=15, le=180)
