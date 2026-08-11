"""Add community bans.

Revision ID: 0018
Revises: 0017
"""
from alembic import op
from app.core.database import Base
from app.core import model_registry  # noqa: F401
revision = "0018"
down_revision = "0017"
branch_labels = None
depends_on = None
def upgrade(): Base.metadata.tables["community_bans"].create(bind=op.get_bind(), checkfirst=True)
def downgrade(): Base.metadata.tables["community_bans"].drop(bind=op.get_bind(), checkfirst=True)
