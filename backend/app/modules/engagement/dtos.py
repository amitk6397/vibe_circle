from typing import Literal
from pydantic import AliasChoices, BaseModel, Field


class GiftSend(BaseModel):
    gift_id: str
    recipient_id: str = Field(validation_alias=AliasChoices("recipient_id", "creator_id"))
    target_type: Literal["user_profile", "creator_profile", "post", "story", "chat", "audio_call", "video_call"]
    target_id: str


class RatingCreate(BaseModel):
    session_id: str
    overall_rating: int = Field(ge=1, le=5)
    conversation_quality: int = Field(ge=1, le=5)
    behaviour: int = Field(ge=1, le=5)
    helpfulness: int = Field(ge=1, le=5)
    media_quality: int = Field(ge=1, le=5)
    review: str = Field(default="", max_length=1000)
