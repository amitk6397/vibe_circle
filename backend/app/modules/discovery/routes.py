from fastapi import APIRouter

from app.modules.discovery import controller
from app.modules.users.dtos import PublicUser


router = APIRouter(prefix="/discovery", tags=["discovery"])
router.add_api_route("/search", controller.search, methods=["GET"])
router.add_api_route("/users", controller.discover_users, methods=["GET"], response_model=list[PublicUser])
router.add_api_route("/recommended-people", controller.recommended_people, methods=["GET"], response_model=list[PublicUser])
router.add_api_route("/communities", controller.discover_communities, methods=["GET"])
router.add_api_route("/posts", controller.discover_posts, methods=["GET"])
