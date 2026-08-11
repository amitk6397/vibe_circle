from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.app_content.models import SupportArticle
from app.modules.commerce.models import CoinPackage, SubscriptionPlan
from app.modules.engagement.models import VirtualGift


def seed_app_content(db: Session) -> None:
    """Install required system-owned support content, never user/content fixtures."""
    if not db.scalar(select(SupportArticle.id).limit(1)):
        articles = [
            ("help-center", "Help center", "help-circle-outline", "Find answers about accounts, profiles, communities, messaging, privacy, and reporting."),
            ("safety-center", "Safety center", "shield-checkmark-outline", "Block unsafe accounts, report harmful content, protect personal information, and contact local emergency services when immediate help is needed."),
            ("community-rules", "Community rules", "people-outline", "Be respectful, stay on topic, do not spam, impersonate, threaten, harass, or share another person's private information."),
            ("terms", "Terms of service", "document-text-outline", "Use VibeCircle lawfully and responsibly. Accounts or content that violate these terms may be restricted or removed."),
            ("privacy", "Privacy policy", "lock-closed-outline", "VibeCircle stores the information needed to operate your account and does not expose your email or password on public profiles."),
            ("about", "About VibeCircle", "information-circle-outline", "VibeCircle helps adults discover people and communities for respectful conversations and shared interests."),
        ]
        db.add_all([SupportArticle(slug=slug, title=title, icon=icon, body=body, position=index) for index, (slug, title, icon, body) in enumerate(articles, 1)])
    if not db.scalar(select(SubscriptionPlan.id).limit(1)):
        db.add_all([
            SubscriptionPlan(name="1 Day Pass", description="Use private chat, audio calls, and video calls for one day.", price_minor=2900, currency="INR", interval="day", features=["Private chat access", "Audio and video call access", "Coins are charged separately"], chat_allowance=None),
            SubscriptionPlan(name="1 Week Pass", description="Use private chat, audio calls, and video calls for one week.", price_minor=9900, currency="INR", interval="week", features=["Private chat access", "Audio and video call access", "Coins are charged separately"], chat_allowance=None, highlighted=True),
            SubscriptionPlan(name="1 Month Pass", description="Use private chat, audio calls, and video calls for one month.", price_minor=29900, currency="INR", interval="month", features=["Private chat access", "Audio and video call access", "Coins are charged separately"], chat_allowance=None),
        ])
    if not db.scalar(select(CoinPackage.id).limit(1)):
        db.add_all([
            CoinPackage(name="Starter", purchased_coins=100, bonus_coins=0, price_minor=9900),
            CoinPackage(name="Value", purchased_coins=500, bonus_coins=50, price_minor=44900),
            CoinPackage(name="Supporter", purchased_coins=1200, bonus_coins=200, price_minor=99900),
        ])
    if not db.scalar(select(VirtualGift.id).limit(1)):
        db.add_all([
            VirtualGift(name="Appreciation", icon="heart", coin_price=20, creator_earning_value=16),
            VirtualGift(name="Great Conversation", icon="chatbubbles", coin_price=50, creator_earning_value=40),
            VirtualGift(name="Star Supporter", icon="star", coin_price=100, creator_earning_value=80),
        ])
    db.commit()
