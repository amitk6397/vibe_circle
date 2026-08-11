"""Add monetization & engagement feature columns.

Adds:
  - user_wallets: login_streak, last_login_reward_at
  - users: referral_code, referred_by
  - call_sessions: end_reason

Revision ID: 0024_monetization_features
Revises: 0023_admin_pricing_paid_content
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect


revision = "0024_monetization_features"
down_revision = "0023_admin_pricing_paid_content"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()

    # --- user_wallets ---
    wallet_columns = {col["name"] for col in inspect(bind).get_columns("user_wallets")}
    with op.batch_alter_table("user_wallets") as batch:
        if "login_streak" not in wallet_columns:
            batch.add_column(sa.Column("login_streak", sa.Integer(), nullable=False, server_default="0"))
        if "last_login_reward_at" not in wallet_columns:
            batch.add_column(sa.Column("last_login_reward_at", sa.DateTime(timezone=True), nullable=True))

    # --- users ---
    user_columns = {col["name"] for col in inspect(bind).get_columns("users")}
    with op.batch_alter_table("users") as batch:
        if "referral_code" not in user_columns:
            batch.add_column(sa.Column("referral_code", sa.String(16), nullable=True))
            batch.create_index("ix_users_referral_code", ["referral_code"], unique=True)
        if "referred_by" not in user_columns:
            batch.add_column(sa.Column("referred_by", sa.String(36), nullable=True))

    # --- call_sessions ---
    call_columns = {col["name"] for col in inspect(bind).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        if "end_reason" not in call_columns:
            batch.add_column(sa.Column("end_reason", sa.String(30), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("call_sessions") as batch:
        batch.drop_column("end_reason")

    with op.batch_alter_table("users") as batch:
        batch.drop_index("ix_users_referral_code")
        batch.drop_column("referral_code")
        batch.drop_column("referred_by")

    with op.batch_alter_table("user_wallets") as batch:
        batch.drop_column("last_login_reward_at")
        batch.drop_column("login_streak")
