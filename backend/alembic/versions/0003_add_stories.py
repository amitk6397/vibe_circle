"""Add photo stories.

Revision ID: 0003
Revises: 0002
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade():
    if inspect(op.get_bind()).has_table("stories"):
        return
    op.create_table(
        "stories",
        sa.Column("author_id", sa.String(length=36), nullable=False),
        sa.Column("media_url", sa.String(length=500), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("viewed_by", sa.JSON(), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_stories_author_id", "stories", ["author_id"])
    op.create_index("ix_stories_expires_at", "stories", ["expires_at"])


def downgrade():
    if inspect(op.get_bind()).has_table("stories"):
        op.drop_table("stories")
