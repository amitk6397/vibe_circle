"""Remove onboarding content.

Revision ID: 0002
Revises: 0001
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade():
    if inspect(op.get_bind()).has_table("onboarding_slides"):
        op.drop_table("onboarding_slides")


def downgrade():
    if inspect(op.get_bind()).has_table("onboarding_slides"):
        return
    op.create_table(
        "onboarding_slides",
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("icon", sa.String(length=50), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_onboarding_slides_active", "onboarding_slides", ["active"])
    op.create_index("ix_onboarding_slides_position", "onboarding_slides", ["position"], unique=True)
