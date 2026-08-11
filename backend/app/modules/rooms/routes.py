from fastapi import APIRouter

from app.modules.rooms import controller


router = APIRouter(prefix="/rooms", tags=["rooms"])
router.add_api_route("", controller.list_rooms, methods=["GET"])
router.add_api_route("", controller.create, methods=["POST"], status_code=201)
router.add_api_route("/{room_id}", controller.details, methods=["GET"])
router.add_api_route("/{room_id}/join", controller.join, methods=["POST"])
router.add_api_route("/{room_id}/leave", controller.leave, methods=["POST"])
router.add_api_route("/{room_id}/participants", controller.participants, methods=["GET"])
router.add_api_route("/{room_id}/participants/{participant_id}", controller.participant_action, methods=["PATCH"])
router.add_api_route("/{room_id}/end", controller.end, methods=["POST"])

