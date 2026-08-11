from fastapi import APIRouter

from app.modules.users import controller
from app.modules.users.dtos import PrivateUser, PublicUser


router = APIRouter(prefix="/users", tags=["users"])
router.add_api_route("/me", controller.me, methods=["GET"], response_model=PrivateUser)
router.add_api_route("/me", controller.patch_profile, methods=["PATCH"], response_model=PrivateUser)
router.add_api_route("/me/preferences", controller.patch_preferences, methods=["PATCH"], response_model=PrivateUser)
router.add_api_route("/me/notification-preferences", controller.patch_notifications, methods=["PATCH"], response_model=PrivateUser)
router.add_api_route("/me/availability", controller.set_availability, methods=["PATCH"], response_model=PrivateUser)
router.add_api_route("/me/availability", controller.clear_availability, methods=["DELETE"])
router.add_api_route("/me/export", controller.export_data, methods=["GET"])
router.add_api_route("/me/activity", controller.activity, methods=["GET"])
router.add_api_route("/connections", controller.list_connections, methods=["GET"])
router.add_api_route("/connections", controller.request_connection, methods=["POST"], status_code=201)
router.add_api_route("/connections/{connection_id}", controller.connection_action, methods=["PATCH"])
router.add_api_route("/connections/{connection_id}", controller.remove_connection, methods=["DELETE"])
router.add_api_route("/{user_id}", controller.public_profile, methods=["GET"], response_model=PublicUser)
