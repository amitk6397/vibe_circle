from datetime import UTC, datetime

from sqlalchemy import select, update

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.common.schemas import ApiMessage
from app.core.security import hash_password, token_digest
from app.modules.auth import service
from app.modules.auth.dtos import (
    EmailRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenPair,
    VerifyRequest,
)
from app.modules.auth.models import OneTimeToken, Session
from app.modules.users.models import User


def _response(user: User, access: str, refresh: str) -> TokenPair:
    return TokenPair(access_token=access, refresh_token=refresh, user=user)


def register(payload: RegisterRequest, db: DbSession):
    return _response(*service.register(db, payload))


def login(payload: LoginRequest, db: DbSession):
    return _response(*service.login(db, payload))


def refresh(payload: RefreshRequest, db: DbSession):
    return _response(*service.refresh(db, payload.refresh_token))


def logout(payload: RefreshRequest, db: DbSession, _: CurrentUser):
    session = db.scalar(select(Session).where(Session.refresh_hash == token_digest(payload.refresh_token)))
    if session:
        session.revoked_at = datetime.now(UTC)
        db.commit()
    return ApiMessage(message="Logged out successfully.")


def logout_all(db: DbSession, user: CurrentUser):
    db.execute(update(Session).where(Session.user_id == user.id).values(revoked_at=datetime.now(UTC)))
    db.commit()
    return ApiMessage(message="All sessions were revoked.")


def forgot_password(payload: EmailRequest, db: DbSession):
    user = db.scalar(select(User).where(User.email == str(payload.email).lower()))
    token = service.create_one_time_token(db, user, "password_reset") if user else None
    message = "If the account exists, password reset instructions were created."
    return {"message": message, "development_token": token}


def request_verification(db: DbSession, user: CurrentUser):
    if user.is_verified:
        raise AppError(409, "email_already_verified", "Email is already verified.")
    otp = service.create_email_otp(db, user)
    return {
        "message": "Verification OTP created. It expires in 10 minutes.",
        "otp": otp,
        "expires_in": 600,
    }


def _consume(db: DbSession, raw: str, purpose: str) -> tuple[OneTimeToken, User]:
    item = db.scalar(select(OneTimeToken).where(OneTimeToken.token_hash == token_digest(raw), OneTimeToken.purpose == purpose))
    expires_at = item.expires_at.replace(tzinfo=UTC) if item and item.expires_at.tzinfo is None else (item.expires_at if item else datetime.now(UTC))
    if not item or item.used_at or expires_at <= datetime.now(UTC):
        raise AppError(400, "invalid_one_time_token", "This link is invalid or expired.")
    return item, db.get(User, item.user_id)


def verify_email(payload: VerifyRequest, db: DbSession):
    item, user = _consume(db, payload.token, "email_verification")
    item.used_at = datetime.now(UTC)
    user.is_verified = True
    db.commit()
    return ApiMessage(message="Email verified successfully.")


def reset_password(payload: ResetPasswordRequest, db: DbSession):
    item, user = _consume(db, payload.token, "password_reset")
    item.used_at = datetime.now(UTC)
    user.password_hash = hash_password(payload.password)
    db.execute(update(Session).where(Session.user_id == user.id).values(revoked_at=datetime.now(UTC)))
    db.commit()
    return ApiMessage(message="Password reset successfully.")


def delete_account(db: DbSession, user: CurrentUser):
    user.status = "deleted"
    user.email = f"deleted-{user.id}@invalid.local"
    user.name = "Deleted user"
    user.bio = ""
    user.avatar_url = None
    db.execute(update(Session).where(Session.user_id == user.id).values(revoked_at=datetime.now(UTC)))
    db.commit()
    return ApiMessage(message="Account deleted successfully.")


def get_referral_info(db: DbSession, user: CurrentUser):
    from app.modules.auth.referral import referral_info, generate_referral_code
    # Ensure user has a referral code assigned
    if not user.referral_code:
        user.referral_code = generate_referral_code(user.id)
        db.commit()
    return referral_info(db, user)
