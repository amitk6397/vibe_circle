"""Add story privacy controls.

Revision ID: 0016
Revises: 0015
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect
from app.core.database import Base
from app.core import model_registry  # noqa: F401
revision = "0016"
down_revision = "0015"
branch_labels = None
depends_on = None

def upgrade():
    columns = {item["name"] for item in inspect(op.get_bind()).get_columns("stories")}
    definitions = {"audience": sa.Column("audience", sa.String(30), nullable=False, server_default="public"), "selected_user_ids": sa.Column("selected_user_ids", sa.JSON(), nullable=True), "audience_community_id": sa.Column("audience_community_id", sa.String(36), nullable=True), "replies_enabled": sa.Column("replies_enabled", sa.Boolean(), nullable=False, server_default=sa.true()), "archived": sa.Column("archived", sa.Boolean(), nullable=False, server_default=sa.false())}
    with op.batch_alter_table("stories") as batch:
        for name, column in definitions.items():
            if name not in columns: batch.add_column(column)
    Base.metadata.tables["story_mutes"].create(bind=op.get_bind(), checkfirst=True)

def downgrade():
    Base.metadata.tables["story_mutes"].drop(bind=op.get_bind(), checkfirst=True)
