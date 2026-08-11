"""Call WebSocket — Real-time coin deduction, low balance warning, and grace period.

Connect: ws://<host>/api/v1/calls/ws/{call_id}?token=<access_token>

Events emitted by server → client:
  coin_update        {"event": "coin_update", "balance": int, "elapsed_seconds": int, "reserved_minutes": int}
  low_balance_warning{"event": "low_balance_warning", "balance": int, "minutes_left": float}
  grace_period       {"event": "grace_period", "grace_seconds": int, "message": str}
  call_terminated    {"event": "call_terminated", "reason": "grace_timeout" | "insufficient_funds"}
  error              {"event": "error", "message": str}

Events sent by client → server:
  recharge           {"event": "recharge"} — client signals a recharge was completed; resets grace timer
  ping               {"event": "ping"}
"""
import asyncio
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.config import settings
from app.core.database import SessionLocal
from app.core.security import decode_access_token
from app.modules.calls import service as call_service
from app.modules.calls.models import CallSession
from app.modules.commerce import service as commerce_service


ws_router = APIRouter(prefix="/calls", tags=["calls-ws"])


class CallCoinState:
    """Tracks the real-time deduction state for one call connection."""

    NORMAL = "normal"
    LOW_BALANCE = "low_balance"
    GRACE = "grace"
    TERMINATED = "terminated"

    def __init__(self):
        self.state = self.NORMAL
        self.grace_start: datetime | None = None


async def _get_wallet_balance(user_id: str) -> int:
    """Return current combined coin balance for a user."""
    with SessionLocal() as db:
        wallet = commerce_service.wallet_for(db, user_id)
        db.commit()
        return wallet.purchased_coins + wallet.bonus_coins


async def _deduct_minute(call_id: str, caller_id: str, price_per_minute: int) -> bool:
    """
    Deduct one minute of coins from the caller's held balance.
    Returns True if successful, False if insufficient balance.
    """
    try:
        with SessionLocal() as db:
            item = db.get(CallSession, call_id)
            if not item or item.status != "accepted":
                return False
            wallet = commerce_service.wallet_for(db, caller_id)
            if wallet.purchased_coins + wallet.bonus_coins + wallet.held_coins < price_per_minute:
                return False
            # Deduct from held balance inline (reduce held, charge from sources)
            charge = min(item.held_coins, price_per_minute)
            item.held_coins -= charge
            item.charged_coins += charge
            db.commit()
            return True
    except Exception:
        return False


async def _force_end_call(call_id: str, user_id: str, end_reason: str) -> None:
    """Force-end the call due to grace period timeout or insufficient funds."""
    try:
        from app.modules.calls.controller import call_action as _call_action
        from app.common.dependencies import CurrentUser
        with SessionLocal() as db:
            item = db.get(CallSession, call_id)
            if item and item.status == "accepted":
                item.end_reason = end_reason
                db.commit()
            # Reuse the call_action settle logic via direct service call
            from app.modules.calls.service import call_for
            from datetime import UTC, datetime, timedelta
            from app.modules.creators import service as creator_service
            now = datetime.now(UTC)
            item = db.get(CallSession, call_id)
            if item and item.status == "accepted":
                item.status = "ended"
                item.ended_at = now
                item.end_reason = end_reason
                if item.held_coins:
                    started = item.started_at.replace(tzinfo=UTC) if item.started_at and not item.started_at.tzinfo else item.started_at
                    elapsed_seconds = max(0, int((now - started).total_seconds())) if started else 0
                    billed_minutes = min(item.reserved_minutes, max(1, (elapsed_seconds + 59) // 60)) if started else 0
                    item.charged_coins = min(item.held_coins, billed_minutes * item.price_per_minute)
                    commerce_service.settle_hold(
                        db, item.caller_id, item.held_coins,
                        item.held_bonus_coins, item.held_purchased_coins,
                        item.charged_coins, "call", item.id,
                    )
                    creator = creator_service.profile_for(db, item.recipient_id, False)
                    if creator and item.charged_coins:
                        from app.core.config import settings as cfg
                        commission = item.charged_coins * cfg.platform_commission_percent // 100
                        creator_service.credit_earning(
                            db, creator.user_id, item.charged_coins, commission,
                            "call", item.id, now + timedelta(days=cfg.creator_settlement_days),
                        )
                        creator.completed_sessions += 1
                db.commit()
    except Exception:
        pass


@ws_router.websocket("/ws/{call_id}")
async def call_ws(socket: WebSocket, call_id: str, token: str):
    """
    WebSocket endpoint for real-time call coin management.
    Handles per-minute deduction, low-balance warning, and grace period.
    """
    # --- Authenticate ---
    try:
        user_id = decode_access_token(token)
    except Exception:
        await socket.close(code=4401)
        return

    # --- Validate call access ---
    try:
        with SessionLocal() as db:
            item = call_service.call_for(db, call_id, user_id)
            if item.status not in {"ringing", "accepted"}:
                await socket.close(code=4409)
                return
            caller_id = item.caller_id
            price_per_minute = item.price_per_minute
            reserved_minutes = item.reserved_minutes
    except Exception:
        await socket.close(code=4404)
        return

    await socket.accept()

    coin_state = CallCoinState()
    elapsed_seconds = 0
    deduction_task: asyncio.Task | None = None

    async def deduction_loop():
        """Background loop: deducts coins every 60s and monitors balance."""
        nonlocal elapsed_seconds
        while True:
            await asyncio.sleep(1)
            elapsed_seconds += 1

            # Only deduct after call has started (both joined)
            with SessionLocal() as db:
                item = db.get(CallSession, call_id)
                if not item or item.status != "accepted":
                    break
                if not item.started_at:
                    continue  # call not yet fully connected

            # Per-minute deduction
            if elapsed_seconds > 0 and elapsed_seconds % 60 == 0:
                success = await _deduct_minute(call_id, caller_id, price_per_minute)
                if not success and price_per_minute > 0:
                    # Immediate insufficient funds
                    await socket.send_json({
                        "event": "grace_period",
                        "grace_seconds": settings.call_grace_period_seconds,
                        "message": "Your coins have run out. Recharge now to continue the call.",
                    })
                    coin_state.state = CallCoinState.GRACE
                    coin_state.grace_start = datetime.now(UTC)

            # Get current balance
            balance = await _get_wallet_balance(caller_id)
            minutes_left = balance / price_per_minute if price_per_minute > 0 else 999

            # Low balance warning — exactly 1 minute left
            if coin_state.state == CallCoinState.NORMAL and 0 < minutes_left <= 1:
                coin_state.state = CallCoinState.LOW_BALANCE
                await socket.send_json({
                    "event": "low_balance_warning",
                    "balance": balance,
                    "minutes_left": round(minutes_left, 2),
                    "message": "Less than 1 minute of coins remaining! Recharge to avoid disconnection.",
                })

            # Periodic balance update
            if elapsed_seconds % 10 == 0:
                await socket.send_json({
                    "event": "coin_update",
                    "balance": balance,
                    "elapsed_seconds": elapsed_seconds,
                    "reserved_minutes": reserved_minutes,
                    "price_per_minute": price_per_minute,
                })

            # Grace period timeout check
            if coin_state.state == CallCoinState.GRACE and coin_state.grace_start:
                grace_elapsed = (datetime.now(UTC) - coin_state.grace_start).total_seconds()
                if grace_elapsed >= settings.call_grace_period_seconds:
                    coin_state.state = CallCoinState.TERMINATED
                    await socket.send_json({
                        "event": "call_terminated",
                        "reason": "grace_timeout",
                        "message": "Call ended due to insufficient coins.",
                    })
                    await _force_end_call(call_id, user_id, "grace_timeout")
                    break

    try:
        deduction_task = asyncio.create_task(deduction_loop())

        while True:
            payload = await socket.receive_json()
            event = payload.get("event")

            if event == "ping":
                await socket.send_json({"event": "pong", "at": datetime.now(UTC).isoformat()})

            elif event == "recharge":
                # Client signals recharge was done — re-check balance & reset grace
                balance = await _get_wallet_balance(caller_id)
                minutes_left = balance / price_per_minute if price_per_minute > 0 else 999
                if minutes_left > 0:
                    coin_state.state = CallCoinState.NORMAL
                    coin_state.grace_start = None
                    await socket.send_json({
                        "event": "coin_update",
                        "balance": balance,
                        "elapsed_seconds": elapsed_seconds,
                        "reserved_minutes": reserved_minutes,
                        "price_per_minute": price_per_minute,
                        "recharged": True,
                    })

    except WebSocketDisconnect:
        pass
    except Exception as exc:
        try:
            await socket.send_json({"event": "error", "message": str(exc)})
        except Exception:
            pass
    finally:
        if deduction_task and not deduction_task.done():
            deduction_task.cancel()
