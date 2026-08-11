from pydantic import BaseModel, Field

from app.modules.users.dtos import PublicUser


class SearchResults(BaseModel):
    users: list[PublicUser]
    communities: list[dict]
    posts: list[dict]
    rooms: list[dict]


class DiscoveryFilters(BaseModel):
    query: str = Field(default="", max_length=100)
    min_age: int = Field(default=18, ge=18, le=120)
    max_age: int = Field(default=99, ge=18, le=120)
    language: str | None = None
    interest: str | None = None
    purpose: str | None = None
    online_only: bool = False

