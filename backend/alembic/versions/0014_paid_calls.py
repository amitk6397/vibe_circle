"""Add paid call accounting.

Revision ID: 0014
Revises: 0013
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
revision = "0014"
down_revision = "0013"
branch_labels = None
depends_on = None

def upgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        for name in ["reserved_minutes", "price_per_minute", "held_coins", "held_bonus_coins", "held_purchased_coins", "charged_coins"]:
            if name not in columns: batch.add_column(sa.Column(name, sa.Integer(), nullable=False, server_default="0"))

def downgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("call_sessions")}
    with op.batch_alter_table("call_sessions") as batch:
        for name in ["charged_coins", "held_purchased_coins", "held_bonus_coins", "held_coins", "price_per_minute", "reserved_minutes"]:
            if name in columns: batch.drop_column(name)
