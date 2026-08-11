from typing import Literal

from pydantic import BaseModel, Field


class MatchStart(BaseModel):
    purpose: Literal["Talk", "Friends", "Advice", "Learn", "Support", "Fun", "Local"]
    language: str = Field(min_length=2, max_length=40)
    min_age: int = Field(default=18, ge=18, le=120)
    max_age: int = Field(default=99, ge=18, le=120)
    anonymous: bool = False
    session_minutes: Literal[10, 20] = 10


class MatchFeedback(BaseModel):
    rating: int = Field(ge=1, le=5)
    tags: list[str] = Field(default_factory=list, max_length=10)
