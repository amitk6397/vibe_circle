/**
 * useCallCoins — React hook for real-time call coin events.
 *
 * Connects to the backend call WebSocket (/calls/ws/{callId}) and exposes
 * live coin state, low balance warnings, and grace period info.
 *
 * Usage:
 *   const {
 *     balance, elapsedSeconds, reservedMinutes, pricePerMinute,
 *     isLowBalance, lowBalanceInfo,
 *     isGracePeriod, graceSeconds,
 *     isTerminated, terminatedReason,
 *     sendRecharge,
 *   } = useCallCoins(callId, { enabled: callIsActive });
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { realtimeService } from '../services/realtimeSocket';

// ─────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────

export type CallCoinState = {
  /** Current available balance (purchased + bonus coins) */
  balance: number;
  /** Seconds elapsed since the call started */
  elapsedSeconds: number;
  /** Total reserved minutes for this call */
  reservedMinutes: number;
  /** Coin cost per minute */
  pricePerMinute: number;
  /** True when balance < 1 minute of coins remain */
  isLowBalance: boolean;
  lowBalanceInfo: { balance: number; minutesLeft: number } | null;
  /** True when coins hit 0 and grace period countdown is active */
  isGracePeriod: boolean;
  /** Total grace period seconds as received from server */
  graceSeconds: number;
  /** True after grace period expires and call was auto-terminated */
  isTerminated: boolean;
  terminatedReason: string | null;
  /** Notify server that user recharged (resets grace timer) */
  sendRecharge: () => void;
  /** WebSocket connection status */
  connected: boolean;
};

// ─────────────────────────────────────────────
// Hook
// ─────────────────────────────────────────────

export function useCallCoins(
  callId: string | null,
  options: { enabled?: boolean } = {}
): CallCoinState {
  const { enabled = true } = options;

  const [balance, setBalance] = useState(0);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [reservedMinutes, setReservedMinutes] = useState(0);
  const [pricePerMinute, setPricePerMinute] = useState(0);
  const [isLowBalance, setIsLowBalance] = useState(false);
  const [lowBalanceInfo, setLowBalanceInfo] = useState<{ balance: number; minutesLeft: number } | null>(null);
  const [isGracePeriod, setIsGracePeriod] = useState(false);
  const [graceSeconds, setGraceSeconds] = useState(15);
  const [isTerminated, setIsTerminated] = useState(false);
  const [terminatedReason, setTerminatedReason] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);

  const channelRef = useRef<ReturnType<typeof realtimeService.callChannel> | null>(null);

  const sendRecharge = useCallback(() => {
    channelRef.current?.send({ event: 'recharge' });
  }, []);

  useEffect(() => {
    if (!callId || !enabled) return;

    const channel = realtimeService.callChannel(callId);
    channelRef.current = channel;

    const unsub = channel.subscribe((event) => {
      switch (event.event) {
        case 'connected':
          setConnected(true);
          break;

        case 'disconnected':
          setConnected(false);
          break;

        case 'coin_update':
          setBalance(event.balance ?? 0);
          setElapsedSeconds(event.elapsed_seconds ?? 0);
          setReservedMinutes(event.reserved_minutes ?? 0);
          setPricePerMinute(event.price_per_minute ?? 0);
          // Reset low balance state if balance recovered after recharge
          if (event.recharged && event.balance > 0) {
            setIsLowBalance(false);
            setLowBalanceInfo(null);
            setIsGracePeriod(false);
          }
          break;

        case 'low_balance_warning':
          setIsLowBalance(true);
          setLowBalanceInfo({
            balance: event.balance ?? 0,
            minutesLeft: event.minutes_left ?? 0,
          });
          break;

        case 'grace_period':
          setIsGracePeriod(true);
          setGraceSeconds(event.grace_seconds ?? 15);
          break;

        case 'call_terminated':
          setIsTerminated(true);
          setTerminatedReason(event.reason ?? 'grace_timeout');
          setIsGracePeriod(false);
          break;

        case 'error':
          // Non-fatal — just log; UI can show a toast
          console.warn('[useCallCoins] WebSocket error:', event.message);
          break;
      }
    });

    void channel.connect();

    return () => {
      unsub();
      // Do NOT close the channel on unmount if only the hook unmounts while the
      // call screen remounts — close it explicitly via realtimeService.closeCallChannel(callId)
      // at the call screen's cleanup (call ended / user hung up).
    };
  }, [callId, enabled]);

  return {
    balance,
    elapsedSeconds,
    reservedMinutes,
    pricePerMinute,
    isLowBalance,
    lowBalanceInfo,
    isGracePeriod,
    graceSeconds,
    isTerminated,
    terminatedReason,
    sendRecharge,
    connected,
  };
}
