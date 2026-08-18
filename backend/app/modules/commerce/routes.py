from fastapi import APIRouter

from app.modules.commerce import controller

subscription_router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])
subscription_router.add_api_route("/plans", controller.plans, methods=["GET"])
subscription_router.add_api_route("/active", controller.active_subscription, methods=["GET"])
subscription_router.add_api_route("/history", controller.subscription_history, methods=["GET"])
subscription_router.add_api_route("/purchase", controller.purchase_subscription, methods=["POST"], status_code=201)
subscription_router.add_api_route("/cancel-renewal", controller.cancel_subscription, methods=["POST"])

wallet_router = APIRouter(prefix="/wallet", tags=["wallet"])
wallet_router.add_api_route("", controller.wallet, methods=["GET"])
wallet_router.add_api_route("/coin-packages", controller.coin_packages, methods=["GET"])
wallet_router.add_api_route("/offers", controller.list_active_offers, methods=["GET"])
wallet_router.add_api_route("/pricing", controller.pricing_config, methods=["GET"])
wallet_router.add_api_route("/buy-coins", controller.buy_coins, methods=["POST"], status_code=201)
wallet_router.add_api_route("/transactions", controller.transactions, methods=["GET"])
wallet_router.add_api_route("/dashboard", controller.wallet_dashboard, methods=["GET"])
wallet_router.add_api_route("/claim-daily-reward", controller.claim_daily_reward, methods=["POST"])
wallet_router.add_api_route("/daily-reward-status", controller.daily_reward_status, methods=["GET"])
