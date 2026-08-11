import { apiClient } from '../../../services/apiClient';
import { AgoraCredentials, CallSession, CallType } from '../models/CallSession';

export const callApi = {
  config: () => apiClient.get<{ durationOptions: number[] }>('/calls/config'),
  history: (before?: string) =>
    apiClient.get<CallSession[]>('/calls/history', { params: { before } }),
  start: (conversationId: string, callType: CallType) =>
    apiClient.post<CallSession>('/calls', {
      conversation_id: conversationId,
      call_type: callType,
    }),
  requestPaid: (recipientId: string, callType: CallType, durationMinutes: number) =>
    apiClient.post<CallSession>('/calls', {
      recipient_id: recipientId,
      call_type: callType,
      duration_minutes: durationMinutes,
    }),
  get: (callId: string) => apiClient.get<CallSession>(`/calls/${callId}`),
  token: (callId: string) => apiClient.post<AgoraCredentials>(`/calls/${callId}/token`),
  join: (callId: string) => apiClient.post<CallSession>(`/calls/${callId}/join`),
  action: (callId: string, action: 'accept' | 'reject' | 'end') =>
    apiClient.post<CallSession>(`/calls/${callId}/${action}`),
  extend: (callId: string, durationMinutes: number) =>
    apiClient.post<CallSession>(`/calls/${callId}/extend`, { duration_minutes: durationMinutes }),
};
