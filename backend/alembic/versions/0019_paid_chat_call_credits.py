"""Add paid chat and subscription call credit accounting.

Revision ID: 0019
Revises: 0018
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = "0019"
down_revision = "0018"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    request_columns = {item["name"] for item in inspect(bind).get_columns("message_requests")}
    with op.batch_alter_table("message_requests") as batch:
        if "creator_chat_price" not in request_columns:
            batch.add_column(sa.Column("creator_chat_price", sa.Integer(), nullable=False, server_default="0"))
        if "charged_at" not in request_columns:
            batch.add_column(sa.Column("charged_at", sa.DateTime(timezone=True), nullable=True))
    call_columns = {item["name"] for item in inspect(bind).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        if "held_credit_minutes" not in call_columns:
            batch.add_column(sa.Column("held_credit_minutes", sa.Integer(), nullable=False, server_default="0"))
        if "used_credit_minutes" not in call_columns:
            batch.add_column(sa.Column("used_credit_minutes", sa.Integer(), nullable=False, server_default="0"))


def downgrade():
    bind = op.get_bind()
    call_columns = {item["name"] for item in inspect(bind).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        for name in ["used_credit_minutes", "held_credit_minutes"]:
            if name in call_columns:
                batch.drop_column(name)
    request_columns = {item["name"] for item in inspect(bind).get_columns("message_requests")}
    with op.batch_alter_table("message_requests") as batch:
        for name in ["charged_at", "creator_chat_price"]:
            if name in request_columns:
                batch.drop_column(name)
