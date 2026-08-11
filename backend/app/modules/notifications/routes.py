from fastapi import APIRouter

from app.modules.notifications import controller


router = APIRouter(prefix="/notifications", tags=["notifications"])
router.add_api_route("", controller.list_notifications, methods=["GET"])
router.add_api_route("/read-all", controller.mark_all_read, methods=["POST"])
router.add_api_route("/device-token", controller.register_device, methods=["POST"])
router.add_api_route("/device-token", controller.unregister_device, methods=["DELETE"])
router.add_api_route("/{notification_id}/read", controller.mark_read, methods=["POST"])
router.add_api_route("/{notification_id}", controller.remove, methods=["DELETE"])
