from fastapi import APIRouter

from app.modules.admin import controller
from app.modules.admin.dtos import (
    CoinPackageCreate,
    CoinPackageUpdate,
    CommunityStatusUpdate,
    CreatorApplicationReview,
    PlatformSettingsUpdate,
    ReportReview,
    SubscriptionPlanCreate,
    SubscriptionPlanUpdate,
    SupportArticleCreate,
    SupportArticleUpdate,
    UserStatusUpdate,
    WithdrawalReview,
    VirtualGiftCreate,
    VirtualGiftUpdate,
)


router = APIRouter(prefix="/admin", tags=["admin"])


# ── Dashboard ─────────────────────────────────────────────────────────────────
router.add_api_route("/dashboard", controller.dashboard, methods=["GET"])

# ── Users ─────────────────────────────────────────────────────────────────────
router.add_api_route("/users", controller.list_users, methods=["GET"])
router.add_api_route("/users/{user_id}", controller.get_user, methods=["GET"])
router.add_api_route("/users/{user_id}", controller.update_user, methods=["PATCH"])
router.add_api_route("/users/{user_id}", controller.delete_user, methods=["DELETE"])

# ── Communities ───────────────────────────────────────────────────────────────
router.add_api_route("/communities", controller.list_communities, methods=["GET"])
router.add_api_route("/communities/{community_id}", controller.update_community, methods=["PATCH"])
router.add_api_route("/communities/{community_id}", controller.delete_community, methods=["DELETE"])
router.add_api_route("/communities/{community_id}/members", controller.list_community_members, methods=["GET"])

# ── Subscription Plans ────────────────────────────────────────────────────────
router.add_api_route("/subscription-plans", controller.list_subscription_plans, methods=["GET"])
router.add_api_route("/subscription-plans", controller.create_subscription_plan, methods=["POST"], status_code=201)
router.add_api_route("/subscription-plans/{plan_id}", controller.update_subscription_plan, methods=["PATCH"])
router.add_api_route("/subscription-plans/{plan_id}", controller.delete_subscription_plan, methods=["DELETE"])

# ── Coin Packages ─────────────────────────────────────────────────────────────
router.add_api_route("/coin-packages", controller.list_coin_packages, methods=["GET"])
router.add_api_route("/coin-packages", controller.create_coin_package, methods=["POST"], status_code=201)
router.add_api_route("/coin-packages/{package_id}", controller.update_coin_package, methods=["PATCH"])


# ── Special Offers ────────────────────────────────────────────────────────────
router.add_api_route("/offers", controller.list_offers, methods=["GET"])
router.add_api_route("/offers", controller.create_offer, methods=["POST"], status_code=201)
router.add_api_route("/offers/{offer_id}", controller.update_offer, methods=["PATCH"])
router.add_api_route("/offers/{offer_id}", controller.delete_offer, methods=["DELETE"])


# ── Withdrawals ───────────────────────────────────────────────────────────────
router.add_api_route("/withdrawals", controller.list_withdrawals, methods=["GET"])
router.add_api_route("/withdrawals/{withdrawal_id}/review", controller.review_withdrawal, methods=["PATCH"])

router.add_api_route("/creator-applications", controller.list_creator_applications, methods=["GET"])
router.add_api_route("/creator-applications/{application_id}", controller.review_creator_application, methods=["PATCH"])

router.add_api_route("/reports", controller.list_reports, methods=["GET"])
router.add_api_route("/reports/{report_id}", controller.review_report, methods=["PATCH"])
router.add_api_route("/audit-logs", controller.list_audit_logs, methods=["GET"])

# ── Transactions ──────────────────────────────────────────────────────────────
router.add_api_route("/transactions", controller.list_transactions, methods=["GET"])

# ── Support Articles ──────────────────────────────────────────────────────────
router.add_api_route("/support-articles", controller.list_support_articles, methods=["GET"])
router.add_api_route("/support-articles", controller.create_support_article, methods=["POST"], status_code=201)
router.add_api_route("/support-articles/{article_id}", controller.update_support_article, methods=["PATCH"])
router.add_api_route("/support-articles/{article_id}", controller.delete_support_article, methods=["DELETE"])

# ── Virtual Gifts ─────────────────────────────────────────────────────────────
router.add_api_route("/gifts", controller.list_virtual_gifts, methods=["GET"])
router.add_api_route("/gifts", controller.create_virtual_gift, methods=["POST"], status_code=201)
router.add_api_route("/gifts/{gift_id}", controller.update_virtual_gift, methods=["PATCH"])
router.add_api_route("/gifts/{gift_id}", controller.delete_virtual_gift, methods=["DELETE"])

# ── Platform Settings ─────────────────────────────────────────────────────────
router.add_api_route("/settings", controller.get_settings, methods=["GET"])
router.add_api_route("/settings", controller.update_settings, methods=["PATCH"])

# ── Revenue Summary ───────────────────────────────────────────────────────────
router.add_api_route("/revenue-summary", controller.revenue_summary, methods=["GET"])

# ── Referral Stats ────────────────────────────────────────────────────────────
router.add_api_route("/referral-stats", controller.referral_stats, methods=["GET"])
router.add_api_route("/top-referrers", controller.top_referrers, methods=["GET"])

