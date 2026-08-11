from typing import Annotated

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.core.database import get_db
from app.core.security import decode_access_token


bearer = HTTPBearer(auto_error=False)
DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(
    db: DbSession,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
):
    from app.modules.users.models import User

    if not credentials:
        raise AppError(401, "not_authenticated", "Authentication is required.")
    try:
        user_id = decode_access_token(credentials.credentials)
    except jwt.InvalidTokenError as exc:
        raise AppError(401, "invalid_token", "The access token is invalid or expired.") from exc
    user = db.get(User, user_id)
    if not user or user.status != "active":
        raise AppError(403, "account_unavailable", "This account is not available.")
    return user


CurrentUser = Annotated[object, Depends(get_current_user)]

