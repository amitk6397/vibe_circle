"""Add Agora call expiry.

Revision ID: 0009
Revises: 0008
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade():
    inspector = inspect(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("call_sessions")}
    if "expires_at" not in columns:
        with op.batch_alter_table("call_sessions") as batch:
            batch.add_column(sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True))
        op.execute(sa.text("UPDATE call_sessions SET expires_at = created_at WHERE expires_at IS NULL"))
        with op.batch_alter_table("call_sessions") as batch:
            batch.alter_column("expires_at", nullable=False)
            batch.create_index("ix_call_sessions_expires_at", ["expires_at"])


def downgrade():
    columns = {column["name"] for column in inspect(op.get_bind()).get_columns("call_sessions")}
    if "expires_at" in columns:
        with op.batch_alter_table("call_sessions") as batch:
            batch.drop_index("ix_call_sessions_expires_at")
            batch.drop_column("expires_at")
