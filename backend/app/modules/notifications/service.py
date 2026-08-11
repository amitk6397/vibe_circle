from sqlalchemy.orm import Session

from app.modules.notifications.models import Notification
from app.modules.notifications.firebase import send_to_user


CATEGORY_BY_TYPE = {
    "message": "messages",
    "incoming_call": "calls",
    "call_answered": "calls",
    "call_rejected": "calls",
    "call_ended": "calls",
    "follow_request": "connections",
    "new_follower": "connections",
    "follow_accepted": "connections",
    "community_join_request": "communities",
    "community_join_response": "communities",
    "circle_invite": "communities",
}


def create_notification(db: Session, user_id: str, type_: str, title: str, body: str, data: dict | None = None):
    payload = data or {}
    item = Notification(user_id=user_id, type=type_, title=title, body=body, data=payload)
    db.add(item)
    db.flush()
    send_to_user(
        db,
        user_id,
        title,
        body,
        {"notificationId": item.id, "type": type_, **payload},
        category=CATEGORY_BY_TYPE.get(type_, "system"),
    )
    return item
