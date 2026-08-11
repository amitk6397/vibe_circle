from fastapi import APIRouter

from app.modules.moderation import controller


router = APIRouter(prefix="/safety", tags=["safety"])
router.add_api_route("/blocks", controller.blocked, methods=["GET"])
router.add_api_route("/blocks", controller.block, methods=["POST"], status_code=201)
router.add_api_route("/blocks/{user_id}", controller.unblock, methods=["DELETE"])
router.add_api_route("/reports", controller.report, methods=["POST"], status_code=201)
router.add_api_route("/reports/me", controller.my_reports, methods=["GET"])
