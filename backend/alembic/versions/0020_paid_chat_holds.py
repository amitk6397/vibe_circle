"""Reserve paid chat coins while a request is pending.

Revision ID: 0020
Revises: 0019
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = "0020"
down_revision = "0019"
branch_labels = None
depends_on = None


def upgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("message_requests")}
    with op.batch_alter_table("message_requests") as batch:
        if "held_bonus_coins" not in columns:
            batch.add_column(sa.Column("held_bonus_coins", sa.Integer(), nullable=False, server_default="0"))
        if "held_purchased_coins" not in columns:
            batch.add_column(sa.Column("held_purchased_coins", sa.Integer(), nullable=False, server_default="0"))


def downgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("message_requests")}
    with op.batch_alter_table("message_requests") as batch:
        for name in ["held_purchased_coins", "held_bonus_coins"]:
            if name in columns:
                batch.drop_column(name)
