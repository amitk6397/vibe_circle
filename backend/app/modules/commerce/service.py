from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.common.errors import AppError
from app.core.config import settings
from app.modules.commerce.models import CoinPackage, SubscriptionPlan, UserSubscription, UserWallet, WalletTransaction


def wallet_for(db: Session, user_id: str) -> UserWallet:
    wallet = db.scalar(select(UserWallet).where(UserWallet.user_id == user_id))
    if not wallet:
        wallet = UserWallet(user_id=user_id)
        db.add(wallet)
        db.flush()
    return wallet


def active_subscription(db: Session, user_id: str) -> UserSubscription | None:
    now = datetime.now(UTC)
    return db.scalar(select(UserSubscription).where(
        UserSubscription.user_id == user_id,
        UserSubscription.status == "active",
        UserSubscription.expires_at > now,
    ).order_by(UserSubscription.expires_at.desc()))


def require_active_subscription(db: Session, user_id: str) -> UserSubscription:
    item = active_subscription(db, user_id)
    if not item:
        raise AppError(
            402,
            "subscription_required",
            "An active 1 day, 1 week, or 1 month pass is required.",
        )
    return item


def add_transaction(db: Session, wallet: UserWallet, transaction_type: str, balance_type: str, amount: int, **values) -> WalletTransaction:
    if balance_type not in {"purchased_coins", "bonus_coins", "held_coins", "chat_credits", "audio_call_credits", "video_call_credits"}:
        raise AppError(422, "invalid_balance", "Unsupported wallet balance.")
    next_value = getattr(wallet, balance_type) + amount
    if next_value < 0:
        raise AppError(402, "insufficient_balance", "Your wallet balance is insufficient.")
    setattr(wallet, balance_type, next_value)
    item = WalletTransaction(user_id=wallet.user_id, transaction_type=transaction_type, balance_type=balance_type, amount=amount, **values)
    db.add(item)
    return item


def dummy_reference(token: str) -> str:
    if not settings.dummy_payments_enabled or settings.app_env == "production":
        raise AppError(503, "payment_provider_required", "A verified payment provider is required.")
    if not token.startswith("dummy_"):
        raise AppError(422, "invalid_dummy_token", "Use a dummy_ payment token in development.")
    return token


def purchase_subscription(db: Session, user_id: str, plan: SubscriptionPlan, token: str) -> UserSubscription:
    reference = dummy_reference(token)
    existing = db.scalar(select(UserSubscription).where(UserSubscription.provider_reference == reference))
    if existing:
        if existing.user_id != user_id:
            raise AppError(409, "payment_token_used", "Payment token was already used.")
        return existing
    now = datetime.now(UTC)
    days = {"day": 1, "week": 7, "month": 30}.get(plan.interval)
    if days is None:
        raise AppError(422, "invalid_plan_interval", "Choose a 1 day, 1 week, or 1 month plan.")
    item = UserSubscription(user_id=user_id, plan_id=plan.id, starts_at=now, expires_at=now + timedelta(days=days), auto_renews=False, provider="dummy", provider_reference=reference)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def purchase_coins(db: Session, user_id: str, package: CoinPackage, token: str):
    reference = dummy_reference(token)
    existing = db.scalar(select(WalletTransaction).where(WalletTransaction.idempotency_key == reference))
    if existing:
        if existing.user_id != user_id:
            raise AppError(409, "payment_token_used", "Payment token was already used.")
        return wallet_for(db, user_id)
    wallet = wallet_for(db, user_id)
    add_transaction(db, wallet, "coin_purchase", "purchased_coins", package.purchased_coins, reference_type="coin_package", reference_id=package.id, payment_method="dummy", idempotency_key=reference)
    if package.bonus_coins:
        add_transaction(db, wallet, "bonus_credit", "bonus_coins", package.bonus_coins, reference_type="coin_package", reference_id=package.id)
    db.commit()
    db.refresh(wallet)
    return wallet


def spend_coins(db: Session, user_id: str, amount: int, transaction_type: str, reference_type: str, reference_id: str):
    wallet = wallet_for(db, user_id)
    if amount <= 0 or wallet.bonus_coins + wallet.purchased_coins < amount:
        raise AppError(402, "insufficient_coins", "Your coin balance is insufficient.")
    bonus = min(wallet.bonus_coins, amount)
    purchased = amount - bonus
    if bonus:
        add_transaction(db, wallet, transaction_type, "bonus_coins", -bonus, reference_type=reference_type, reference_id=reference_id)
    if purchased:
        add_transaction(db, wallet, transaction_type, "purchased_coins", -purchased, reference_type=reference_type, reference_id=reference_id)
    return wallet


def hold_coins(db: Session, user_id: str, amount: int, reference_type: str, reference_id: str) -> tuple[int, int]:
    wallet = wallet_for(db, user_id)
    if amount <= 0:
        return (0, 0)
    if wallet.bonus_coins + wallet.purchased_coins < amount:
        raise AppError(402, "insufficient_coins", "Your coin balance is insufficient.")
    bonus = min(wallet.bonus_coins, amount); purchased = amount - bonus
    if bonus: add_transaction(db, wallet, "credit_hold", "bonus_coins", -bonus, reference_type=reference_type, reference_id=reference_id)
    if purchased: add_transaction(db, wallet, "credit_hold", "purchased_coins", -purchased, reference_type=reference_type, reference_id=reference_id)
    add_transaction(db, wallet, "credit_hold", "held_coins", amount, reference_type=reference_type, reference_id=reference_id)
    return bonus, purchased


def settle_hold(db: Session, user_id: str, held: int, bonus_source: int, purchased_source: int, captured: int, reference_type: str, reference_id: str):
    wallet = wallet_for(db, user_id)
    if captured < 0 or captured > held:
        raise AppError(422, "invalid_capture", "Invalid held-credit capture.")
    add_transaction(db, wallet, "credit_capture", "held_coins", -held, reference_type=reference_type, reference_id=reference_id)
    refund = held - captured
    refund_bonus = min(refund, bonus_source)
    refund_purchased = refund - refund_bonus
    if refund_bonus: add_transaction(db, wallet, "credit_refund", "bonus_coins", refund_bonus, reference_type=reference_type, reference_id=reference_id)
    if refund_purchased: add_transaction(db, wallet, "credit_refund", "purchased_coins", refund_purchased, reference_type=reference_type, reference_id=reference_id)
