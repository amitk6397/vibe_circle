from pydantic import BaseModel


class UploadResult(BaseModel):
    url: str
    name: str
    mime_type: str
    size: int
    kind: str

