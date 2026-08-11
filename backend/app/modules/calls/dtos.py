from typing import Literal

from pydantic import BaseModel, Field, model_validator


class CallCreate(BaseModel):
    conversation_id: str | None = Field(default=None, min_length=1, max_length=36)
    recipient_id: str | None = None
    call_type: Literal["audio", "video"]
    duration_minutes: int = Field(default=5, ge=1, le=120)

    @model_validator(mode="after")
    def require_target(self):
        if not self.conversation_id and not self.recipient_id:
            raise ValueError("conversation_id or recipient_id is required")
        return self


class CallExtension(BaseModel):
    duration_minutes: int = Field(ge=1, le=120)
