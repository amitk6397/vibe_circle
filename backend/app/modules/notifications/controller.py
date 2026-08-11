from sqlalchemy import delete, select, update

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.modules.notifications.dtos import DeviceTokenCreate
from app.modules.notifications.models import DeviceToken, Notification


def list_notifications(db: DbSession, user: CurrentUser, unread_only: bool = False):
    stmt = select(Notification).where(Notification.user_id == user.id)
    if unread_only:
        stmt = stmt.where(Notification.is_read.is_(False))
    return list(db.scalars(stmt.order_by(Notification.created_at.desc()).limit(100)))


def mark_read(notification_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Notification, notification_id)
    if not item or item.user_id != user.id:
        raise AppError(404, "notification_not_found", "Notification not found.")
    item.is_read = True
    db.commit()
    return item


def mark_all_read(db: DbSession, user: CurrentUser):
    db.execute(update(Notification).where(Notification.user_id == user.id).values(is_read=True))
    db.commit()
    return ApiMessage(message="All notifications marked as read.")


def remove(notification_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Notification, notification_id)
    if not item or item.user_id != user.id:
        raise AppError(404, "notification_not_found", "Notification not found.")
    db.delete(item)
    db.commit()
    return ApiMessage(message="Notification deleted.")


def register_device(payload: DeviceTokenCreate, db: DbSession, user: CurrentUser):
    item = db.scalar(select(DeviceToken).where(DeviceToken.token == payload.token))
    if item:
        item.user_id, item.platform = user.id, payload.platform
    else:
        item = DeviceToken(user_id=user.id, **payload.model_dump())
        db.add(item)
    db.commit()
    return ApiMessage(message="Device registered.")


def unregister_device(token: str, db: DbSession, user: CurrentUser):
    db.execute(
        delete(DeviceToken).where(DeviceToken.user_id == user.id, DeviceToken.token == token)
    )
    db.commit()
    return ApiMessage(message="Device unregistered.")
