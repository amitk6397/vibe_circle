"""Add admin-priced chat sessions and private post unlocks.

Revision ID: 0023_admin_pricing_paid_content
Revises: 0022_every_user_can_earn
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

from app.core.database import Base
from app.core import model_registry  # noqa: F401


revision = "0023_admin_pricing_paid_content"
down_revision = "0022_every_user_can_earn"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    post_columns = {item["name"] for item in inspect(bind).get_columns("posts")}
    with op.batch_alter_table("posts") as batch:
        if "visibility" not in post_columns:
            batch.add_column(sa.Column("visibility", sa.String(20), nullable=False, server_default="public"))
            batch.create_index("ix_posts_visibility", ["visibility"])
        if "coin_price" not in post_columns:
            batch.add_column(sa.Column("coin_price", sa.Integer(), nullable=False, server_default="0"))

    request_columns = {item["name"] for item in inspect(bind).get_columns("message_requests")}
    with op.batch_alter_table("message_requests") as batch:
        if "reserved_minutes" not in request_columns:
            batch.add_column(sa.Column("reserved_minutes", sa.Integer(), nullable=False, server_default="10"))
        if "price_per_minute" not in request_columns:
            batch.add_column(sa.Column("price_per_minute", sa.Integer(), nullable=False, server_default="2"))

    Base.metadata.tables["post_unlocks"].create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    Base.metadata.tables["post_unlocks"].drop(bind=bind, checkfirst=True)
    with op.batch_alter_table("message_requests") as batch:
        batch.drop_column("price_per_minute")
        batch.drop_column("reserved_minutes")
    with op.batch_alter_table("posts") as batch:
        batch.drop_column("coin_price")
        batch.drop_index("ix_posts_visibility")
        batch.drop_column("visibility")
