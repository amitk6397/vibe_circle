from typing import Literal

from pydantic import BaseModel, Field


class ConversationCreate(BaseModel):
    member_id: str


class MessageCreate(BaseModel):
    text: str = Field(default="", max_length=5000)
    type: Literal["text", "image", "file", "voice"] = "text"
    media_url: str | None = None
    media_name: str | None = None
    mime_type: str | None = None
    reply_to_id: str | None = None


class ReactionCreate(BaseModel):
    emoji: str = Field(min_length=1, max_length=12)


class MessageEdit(BaseModel):
    text: str = Field(min_length=1, max_length=5000)


class ConversationSettings(BaseModel):
    muted: bool | None = None
    archived: bool | None = None


class MessageRequestCreate(BaseModel):
    recipient_id: str
    introduction: str = Field(min_length=1, max_length=300)
    duration_minutes: int = Field(default=10, ge=1, le=120)


class MessageRequestAction(BaseModel):
    action: Literal["accept", "reject", "block"]
