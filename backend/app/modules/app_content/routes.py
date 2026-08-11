from fastapi import APIRouter

from app.modules.app_content import controller
from app.modules.app_content.dtos import SupportArticleResponse


router = APIRouter(prefix="/app-content", tags=["app-content"])
router.add_api_route("/support", controller.support, methods=["GET"], response_model=list[SupportArticleResponse])
