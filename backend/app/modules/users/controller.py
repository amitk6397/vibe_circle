from datetime import UTC, datetime, timedelta

from fastapi import UploadFile
from sqlalchemy import or_, select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.users import service
from app.modules.users.dtos import (
    ConnectionAction,
    ConnectionCreate,
    AvailabilityUpdate,
    NotificationPreferencesUpdate,
    PreferencesUpdate,
    ProfileUpdate,
)
from app.modules.users.models import Connection, User
from app.modules.notifications.models import Notification
from app.modules.notifications.service import create_notification
from app.modules.feed.models import Comment, Post, SavedPost


def me(user: CurrentUser):
    user.performance_rating = 0
    user.review_count = 0
    user.completed_sessions = 0
    user.performance_tier = "new"
    return user


def public_profile(user_id: str, db: DbSession):
    user = db.get(User, user_id)
    if not user:
        user = db.scalar(select(User).where(User.username.ilike(user_id)))
    if not user or user.status != "active":
        raise AppError(404, "user_not_found", "User not found.")
    from app.modules.discovery.service import with_performance
    return with_performance(db, [user])[0]


def patch_profile(payload: ProfileUpdate, db: DbSession, user: CurrentUser):
    return service.update_profile(db, user, payload)


def patch_preferences(payload: PreferencesUpdate, db: DbSession, user: CurrentUser):
    return service.update_preferences(db, user, payload)


def patch_notifications(payload: NotificationPreferencesUpdate, db: DbSession, user: CurrentUser):
    return service.update_privacy(
        db, user, payload.model_dump(exclude_none=True), "notification_preferences"
    )


def set_availability(payload: AvailabilityUpdate, db: DbSession, user: CurrentUser):
    user.vibe_status = payload.status
    user.vibe_expires_at = datetime.now(UTC) + timedelta(minutes=payload.duration_minutes)
    db.commit()
    db.refresh(user)
    return user


def clear_availability(db: DbSession, user: CurrentUser):
    user.vibe_status = None
    user.vibe_expires_at = None
    db.commit()
    return {"message": "Availability cleared."}


def list_connections(db: DbSession, user: CurrentUser):
    return list(
        db.scalars(
            select(Connection).where(
                or_(Connection.requester_id == user.id, Connection.receiver_id == user.id)
            )
        )
    )


def request_connection(payload: ConnectionCreate, db: DbSession, user: CurrentUser):
    item = service.create_connection(db, user, payload.user_id)
    if item.status == "pending":
        message = f"{user.name} wants to follow you."
        exists = db.scalar(select(Notification.id).where(Notification.user_id == payload.user_id, Notification.type == "follow_request", Notification.body == message))
        if not exists:
            create_notification(db, payload.user_id, "follow_request", "New follow request", message, {"screen": "ConnectionRequest", "connectionId": item.id, "requesterId": user.id})
            db.commit()
    else:
        message = f"{user.name} started following you."
        exists = db.scalar(select(Notification.id).where(Notification.user_id == payload.user_id, Notification.type == "new_follower", Notification.body == message))
        if not exists:
            create_notification(db, payload.user_id, "new_follower", "New follower", message, {"screen": "PublicProfile", "personId": user.id})
            db.commit()
    return item


def connection_action(connection_id: str, payload: ConnectionAction, db: DbSession, user: CurrentUser):
    item = db.get(Connection, connection_id)
    if not item or item.receiver_id != user.id or item.status != "pending":
        raise AppError(404, "request_not_found", "Connection request not found.")
    item.status = "accepted" if payload.action == "accept" else "rejected"
    if payload.action == "accept":
        create_notification(db, item.requester_id, "follow_accepted", "Follow request accepted", f"{user.name} accepted your follow request.", {"screen": "PublicProfile", "personId": user.id})
    db.commit()
    db.refresh(item)
    return item


def remove_connection(connection_id: str, db: DbSession, user: CurrentUser):
    item = db.get(Connection, connection_id)
    if not item or user.id not in {item.requester_id, item.receiver_id}:
        raise AppError(404, "connection_not_found", "Follow relationship not found.")
    db.delete(item)
    db.commit()
    return {"message": "Unfollowed successfully."}


def export_data(db: DbSession, user: CurrentUser):
    connections = list_connections(db, user)
    return {
        "profile": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "age": user.age,
            "username": user.username,
            "bio": user.bio,
            "city": user.city,
            "interests": user.interests,
            "languages": user.languages,
        },
        "connections": connections,
        "exported_at": __import__("datetime").datetime.now(__import__("datetime").UTC),
    }


def activity(db: DbSession, user: CurrentUser):
    posts = list(db.scalars(select(Post).where(Post.author_id == user.id, Post.status == "active").order_by(Post.created_at.desc()).limit(50)))
    comments = list(db.scalars(select(Comment).where(Comment.author_id == user.id, Comment.status == "active").order_by(Comment.created_at.desc()).limit(50)))
    saved = list(db.scalars(select(SavedPost).where(SavedPost.user_id == user.id).order_by(SavedPost.created_at.desc()).limit(50)))

    def post_data(post: Post):
        author = db.get(User, post.author_id)
        return {
            "id": post.id,
            "author_name": "Anonymous member" if post.anonymous else (author.name if author else "Member"),
            "body": post.body,
            "type": post.type,
            "media_url": post.media_url,
            "poll_options": post.poll_options,
            "likes": post.like_count,
            "comments": post.comment_count,
            "created_at": post.created_at,
        }

    return {
        "counts": {"posts": len(posts), "comments": len(comments), "saved": len(saved)},
        "posts": [post_data(item) for item in posts],
        "comments": [
            {
                "id": item.id,
                "post_id": item.post_id,
                "body": item.body,
                "created_at": item.created_at,
                "post": post_data(post) if (post := db.get(Post, item.post_id)) is not None and post.status == "active" else None,
            }
            for item in comments
        ],
        "saved": [
            post_data(post)
            for item in saved
            if (post := db.get(Post, item.post_id)) is not None and post.status == "active"
        ],
    }
