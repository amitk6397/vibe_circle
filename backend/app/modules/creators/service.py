from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.modules.creators.models import CreatorProfile, CreatorTransaction, CreatorWallet
from app.modules.users.models import User


def profile_for(db: Session, user_id: str, required: bool = True) -> CreatorProfile | None:
    item = db.scalar(select(CreatorProfile).where(CreatorProfile.user_id == user_id, CreatorProfile.status == "active"))
    if not item:
        user = db.get(User, user_id)
        if user and user.status == "active":
            item = CreatorProfile(
                user_id=user.id,
                topics=list(user.conversation_topics or user.interests),
                languages=list(user.languages),
                introduction=user.bio,
                verified=False,
                availability_status="available",
                chat_available=True,
                audio_available=True,
                video_available=True,
                chat_price=10,
                audio_price_per_minute=5,
                video_price_per_minute=10,
            )
            db.add(item)
            db.flush()
    if required and not item:
        raise AppError(404, "user_not_found", "User is unavailable.")
    return item


def wallet_for(db: Session, creator_id: str) -> CreatorWallet:
    item = db.scalar(select(CreatorWallet).where(CreatorWallet.creator_id == creator_id))
    if not item:
        item = CreatorWallet(creator_id=creator_id)
        db.add(item)
        db.flush()
    return item


def settle_due(db: Session, creator_id: str):
    wallet = wallet_for(db, creator_id)
    rows = db.scalars(select(CreatorTransaction).where(
        CreatorTransaction.creator_id == creator_id,
        CreatorTransaction.status == "pending",
        CreatorTransaction.settles_at <= datetime.now(UTC),
    ))
    for row in rows:
        row.status = "available"
        wallet.pending_earnings -= row.creator_amount
        wallet.available_earnings += row.creator_amount
    db.flush()
    return wallet


def credit_earning(db: Session, creator_id: str, gross: int, commission: int, reference_type: str, reference_id: str, settles_at: datetime):
    if db.scalar(select(CreatorTransaction.id).where(CreatorTransaction.reference_type == reference_type, CreatorTransaction.reference_id == reference_id)):
        return
    creator_amount = gross - commission
    wallet = wallet_for(db, creator_id)
    wallet.pending_earnings += creator_amount
    db.add(CreatorTransaction(creator_id=creator_id, transaction_type="earning", gross_amount=gross, commission_amount=commission, creator_amount=creator_amount, status="pending", reference_type=reference_type, reference_id=reference_id, settles_at=settles_at))
