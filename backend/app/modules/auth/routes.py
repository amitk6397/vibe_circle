from fastapi import APIRouter

from app.modules.auth import controller
from app.modules.auth.dtos import TokenPair


router = APIRouter(prefix="/auth", tags=["auth"])
router.add_api_route("/register", controller.register, methods=["POST"], response_model=TokenPair, status_code=201)
router.add_api_route("/login", controller.login, methods=["POST"], response_model=TokenPair)
router.add_api_route("/refresh", controller.refresh, methods=["POST"], response_model=TokenPair)
router.add_api_route("/logout", controller.logout, methods=["POST"])
router.add_api_route("/logout-all", controller.logout_all, methods=["POST"])
router.add_api_route("/forgot-password", controller.forgot_password, methods=["POST"])
router.add_api_route("/request-verification", controller.request_verification, methods=["POST"])
router.add_api_route("/verify-email", controller.verify_email, methods=["POST"])
router.add_api_route("/reset-password", controller.reset_password, methods=["POST"])
router.add_api_route("/account", controller.delete_account, methods=["DELETE"])
router.add_api_route("/referral-info", controller.get_referral_info, methods=["GET"])

