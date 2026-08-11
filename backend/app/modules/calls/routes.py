from fastapi import APIRouter

from app.modules.calls import controller


router = APIRouter(prefix="/calls", tags=["calls"])
router.add_api_route("/config", controller.call_config, methods=["GET"])
router.add_api_route("/history", controller.call_history, methods=["GET"])
router.add_api_route("", controller.create_call, methods=["POST"], status_code=201)
router.add_api_route("/{call_id}", controller.get_call, methods=["GET"])
router.add_api_route("/{call_id}/token", controller.rtc_token, methods=["POST"])
router.add_api_route("/{call_id}/join", controller.join_call, methods=["POST"])
router.add_api_route("/{call_id}/extend", controller.extend_call, methods=["POST"])
router.add_api_route("/{call_id}/{action}", controller.call_action, methods=["POST"])
