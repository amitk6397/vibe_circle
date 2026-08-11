"""Add premium communities.

Revision ID: 0015
Revises: 0014
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
from app.core.database import Base
from app.core import model_registry  # noqa: F401
revision = "0015"
down_revision = "0014"
branch_labels = None
depends_on = None

def upgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("communities")}
    if "premium_price" not in columns:
        with op.batch_alter_table("communities") as batch: batch.add_column(sa.Column("premium_price", sa.Integer(), nullable=False, server_default="0"))
    Base.metadata.tables["community_subscriptions"].create(bind=op.get_bind(), checkfirst=True)

def downgrade():
    Base.metadata.tables["community_subscriptions"].drop(bind=op.get_bind(), checkfirst=True)
    if "premium_price" in {item["name"] for item in inspect(op.get_bind()).get_columns("communities")}:
        with op.batch_alter_table("communities") as batch: batch.drop_column("premium_price")
