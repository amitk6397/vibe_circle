export type ConversationLimit = {
  weeklyConversationLimit: number;
  weeklyConversationUsed: number;
  messagesPerConversation: number;
  conversationMessageUsed: number;
  subscriptionActive: boolean;
  canUseChatCredit: boolean;
  resetAt?: string;
  chatCoinsPerMessage?: number;
  chatMessageDeductionInterval?: number;
};

export type MessageRequestStatus = 'pending' | 'accepted' | 'rejected' | 'blocked' | 'expired';

export type MessageRequest = {
  id: string;
  conversationId?: string;
  senderId: string;
  senderName: string;
  recipientId: string;
  introduction: string;
  status: MessageRequestStatus;
  createdAt: string;
  chatPrice?: number;
  chatPricePerMinute?: number;
  reservedMinutes?: number;
  sessionEndsAt?: string;
  paid?: boolean;
};
