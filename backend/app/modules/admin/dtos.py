from typing import Literal, Optional
from pydantic import BaseModel


# ── User Management ──────────────────────────────────────────────────────────

class UserStatusUpdate(BaseModel):
    status: str  # active | restricted | suspended | banned | deleted
    role: Optional[str] = None  # user | moderator | admin


class ReportReview(BaseModel):
    status: Literal["reviewing", "resolved", "dismissed"]
    action: Literal["none", "warn", "restrict", "suspend", "ban", "remove_content"] = "none"


class WithdrawalReview(BaseModel):
    status: Literal["under_review", "approved", "processing", "paid", "rejected", "failed"]
    reason: str = ""


class CreatorApplicationReview(BaseModel):
    action: Literal["approve", "reject"]
    note: str = ""


# ── Community Management ─────────────────────────────────────────────────────

class CommunityStatusUpdate(BaseModel):
    status: str  # active | suspended


# ── Subscription Plans ───────────────────────────────────────────────────────

class SubscriptionPlanCreate(BaseModel):
    name: str
    description: str = ""
    price_minor: int           # in paise (INR)
    currency: str = "INR"
    interval: str = "month"
    features: list[str] = []
    chat_allowance: Optional[int] = None
    audio_credits: int = 0
    video_credits: int = 0
    highlighted: bool = False
    active: bool = True


class SubscriptionPlanUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price_minor: Optional[int] = None
    features: Optional[list[str]] = None
    chat_allowance: Optional[int] = None
    audio_credits: Optional[int] = None
    video_credits: Optional[int] = None
    highlighted: Optional[bool] = None
    active: Optional[bool] = None


# ── Coin Packages ────────────────────────────────────────────────────────────

class CoinPackageCreate(BaseModel):
    name: str
    purchased_coins: int
    bonus_coins: int = 0
    price_minor: int
    currency: str = "INR"
    active: bool = True


class CoinPackageUpdate(BaseModel):
    name: Optional[str] = None
    purchased_coins: Optional[int] = None
    bonus_coins: Optional[int] = None
    price_minor: Optional[int] = None
    active: Optional[bool] = None


# ── Support Articles ─────────────────────────────────────────────────────────

class SupportArticleCreate(BaseModel):
    slug: str
    title: str
    icon: str = "document-text-outline"
    body: str
    position: int = 0
    active: bool = True


class SupportArticleUpdate(BaseModel):
    title: Optional[str] = None
    icon: Optional[str] = None
    body: Optional[str] = None
    position: Optional[int] = None
    active: Optional[bool] = None


# ── Platform Settings ─────────────────────────────────────────────────────────

class PlatformSettingsUpdate(BaseModel):
    # Coin rates
    chat_coins_per_minute: Optional[int] = None
    audio_coins_per_minute: Optional[int] = None
    video_coins_per_minute: Optional[int] = None
    # Paid chat (per-message deduction)
    chat_coins_per_message: Optional[int] = None
    chat_message_deduction_interval: Optional[int] = None
    # Private content pricing
    private_post_coin_price: Optional[int] = None
    private_community_coin_price: Optional[int] = None
    # Conversation limits
    free_conversations_per_week: Optional[int] = None
    free_messages_per_conversation: Optional[int] = None
    message_requests_per_day: Optional[int] = None
    message_request_expiry_hours: Optional[int] = None
    # Platform financials
    platform_commission_percent: Optional[int] = None
    creator_settlement_days: Optional[int] = None
    # Rewards
    daily_login_reward_schedule: Optional[list[int]] = None
    referral_inviter_coins: Optional[int] = None
    referral_invitee_coins: Optional[int] = None
    # Post/Community pricing limits
    post_price_min_coins: Optional[int] = None
    post_price_max_coins: Optional[int] = None
    community_price_min_coins: Optional[int] = None
    community_price_max_coins: Optional[int] = None
    community_subscription_days: Optional[int] = None
    # Post boosting
    post_boost_coins: Optional[int] = None
    post_boost_hours: Optional[int] = None
    # Bounty
    bounty_min_coins: Optional[int] = None
    # Call settings
    call_grace_period_seconds: Optional[int] = None
    call_ring_timeout_seconds: Optional[int] = None
    call_join_timeout_seconds: Optional[int] = None
    call_duration_options: Optional[list[int]] = None
    paid_chat_duration_options: Optional[list[int]] = None
    # Safety
    restricted_words: Optional[list[str]] = None
    dummy_payments_enabled: Optional[bool] = None


# ── Virtual Gifts ─────────────────────────────────────────────────────────────

class VirtualGiftCreate(BaseModel):
    name: str
    icon: str
    coin_price: int
    creator_earning_value: int
    animation_url: Optional[str] = None
    active: bool = True


class VirtualGiftUpdate(BaseModel):
    name: Optional[str] = None
    icon: Optional[str] = None
    coin_price: Optional[int] = None
    creator_earning_value: Optional[int] = None
    animation_url: Optional[str] = None
    active: Optional[bool] = None

