"""HTTP controllers for Live Streaming endpoints."""
from app.common.dependencies import CurrentUser, DbSession
from app.modules.livestream import service
from app.modules.livestream.dtos import (
    SendGiftRequest,
    StartStreamRequest,
)


def start_stream(payload: StartStreamRequest, db: DbSession, user: CurrentUser):
    result = service.start_stream(
        db, user,
        title=payload.title,
        description=payload.description,
        category=payload.category,
    )
    stream = result["stream"]
    host = db.get(__import__("app.modules.users.models", fromlist=["User"]).User, stream.host_id)
    return {
        "stream": {
            "id": stream.id,
            "host_id": stream.host_id,
            "host": {
                "id": host.id,
                "name": host.name,
                "avatar_url": host.avatar_url,
                "is_verified": host.is_verified,
            } if host else None,
            "title": stream.title,
            "description": stream.description,
            "status": stream.status,
            "channel_name": stream.channel_name,
            "current_viewers": stream.current_viewers,
            "peak_viewers": stream.peak_viewers,
            "total_gifts_received": stream.total_gifts_received,
            "category": stream.category,
            "thumbnail_url": stream.thumbnail_url,
            "started_at": stream.started_at,
            "ended_at": stream.ended_at,
            "host_uid": result["uid"],
        },
        "agora_token": result["agora_token"],
        "channel_name": result["channel_name"],
        "uid": result["uid"],
        "agora_app_id": result["agora_app_id"],
    }


def end_stream(stream_id: str, db: DbSession, user: CurrentUser):
    stream = service.end_stream(db, stream_id, user)
    return {"message": "Stream ended successfully.", "stream_id": stream.id, "status": stream.status}


def list_active_streams(db: DbSession, user: CurrentUser):
    streams = service.list_active_streams(db)
    result = []
    for s in streams:
        from app.modules.users.models import User
        host = db.get(User, s.host_id)
        result.append({
            "id": s.id,
            "host_id": s.host_id,
            "host": {
                "id": host.id,
                "name": host.name,
                "avatar_url": host.avatar_url,
                "is_verified": host.is_verified,
            } if host else None,
            "title": s.title,
            "description": s.description,
            "status": s.status,
            "channel_name": s.channel_name,
            "current_viewers": s.current_viewers,
            "peak_viewers": s.peak_viewers,
            "total_gifts_received": s.total_gifts_received,
            "category": s.category,
            "thumbnail_url": s.thumbnail_url,
            "started_at": s.started_at,
            "ended_at": s.ended_at,
        })
    return result


def join_stream(stream_id: str, db: DbSession, user: CurrentUser):
    result = service.join_stream(db, stream_id, user)
    s = result["stream"]
    from app.modules.users.models import User
    host = db.get(User, s.host_id)
    return {
        "stream": {
            "id": s.id,
            "host_id": s.host_id,
            "host": {
                "id": host.id,
                "name": host.name,
                "avatar_url": host.avatar_url,
                "is_verified": host.is_verified,
            } if host else None,
            "title": s.title,
            "description": s.description,
            "status": s.status,
            "channel_name": s.channel_name,
            "current_viewers": s.current_viewers,
            "peak_viewers": s.peak_viewers,
            "total_gifts_received": s.total_gifts_received,
            "category": s.category,
            "thumbnail_url": s.thumbnail_url,
            "started_at": s.started_at,
            "ended_at": s.ended_at,
            "host_uid": service._uid_for_user(s.host_id),
        },
        "agora_token": result["agora_token"],
        "channel_name": result["channel_name"],
        "uid": result["uid"],
        "agora_app_id": result["agora_app_id"],
    }


def leave_stream(stream_id: str, db: DbSession, user: CurrentUser):
    service.leave_stream(db, stream_id, user)
    return {"message": "Left stream."}


def send_gift(stream_id: str, payload: SendGiftRequest, db: DbSession, user: CurrentUser):
    gift = service.send_gift_to_stream(
        db, stream_id, user,
        gift_name=payload.gift_name,
        gift_emoji=payload.gift_emoji,
        coins=payload.coins,
    )
    return {
        "id": gift.id,
        "stream_id": stream_id,
        "gift_name": gift.gift_name,
        "gift_emoji": gift.gift_emoji,
        "coins_spent": gift.coins_spent,
        "coins_earned": gift.coins_earned,
        "message": f"Gift sent! Host earned {gift.coins_earned} coins.",
    }


def admin_list_streams(db: DbSession, user: CurrentUser):
    """Admin endpoint to list all streams."""
    if user.role != "admin":
        from app.common.errors import AppError
        raise AppError(403, "forbidden", "Admin access required.")
    streams = service.list_all_streams(db, limit=100)
    result = []
    for s in streams:
        from app.modules.users.models import User
        host = db.get(User, s.host_id)
        result.append({
            "id": s.id,
            "host_id": s.host_id,
            "host_name": host.name if host else "Unknown",
            "host_avatar": host.avatar_url if host else None,
            "title": s.title,
            "description": s.description,
            "status": s.status,
            "channel_name": s.channel_name,
            "current_viewers": s.current_viewers,
            "peak_viewers": s.peak_viewers,
            "total_gifts_received": s.total_gifts_received,
            "category": s.category,
            "started_at": s.started_at,
            "ended_at": s.ended_at,
            "force_ended": s.force_ended,
        })
    return result


def admin_force_end(stream_id: str, db: DbSession, user: CurrentUser):
    """Admin force-ends a live stream."""
    if user.role != "admin":
        from app.common.errors import AppError
        raise AppError(403, "forbidden", "Admin access required.")
    stream = service.admin_force_end_stream(db, stream_id)
    return {"message": "Stream force-ended by admin.", "stream_id": stream.id}
