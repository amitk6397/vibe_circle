from fastapi import APIRouter

from app.modules.matching import controller


router = APIRouter(prefix="/matching", tags=["matching"])
router.add_api_route("/start", controller.start, methods=["POST"], status_code=201)
router.add_api_route("/status", controller.status, methods=["GET"])
router.add_api_route("/{match_id}/feedback", controller.feedback, methods=["POST"])
router.add_api_route("/{match_id}/{action}", controller.action, methods=["POST"])
