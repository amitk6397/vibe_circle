from fastapi import APIRouter

from app.modules.creators import controller

router = APIRouter(prefix="/earnings", tags=["earnings"])
router.add_api_route("/profile/me", controller.my_profile, methods=["GET"])
router.add_api_route("/profile/{user_id}", controller.public_profile, methods=["GET"])
router.add_api_route("/dashboard", controller.dashboard, methods=["GET"])
router.add_api_route("/history", controller.earnings, methods=["GET"])
router.add_api_route("/withdrawals", controller.withdrawals, methods=["GET"])
router.add_api_route("/withdrawals", controller.request_withdrawal, methods=["POST"], status_code=201)
