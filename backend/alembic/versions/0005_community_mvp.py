"""Community MVP privacy and customization.

Revision ID: 0005
Revises: 0004
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade():
    inspector = inspect(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("communities")}
    additions = {
        "logo_url": sa.Column("logo_url", sa.String(500), nullable=True),
        "cover_url": sa.Column("cover_url", sa.String(500), nullable=True),
        "tags": sa.Column("tags", sa.JSON(), nullable=False, server_default="[]"),
        "location": sa.Column("location", sa.String(100), nullable=True),
        "language": sa.Column("language", sa.String(60), nullable=True),
    }
    for name, column in additions.items():
        if name not in columns:
            op.add_column("communities", column)
    if "community_join_requests" not in inspector.get_table_names():
        op.create_table(
            "community_join_requests",
            sa.Column("community_id", sa.String(36), nullable=False),
            sa.Column("user_id", sa.String(36), nullable=False),
            sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
            sa.Column("id", sa.String(36), primary_key=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        )
    inspector = inspect(op.get_bind())
    indexes = {index["name"] for index in inspector.get_indexes("community_join_requests")}
    for name, column in [
        ("ix_community_join_requests_community_id", "community_id"),
        ("ix_community_join_requests_user_id", "user_id"),
        ("ix_community_join_requests_status", "status"),
    ]:
        if name not in indexes:
            op.create_index(name, "community_join_requests", [column])


def downgrade():
    op.drop_table("community_join_requests")
    for column in ["language", "location", "tags", "cover_url", "logo_url"]:
        op.drop_column("communities", column)
