from fastapi import APIRouter

from app.modules.feed import controller
from app.modules.feed import tip_controller
from app.modules.feed import boost_controller
from app.modules.feed import bounty_controller


router = APIRouter(prefix="/feed", tags=["feed"])
router.add_api_route("/posts", controller.list_posts, methods=["GET"])
router.add_api_route("/posts", controller.create, methods=["POST"], status_code=201)
router.add_api_route("/posts/{post_id}", controller.details, methods=["GET"])
router.add_api_route("/posts/{post_id}/unlock", controller.unlock_post, methods=["POST"])
router.add_api_route("/posts/{post_id}", controller.update, methods=["PATCH"])
router.add_api_route("/posts/{post_id}", controller.delete, methods=["DELETE"])
router.add_api_route("/posts/{post_id}/comments", controller.comments, methods=["GET"])
router.add_api_route("/posts/{post_id}/comments", controller.comment, methods=["POST"], status_code=201)
router.add_api_route("/comments/{comment_id}/like", controller.toggle_comment_like, methods=["POST"])
router.add_api_route("/comments/{comment_id}", controller.delete_comment, methods=["DELETE"])
router.add_api_route("/posts/{post_id}/like", controller.toggle_like, methods=["POST"])
router.add_api_route("/posts/{post_id}/save", controller.toggle_save, methods=["POST"])
router.add_api_route("/posts/{post_id}/vote", controller.vote, methods=["POST"])
router.add_api_route("/posts/{post_id}/share", controller.share_post, methods=["POST"])

# Tipping, Boosting, and Bounty routes
router.add_api_route("/posts/{post_id}/tip", tip_controller.tip_post, methods=["POST"])
router.add_api_route("/posts/{post_id}/tips", tip_controller.get_post_tips, methods=["GET"])
router.add_api_route("/posts/{post_id}/boost", boost_controller.boost_post, methods=["POST"])
router.add_api_route("/posts/{post_id}/award-bounty", bounty_controller.award_bounty, methods=["POST"])
router.add_api_route("/posts/{post_id}/bounty", bounty_controller.get_bounty_status, methods=["GET"])

router.add_api_route("/stories", controller.stories, methods=["GET"])
router.add_api_route("/stories", controller.create_story, methods=["POST"], status_code=201)
router.add_api_route("/stories/archive", controller.story_archive, methods=["GET"])
router.add_api_route("/stories/{story_id}/view", controller.view_story, methods=["POST"])
router.add_api_route("/stories/{story_id}/reactions", controller.react_story, methods=["POST"])
router.add_api_route("/stories/{story_id}/replies", controller.reply_story, methods=["POST"])
router.add_api_route("/stories/{story_id}/mute", controller.mute_story_author, methods=["POST"])
router.add_api_route("/stories/{story_id}/archive", controller.archive_story, methods=["POST"])
router.add_api_route("/stories/{story_id}", controller.delete_story, methods=["DELETE"])
