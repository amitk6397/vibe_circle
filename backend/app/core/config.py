from functools import lru_cache
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    app_name: str = "VibeCircle API"
    app_env: str = "development"
    api_v1_prefix: str = "/api/v1"
    secret_key: str = "development-secret-change-before-production"
    database_url: str = f"sqlite:///{(BASE_DIR / 'vibecircle.db').as_posix()}"
    access_token_minutes: int = 30
    refresh_token_days: int = 30
    allowed_origins: list[str] | str = ["http://localhost:8081", "http://localhost:19006"]
    public_base_url: str = "http://127.0.0.1:8000"
    upload_dir: Path = BASE_DIR / "uploads"
    max_upload_bytes: int = 15 * 1024 * 1024
    firebase_credentials_path: Path | None = None
    agora_app_id: str = ""
    agora_app_certificate: str = ""
    agora_token_ttl_seconds: int = 3600
    call_ring_timeout_seconds: int = 60
    call_join_timeout_seconds: int = 120
    call_duration_options: list[int] | str = [5, 10, 15, 30]
    free_conversations_per_week: int = 5
    free_messages_per_conversation: int = 10
    message_requests_per_day: int = 10
    message_request_expiry_hours: int = 72
    dummy_payments_enabled: bool = True
    platform_commission_percent: int = 20
    creator_settlement_days: int = 7
    chat_coins_per_minute: int = 2
    audio_coins_per_minute: int = 5
    video_coins_per_minute: int = 10
    private_post_coin_price: int = 15
    private_community_coin_price: int = 50
    paid_chat_duration_options: list[int] | str = [5, 10, 15, 30]
    restricted_words: list[str] | str = ["kill yourself", "child sexual", "rape threat"]
    # Referral system
    referral_inviter_coins: int = 50
    referral_invitee_coins: int = 20
    # Daily login rewards (7 values = Day 1 through Day 7, Day 7 repeats)
    daily_login_reward_schedule: list[int] | str = [5, 10, 15, 20, 25, 35, 50]
    # Post pricing limits for creator-set prices
    post_price_min_coins: int = 5
    post_price_max_coins: int = 500
    # Call grace period before auto-disconnect (seconds)
    call_grace_period_seconds: int = 15
    # Per-message coin cost in paid chats (0 = disabled)
    chat_coins_per_message: int = 1
    # Messages interval between coin deductions in paid chats (e.g. 2 = every 2 messages)
    chat_message_deduction_interval: int = 2
    # Community subscriptions
    community_subscription_days: int = 30
    community_price_min_coins: int = 50
    community_price_max_coins: int = 5000
    # Post boosting
    post_boost_coins: int = 50
    post_boost_hours: int = 24
    # Ask & Earn bounty
    bounty_min_coins: int = 10

    model_config = SettingsConfigDict(env_file=BASE_DIR / ".env", extra="ignore")

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def parse_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @field_validator("restricted_words", mode="before")
    @classmethod
    def parse_restricted_words(cls, value: object) -> object:
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @field_validator("call_duration_options", mode="before")
    @classmethod
    def parse_call_durations(cls, value: object) -> object:
        if isinstance(value, str):
            return [int(item.strip()) for item in value.split(",") if item.strip()]
        return value

    @field_validator("paid_chat_duration_options", mode="before")
    @classmethod
    def parse_chat_durations(cls, value: object) -> object:
        if isinstance(value, str):
            return [int(item.strip()) for item in value.split(",") if item.strip()]
        return value

    @field_validator("daily_login_reward_schedule", mode="before")
    @classmethod
    def parse_daily_rewards(cls, value: object) -> object:
        if isinstance(value, str):
            return [int(item.strip()) for item in value.split(",") if item.strip()]
        return value

    @field_validator("firebase_credentials_path", mode="before")
    @classmethod
    def resolve_firebase_credentials(cls, value: object) -> object:
        if value in (None, ""):
            matches = list(BASE_DIR.glob("*firebase-adminsdk*.json"))
            return matches[0] if matches else None
        path = Path(str(value))
        return path if path.is_absolute() else BASE_DIR / path


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
