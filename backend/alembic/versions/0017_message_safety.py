"""Add message safety flags.

Revision ID: 0017
Revises: 0016
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
revision = "0017"
down_revision = "0016"
branch_labels = None
depends_on = None
def upgrade():
    if "safety_flags" not in {item["name"] for item in inspect(op.get_bind()).get_columns("messages")}:
        with op.batch_alter_table("messages") as batch: batch.add_column(sa.Column("safety_flags", sa.JSON(), nullable=True))
def downgrade():
    if "safety_flags" in {item["name"] for item in inspect(op.get_bind()).get_columns("messages")}:
        with op.batch_alter_table("messages") as batch: batch.drop_column("safety_flags")
