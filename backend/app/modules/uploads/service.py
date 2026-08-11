import re
import uuid
from pathlib import Path

from fastapi import UploadFile

from app.common.errors import AppError
from app.core.config import settings


ALLOWED = {
    "image/jpeg", "image/png", "image/webp", "image/gif",
    "application/pdf", "text/plain", "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "audio/mpeg", "audio/mp4", "audio/wav", "audio/x-m4a",
}


async def save_upload(file: UploadFile) -> dict:
    mime = file.content_type or "application/octet-stream"
    if mime not in ALLOWED:
        raise AppError(415, "unsupported_file", "This file type is not supported.")
    content = await file.read(settings.max_upload_bytes + 1)
    if len(content) > settings.max_upload_bytes:
        raise AppError(413, "file_too_large", "Files must be 15 MB or smaller.")
    safe_name = re.sub(r"[^a-zA-Z0-9._-]", "_", file.filename or "upload")
    stored_name = f"{uuid.uuid4()}-{safe_name}"
    settings.upload_dir.mkdir(parents=True, exist_ok=True)
    destination = settings.upload_dir / stored_name
    destination.write_bytes(content)
    return {
        "url": f"{settings.public_base_url}/uploads/{stored_name}",
        "name": safe_name,
        "mime_type": mime,
        "size": len(content),
        "kind": "image" if mime.startswith("image/") else ("voice" if mime.startswith("audio/") else "file"),
    }

