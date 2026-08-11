import { AppState, AppStateStatus } from 'react-native';
import { environment } from '../config/environment';
import { tokenStorage } from './tokenStorage';

export type RealtimeEvent = {
  event:
    | 'connected'
    | 'disconnected'
    | 'message'
    | 'typing'
    | 'presence'
    | 'read'
    | 'error'
    | 'pong'
    | 'coin_update'
    | 'low_balance_warning'
    | 'grace_period'
    | 'call_terminated';
  [key: string]: any;
};

type Listener = (event: RealtimeEvent) => void;

class RealtimeChannel {
  private socket: WebSocket | null = null;
  private listeners = new Set<Listener>();
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  private reconnectAttempt = 0;
  private manuallyClosed = false;

  constructor(private path: string) {}

  subscribe(listener: Listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private emit(event: RealtimeEvent) {
    this.listeners.forEach((listener) => listener(event));
  }

  async connect() {
    if (
      this.socket?.readyState === WebSocket.OPEN ||
      this.socket?.readyState === WebSocket.CONNECTING
    )
      return;
    this.manuallyClosed = false;
    const token = await tokenStorage.getAccess();
    if (!token) return this.emit({ event: 'error', message: 'Authentication is required.' });
    const base = environment.apiUrl.replace(/^http/, 'ws');
    this.socket = new WebSocket(`${base}${this.path}?token=${encodeURIComponent(token)}`);
    this.socket.onopen = () => {
      this.reconnectAttempt = 0;
      this.emit({ event: 'connected' });
      this.heartbeatTimer = setInterval(() => this.send({ event: 'ping' }), 20000);
    };
    this.socket.onmessage = ({ data }) => {
      try {
        this.emit(JSON.parse(data));
      } catch {
        this.emit({ event: 'error', message: 'Invalid realtime response.' });
      }
    };
    this.socket.onerror = () =>
      this.emit({ event: 'error', message: 'Realtime connection interrupted.' });
    this.socket.onclose = () => {
      this.stopHeartbeat();
      this.socket = null;
      this.emit({ event: 'disconnected' });
      if (!this.manuallyClosed) this.scheduleReconnect();
    };
  }

  private scheduleReconnect() {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    const delay = Math.min(30000, 1000 * 2 ** this.reconnectAttempt++) + Math.random() * 500;
    this.reconnectTimer = setTimeout(() => void this.connect(), delay);
  }

  private stopHeartbeat() {
    if (this.heartbeatTimer) clearInterval(this.heartbeatTimer);
    this.heartbeatTimer = null;
  }

  send(payload: Record<string, unknown>) {
    if (this.socket?.readyState !== WebSocket.OPEN) return false;
    this.socket.send(JSON.stringify(payload));
    return true;
  }

  reconnect() {
    if (this.socket?.readyState === WebSocket.OPEN) return;
    void this.connect();
  }

  close() {
    this.manuallyClosed = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.stopHeartbeat();
    this.socket?.close();
    this.socket = null;
  }
}

class RealtimeService {
  private channels = new Map<string, RealtimeChannel>();

  constructor() {
    AppState.addEventListener('change', (state: AppStateStatus) => {
      if (state === 'active') this.channels.forEach((channel) => channel.reconnect());
    });
  }

  private get(key: string, path: string) {
    if (!this.channels.has(key)) this.channels.set(key, new RealtimeChannel(path));
    return this.channels.get(key)!;
  }

  privateChannel(id: string) {
    return this.get(`private:${id}`, `/chat/ws/${id}`);
  }

  communityChannel(id: string) {
    return this.get(`community:${id}`, `/communities/ws/${id}`);
  }

  /** Call coin WebSocket — connects to /calls/ws/{callId} for real-time deduction events */
  callChannel(callId: string) {
    return this.get(`call:${callId}`, `/calls/ws/${callId}`);
  }

  closeCallChannel(callId: string) {
    const key = `call:${callId}`;
    const channel = this.channels.get(key);
    channel?.close();
    this.channels.delete(key);
  }
}

export const realtimeService = new RealtimeService();
