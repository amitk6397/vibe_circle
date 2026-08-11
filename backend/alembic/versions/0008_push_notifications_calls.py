"""Push notification devices and call sessions.

Revision ID: 0008
Revises: 0007
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None


def upgrade():
    tables = set(inspect(op.get_bind()).get_table_names())
    if "notifications" not in tables:
        op.create_table(
            "notifications",
            sa.Column("user_id", sa.String(36), nullable=False),
            sa.Column("type", sa.String(30), nullable=False),
            sa.Column("title", sa.String(120), nullable=False),
            sa.Column("body", sa.Text(), nullable=False),
            sa.Column("data", sa.JSON(), nullable=False),
            sa.Column("is_read", sa.Boolean(), nullable=False),
            sa.Column("id", sa.String(36), primary_key=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        )
        op.create_index("ix_notifications_user_id", "notifications", ["user_id"])
    if "device_tokens" not in tables:
        op.create_table(
            "device_tokens",
            sa.Column("user_id", sa.String(36), nullable=False),
            sa.Column("token", sa.String(512), nullable=False, unique=True),
            sa.Column("platform", sa.String(20), nullable=False),
            sa.Column("id", sa.String(36), primary_key=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        )
        op.create_index("ix_device_tokens_user_id", "device_tokens", ["user_id"])
    if "call_sessions" not in tables:
        op.create_table(
            "call_sessions",
            sa.Column("conversation_id", sa.String(36), nullable=False),
            sa.Column("caller_id", sa.String(36), nullable=False),
            sa.Column("recipient_id", sa.String(36), nullable=False),
            sa.Column("call_type", sa.String(10), nullable=False),
            sa.Column("status", sa.String(20), nullable=False),
            sa.Column("answered_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("id", sa.String(36), primary_key=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        )
        op.create_index("ix_call_sessions_conversation_id", "call_sessions", ["conversation_id"])
        op.create_index("ix_call_sessions_caller_id", "call_sessions", ["caller_id"])
        op.create_index("ix_call_sessions_recipient_id", "call_sessions", ["recipient_id"])
        op.create_index("ix_call_sessions_status", "call_sessions", ["status"])
        op.create_index("ix_call_sessions_expires_at", "call_sessions", ["expires_at"])


def downgrade():
    op.drop_table("call_sessions")
    op.drop_table("device_tokens")
    op.drop_table("notifications")
