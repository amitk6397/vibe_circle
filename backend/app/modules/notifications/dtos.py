from typing import Literal

from pydantic import BaseModel, Field


class DeviceTokenCreate(BaseModel):
    token: str = Field(min_length=10, max_length=512)
    platform: Literal["android", "ios", "web"]

