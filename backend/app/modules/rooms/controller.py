from datetime import UTC, datetime

from sqlalchemy import func, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.modules.rooms import service
from app.modules.rooms.dtos import ParticipantAction, RoomCreate
from app.modules.rooms.models import Room, RoomParticipant
from app.modules.users.models import User


def _room_response(db: DbSession, room: Room, user_id: str | None = None):
    host = db.get(User, room.host_id)
    people = db.scalar(select(func.count()).select_from(RoomParticipant).where(RoomParticipant.room_id == room.id)) or 0
    return {
        "id": room.id, "host_id": room.host_id, "host_name": host.name if host else "",
        "title": room.title, "type": room.type, "scheduled_at": room.scheduled_at,
        "participant_limit": room.participant_limit, "participant_count": people,
        "live": room.live, "rules": room.rules, "status": room.status,
        "joined": service.participant(db, room.id, user_id) is not None if user_id else False,
    }


def list_rooms(db: DbSession, user: CurrentUser):
    rooms = list(db.scalars(select(Room).where(Room.status == "active").order_by(Room.live.desc(), Room.scheduled_at)))
    return [_room_response(db, room, user.id) for room in rooms]


def create(payload: RoomCreate, db: DbSession, user: CurrentUser):
    live = payload.scheduled_at is None or payload.scheduled_at <= datetime.now(UTC)
    room = Room(host_id=user.id, live=live, **payload.model_dump())
    db.add(room)
    db.flush()
    db.add(RoomParticipant(room_id=room.id, user_id=user.id, role="host"))
    db.commit()
    db.refresh(room)
    return room


def details(room_id: str, db: DbSession, _: CurrentUser):
    room = service.room_or_404(db, room_id)
    people = db.scalar(select(func.count()).select_from(RoomParticipant).where(RoomParticipant.room_id == room_id))
    return _room_response(db, room, _.id)


def join(room_id: str, db: DbSession, user: CurrentUser):
    room = service.room_or_404(db, room_id)
    item = service.participant(db, room_id, user.id)
    count = db.scalar(select(func.count()).select_from(RoomParticipant).where(RoomParticipant.room_id == room_id))
    if not item and count >= room.participant_limit:
        raise AppError(409, "room_full", "This room is full.")
    if not item:
        item = RoomParticipant(room_id=room_id, user_id=user.id)
        db.add(item)
        db.commit()
        db.refresh(item)
    return item


def leave(room_id: str, db: DbSession, user: CurrentUser):
    room = service.room_or_404(db, room_id)
    item = service.participant(db, room_id, user.id)
    if room.host_id == user.id:
        return end(room_id, db, user)
    if item:
        db.delete(item)
        db.commit()
    return ApiMessage(message="You left the room.")


def participants(room_id: str, db: DbSession, _: CurrentUser):
    service.room_or_404(db, room_id)
    rows = list(db.scalars(select(RoomParticipant).where(RoomParticipant.room_id == room_id)))
    users = {item.id: item for item in db.scalars(select(User).where(User.id.in_([row.user_id for row in rows])))}
    return [{"id": row.id, "user_id": row.user_id, "role": row.role, "muted": row.muted, "mic_requested": row.mic_requested, "name": users[row.user_id].name if row.user_id in users else "", "avatar_url": users[row.user_id].avatar_url if row.user_id in users else None, "is_current_user": row.user_id == _.id} for row in rows]


def participant_action(room_id: str, participant_id: str, payload: ParticipantAction, db: DbSession, user: CurrentUser):
    room = service.room_or_404(db, room_id)
    target = db.get(RoomParticipant, participant_id)
    if not target or target.room_id != room_id:
        raise AppError(404, "participant_not_found", "Participant not found.")
    if payload.action == "request_mic" and target.user_id == user.id:
        target.mic_requested = True
    elif room.host_id != user.id:
        raise AppError(403, "host_permission_required", "Only the host can moderate participants.")
    elif payload.action == "approve_speaker":
        target.role, target.mic_requested = "speaker", False
    elif payload.action == "mute":
        target.muted = True
    elif payload.action == "remove":
        db.delete(target)
    db.commit()
    return ApiMessage(message="Room action completed.")


def end(room_id: str, db: DbSession, user: CurrentUser):
    room = service.room_or_404(db, room_id)
    if room.host_id != user.id:
        raise AppError(403, "host_permission_required", "Only the host can end this room.")
    room.live = False
    room.status = "ended"
    db.commit()
    return ApiMessage(message="Room ended.")
