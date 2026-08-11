import { LocalAttachment } from '../types';
import {
  ConversationLimit,
  MessageRequest,
} from '../features/conversation/models/ConversationAccess';
import { SubscriptionPlan, UserSubscription } from '../features/subscription/models/Subscription';
import {
  CoinPackage,
  UserPerformanceProfile,
  UserWallet,
  WalletTransaction,
} from '../features/commerce/models/Commerce';
import { apiClient } from './apiClient';
import { tokenStorage } from './tokenStorage';

export type ApiUser = {
  id: string;
  email?: string;
  name: string;
  age: number;
  username: string | null;
  bio: string;
  city: string;
  avatar_url: string | null;
  languages: string[];
  interests: string[];
  conversation_topics?: string[];
  date_of_birth?: string | null;
  gender?: string | null;
  preferred_language?: string | null;
  performance_rating?: number;
  review_count?: number;
  completed_sessions?: number;
  performance_tier?: 'top_performer' | 'recommended' | 'new';
  purposes: string[];
  is_online: boolean;
  vibe_status?: string | null;
  vibe_expires_at?: string | null;
  notification_preferences?: Record<string, boolean>;
};

type TokenPair = { access_token: string; refresh_token: string; user: ApiUser };

const storeSession = async ({ access_token, refresh_token, user }: TokenPair) => {
  await tokenStorage.save(access_token, refresh_token);
  return user;
};

export const authApi = {
  async login(email: string, password: string) {
    const { data } = await apiClient.post<TokenPair>('/auth/login', {
      email,
      password,
      device_name: 'Expo mobile',
    });
    return storeSession(data);
  },
  async register(payload: { name: string; age: number; email: string; password: string; avatar_url?: string | null; referral_code?: string }) {
    const { data } = await apiClient.post<TokenPair>('/auth/register', payload);
    return storeSession(data);
  },
  async restore() {
    if (!(await tokenStorage.getAccess())) return null;
    const { data } = await apiClient.get<ApiUser>('/users/me');
    return data;
  },
  async logout() {
    const refresh_token = await tokenStorage.getRefresh();
    try {
      if (refresh_token) await apiClient.post('/auth/logout', { refresh_token });
    } finally {
      await tokenStorage.clear();
    }
  },
  forgotPassword: (email: string) => apiClient.post('/auth/forgot-password', { email }),
  requestVerification: () =>
    apiClient.post<{ message: string; otp: string; expires_in: number }>(
      '/auth/request-verification',
    ),
  verifyEmail: (otp: string) => apiClient.post('/auth/verify-email', { token: otp }),
  getReferralInfo: () => apiClient.get<{ referralCode: string; totalReferrals: number; totalEarned: number; rewardPerReferral: number; inviteeBonus: number }>('/auth/referral-info'),
};

export const appContentApi = {
  support: () => apiClient.get<any[]>('/app-content/support'),
};

export const usersApi = {
  publicProfile: (id: string) => apiClient.get<ApiUser>(`/users/${id}`),
  updateProfile: (payload: Record<string, unknown>) =>
    apiClient.patch<ApiUser>('/users/me', payload),
  updatePreferences: (payload: Record<string, unknown>) =>
    apiClient.patch<ApiUser>('/users/me/preferences', payload),
  updatePrivacy: (payload: Record<string, unknown>) =>
    apiClient.patch('/users/me/privacy', payload),
  updateNotificationPreferences: (payload: Record<string, boolean>) =>
    apiClient.patch('/users/me/notification-preferences', payload),
  setAvailability: (status: string, durationMinutes: number) =>
    apiClient.patch<ApiUser>('/users/me/availability', {
      status,
      duration_minutes: durationMinutes,
    }),
  clearAvailability: () => apiClient.delete('/users/me/availability'),
  connections: () => apiClient.get<any[]>('/users/connections'),
  requestConnection: (userId: string) => apiClient.post('/users/connections', { user_id: userId }),
  connectionAction: (connectionId: string, action: 'accept' | 'reject') =>
    apiClient.patch(`/users/connections/${connectionId}`, { action }),
  removeConnection: (connectionId: string) =>
    apiClient.delete(`/users/connections/${connectionId}`),
  activity: () => apiClient.get<any>('/users/me/activity'),
};

export const discoveryApi = {
  users: (params?: {
    purpose?: string;
    q?: string;
    min_age?: number;
    max_age?: number;
    online_only?: boolean;
    gender?: string;
    city?: string;
    languages?: string;
  }) => apiClient.get<ApiUser[]>('/discovery/users', { params }),
  communities: () => apiClient.get<any[]>('/communities'),
  posts: () => apiClient.get<any[]>('/feed/posts'),
  search: (q: string) => apiClient.get('/discovery/search', { params: { q } }),
  recommendedPeople: (params?: { page?: number; limit?: number }) =>
    apiClient.get<ApiUser[]>('/discovery/recommended-people', { params }),
};

export const contentApi = {
  details: (postId: string) => apiClient.get<any>(`/feed/posts/${postId}`),
  posts: (communityId?: string, before?: string) =>
    apiClient.get<any[]>('/feed/posts', {
      params: { community_id: communityId, before },
    }),
  createPost: (payload: Record<string, unknown>) => apiClient.post('/feed/posts', payload),
  updatePost: (postId: string, body: string) => apiClient.patch(`/feed/posts/${postId}`, { body }),
  deletePost: (postId: string) => apiClient.delete(`/feed/posts/${postId}`),
  addComment: (postId: string, body: string, parentId?: string) =>
    apiClient.post(`/feed/posts/${postId}/comments`, { body, parent_id: parentId }),
  toggleCommentLike: (commentId: string) => apiClient.post(`/feed/comments/${commentId}/like`),
  deleteComment: (commentId: string) => apiClient.delete(`/feed/comments/${commentId}`),
  vote: (postId: string, option: string) =>
    apiClient.post(`/feed/posts/${postId}/vote`, { option }),
  comments: (postId: string) => apiClient.get<any[]>(`/feed/posts/${postId}/comments`),
  toggleLike: (postId: string) => apiClient.post(`/feed/posts/${postId}/like`),
  toggleSave: (postId: string) => apiClient.post(`/feed/posts/${postId}/save`),
  unlockPost: (postId: string) => apiClient.post<any>(`/feed/posts/${postId}/unlock`),
  createCommunity: (payload: Record<string, unknown>) => apiClient.post('/communities', payload),
  joinCommunity: (id: string) => apiClient.post(`/communities/${id}/join`),
  leaveCommunity: (id: string) => apiClient.post(`/communities/${id}/leave`),
  deleteCommunity: (id: string) => apiClient.delete(`/communities/${id}`),
  shareCommunity: (id: string, userIds: string[]) =>
    apiClient.post(`/communities/${id}/share`, { user_ids: userIds }),
  sharePost: (postId: string, userIds: string[]) =>
    apiClient.post(`/feed/posts/${postId}/share`, { user_ids: userIds }),
  circleInvites: () => apiClient.get<any[]>('/communities/invitations/me'),
  inviteToCircle: (communityId: string, userId: string) =>
    apiClient.post(`/communities/${communityId}/invite`, { user_id: userId }),
  respondCircleInvite: (inviteId: string, action: 'accept' | 'reject') =>
    apiClient.patch(`/communities/invitations/${inviteId}`, { action }),
  communityJoinRequests: (id: string) => apiClient.get<any[]>(`/communities/${id}/join-requests`),
  respondCommunityJoinRequest: (communityId: string, requestId: string, action: string) =>
    apiClient.patch(`/communities/${communityId}/join-requests/${requestId}`, { action }),
  sendCommunityMessage: (id: string, payload: Record<string, unknown>) =>
    apiClient.post(`/communities/${id}/messages`, payload),
  communitySubscriptionStatus: (communityId: string) =>
    apiClient.get<any>(`/communities/${communityId}/subscription-status`),
  tipPost: (postId: string, amount: number, message?: string) =>
    apiClient.post<any>(`/feed/posts/${postId}/tip`, { amount, message }),
  getPostTips: (postId: string) =>
    apiClient.get<any[]>(`/feed/posts/${postId}/tips`),
  boostPost: (postId: string) =>
    apiClient.post<any>(`/feed/posts/${postId}/boost`),
  awardBounty: (postId: string, commentId: string) =>
    apiClient.post<any>(`/feed/posts/${postId}/award-bounty`, { comment_id: commentId }),
  getBountyStatus: (postId: string) =>
    apiClient.get<any>(`/feed/posts/${postId}/bounty`),
};

export const storyApi = {
  list: () => apiClient.get<any[]>('/feed/stories'),
  create: (mediaUrl: string, audience = 'public') =>
    apiClient.post<any>('/feed/stories', { media_url: mediaUrl, audience }),
  view: (storyId: string) => apiClient.post(`/feed/stories/${storyId}/view`),
  react: (storyId: string, emoji: string) =>
    apiClient.post(`/feed/stories/${storyId}/reactions`, { emoji }),
  reply: (storyId: string, text: string) =>
    apiClient.post(`/feed/stories/${storyId}/replies`, { text }),
  remove: (storyId: string) => apiClient.delete(`/feed/stories/${storyId}`),
  mute: (storyId: string) => apiClient.post(`/feed/stories/${storyId}/mute`),
  archive: (storyId: string) => apiClient.post(`/feed/stories/${storyId}/archive`),
  archiveList: () => apiClient.get<any[]>('/feed/stories/archive'),
};

export const chatApi = {
  createConversation: (userId: string) =>
    apiClient.post<any>('/chat/conversations', { member_id: userId }),
  conversations: (folder: 'active' | 'archived' | 'paid' = 'active') =>
    apiClient.get<any[]>('/chat/conversations', { params: { folder } }),
  messages: (conversationId: string, limit = 100, before?: string) =>
    apiClient.get<any[]>(`/chat/conversations/${conversationId}/messages`, {
      params: { limit, before },
    }),
  communityMessages: (communityId: string, limit = 100) =>
    apiClient.get<any[]>(`/communities/${communityId}/messages`, { params: { limit } }),
  markRead: (conversationId: string) =>
    apiClient.post(`/chat/conversations/${conversationId}/read`),
  send: (conversationId: string, payload: Record<string, unknown>) =>
    apiClient.post(`/chat/conversations/${conversationId}/messages`, payload),
  react: (messageId: string, emoji: string) =>
    apiClient.post(`/chat/messages/${messageId}/reactions`, { emoji }),
  deleteMessage: (messageId: string) => apiClient.delete(`/chat/messages/${messageId}`),
  limits: (conversationId?: string) =>
    apiClient.get<ConversationLimit>('/chat/limits', {
      params: { conversation_id: conversationId },
    }),
  messageRequests: () => apiClient.get<MessageRequest[]>('/chat/message-requests'),
  sendMessageRequest: (recipientId: string, introduction: string, durationMinutes: number) =>
    apiClient.post<MessageRequest>('/chat/message-requests', {
      recipient_id: recipientId,
      introduction,
      duration_minutes: durationMinutes,
    }),
  messageRequestAction: (requestId: string, action: 'accept' | 'reject' | 'block') =>
    apiClient.patch<MessageRequest>(`/chat/message-requests/${requestId}`, { action }),
  unlockConversation: (conversationId: string) =>
    apiClient.post<ConversationLimit>(`/chat/conversations/${conversationId}/unlock`),
  deductChatMinute: (conversationId: string) =>
    apiClient.post<{ coinsDeducted: number; currentBalance: number; message: string }>(
      `/chat/conversations/${conversationId}/deduct-minute`,
    ),
};

export const subscriptionApi = {
  plans: () => apiClient.get<SubscriptionPlan[]>('/subscriptions/plans'),
  active: () => apiClient.get<UserSubscription | null>('/subscriptions/active'),
  history: (before?: string) =>
    apiClient.get<UserSubscription[]>('/subscriptions/history', { params: { before } }),
  purchase: (planId: string, purchaseToken: string) =>
    apiClient.post<UserSubscription>('/subscriptions/purchase', {
      plan_id: planId,
      purchase_token: purchaseToken,
    }),
  cancelRenewal: () => apiClient.post('/subscriptions/cancel-renewal'),
};

export const walletApi = {
  get: () => apiClient.get<UserWallet>('/wallet'),
  packages: () => apiClient.get<CoinPackage[]>('/wallet/coin-packages'),
  transactions: (before?: string) =>
    apiClient.get<WalletTransaction[]>('/wallet/transactions', { params: { before } }),
  buyCoins: (packageId: string, purchaseToken: string) =>
    apiClient.post<UserWallet>('/wallet/buy-coins', {
      package_id: packageId,
      purchase_token: purchaseToken,
    }),
  pricing: () => apiClient.get<any>('/wallet/pricing'),
  dashboard: (period: '7d' | '30d' | '90d' | 'all') =>
    apiClient.get<any>('/wallet/dashboard', { params: { period } }),
  claimDailyReward: () => apiClient.post<any>('/wallet/claim-daily-reward'),
  dailyRewardStatus: () => apiClient.get<any>('/wallet/daily-reward-status'),
};

export const earningsApi = {
  profile: (userId: string) => apiClient.get<UserPerformanceProfile>(`/earnings/profile/${userId}`),
  myProfile: () => apiClient.get<UserPerformanceProfile>('/earnings/profile/me'),
  dashboard: () => apiClient.get('/earnings/dashboard'),
  history: (before?: string) => apiClient.get('/earnings/history', { params: { before } }),
  withdrawals: () => apiClient.get('/earnings/withdrawals'),
  requestWithdrawal: (amount: number, payoutReference: string) =>
    apiClient.post('/earnings/withdrawals', { amount, payout_account_reference: payoutReference }),
};

export const engagementApi = {
  gifts: () => apiClient.get<any[]>('/gifts'),
  sendGift: (payload: {
    gift_id: string;
    recipient_id: string;
    target_type: string;
    target_id: string;
  }) => apiClient.post('/gifts/send', payload),
  reviews: (userId: string, before?: string) =>
    apiClient.get<any[]>(`/users/${userId}/reviews`, { params: { before } }),
  submitRating: (payload: Record<string, unknown>) => apiClient.post('/ratings', payload),
};

export const matchingApi = {
  start: (payload: Record<string, unknown>) => apiClient.post('/matching/start', payload),
  status: () => apiClient.get<any>('/matching/status'),
  action: (matchId: string, action: 'accept' | 'reject' | 'skip' | 'cancel') =>
    apiClient.post(`/matching/${matchId}/${action}`),
  feedback: (matchId: string, rating: number, tags: string[]) =>
    apiClient.post(`/matching/${matchId}/feedback`, { rating, tags }),
};

export const notificationsApi = {
  list: () => apiClient.get<any[]>('/notifications'),
  markAllRead: () => apiClient.post('/notifications/read-all'),
  markRead: (id: string) => apiClient.post(`/notifications/${id}/read`),
  remove: (id: string) => apiClient.delete(`/notifications/${id}`),
  registerDevice: (token: string, platform: 'android' | 'ios' | 'web') =>
    apiClient.post('/notifications/device-token', { token, platform }),
  unregisterDevice: (token: string) =>
    apiClient.delete('/notifications/device-token', { params: { token } }),
};

export const safetyApi = {
  block: (userId: string) => apiClient.post('/safety/blocks', { user_id: userId }),
  unblock: (userId: string) => apiClient.delete(`/safety/blocks/${userId}`),
  report: (targetType: string, targetId: string, reason: string, details = '') =>
    apiClient.post('/safety/reports', {
      target_type: targetType,
      target_id: targetId,
      reason,
      details,
    }),
  myReports: () => apiClient.get<any[]>('/safety/reports/me'),
};

export const accountApi = {
  logoutAll: () => apiClient.post('/auth/logout-all'),
  delete: () => apiClient.delete('/auth/account'),
  exportData: () => apiClient.get('/users/me/export'),
};

export const livestreamApi = {
  /** Start a new live stream (broadcaster) */
  start: (payload: { title: string; description?: string; category?: string }) =>
    apiClient.post<any>('/livestream/start', payload),
  /** End your stream */
  end: (streamId: string) => apiClient.post(`/livestream/${streamId}/end`),
  /** Get all currently active streams */
  active: () => apiClient.get<any[]>('/livestream/active'),
  /** Join a stream as viewer, returns Agora token */
  join: (streamId: string) => apiClient.post<any>(`/livestream/${streamId}/join`),
  /** Leave a stream */
  leave: (streamId: string) => apiClient.post(`/livestream/${streamId}/leave`),
  /** Send a gift to the streamer */
  sendGift: (streamId: string, payload: { gift_name: string; gift_emoji: string; coins: number }) =>
    apiClient.post<any>(`/livestream/${streamId}/gift`, payload),
};

export async function uploadAttachment(attachment: LocalAttachment) {
  const body = new FormData();
  body.append('file', {
    uri: attachment.uri,
    name: attachment.name,
    type: attachment.mimeType || 'application/octet-stream',
  } as any);
  const { data } = await apiClient.post('/uploads', body, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return data as { url: string; name: string; mime_type: string; size: number; kind: string };
}
