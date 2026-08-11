"""Add gifts and ratings.

Revision ID: 0013
Revises: 0012
"""
from alembic import op
from app.core.database import Base
from app.core import model_registry  # noqa: F401

revision = "0013"
down_revision = "0012"
branch_labels = None
depends_on = None
TABLES = ["virtual_gifts", "gift_transactions", "rating_reviews"]

def upgrade():
    bind = op.get_bind()
    for name in TABLES: Base.metadata.tables[name].create(bind=bind, checkfirst=True)

def downgrade():
    bind = op.get_bind()
    for name in reversed(TABLES): Base.metadata.tables[name].drop(bind=bind, checkfirst=True)
