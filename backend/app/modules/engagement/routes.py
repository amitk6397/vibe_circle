from fastapi import APIRouter
from app.modules.engagement import controller

router = APIRouter(tags=["engagement"])
router.add_api_route("/gifts", controller.gifts, methods=["GET"])
router.add_api_route("/gifts/send", controller.send_gift, methods=["POST"], status_code=201)
router.add_api_route("/gifts/history", controller.gift_history, methods=["GET"])
router.add_api_route("/ratings", controller.submit_rating, methods=["POST"], status_code=201)
router.add_api_route("/users/{user_id}/reviews", controller.user_reviews, methods=["GET"])
