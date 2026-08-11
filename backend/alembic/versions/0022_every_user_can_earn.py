"""Make paid conversations and earnings available to every user.

Revision ID: 0022_every_user_can_earn
Revises: 0021_call_join_state
"""

from datetime import UTC, datetime
from uuid import uuid4

import sqlalchemy as sa
from alembic import op


revision = "0022_every_user_can_earn"
down_revision = "0021"
branch_labels = None
depends_on = None


PLANS = [
    ("1 Day Pass", "Use private chat, audio calls, and video calls for one day.", 2900, "day", False),
    ("1 Week Pass", "Use private chat, audio calls, and video calls for one week.", 9900, "week", True),
    ("1 Month Pass", "Use private chat, audio calls, and video calls for one month.", 29900, "month", False),
]


def upgrade() -> None:
    bind = op.get_bind()
    now = datetime.now(UTC)
    metadata = sa.MetaData()
    users = sa.Table("users", metadata, autoload_with=bind)
    profiles = sa.Table("creator_profiles", metadata, autoload_with=bind)
    plans = sa.Table("subscription_plans", metadata, autoload_with=bind)

    bind.execute(sa.update(users).values(account_type="normal"))
    bind.execute(sa.update(plans).values(active=False, highlighted=False))

    feature_list = [
        "Private chat access",
        "Audio and video call access",
        "Coins are charged separately",
    ]
    existing_plan_names = set(bind.execute(sa.select(plans.c.name)).scalars())
    for name, description, price_minor, interval, highlighted in PLANS:
        values = {
            "description": description,
            "price_minor": price_minor,
            "currency": "INR",
            "interval": interval,
            "features": feature_list,
            "chat_allowance": None,
            "audio_credits": 0,
            "video_credits": 0,
            "highlighted": highlighted,
            "active": True,
        }
        if name in existing_plan_names:
            bind.execute(sa.update(plans).where(plans.c.name == name).values(**values))
        else:
            bind.execute(sa.insert(plans).values(id=str(uuid4()), name=name, created_at=now, updated_at=now, **values))

    existing_profile_ids = set(bind.execute(sa.select(profiles.c.user_id)).scalars())
    for user_id, bio, interests, topics, languages in bind.execute(
        sa.select(users.c.id, users.c.bio, users.c.interests, users.c.conversation_topics, users.c.languages)
        .where(users.c.status == "active")
    ):
        if user_id in existing_profile_ids:
            continue
        bind.execute(
            sa.insert(profiles).values(
                id=str(uuid4()),
                user_id=user_id,
                category="Community member",
                topics=topics or interests or [],
                languages=languages or [],
                introduction=bio or "",
                verified=False,
                status="active",
                rating_total=0,
                rating_count=0,
                completed_sessions=0,
                response_count=0,
                request_count=0,
                average_response_seconds=0,
                availability_status="available",
                chat_available=True,
                audio_available=True,
                video_available=True,
                chat_price=10,
                audio_price_per_minute=5,
                video_price_per_minute=10,
                schedule={},
                maximum_daily_sessions=10,
                created_at=now,
                updated_at=now,
            )
        )


def downgrade() -> None:
    bind = op.get_bind()
    metadata = sa.MetaData()
    plans = sa.Table("subscription_plans", metadata, autoload_with=bind)
    bind.execute(sa.update(plans).where(plans.c.name.in_([item[0] for item in PLANS])).values(active=False))
