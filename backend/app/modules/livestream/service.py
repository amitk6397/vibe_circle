"""Business logic for the Live Streaming module."""
import time
import uuid
from datetime import UTC, datetime
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.core.config import settings
from app.modules.commerce import service as commerce_service
from app.modules.livestream.models import LiveStream, StreamViewer, StreamGift
from app.modules.notifications.service import create_notification
from app.modules.users.models import User


# ---------------------------------------------------------------------------
# Agora token generation (RTC token with publisher/subscriber role)
# ---------------------------------------------------------------------------
def _generate_agora_token(channel: str, uid: int, role: int = 1) -> str:
    """
    Generate an Agora RTC token.
    role=1 → PUBLISHER (broadcaster)
    role=2 → SUBSCRIBER (audience)
    Returns a placeholder when credentials are missing (dev mode).
    """
    app_id = settings.agora_app_id
    app_certificate = settings.agora_app_certificate

    if not app_id or not app_certificate:
        # Return a development placeholder so the app can still load
        return f"dev_agora_token_{channel}_{uid}"

    try:
        # agora_token_builder must be installed: pip install agora-token-builder
        from agora_token_builder import RtcTokenBuilder  # type: ignore
        expire_time = int(time.time()) + settings.agora_token_ttl_seconds
        token = RtcTokenBuilder.buildTokenWithUid(
            app_id, app_certificate, channel, uid, role, expire_time
        )
        return token
    except ImportError:
        # Fallback when agora_token_builder is not installed
        return f"dev_agora_token_{channel}_{uid}"


import hashlib

def _uid_for_user(user_id: str) -> int:
    """Convert UUID string to a stable positive int for Agora UID deterministically."""
    hasher = hashlib.md5(user_id.encode('utf-8'))
    val = int(hasher.hexdigest()[:8], 16)
    return val if val != 0 else 1


# ---------------------------------------------------------------------------
# Stream management
# ---------------------------------------------------------------------------
def start_stream(db: Session, user: User, title: str, description: str, category: str) -> dict:
    """Create a new live stream for the given user."""
    # End any existing live stream from this user
    existing = db.scalar(
        select(LiveStream).where(
            LiveStream.host_id == user.id,
            LiveStream.status == "live",
        )
    )
    if existing:
        existing.status = "ended"
        existing.ended_at = datetime.now(UTC)
        db.flush()

    channel_name = f"vibecam_{uuid.uuid4().hex[:12]}"
    stream = LiveStream(
        host_id=user.id,
        title=title,
        description=description,
        category=category,
        channel_name=channel_name,
        status="live",
    )
    db.add(stream)
    db.commit()
    db.refresh(stream)

    uid = _uid_for_user(user.id)
    token = _generate_agora_token(channel_name, uid, role=1)

    return {
        "stream": stream,
        "agora_token": token,
        "channel_name": channel_name,
        "uid": uid,
        "agora_app_id": settings.agora_app_id or "placeholder_app_id",
    }


def end_stream(db: Session, stream_id: str, user: User) -> LiveStream:
    """End a live stream. Only the host or an admin can end it."""
    stream = db.get(LiveStream, stream_id)
    if not stream:
        raise AppError(404, "stream_not_found", "Stream not found.")
    if stream.host_id != user.id and user.role != "admin":
        raise AppError(403, "forbidden", "Only the host can end this stream.")
    if stream.status == "ended":
        return stream

    stream.status = "ended"
    stream.ended_at = datetime.now(UTC)
    db.commit()
    db.refresh(stream)
    return stream


def admin_force_end_stream(db: Session, stream_id: str) -> LiveStream:
    """Admin force-ends a stream."""
    stream = db.get(LiveStream, stream_id)
    if not stream:
        raise AppError(404, "stream_not_found", "Stream not found.")
    stream.status = "ended"
    stream.ended_at = datetime.now(UTC)
    stream.force_ended = True
    db.commit()
    db.refresh(stream)
    return stream


def list_active_streams(db: Session) -> list[LiveStream]:
    """Return all currently live streams, ordered by viewer count."""
    return list(
        db.scalars(
            select(LiveStream)
            .where(LiveStream.status == "live")
            .order_by(LiveStream.current_viewers.desc())
        )
    )


def list_all_streams(db: Session, limit: int = 50) -> list[LiveStream]:
    """Return all streams (live + ended) for admin view."""
    return list(
        db.scalars(
            select(LiveStream)
            .order_by(LiveStream.started_at.desc())
            .limit(limit)
        )
    )


def join_stream(db: Session, stream_id: str, user: User) -> dict:
    """Register viewer and return Agora token for audience role."""
    stream = db.get(LiveStream, stream_id)
    if not stream:
        raise AppError(404, "stream_not_found", "Stream not found.")
    if stream.status != "live":
        raise AppError(410, "stream_ended", "This stream has ended.")

    # Track viewer
    viewer = StreamViewer(stream_id=stream_id, user_id=user.id)
    db.add(viewer)

    # Increment viewer count
    stream.current_viewers = (stream.current_viewers or 0) + 1
    if stream.current_viewers > (stream.peak_viewers or 0):
        stream.peak_viewers = stream.current_viewers
    db.commit()

    uid = _uid_for_user(user.id)
    token = _generate_agora_token(stream.channel_name, uid, role=2)

    return {
        "stream": stream,
        "agora_token": token,
        "channel_name": stream.channel_name,
        "uid": uid,
        "agora_app_id": settings.agora_app_id or "placeholder_app_id",
    }


def leave_stream(db: Session, stream_id: str, user: User) -> None:
    """Decrement viewer count when a user leaves a stream."""
    stream = db.get(LiveStream, stream_id)
    if not stream:
        return

    # Mark viewer exit
    viewer = db.scalar(
        select(StreamViewer).where(
            StreamViewer.stream_id == stream_id,
            StreamViewer.user_id == user.id,
            StreamViewer.left_at.is_(None),
        )
    )
    if viewer:
        viewer.left_at = datetime.now(UTC)

    if stream.current_viewers and stream.current_viewers > 0:
        stream.current_viewers -= 1
    db.commit()


def send_gift_to_stream(
    db: Session,
    stream_id: str,
    sender: User,
    gift_name: str,
    gift_emoji: str,
    coins: int,
) -> StreamGift:
    """Deduct coins from sender, credit streamer (minus platform commission)."""
    stream = db.get(LiveStream, stream_id)
    if not stream:
        raise AppError(404, "stream_not_found", "Stream not found.")
    if stream.status != "live":
        raise AppError(410, "stream_ended", "This stream has ended.")
    if stream.host_id == sender.id:
        raise AppError(400, "self_gift", "You cannot send gifts to yourself.")

    # Deduct from sender
    sender_wallet = commerce_service.wallet_for(db, sender.id)
    total_available = (sender_wallet.purchased_coins or 0) + (sender_wallet.bonus_coins or 0)
    if total_available < coins:
        raise AppError(402, "insufficient_balance", "Your wallet balance is insufficient.")

    purchased_deduct = min(sender_wallet.purchased_coins or 0, coins)
    bonus_deduct = coins - purchased_deduct

    if purchased_deduct > 0:
        commerce_service.add_transaction(
            db, sender_wallet, "live_gift_sent", "purchased_coins", -purchased_deduct,
            reference_type="stream_gift", reference_id=stream_id,
        )
    if bonus_deduct > 0:
        commerce_service.add_transaction(
            db, sender_wallet, "live_gift_sent", "bonus_coins", -bonus_deduct,
            reference_type="stream_gift", reference_id=stream_id,
        )

    # Credit to host (after platform cut)
    platform_cut = max(1, int(coins * settings.platform_commission_percent / 100))
    host_earn = coins - platform_cut
    host_wallet = commerce_service.wallet_for(db, stream.host_id)
    commerce_service.add_transaction(
        db, host_wallet, "live_gift_received", "bonus_coins", host_earn,
        reference_type="stream_gift", reference_id=stream_id,
    )

    # Update stream totals
    stream.total_gifts_received = (stream.total_gifts_received or 0) + coins

    # Record the gift
    gift_record = StreamGift(
        stream_id=stream_id,
        sender_id=sender.id,
        host_id=stream.host_id,
        gift_name=gift_name,
        gift_emoji=gift_emoji,
        coins_spent=coins,
        coins_earned=host_earn,
    )
    db.add(gift_record)
    db.commit()
    db.refresh(gift_record)

    # Notify host
    host = db.get(User, stream.host_id)
    if host:
        create_notification(
            db, host.id, "live_gift",
            f"{gift_emoji} Gift Received!",
            f"{sender.name} sent you a {gift_name} worth {coins} coins during your live stream!",
            {"screen": "Wallet"},
        )

    return gift_record


def get_stream_with_host(db: Session, stream: LiveStream) -> dict:
    """Enrich stream with host user info."""
    host = db.get(User, stream.host_id)
    return {
        **stream.__dict__,
        "host": {
            "id": host.id,
            "name": host.name,
            "avatar_url": host.avatar_url,
            "is_verified": host.is_verified,
        } if host else None,
    }
