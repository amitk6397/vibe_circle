from sqlalchemy.orm import Session
import re

from app.common.errors import AppError
from app.modules.moderation.models import AuditLog
from app.core.config import settings


def require_admin(user):
    if user.role not in {"admin", "moderator"}:
        raise AppError(403, "admin_required", "Moderator access is required.")


def audit(db: Session, actor_id: str, action: str, target_type: str, target_id: str, metadata: dict | None = None):
    db.add(AuditLog(actor_id=actor_id, action=action, target_type=target_type, target_id=target_id, metadata_json=metadata or {}))


def scan_text(value: str, allow_contact_details: bool = True) -> list[str]:
    normalized = value.casefold()
    if any(term.casefold() in normalized for term in settings.restricted_words):
        raise AppError(422, "restricted_content", "This content violates safety rules.")
    flags: list[str] = []
    if re.search(r"(?:https?://|www\.)\S+", value, re.I):
        flags.append("external_link")
    if re.search(r"(?<!\d)(?:\+?\d[\s-]?){8,15}(?!\d)", value):
        flags.append("phone_number")
    if flags and not allow_contact_details:
        raise AppError(422, "contact_details_not_allowed", "Links and phone numbers are disabled before request acceptance.")
    return flags
