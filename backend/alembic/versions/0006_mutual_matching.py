"""Mutual matching lifecycle.

Revision ID: 0006
Revises: 0005
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade():
    existing = {column["name"] for column in inspect(op.get_bind()).get_columns("matches")}
    additions = {
        "candidate_preferences": sa.Column("candidate_preferences", sa.JSON(), nullable=False, server_default="{}"),
        "accepted_by": sa.Column("accepted_by", sa.JSON(), nullable=False, server_default="[]"),
        "conversation_id": sa.Column("conversation_id", sa.String(36), nullable=True),
        "expires_at": sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
    }
    for name, column in additions.items():
        if name not in existing:
            op.add_column("matches", column)


def downgrade():
    existing = {column["name"] for column in inspect(op.get_bind()).get_columns("matches")}
    for name in ["expires_at", "conversation_id", "accepted_by", "candidate_preferences"]:
        if name in existing:
            op.drop_column("matches", name)
