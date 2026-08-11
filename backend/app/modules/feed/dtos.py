from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class PostCreate(BaseModel):
    community_id: str | None = None
    type: Literal["text", "question", "poll", "image"] = "text"
    body: str = Field(min_length=3, max_length=5000)
    anonymous: bool = False
    media_url: str | None = None
    poll_options: list[str] = Field(default_factory=list, max_length=10)
    visibility: Literal["public", "private"] = "public"
    # Creator-set price (None = use platform default; only applies when visibility='private')
    coin_price: int | None = Field(default=None, ge=1, le=10000)
    # Ask & Earn Bounty
    bounty_amount: int | None = Field(default=None, ge=10)

    @model_validator(mode="after")
    def validate_type_fields(self):
        if self.type == "poll" and len(self.poll_options) < 2:
            raise ValueError("Polls require at least two options")
        if self.type == "image" and not self.media_url:
            raise ValueError("Image posts require media_url")
        if self.coin_price is not None and self.visibility != "private":
            raise ValueError("coin_price can only be set for private posts")
        if self.bounty_amount is not None and self.type != "question":
            raise ValueError("Bounty can only be set for question posts")
        return self


class PostUpdate(BaseModel):
    body: str = Field(min_length=3, max_length=5000)


class CommentCreate(BaseModel):
    body: str = Field(min_length=1, max_length=2000)
    parent_id: str | None = None


class VoteCreate(BaseModel):
    option: str


class StoryCreate(BaseModel):
    media_url: str = Field(min_length=1, max_length=500)
    audience: Literal["public", "followers", "close_circle", "selected_users", "community_members", "paid_supporters"] = "public"
    selected_user_ids: list[str] = Field(default_factory=list, max_length=100)
    audience_community_id: str | None = None
    replies_enabled: bool = True

    @field_validator("media_url")
    @classmethod
    def photo_only(cls, value: str):
        path = value.lower().split("?", 1)[0]
        if not path.endswith((".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif")):
            raise ValueError("Stories support photos only")
        return value


class StoryReactionCreate(BaseModel):
    emoji: Literal["❤️", "😂", "🔥", "👏", "😮"]


class StoryReplyCreate(BaseModel):
    text: str = Field(min_length=1, max_length=500)


class ShareCreate(BaseModel):
    user_ids: list[str] = Field(min_length=1, max_length=20)


class PostTipRequest(BaseModel):
    amount: int = Field(ge=1, le=10000)
    message: str | None = Field(default=None, max_length=200)


class BountyAwardRequest(BaseModel):
    comment_id: str
