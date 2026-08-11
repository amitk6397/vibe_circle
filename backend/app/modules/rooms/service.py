from sqlalchemy import select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.rooms.models import Room, RoomParticipant


def room_or_404(db: Session, room_id: str) -> Room:
    room = db.get(Room, room_id)
    if not room or room.status != "active":
        raise AppError(404, "room_not_found", "Room not found.")
    return room


def participant(db: Session, room_id: str, user_id: str):
    return db.scalar(select(RoomParticipant).where(RoomParticipant.room_id == room_id, RoomParticipant.user_id == user_id))

