"""DTOs (Pydantic schemas) for the Live Streaming module."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class StartStreamRequest(BaseModel):
    title: str = Field(default="Live Stream", max_length=200)
    description: str = Field(default="", max_length=500)
    category: str = Field(default="General", max_length=50)


class EndStreamRequest(BaseModel):
    stream_id: str


class SendGiftRequest(BaseModel):
    gift_name: str = Field(..., max_length=80)
    gift_emoji: str = Field(default="🎁", max_length=10)
    coins: int = Field(..., gt=0, le=10000)


class HostInfo(BaseModel):
    id: str
    name: str
    avatar_url: Optional[str] = None
    is_verified: bool = False

    model_config = {"from_attributes": True}


class LiveStreamResponse(BaseModel):
    id: str
    host_id: str
    host: Optional[HostInfo] = None
    title: str
    description: str
    status: str
    channel_name: str
    current_viewers: int
    peak_viewers: int
    total_gifts_received: int
    category: str
    thumbnail_url: Optional[str] = None
    started_at: datetime
    ended_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class JoinStreamResponse(BaseModel):
    stream: LiveStreamResponse
    agora_token: str
    channel_name: str
    uid: int


class StartStreamResponse(BaseModel):
    stream: LiveStreamResponse
    agora_token: str
    channel_name: str
    uid: int


class GiftResponse(BaseModel):
    id: str
    sender_id: str
    gift_name: str
    gift_emoji: str
    coins_spent: int
    coins_earned: int
    created_at: datetime

    model_config = {"from_attributes": True}


class AdminStreamResponse(LiveStreamResponse):
    host_name: Optional[str] = None
    force_ended: bool = False
