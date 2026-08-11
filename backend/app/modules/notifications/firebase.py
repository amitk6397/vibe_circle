import json
import logging
from functools import lru_cache

from firebase_admin import credentials, initialize_app, messaging
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.modules.notifications.models import DeviceToken
from app.modules.users.models import User

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def firebase_app():
    path = settings.firebase_credentials_path
    if not path or not path.is_file():
        logger.warning("Firebase credentials are not configured; push delivery is disabled.")
        return None
    try:
        return initialize_app(credentials.Certificate(str(path)))
    except ValueError:
        from firebase_admin import get_app

        return get_app()
    except Exception:
        logger.exception("Firebase initialization failed.")
        return None


def _string_data(data: dict) -> dict[str, str]:
    return {
        str(key): value if isinstance(value, str) else json.dumps(value, separators=(",", ":"))
        for key, value in data.items()
        if value is not None
    }


def send_to_user(
    db: Session,
    user_id: str,
    title: str,
    body: str,
    data: dict,
    *,
    category: str,
) -> int:
    user = db.get(User, user_id)
    preferences = (user.notification_preferences if user else {}) or {}
    if preferences.get(category) is False:
        return 0
    tokens = list(db.scalars(select(DeviceToken).where(DeviceToken.user_id == user_id)))
    if not tokens:
        return 0
    app = firebase_app()
    if not app:
        return 0

    sent = 0
    stale_ids: list[str] = []
    for start in range(0, len(tokens), 500):
        batch = tokens[start : start + 500]
        message = messaging.MulticastMessage(
            tokens=[item.token for item in batch],
            notification=messaging.Notification(title=title, body=body),
            data=_string_data(data),
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="calls" if category == "calls" else "default",
                    sound="default",
                    visibility="private",
                ),
            ),
            apns=messaging.APNSConfig(
                headers={"apns-priority": "10"},
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default", content_available=True)
                ),
            ),
        )
        try:
            response = messaging.send_each_for_multicast(message, app=app)
        except Exception:
            logger.exception("Firebase multicast send failed for user %s", user_id)
            continue
        sent += response.success_count
        for token, result in zip(batch, response.responses, strict=True):
            if result.success:
                continue
            error = str(result.exception).lower()
            if "registration-token-not-registered" in error or "invalid-registration-token" in error:
                stale_ids.append(token.id)
            else:
                logger.warning("Push delivery failed for token %s: %s", token.id, result.exception)
    if stale_ids:
        db.execute(delete(DeviceToken).where(DeviceToken.id.in_(stale_ids)))
    return sent
