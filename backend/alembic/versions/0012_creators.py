"""Add creator applications, profiles and earnings.

Revision ID: 0012
Revises: 0011
"""
from alembic import op
from app.core.database import Base
from app.core import model_registry  # noqa: F401

revision = "0012"
down_revision = "0011"
branch_labels = None
depends_on = None
TABLES = ["creator_applications", "creator_profiles", "creator_wallets", "creator_transactions", "withdrawal_requests"]

def upgrade():
    bind = op.get_bind()
    for name in TABLES: Base.metadata.tables[name].create(bind=bind, checkfirst=True)

def downgrade():
    bind = op.get_bind()
    for name in reversed(TABLES): Base.metadata.tables[name].drop(bind=bind, checkfirst=True)
