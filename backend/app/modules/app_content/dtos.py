from pydantic import BaseModel, ConfigDict


class SupportArticleResponse(BaseModel):
    id: str
    slug: str
    title: str
    icon: str
    body: str
    position: int

    model_config = ConfigDict(from_attributes=True)
