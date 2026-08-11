from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.common.models import IdMixin, TimestampMixin
from app.core.database import Base


class Post(Base, IdMixin, TimestampMixin):
    __tablename__ = "posts"

    author_id: Mapped[str] = mapped_column(String(36), index=True)
    community_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    type: Mapped[str] = mapped_column(String(20), default="text")
    body: Mapped[str] = mapped_column(Text)
    anonymous: Mapped[bool] = mapped_column(Boolean, default=False)
    media_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    poll_options: Mapped[list[str]] = mapped_column(JSON, default=list)
    poll_votes: Mapped[dict] = mapped_column(JSON, default=dict)
    like_count: Mapped[int] = mapped_column(Integer, default=0)
    comment_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(20), default="active")
    visibility: Mapped[str] = mapped_column(String(20), default="public", index=True)
    coin_price: Mapped[int] = mapped_column(Integer, default=0)
    # Post Tipping / Super Likes
    tip_count: Mapped[int] = mapped_column(Integer, default=0)
    tip_total: Mapped[int] = mapped_column(Integer, default=0)
    # Post Boosting
    is_boosted: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    boosted_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    boost_cost: Mapped[int] = mapped_column(Integer, default=0)
    # Ask & Earn Bounty
    bounty_amount: Mapped[int] = mapped_column(Integer, default=0)
    bounty_held_bonus: Mapped[int] = mapped_column(Integer, default=0)
    bounty_held_purchased: Mapped[int] = mapped_column(Integer, default=0)
    bounty_status: Mapped[str] = mapped_column(String(20), default="none", index=True)
    bounty_winner_comment_id: Mapped[str | None] = mapped_column(String(36), nullable=True)


class PostTip(Base, IdMixin, TimestampMixin):
    """Tracks coin tips sent to post authors (Super Likes)."""
    __tablename__ = "post_tips"
    post_id: Mapped[str] = mapped_column(String(36), index=True)
    tipper_id: Mapped[str] = mapped_column(String(36), index=True)
    coin_amount: Mapped[int] = mapped_column(Integer)
    message: Mapped[str | None] = mapped_column(String(200), nullable=True)



class PostUnlock(Base, IdMixin, TimestampMixin):
    __tablename__ = "post_unlocks"
    post_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    coin_amount: Mapped[int] = mapped_column(Integer)


class Comment(Base, IdMixin, TimestampMixin):
    __tablename__ = "comments"

    post_id: Mapped[str] = mapped_column(String(36), index=True)
    author_id: Mapped[str] = mapped_column(String(36), index=True)
    parent_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    body: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="active")


class PostReaction(Base, IdMixin, TimestampMixin):
    __tablename__ = "post_reactions"

    post_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    kind: Mapped[str] = mapped_column(String(20), default="like")


class SavedPost(Base, IdMixin, TimestampMixin):
    __tablename__ = "saved_posts"

    post_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str] = mapped_column(String(36), index=True)


class Story(Base, IdMixin, TimestampMixin):
    __tablename__ = "stories"

    author_id: Mapped[str] = mapped_column(String(36), index=True)
    media_url: Mapped[str] = mapped_column(String(500))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    viewed_by: Mapped[list[str]] = mapped_column(JSON, default=list)
    reactions: Mapped[list[dict]] = mapped_column(JSON, default=list)
    replies: Mapped[list[dict]] = mapped_column(JSON, default=list)
    audience: Mapped[str] = mapped_column(String(30), default="public", index=True)
    selected_user_ids: Mapped[list[str]] = mapped_column(JSON, default=list)
    audience_community_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    replies_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    archived: Mapped[bool] = mapped_column(Boolean, default=False)


class StoryMute(Base, IdMixin, TimestampMixin):
    __tablename__ = "story_mutes"
    user_id: Mapped[str] = mapped_column(String(36), index=True)
    muted_user_id: Mapped[str] = mapped_column(String(36), index=True)
