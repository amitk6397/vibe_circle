from fastapi import APIRouter

from app.modules.auth.routes import router as auth_router
from app.modules.app_content.routes import router as app_content_router
from app.modules.chat.routes import router as chat_router
from app.modules.calls.routes import router as calls_router
from app.modules.calls.ws_routes import ws_router as calls_ws_router
from app.modules.communities.routes import router as communities_router
from app.modules.commerce.routes import subscription_router, wallet_router
from app.modules.creators.routes import router as creators_router
from app.modules.engagement.routes import router as engagement_router
from app.modules.discovery.routes import router as discovery_router
from app.modules.feed.routes import router as feed_router
from app.modules.matching.routes import router as matching_router
from app.modules.moderation.routes import router as moderation_router
from app.modules.notifications.routes import router as notifications_router
from app.modules.uploads.routes import router as uploads_router
from app.modules.users.routes import router as users_router
from app.modules.admin.routes import router as admin_router
from app.modules.livestream.routes import router as livestream_router


api_router = APIRouter()
for router in [
    app_content_router, auth_router, users_router, discovery_router, matching_router, chat_router, calls_router,
    calls_ws_router,
    communities_router, feed_router, subscription_router, wallet_router, creators_router, engagement_router, notifications_router,
    moderation_router, uploads_router, admin_router, livestream_router,
]:
    api_router.include_router(router)
