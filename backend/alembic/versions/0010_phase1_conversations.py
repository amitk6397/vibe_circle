"""Add Phase 1 profile and message request data.

Revision ID: 0010
Revises: 0009
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = "0010"
down_revision = "0009"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    user_columns = {column["name"] for column in inspect(bind).get_columns("users")}
    with op.batch_alter_table("users") as batch:
        if "conversation_topics" not in user_columns:
            batch.add_column(sa.Column("conversation_topics", sa.JSON(), nullable=True))
        if "date_of_birth" not in user_columns:
            batch.add_column(sa.Column("date_of_birth", sa.Date(), nullable=True))
        if "gender" not in user_columns:
            batch.add_column(sa.Column("gender", sa.String(length=40), nullable=True))
        if "preferred_language" not in user_columns:
            batch.add_column(sa.Column("preferred_language", sa.String(length=60), nullable=True))
        if "account_type" not in user_columns:
            batch.add_column(sa.Column("account_type", sa.String(length=20), nullable=True))
            batch.create_index("ix_users_account_type", ["account_type"])
    op.execute(sa.text("UPDATE users SET conversation_topics = '[]' WHERE conversation_topics IS NULL"))
    op.execute(sa.text("UPDATE users SET account_type = 'normal' WHERE account_type IS NULL"))
    if "message_requests" not in inspect(bind).get_table_names():
        op.create_table(
            "message_requests",
            sa.Column("sender_id", sa.String(length=36), nullable=False),
            sa.Column("recipient_id", sa.String(length=36), nullable=False),
            sa.Column("introduction", sa.String(length=300), nullable=False),
            sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
            sa.Column("conversation_id", sa.String(length=36), nullable=True),
            sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("id", sa.String(length=36), primary_key=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        )
        op.create_index("ix_message_requests_sender_id", "message_requests", ["sender_id"])
        op.create_index("ix_message_requests_recipient_id", "message_requests", ["recipient_id"])
        op.create_index("ix_message_requests_status", "message_requests", ["status"])


def downgrade():
    bind = op.get_bind()
    if "message_requests" in inspect(bind).get_table_names():
        op.drop_table("message_requests")
