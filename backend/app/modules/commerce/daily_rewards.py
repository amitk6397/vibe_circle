"""Daily login reward logic for VibeCam.

Reward schedule (Day 1–7):
  Day 1: 5 coins, Day 2: 10 coins, ..., Day 7: 50 coins
  Day 7+ repeats the Day 7 reward (50 coins).

Rules:
  - One claim per calendar day (UTC).
  - Consecutive daily claims increase the streak.
  - Missing a day resets streak to 1.
"""
from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.core.config import settings
from app.modules.commerce.models import UserWallet
from app.modules.commerce import service as commerce_service


def _day_reward(streak: int) -> int:
    """Return the coin amount for a given streak day (1-indexed, capped at schedule length)."""
    schedule = settings.daily_login_reward_schedule
    if not schedule:
        return 5
    idx = min(streak - 1, len(schedule) - 1)
    return schedule[idx]


def _next_reward(streak: int) -> int:
    """Preview the reward for the *next* day claim."""
    return _day_reward(streak + 1)


def claim_daily_reward(db: Session, user_id: str) -> dict:
    """
    Attempt to claim the daily login reward for user_id.
    Returns a dict with reward details.
    Raises AppError 409 if already claimed today.
    """
    wallet = commerce_service.wallet_for(db, user_id)
    now = datetime.now(UTC)
    today = now.date()

    # --- Already claimed today? ---
    if wallet.last_login_reward_at:
        last_aware = (
            wallet.last_login_reward_at
            if wallet.last_login_reward_at.tzinfo
            else wallet.last_login_reward_at.replace(tzinfo=UTC)
        )
        if last_aware.date() >= today:
            next_claim_at = datetime.combine(today + timedelta(days=1), datetime.min.time()).replace(tzinfo=UTC)
            raise AppError(
                409,
                "daily_reward_already_claimed",
                "You have already claimed today's reward. Come back tomorrow!",
            )

    # --- Determine streak ---
    if wallet.last_login_reward_at:
        last_aware = (
            wallet.last_login_reward_at
            if wallet.last_login_reward_at.tzinfo
            else wallet.last_login_reward_at.replace(tzinfo=UTC)
        )
        yesterday = today - timedelta(days=1)
        if last_aware.date() == yesterday:
            # Consecutive day — continue streak
            new_streak = wallet.login_streak + 1
        else:
            # Missed one or more days — reset
            new_streak = 1
    else:
        # First ever claim
        new_streak = 1

    reward_coins = _day_reward(new_streak)

    # --- Credit coins ---
    commerce_service.add_transaction(
        db,
        wallet,
        "daily_login_reward",
        "bonus_coins",
        reward_coins,
        reference_type="daily_reward",
        reference_id=f"{user_id}:{today.isoformat()}",
    )

    wallet.login_streak = new_streak
    wallet.last_login_reward_at = now

    db.commit()
    db.refresh(wallet)

    next_claim_at = datetime.combine(today + timedelta(days=1), datetime.min.time()).replace(tzinfo=UTC)
    return {
        "coins_awarded": reward_coins,
        "streak_day": new_streak,
        "next_reward_coins": _next_reward(new_streak),
        "next_claim_at": next_claim_at.isoformat(),
        "wallet": wallet,
    }
