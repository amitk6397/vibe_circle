"""FastAPI routes for Live Streaming."""
from fastapi import APIRouter

from app.modules.livestream import controller

router = APIRouter(prefix="/livestream", tags=["livestream"])

# Broadcaster endpoints
router.add_api_route("/start", controller.start_stream, methods=["POST"], status_code=201)
router.add_api_route("/{stream_id}/end", controller.end_stream, methods=["POST"])
router.add_api_route("/{stream_id}/leave", controller.leave_stream, methods=["POST"])

# Audience endpoints
router.add_api_route("/active", controller.list_active_streams, methods=["GET"])
router.add_api_route("/{stream_id}/join", controller.join_stream, methods=["POST"])
router.add_api_route("/{stream_id}/gift", controller.send_gift, methods=["POST"], status_code=201)

# Admin endpoints
router.add_api_route("/admin/streams", controller.admin_list_streams, methods=["GET"])
router.add_api_route("/admin/{stream_id}/force-end", controller.admin_force_end, methods=["POST"])
