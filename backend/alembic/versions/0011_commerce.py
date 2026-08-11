"""Add subscriptions and wallet ledger.

Revision ID: 0011
Revises: 0010
"""

from alembic import op

from app.core.database import Base
from app.core import model_registry  # noqa: F401

revision = "0011"
down_revision = "0010"
branch_labels = None
depends_on = None

TABLES = ["subscription_plans", "user_subscriptions", "coin_packages", "user_wallets", "wallet_transactions", "conversation_unlocks"]


def upgrade():
    bind = op.get_bind()
    for name in TABLES:
        Base.metadata.tables[name].create(bind=bind, checkfirst=True)


def downgrade():
    bind = op.get_bind()
    for name in reversed(TABLES):
        Base.metadata.tables[name].drop(bind=bind, checkfirst=True)
