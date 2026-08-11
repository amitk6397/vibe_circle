from typing import Literal

from pydantic import BaseModel, Field


class BlockCreate(BaseModel):
    user_id: str


class ReportCreate(BaseModel):
    target_type: Literal[
        "user", "message", "conversation", "post", "comment", "community", "room", "story", "call", "rating"
    ]
    target_id: str
    reason: str = Field(min_length=3, max_length=80)
    details: str = Field(default="", max_length=2000)
    evidence_ids: list[str] = Field(default_factory=list, max_length=20)
