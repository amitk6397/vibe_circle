from typing import Literal

from pydantic import BaseModel, Field


class CommunityCreate(BaseModel):
    name: str = Field(min_length=3, max_length=100)
    category: str = Field(min_length=2, max_length=60)
    description: str = Field(min_length=10, max_length=1000)
    privacy: Literal["public", "request", "private", "premium"] = "public"
    rules: list[str] = Field(default_factory=list, max_length=20)
    color: str = Field(default="#5B5CE2", pattern=r"^#[0-9A-Fa-f]{6}$")
    logo_url: str | None = Field(default=None, max_length=500)
    cover_url: str | None = Field(default=None, max_length=500)
    tags: list[str] = Field(default_factory=list, max_length=10)
    location: str | None = Field(default=None, max_length=100)
    language: str | None = Field(default=None, max_length=60)
    kind: Literal["community", "circle"] = "community"
    max_members: int = Field(default=500, ge=2, le=500)
    premium_price: int = Field(default=0, ge=0, le=100000)


class CommunityUpdate(BaseModel):
    description: str | None = Field(default=None, min_length=10, max_length=1000)
    privacy: Literal["public", "request", "private", "premium"] | None = None
    premium_price: int | None = Field(default=None, ge=0, le=100000)
    rules: list[str] | None = Field(default=None, max_length=20)
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    logo_url: str | None = Field(default=None, max_length=500)
    cover_url: str | None = Field(default=None, max_length=500)
    tags: list[str] | None = Field(default=None, max_length=10)
    location: str | None = Field(default=None, max_length=100)
    language: str | None = Field(default=None, max_length=60)


class MemberRoleUpdate(BaseModel):
    role: Literal["member", "moderator", "admin"]


class MemberModerationUpdate(BaseModel):
    action: Literal["mute", "unmute", "ban"]
    reason: str = Field(default="", max_length=200)


class JoinRequestAction(BaseModel):
    action: Literal["accept", "reject"]


class CommunityInviteCreate(BaseModel):
    user_id: str


class CommunityInviteAction(BaseModel):
    action: Literal["accept", "reject"]


class CommunityMessageCreate(BaseModel):
    text: str = Field(default="", max_length=5000)
    media_url: str | None = None
    media_name: str | None = None
    mime_type: str | None = None


class ShareCreate(BaseModel):
    user_ids: list[str] = Field(min_length=1, max_length=20)
