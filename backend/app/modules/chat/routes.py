from datetime import UTC, datetime

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import ValidationError
from sqlalchemy import select

from app.core.database import SessionLocal
from app.core.security import decode_access_token
from app.modules.chat import controller, service
from app.modules.chat.dtos import MessageCreate
from app.modules.chat.models import Message
from app.modules.users.models import User


router = APIRouter(prefix="/chat", tags=["chat"])
router.add_api_route("/conversations", controller.conversations, methods=["GET"])
router.add_api_route("/conversations", controller.create_conversation, methods=["POST"], status_code=201)
router.add_api_route("/limits", controller.chat_limits, methods=["GET"])
router.add_api_route("/message-requests", controller.message_requests, methods=["GET"])
router.add_api_route("/message-requests", controller.create_message_request, methods=["POST"], status_code=201)
router.add_api_route("/message-requests/{request_id}", controller.message_request_action, methods=["PATCH"])
router.add_api_route("/conversations/{conversation_id}/messages", controller.messages, methods=["GET"])
router.add_api_route("/conversations/{conversation_id}/messages", controller.send_message, methods=["POST"], status_code=201)
router.add_api_route("/conversations/{conversation_id}/unlock", controller.unlock_conversation, methods=["POST"])
router.add_api_route("/conversations/{conversation_id}/deduct-minute", controller.deduct_chat_minute, methods=["POST"])
router.add_api_route("/conversations/{conversation_id}/read", controller.read_messages, methods=["POST"])
router.add_api_route("/conversations/{conversation_id}/settings", controller.settings, methods=["PATCH"])
router.add_api_route("/conversations/{conversation_id}/clear", controller.clear, methods=["DELETE"])
router.add_api_route("/messages/{message_id}/reactions", controller.react, methods=["POST"])
router.add_api_route("/messages/{message_id}", controller.delete_message, methods=["DELETE"])


class ConnectionManager:
    def __init__(self):
        self.connections: dict[str, dict[WebSocket, str]] = {}

    async def connect(self, channel: str, user_id: str, socket: WebSocket):
        await socket.accept()
        self.connections.setdefault(channel, {})[socket] = user_id

    def disconnect(self, channel: str, socket: WebSocket):
        self.connections.get(channel, {}).pop(socket, None)

    def has_user(self, user_id: str) -> bool:
        return any(user_id in sockets.values() for sockets in self.connections.values())

    async def broadcast(self, channel: str, payload: dict, exclude: WebSocket | None = None):
        stale: list[WebSocket] = []
        for socket in list(self.connections.get(channel, {})):
            if socket is exclude:
                continue
            try:
                await socket.send_json(payload)
            except Exception:
                stale.append(socket)
        for socket in stale:
            self.disconnect(channel, socket)


manager = ConnectionManager()


def message_json(item: Message) -> dict:
    return {
        "id": item.id,
        "conversation_id": item.conversation_id,
        "sender_id": item.sender_id,
        "type": item.type,
        "text": item.text,
        "media_url": item.media_url,
        "media_name": item.media_name,
        "mime_type": item.mime_type,
        "reply_to_id": item.reply_to_id,
        "reactions": item.reactions,
        "delivered_at": item.delivered_at.isoformat() if item.delivered_at else None,
        "read_at": item.read_at.isoformat() if item.read_at else None,
        "is_deleted": item.is_deleted,
        "safety_flags": item.safety_flags,
        "created_at": item.created_at.isoformat(),
    }


@router.websocket("/ws/{conversation_id}")
async def websocket_chat(socket: WebSocket, conversation_id: str, token: str):
    try:
        user_id = decode_access_token(token)
        with SessionLocal() as db:
            service.conversation_for(db, conversation_id, user_id)
    except Exception:
        await socket.close(code=4401)
        return
    channel = f"private:{conversation_id}"
    await manager.connect(channel, user_id, socket)
    with SessionLocal() as db:
        user = db.get(User, user_id)
        if user:
            user.is_online = True
            user.last_active_at = datetime.now(UTC)
            db.commit()
    with SessionLocal() as db:
        visible_online = bool((db.get(User, user_id).privacy or {}).get("showOnline", True))
    if visible_online:
        await manager.broadcast(channel, {"event": "presence", "user_id": user_id, "online": True})
    try:
        while True:
            payload = await socket.receive_json()
            event = payload.get("event")
            if event == "ping":
                await socket.send_json({"event": "pong", "at": datetime.now(UTC).isoformat()})
            elif event == "typing":
                await manager.broadcast(channel, {"event": "typing", "user_id": user_id, "typing": bool(payload.get("typing"))}, exclude=socket)
            elif event == "read":
                with SessionLocal() as db:
                    reader = db.get(User, user_id)
                    if reader and not (reader.privacy or {}).get("readReceipts", True):
                        continue
                    items = db.scalars(select(Message).where(Message.conversation_id == conversation_id, Message.sender_id != user_id, Message.read_at.is_(None)))
                    now = datetime.now(UTC)
                    ids = []
                    for item in items:
                        item.read_at = now
                        ids.append(item.id)
                    db.commit()
                await manager.broadcast(channel, {"event": "read", "user_id": user_id, "message_ids": ids, "read_at": now.isoformat()})
            elif event == "message":
                try:
                    message_payload = MessageCreate.model_validate(payload.get("data") or {})
                    with SessionLocal() as db:
                        conversation = service.conversation_for(db, conversation_id, user_id)
                        item = service.send(db, conversation, user_id, message_payload)
                        response = message_json(item)
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
