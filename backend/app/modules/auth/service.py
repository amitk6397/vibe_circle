import secrets
from datetime import UTC, datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    token_digest,
    verify_password,
)
from app.modules.auth.dtos import LoginRequest, RegisterRequest
from app.modules.auth.models import OneTimeToken, Session as UserSession
from app.modules.users.models import User
from app.modules.creators.models import CreatorProfile


def issue_tokens(db: Session, user: User, device_name: str = "mobile") -> tuple[str, str]:
    refresh = create_refresh_token()
    session = UserSession(
        user_id=user.id,
        refresh_hash=token_digest(refresh),
        device_name=device_name,
        expires_at=datetime.now(UTC) + timedelta(days=settings.refresh_token_days),
    )
    db.add(session)
    db.commit()
    return create_access_token(user.id), refresh


def register(db: Session, payload: RegisterRequest) -> tuple[User, str, str]:
    from app.modules.auth.referral import generate_referral_code, apply_referral
    user = User(
        email=str(payload.email).lower(),
        password_hash=hash_password(payload.password),
        name=payload.name.strip(),
        age=payload.age,
        avatar_url=payload.avatar_url,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise AppError(409, "email_registered", "An account already exists for this email.") from exc
    db.refresh(user)
    # Assign a unique referral code to every new user
    user.referral_code = generate_referral_code(user.id)
    db.add(
        CreatorProfile(
            user_id=user.id,
            category="Community member",
            availability_status="available",
            chat_available=True,
            audio_available=True,
            video_available=True,
            chat_price=10,
            audio_price_per_minute=5,
            video_price_per_minute=10,
        )
    )
    db.commit()
    # Apply referral bonus if a valid code was provided
    if payload.referral_code:
        apply_referral(db, user, payload.referral_code)
        db.commit()
    access, refresh = issue_tokens(db, user)
    return user, access, refresh


def login(db: Session, payload: LoginRequest) -> tuple[User, str, str]:
    user = db.scalar(select(User).where(User.email == str(payload.email).lower()))
    if not user or not verify_password(payload.password, user.password_hash):
        raise AppError(401, "invalid_credentials", "Email or password is incorrect.")
    if user.status != "active":
        raise AppError(403, "account_restricted", "This account is currently restricted.")
    access, refresh = issue_tokens(db, user, payload.device_name)
    return user, access, refresh


def refresh(db: Session, value: str) -> tuple[User, str, str]:
    now = datetime.now(UTC)
    session = db.scalar(
        select(UserSession).where(UserSession.refresh_hash == token_digest(value))
    )
    expires_at = session.expires_at.replace(tzinfo=UTC) if session and session.expires_at.tzinfo is None else (session.expires_at if session else now)
    if not session or session.revoked_at or expires_at <= now:
        raise AppError(401, "invalid_refresh_token", "Refresh token is invalid or expired.")
    user = db.get(User, session.user_id)
    session.revoked_at = now
    db.commit()
    access, new_refresh = issue_tokens(db, user, session.device_name)
    return user, access, new_refresh


def create_one_time_token(db: Session, user: User, purpose: str) -> str:
    raw = secrets.token_urlsafe(24)
    db.add(
        OneTimeToken(
            user_id=user.id,
            token_hash=token_digest(raw),
            purpose=purpose,
            expires_at=datetime.now(UTC) + timedelta(minutes=30),
        )
    )
    db.commit()
    return raw


def create_email_otp(db: Session, user: User) -> str:
    now = datetime.now(UTC)
    db.execute(
        update(OneTimeToken)
        .where(
            OneTimeToken.user_id == user.id,
            OneTimeToken.purpose == "email_verification",
            OneTimeToken.used_at.is_(None),
        )
        .values(used_at=now)
    )
    otp = f"{secrets.randbelow(1_000_000):06d}"
    db.add(
        OneTimeToken(
            user_id=user.id,
            token_hash=token_digest(otp),
            purpose="email_verification",
            expires_at=now + timedelta(minutes=10),
        )
    )
    db.commit()
    return otp
