"""Add community monetization features.

Adds:
  - community_subscriptions: expires_at
  - posts: tip_count, tip_total, is_boosted, boosted_until, boost_cost,
           bounty_amount, bounty_held_bonus, bounty_held_purchased,
           bounty_status, bounty_winner_comment_id
  - post_tips: new table

Revision ID: 0025_community_monetization
Revises: 0024_monetization_features
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

from app.core.database import Base
from app.core import model_registry  # noqa: F401


revision = "0025_community_monetization"
down_revision = "0024_monetization_features"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()

    # --- community_subscriptions: add expires_at ---
    cs_cols = {col["name"] for col in inspect(bind).get_columns("community_subscriptions")}
    with op.batch_alter_table("community_subscriptions") as batch:
        if "expires_at" not in cs_cols:
            batch.add_column(sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True))

    # --- posts: add tipping, boosting, bounty columns ---
    post_cols = {col["name"] for col in inspect(bind).get_columns("posts")}
    with op.batch_alter_table("posts") as batch:
        if "tip_count" not in post_cols:
            batch.add_column(sa.Column("tip_count", sa.Integer(), nullable=False, server_default="0"))
        if "tip_total" not in post_cols:
            batch.add_column(sa.Column("tip_total", sa.Integer(), nullable=False, server_default="0"))
        if "is_boosted" not in post_cols:
            batch.add_column(sa.Column("is_boosted", sa.Boolean(), nullable=False, server_default="0"))
            batch.create_index("ix_posts_is_boosted", ["is_boosted"])
        if "boosted_until" not in post_cols:
            batch.add_column(sa.Column("boosted_until", sa.DateTime(timezone=True), nullable=True))
        if "boost_cost" not in post_cols:
            batch.add_column(sa.Column("boost_cost", sa.Integer(), nullable=False, server_default="0"))
        if "bounty_amount" not in post_cols:
            batch.add_column(sa.Column("bounty_amount", sa.Integer(), nullable=False, server_default="0"))
        if "bounty_held_bonus" not in post_cols:
            batch.add_column(sa.Column("bounty_held_bonus", sa.Integer(), nullable=False, server_default="0"))
        if "bounty_held_purchased" not in post_cols:
            batch.add_column(sa.Column("bounty_held_purchased", sa.Integer(), nullable=False, server_default="0"))
        if "bounty_status" not in post_cols:
            batch.add_column(sa.Column("bounty_status", sa.String(20), nullable=False, server_default="none"))
            batch.create_index("ix_posts_bounty_status", ["bounty_status"])
        if "bounty_winner_comment_id" not in post_cols:
            batch.add_column(sa.Column("bounty_winner_comment_id", sa.String(36), nullable=True))

    # --- post_tips: create new table ---
    Base.metadata.tables["post_tips"].create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    Base.metadata.tables["post_tips"].drop(bind=bind, checkfirst=True)

    with op.batch_alter_table("posts") as batch:
        batch.drop_column("bounty_winner_comment_id")
        batch.drop_index("ix_posts_bounty_status")
        batch.drop_column("bounty_status")
        batch.drop_column("bounty_held_purchased")
        batch.drop_column("bounty_held_bonus")
        batch.drop_column("bounty_amount")
        batch.drop_column("boost_cost")
        batch.drop_column("boosted_until")
        batch.drop_index("ix_posts_is_boosted")
        batch.drop_column("is_boosted")
        batch.drop_column("tip_total")
        batch.drop_column("tip_count")

    with op.batch_alter_table("community_subscriptions") as batch:
        batch.drop_column("expires_at")
