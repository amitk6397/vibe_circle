from datetime import UTC, datetime, timedelta
from sqlalchemy import func, or_, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.modules.moderation import service
from app.modules.moderation.dtos import BlockCreate, ReportCreate
from app.modules.moderation.models import Block, Report
from app.modules.users.models import Connection, User


def blocked(db: DbSession, user: CurrentUser):
    rows = list(db.scalars(select(Block).where(Block.blocker_id == user.id)))
    users = {item.id: item for item in db.scalars(select(User).where(User.id.in_([row.blocked_id for row in rows])))}
    return [{"block_id": row.id, "user": users.get(row.blocked_id)} for row in rows]


def block(payload: BlockCreate, db: DbSession, user: CurrentUser):
    if payload.user_id == user.id or not db.get(User, payload.user_id):
        raise AppError(404, "user_not_found", "User not found.")
    item = db.scalar(select(Block).where(Block.blocker_id == user.id, Block.blocked_id == payload.user_id))
    if not item:
        item = Block(blocker_id=user.id, blocked_id=payload.user_id)
        db.add(item)
        connections = db.scalars(
            select(Connection).where(
                or_(
                    (Connection.requester_id == user.id)
                    & (Connection.receiver_id == payload.user_id),
                    (Connection.requester_id == payload.user_id)
                    & (Connection.receiver_id == user.id),
                )
            )
        )
        for connection in connections:
            db.delete(connection)
        from app.modules.chat.models import Conversation, MessageRequest
        from app.modules.calls.models import CallSession
        from app.modules.calls.controller import call_action
        conversations = db.scalars(select(Conversation).where(Conversation.type.in_(["private", "match_anonymous"])))
        for conversation in conversations:
            if {user.id, payload.user_id}.issubset(set(conversation.member_ids)):
                conversation.archived_by = list(set((conversation.archived_by or []) + [user.id]))
        for request in db.scalars(select(MessageRequest).where(MessageRequest.status == "pending")):
            if {request.sender_id, request.recipient_id} == {user.id, payload.user_id}:
                request.status = "blocked"
        for call in list(db.scalars(select(CallSession).where(CallSession.status.in_(["ringing", "accepted"])))):
            if {call.caller_id, call.recipient_id} == {user.id, payload.user_id}:
                call_action(call.id, "end", db, user)
        db.commit()
        db.refresh(item)
    return item


def unblock(user_id: str, db: DbSession, user: CurrentUser):
    item = db.scalar(select(Block).where(Block.blocker_id == user.id, Block.blocked_id == user_id))
    if item:
        db.delete(item)
        db.commit()
    return ApiMessage(message="User unblocked.")


def report(payload: ReportCreate, db: DbSession, user: CurrentUser):
    since = datetime.now(UTC) - timedelta(days=1)
    count = db.scalar(select(func.count()).select_from(Report).where(Report.reporter_id == user.id, Report.created_at >= since)) or 0
    if count >= 20:
        raise AppError(429, "report_rate_limit", "Daily report limit reached.")
    duplicate = db.scalar(select(Report).where(Report.reporter_id == user.id, Report.target_type == payload.target_type, Report.target_id == payload.target_id, Report.status.in_(["open", "reviewing"])))
    if duplicate:
        return duplicate
    item = Report(reporter_id=user.id, **payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def my_reports(db: DbSession, user: CurrentUser):
    return list(db.scalars(select(Report).where(Report.reporter_id == user.id).order_by(Report.created_at.desc()).limit(100)))

