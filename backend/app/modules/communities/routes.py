from datetime import UTC, datetime

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import ValidationError

from app.core.database import SessionLocal
from app.core.security import decode_access_token
from app.modules.chat.routes import manager
from app.modules.communities.dtos import CommunityMessageCreate
from app.modules.communities.models import CommunityMessage
from app.modules.communities import service
from app.modules.users.models import User

from app.modules.communities import controller


router = APIRouter(prefix="/communities", tags=["communities"])
router.add_api_route("", controller.list_communities, methods=["GET"])
router.add_api_route("", controller.create, methods=["POST"], status_code=201)
router.add_api_route("/invitations/me", controller.my_invitations, methods=["GET"])
router.add_api_route("/invitations/{invite_id}", controller.respond_invitation, methods=["PATCH"])
router.add_api_route("/{community_id}", controller.details, methods=["GET"])
router.add_api_route("/{community_id}", controller.update, methods=["PATCH"])
router.add_api_route("/{community_id}/join", controller.join, methods=["POST"])
router.add_api_route("/{community_id}/join-requests", controller.join_requests, methods=["GET"])
router.add_api_route("/{community_id}/join-requests/{request_id}", controller.respond_join_request, methods=["PATCH"])
router.add_api_route("/{community_id}/invite", controller.invite_member, methods=["POST"], status_code=201)
router.add_api_route("/{community_id}/leave", controller.leave, methods=["POST"])
router.add_api_route("/{community_id}/members", controller.members, methods=["GET"])
router.add_api_route("/{community_id}/members/{member_id}", controller.update_role, methods=["PATCH"])
router.add_api_route("/{community_id}/members/{member_id}/moderate", controller.moderate_member, methods=["POST"])
router.add_api_route("/{community_id}/members/{member_id}", controller.remove_member, methods=["DELETE"])
router.add_api_route("/{community_id}/messages", controller.messages, methods=["GET"])
router.add_api_route("/{community_id}/messages", controller.send_message, methods=["POST"], status_code=201)
router.add_api_route("/{community_id}", controller.delete_community, methods=["DELETE"])
router.add_api_route("/{community_id}/share", controller.share_community, methods=["POST"])
router.add_api_route("/{community_id}/subscription-status", controller.subscription_status, methods=["GET"])


def community_message_json(item: CommunityMessage) -> dict:
    return {
        "id": item.id,
        "community_id": item.community_id,
        "author_id": item.author_id,
        "text": item.text,
        "media_url": item.media_url,
        "media_name": item.media_name,
        "mime_type": item.mime_type,
        "created_at": item.created_at.isoformat(),
    }


@router.websocket("/ws/{community_id}")
async def websocket_community(socket: WebSocket, community_id: str, token: str):
    try:
        user_id = decode_access_token(token)
        with SessionLocal() as db:
            member = service.membership(db, community_id, user_id)
            if not member or member.muted:
                raise ValueError("Membership required")
    except Exception:
        await socket.close(code=4403)
        return
    channel = f"community:{community_id}"
    await manager.connect(channel, user_id, socket)
    with SessionLocal() as db:
        user = db.get(User, user_id)
        if user:
            user.is_online = True
            user.last_active_at = datetime.now(UTC)
            db.commit()
    await manager.broadcast(channel, {"event": "presence", "user_id": user_id, "online": True})
    try:
        while True:
            payload = await socket.receive_json()
            event = payload.get("event")
            if event == "ping":
                await socket.send_json({"event": "pong", "at": datetime.now(UTC).isoformat()})
            elif event == "typing":
                await manager.broadcast(channel, {"event": "typing", "user_id": user_id, "typing": bool(payload.get("typing"))}, exclude=socket)
            elif event == "message":
                try:
                    values = CommunityMessageCreate.model_validate(payload.get("data") or {})
                    if not values.text.strip() and not values.media_url:
                        raise ValueError("A message or attachment is required")
                    with SessionLocal() as db:
                        item = CommunityMessage(community_id=community_id, author_id=user_id, **values.model_dump())
                        db.add(item)
                        db.commit()
                        db.refresh(item)
                        response = community_message_json(item)
                    await manager.broadcast(channel, {"event": "message", "message": response, "client_id": payload.get("client_id")})
                except (ValidationError, Exception) as exc:
                    await socket.send_json({"event": "error", "client_id": payload.get("client_id"), "message": str(exc)})
    except WebSocketDisconnect:
        manager.disconnect(channel, socket)
        if not manager.has_user(user_id):
            with SessionLocal() as db:
                user = db.get(User, user_id)
                if user:
                    user.is_online = False
                    user.last_active_at = datetime.now(UTC)
                    db.commit()
        await manager.broadcast(channel, {"event": "presence", "user_id": user_id, "online": False})
