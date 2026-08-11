"""Referral system for VibeCam.

Generates deterministic referral codes and handles coin crediting
when new users sign up via an existing user's referral link.
"""
import hashlib

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.modules.users.models import User
from app.modules.commerce import service as commerce_service
from app.modules.notifications.service import create_notification


def generate_referral_code(user_id: str) -> str:
    """
    Generate a deterministic 8-character uppercase referral code
    derived from the user's ID. Uses the first 8 hex chars of the SHA-256
    hash of the user_id, uppercased.
    """
    digest = hashlib.sha256(user_id.encode()).hexdigest()
    return digest[:8].upper()


def find_referrer(db: Session, code: str) -> User | None:
    """Find the user who owns a given referral code (case-insensitive)."""
    return db.scalar(select(User).where(User.referral_code == code.upper()))


def apply_referral(db: Session, new_user: User, referral_code: str) -> bool:
    """
    Credit coins to both the new user (invitee) and the referrer (inviter).
    Returns True if referral was applied, False if code is invalid / self-referral.
    """
    referrer = find_referrer(db, referral_code)
    if not referrer or referrer.id == new_user.id:
        return False

    new_user.referred_by = referrer.id

    # Credit invitee (new user)
    if settings.referral_invitee_coins > 0:
        invitee_wallet = commerce_service.wallet_for(db, new_user.id)
        commerce_service.add_transaction(
            db,
            invitee_wallet,
            "referral_bonus",
            "bonus_coins",
            settings.referral_invitee_coins,
            reference_type="referral",
            reference_id=referrer.id,
        )

    # Credit inviter (referrer)
    if settings.referral_inviter_coins > 0:
        referrer_wallet = commerce_service.wallet_for(db, referrer.id)
        commerce_service.add_transaction(
            db,
            referrer_wallet,
            "referral_reward",
            "bonus_coins",
            settings.referral_inviter_coins,
            reference_type="referral",
            reference_id=new_user.id,
        )
        create_notification(
            db,
            referrer.id,
            "referral_reward",
            "Referral Reward! 🎁",
            f"{new_user.name} joined using your referral link! You earned {settings.referral_inviter_coins} bonus coins.",
            {"screen": "Wallet"},
        )

    return True


def referral_info(db: Session, user: User) -> dict:
    """Return referral stats for a user."""
    from sqlalchemy import func
    referral_count = db.scalar(
        select(func.count()).select_from(User).where(User.referred_by == user.id)
    ) or 0
    total_earned = referral_count * settings.referral_inviter_coins
    return {
        "referralCode": user.referral_code or generate_referral_code(user.id),
        "totalReferrals": referral_count,
        "totalCoinsEarned": total_earned,
        "rewardPerReferral": settings.referral_inviter_coins,
        "inviteeBonus": settings.referral_invitee_coins,
    }
