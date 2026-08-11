from sqlalchemy import select

from app.common.dependencies import DbSession
from app.modules.app_content.models import SupportArticle


def support(db: DbSession):
    return list(db.scalars(select(SupportArticle).where(SupportArticle.active.is_(True)).order_by(SupportArticle.position)))
