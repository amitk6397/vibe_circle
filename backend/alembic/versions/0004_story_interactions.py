"""Add story interactions.

Revision ID: 0004
Revises: 0003
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade():
    columns = {column["name"] for column in inspect(op.get_bind()).get_columns("stories")}
    if "reactions" not in columns:
        op.add_column("stories", sa.Column("reactions", sa.JSON(), nullable=False, server_default="[]"))
    if "replies" not in columns:
        op.add_column("stories", sa.Column("replies", sa.JSON(), nullable=False, server_default="[]"))


def downgrade():
    columns = {column["name"] for column in inspect(op.get_bind()).get_columns("stories")}
    if "replies" in columns:
        op.drop_column("stories", "replies")
    if "reactions" in columns:
        op.drop_column("stories", "reactions")
