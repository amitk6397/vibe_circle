export type CallType = 'audio' | 'video';
export type CallStatus = 'ringing' | 'accepted' | 'rejected' | 'ended' | 'missed';

export type AgoraCredentials = {
  appId: string;
  channel: string;
  userAccount: string;
  token: string;
  expiresAt: string;
  reservedMinutes?: number;
  pricePerMinute?: number;
  heldCoins?: number;
  chargedCoins?: number;
};

export type CallSession = {
  id: string;
  conversationId: string;
  callerId: string;
  recipientId: string;
  callType: CallType;
  status: CallStatus;
  answeredAt?: string | null;
  endedAt?: string | null;
  expiresAt: string;
  reservedMinutes?: number;
  pricePerMinute?: number;
  heldCoins?: number;
  chargedCoins?: number;
  heldCreditMinutes?: number;
  usedCreditMinutes?: number;
  callerJoinedAt?: string;
  recipientJoinedAt?: string;
  startedAt?: string;
  rtc?: AgoraCredentials;
};
