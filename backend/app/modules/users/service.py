from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.moderation.models import Block
from app.modules.users.dtos import PreferencesUpdate, ProfileUpdate
from app.modules.users.models import Connection, User


def update_profile(db: Session, user: User, payload: ProfileUpdate) -> User:
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise AppError(409, "username_taken", "That username is already in use.") from exc
    db.refresh(user)
    return user


def update_preferences(db: Session, user: User, payload: PreferencesUpdate) -> User:
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


def update_privacy(db: Session, user: User, values: dict, field: str = "privacy") -> User:
    setattr(user, field, {**getattr(user, field), **values})
    db.commit()
    db.refresh(user)
    return user


def create_connection(db: Session, requester: User, receiver_id: str) -> Connection:
    if receiver_id == requester.id or not db.get(User, receiver_id):
        raise AppError(404, "user_not_found", "The selected user was not found.")
    blocked = db.scalar(
        select(Block).where(
            or_(
                (Block.blocker_id == requester.id) & (Block.blocked_id == receiver_id),
                (Block.blocker_id == receiver_id) & (Block.blocked_id == requester.id),
            )
        )
    )
    if blocked:
        raise AppError(403, "connection_not_allowed", "This connection is not available.")
    existing = db.scalar(
        select(Connection).where(
            Connection.requester_id == requester.id, Connection.receiver_id == receiver_id
        )
    )
    if existing:
        return existing
    receiver = db.get(User, receiver_id)
    visibility = (receiver.privacy or {}).get("profileVisibility", "Everyone")
    if visibility == "Nobody":
        raise AppError(403, "follow_not_allowed", "This account is not accepting followers.")
    item = Connection(
        requester_id=requester.id,
        receiver_id=receiver_id,
        status="accepted" if visibility == "Everyone" else "pending",
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item
