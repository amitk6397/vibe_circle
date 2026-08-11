"""Availability, private circles, and timed Connect.

Revision ID: 0007
Revises: 0006
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def add_columns(table, additions):
    existing = {column["name"] for column in inspect(op.get_bind()).get_columns(table)}
    for name, column in additions.items():
        if name not in existing:
            op.add_column(table, column)


def upgrade():
    add_columns("users", {
        "vibe_status": sa.Column("vibe_status", sa.String(40), nullable=True),
        "vibe_expires_at": sa.Column("vibe_expires_at", sa.DateTime(timezone=True), nullable=True),
    })
    add_columns("communities", {
        "kind": sa.Column("kind", sa.String(20), nullable=False, server_default="community"),
        "max_members": sa.Column("max_members", sa.Integer(), nullable=False, server_default="500"),
    })
    add_columns("matches", {
        "session_minutes": sa.Column("session_minutes", sa.Integer(), nullable=False, server_default="10"),
        "session_ends_at": sa.Column("session_ends_at", sa.DateTime(timezone=True), nullable=True),
    })
    inspector = inspect(op.get_bind())
    if "community_invites" not in inspector.get_table_names():
        op.create_table(
            "community_invites",
            sa.Column("community_id", sa.String(36), nullable=False),
            sa.Column("inviter_id", sa.String(36), nullable=False),
            sa.Column("invited_user_id", sa.String(36), nullable=False),
            sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
            sa.Column("id", sa.String(36), primary_key=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        )
    inspector = inspect(op.get_bind())
    indexes = {index["name"] for index in inspector.get_indexes("community_invites")}
    for name, column in [
        ("ix_community_invites_community_id", "community_id"),
        ("ix_community_invites_inviter_id", "inviter_id"),
        ("ix_community_invites_invited_user_id", "invited_user_id"),
        ("ix_community_invites_status", "status"),
        ("ix_communities_kind", "kind"),
    ]:
        table = "communities" if column == "kind" else "community_invites"
        existing_indexes = {index["name"] for index in inspector.get_indexes(table)}
        if name not in existing_indexes:
            op.create_index(name, table, [column])


def downgrade():
    if "community_invites" in inspect(op.get_bind()).get_table_names():
        op.drop_table("community_invites")
    for table, columns in [("matches", ["session_ends_at", "session_minutes"]), ("communities", ["max_members", "kind"]), ("users", ["vibe_expires_at", "vibe_status"])]:
        existing = {column["name"] for column in inspect(op.get_bind()).get_columns(table)}
        for column in columns:
            if column in existing:
                op.drop_column(table, column)
