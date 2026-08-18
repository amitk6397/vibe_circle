from datetime import UTC, datetime, timedelta
from sqlalchemy import select

from app.common.dependencies import CurrentUser, DbSession
from app.common.errors import AppError
from app.modules.commerce import service
from app.modules.commerce import daily_rewards as daily_reward_service
from app.modules.commerce.dtos import CoinPurchase, SubscriptionPurchase
from app.modules.commerce.models import CoinPackage, SubscriptionPlan, UserSubscription, WalletTransaction
from app.modules.notifications.service import create_notification
from app.modules.creators.models import CreatorTransaction, CreatorWallet
from app.modules.creators import service as earning_service
from app.core.config import settings


def plan_json(plan: SubscriptionPlan):
    return {"id": plan.id, "name": plan.name, "description": plan.description, "price": plan.price_minor / 100, "currency": plan.currency, "interval": plan.interval, "features": plan.features, "highlighted": plan.highlighted}


def subscription_json(db: DbSession, item: UserSubscription | None):
    if not item:
        return None
    plan = db.get(SubscriptionPlan, item.plan_id)
    return {"id": item.id, "plan": plan_json(plan), "startsAt": item.starts_at, "expiresAt": item.expires_at, "autoRenews": item.auto_renews, "status": item.status}


def plans(db: DbSession):
    return [plan_json(item) for item in db.scalars(select(SubscriptionPlan).where(SubscriptionPlan.active.is_(True)).order_by(SubscriptionPlan.price_minor))]


def active_subscription(db: DbSession, user: CurrentUser):
    return subscription_json(db, service.active_subscription(db, user.id))


def purchase_subscription(payload: SubscriptionPurchase, db: DbSession, user: CurrentUser):
    plan = db.get(SubscriptionPlan, payload.plan_id)
    if not plan or not plan.active:
        raise AppError(404, "plan_not_found", "Subscription plan not found.")
    existing = db.scalar(select(UserSubscription.id).where(UserSubscription.provider_reference == payload.purchase_token))
    item = service.purchase_subscription(db, user.id, plan, payload.purchase_token)
    if not existing:
        create_notification(db, user.id, "subscription_purchased", "Subscription active", f"{plan.name} is now active.", {"screen": "ActiveSubscription", "subscriptionId": item.id})
    db.commit()
    return subscription_json(db, item)


def cancel_subscription(db: DbSession, user: CurrentUser):
    item = service.active_subscription(db, user.id)
    if not item:
        raise AppError(404, "subscription_not_found", "No active subscription found.")
    item.auto_renews = False
    db.commit()
    return subscription_json(db, item)


def subscription_history(db: DbSession, user: CurrentUser, before: str | None = None, limit: int = 30):
    stmt = select(UserSubscription).where(UserSubscription.user_id == user.id)
    if before and (marker := db.get(UserSubscription, before)):
        stmt = stmt.where(UserSubscription.created_at < marker.created_at)
    return [subscription_json(db, item) for item in db.scalars(stmt.order_by(UserSubscription.created_at.desc()).limit(min(limit, 100)))]


def coin_packages(db: DbSession):
    return [
        {
            "id": item.id,
            "name": item.name,
            "purchasedCoins": item.purchased_coins,
            "bonusCoins": item.bonus_coins,
            "price": item.price_minor / 100,
            "currency": item.currency,
            "discountPercentage": item.discount_percentage,
            "badge": item.badge,
            "isPopular": item.is_popular,
            "description": item.description,
        }
        for item in db.scalars(select(CoinPackage).where(CoinPackage.active.is_(True)).order_by(CoinPackage.price_minor))
    ]


def list_active_offers(db: DbSession):
    from app.modules.commerce.models import SpecialOffer
    from datetime import datetime, UTC
    now = datetime.now(UTC)
    
    stmt = select(SpecialOffer).where(SpecialOffer.active.is_(True))
    rows = db.scalars(stmt).all()
    
    active_offers = []
    for r in rows:
        # Check start date if present
        if r.starts_at and r.starts_at.tzinfo:
            if r.starts_at > now:
                continue
        elif r.starts_at and not r.starts_at.tzinfo:
            if r.starts_at > now.replace(tzinfo=None):
                continue
                
        # Check expiration date if present
        if r.expires_at and r.expires_at.tzinfo:
            if r.expires_at < now:
                continue
        elif r.expires_at and not r.expires_at.tzinfo:
            if r.expires_at < now.replace(tzinfo=None):
                continue
                
        active_offers.append({
            "id": r.id,
            "title": r.title,
            "description": r.description,
            "offerType": r.offer_type,
            "discountPercentage": r.discount_percentage,
            "bonusCoinsPercentage": r.bonus_coins_percentage,
            "packageId": r.package_id,
            "bannerUrl": r.banner_url,
            "expiresAt": r.expires_at.isoformat() if r.expires_at else None,
        })
    return active_offers


def pricing_config():
    return {
        "source": "admin_dummy_config",
        "chatCoinsPerMinute": settings.chat_coins_per_minute,
        "audioCoinsPerMinute": settings.audio_coins_per_minute,
        "videoCoinsPerMinute": settings.video_coins_per_minute,
        "privatePostCoins": settings.private_post_coin_price,
        "privateCommunityCoins": settings.private_community_coin_price,
        "chatDurationOptions": settings.paid_chat_duration_options,
        "postPriceMinCoins": settings.post_price_min_coins,
        "postPriceMaxCoins": settings.post_price_max_coins,
        "postDeductionEnabled": settings.post_deduction_enabled,
        "publicPostPriceCoins": settings.public_post_price_coins,
        "privatePostPriceCoins": settings.private_post_price_coins,
    }


def claim_daily_reward(db: DbSession, user: CurrentUser):
    result = daily_reward_service.claim_daily_reward(db, user.id)
    create_notification(
        db,
        user.id,
        "daily_reward_claimed",
        f"Day {result['streak_day']} Reward! 🎉",
        f"You earned {result['coins_awarded']} bonus coins. Come back tomorrow for {result['next_reward_coins']} coins!",
        {"screen": "Wallet", "streakDay": result["streak_day"]},
    )
    db.commit()
    return {
        "coinsAwarded": result["coins_awarded"],
        "streakDay": result["streak_day"],
        "nextRewardCoins": result["next_reward_coins"],
        "nextClaimAt": result["next_claim_at"],
        "wallet": result["wallet"],
    }


def daily_reward_status(db: DbSession, user: CurrentUser):
    """Return current streak info without claiming."""
    from datetime import UTC, datetime, timedelta
    wallet = service.wallet_for(db, user.id)
    now = datetime.now(UTC)
    today = now.date()

    already_claimed_today = False
    if wallet.last_login_reward_at:
        last_aware = (
            wallet.last_login_reward_at
            if wallet.last_login_reward_at.tzinfo
            else wallet.last_login_reward_at.replace(tzinfo=UTC)
        )
        already_claimed_today = last_aware.date() >= today

    next_claim_at = datetime.combine(today + timedelta(days=1), datetime.min.time()).replace(tzinfo=UTC)
    schedule = settings.daily_login_reward_schedule or [5, 10, 15, 20, 30, 40, 50]

    return {
        "streakDay": wallet.login_streak,
        "alreadyClaimedToday": already_claimed_today,
        "lastClaimedAt": wallet.last_login_reward_at.isoformat() if wallet.last_login_reward_at else None,
        "nextClaimAt": next_claim_at.isoformat(),
        "schedule": schedule,
    }


def wallet(db: DbSession, user: CurrentUser):
    item = service.wallet_for(db, user.id)
    db.commit()
    return item


def buy_coins(payload: CoinPurchase, db: DbSession, user: CurrentUser):
    package = db.get(CoinPackage, payload.package_id)
    if not package or not package.active:
        raise AppError(404, "coin_package_not_found", "Coin package not found.")
    existing = db.scalar(select(WalletTransaction.id).where(WalletTransaction.idempotency_key == payload.purchase_token))
    wallet = service.purchase_coins(db, user.id, package, payload.purchase_token)
    if not existing:
        create_notification(db, user.id, "coins_added", "Coins added", f"{package.purchased_coins + package.bonus_coins} coins were added to your wallet.", {"screen": "Wallet"})
    db.commit(); db.refresh(wallet)
    return wallet


def transactions(db: DbSession, user: CurrentUser, before: str | None = None, limit: int = 30):
    stmt = select(WalletTransaction).where(WalletTransaction.user_id == user.id)
    if before and (marker := db.get(WalletTransaction, before)):
        stmt = stmt.where(WalletTransaction.created_at < marker.created_at)
    return list(db.scalars(stmt.order_by(WalletTransaction.created_at.desc()).limit(min(limit, 100))))


def wallet_dashboard(db: DbSession, user: CurrentUser, period: str = "30d"):
    days = {"7d": 7, "30d": 30, "90d": 90, "all": None}.get(period)
    if period not in {"7d", "30d", "90d", "all"}:
        raise AppError(422, "invalid_period", "Choose 7d, 30d, 90d, or all.")
    since = datetime.now(UTC) - timedelta(days=days) if days else None
    user_wallet = service.wallet_for(db, user.id)
    earning_wallet = earning_service.settle_due(db, user.id)
    wallet_stmt = select(WalletTransaction).where(WalletTransaction.user_id == user.id)
    earning_stmt = select(CreatorTransaction).where(CreatorTransaction.creator_id == user.id)
    subscription_stmt = select(UserSubscription).where(UserSubscription.user_id == user.id)
    if since:
        wallet_stmt = wallet_stmt.where(WalletTransaction.created_at >= since)
        earning_stmt = earning_stmt.where(CreatorTransaction.created_at >= since)
        subscription_stmt = subscription_stmt.where(UserSubscription.created_at >= since)
    wallet_rows = list(db.scalars(wallet_stmt.order_by(WalletTransaction.created_at.desc())))
    earning_rows = list(db.scalars(earning_stmt.order_by(CreatorTransaction.created_at.desc())))
    subscription_rows = list(db.scalars(subscription_stmt.order_by(UserSubscription.created_at.desc())))
    spent = sum(-row.amount for row in wallet_rows if row.balance_type in {"purchased_coins", "bonus_coins"} and row.amount < 0)
    spent -= sum(row.amount for row in wallet_rows if row.transaction_type == "credit_refund" and row.amount > 0)
    earned = sum(row.creator_amount for row in earning_rows)
    daily: dict[str, dict[str, int | str]] = {}
    chart_days = days or 30
    for offset in range(chart_days - 1, -1, -1):
        key = (datetime.now(UTC) - timedelta(days=offset)).date().isoformat()
        daily[key] = {"date": key, "spent": 0, "earned": 0}
    for row in wallet_rows:
        key = row.created_at.date().isoformat()
        if key in daily and row.balance_type in {"purchased_coins", "bonus_coins"} and row.amount < 0:
            daily[key]["spent"] += -row.amount
    for row in earning_rows:
        key = row.created_at.date().isoformat()
        if key in daily:
            daily[key]["earned"] += row.creator_amount
    history = [
        {"id": row.id, "kind": "wallet", "type": row.transaction_type, "amount": row.amount, "status": row.status, "createdAt": row.created_at, "balanceType": row.balance_type}
        for row in wallet_rows
    ] + [
        {"id": row.id, "kind": "earning", "type": row.reference_type, "amount": row.creator_amount, "status": row.status, "createdAt": row.created_at, "balanceType": "earnings"}
        for row in earning_rows
    ] + [
        {
            "id": row.id,
            "kind": "subscription",
            "type": "subscription_purchase",
            "title": f"{plan.name} subscription" if (plan := db.get(SubscriptionPlan, row.plan_id)) else "Subscription purchase",
            "amount": -(plan.price_minor / 100) if plan else 0,
            "currency": plan.currency if plan else "INR",
            "status": row.status,
            "createdAt": row.created_at,
            "balanceType": "subscription",
        }
        for row in subscription_rows
    ]
    history.sort(key=lambda row: row["createdAt"], reverse=True)
    db.commit()
    return {
        "period": period,
        "currentCoins": user_wallet.purchased_coins + user_wallet.bonus_coins,
        "purchasedCoins": user_wallet.purchased_coins,
        "bonusCoins": user_wallet.bonus_coins,
        "heldCoins": user_wallet.held_coins,
        "totalSpent": max(0, spent),
        "totalEarned": earned,
        "availableToWithdraw": earning_wallet.available_earnings,
        "pendingEarnings": earning_wallet.pending_earnings,
        "chart": list(daily.values()),
        "history": history[:100],
    }
