"""Track paid call participant joins.

Revision ID: 0021
Revises: 0020
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = "0021"
down_revision = "0020"
branch_labels = None
depends_on = None


def upgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        for name in ["caller_joined_at", "recipient_joined_at", "started_at"]:
            if name not in columns: batch.add_column(sa.Column(name, sa.DateTime(timezone=True), nullable=True))


def downgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        for name in ["started_at", "recipient_joined_at", "caller_joined_at"]:
            if name in columns: batch.drop_column(name)
