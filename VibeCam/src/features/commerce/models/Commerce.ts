export type UserWallet = {
  purchased_coins: number;
  bonus_coins: number;
  held_coins: number;
  chat_credits: number;
  audio_call_credits: number;
  video_call_credits: number;
};

export type CoinPackage = {
  id: string;
  name: string;
  purchasedCoins: number;
  bonusCoins: number;
  price: number;
  currency: string;
};
export type WalletTransaction = {
  id: string;
  transaction_type: string;
  balance_type: string;
  amount: number;
  status: string;
  reference_type?: string;
  reference_id?: string;
  payment_method?: string;
  created_at: string;
};

export type UserPerformanceProfile = {
  userId: string;
  name: string;
  avatarUrl?: string;
  verified: boolean;
  category: string;
  topics: string[];
  languages: string[];
  introduction: string;
  rating: number;
  totalCompletedSessions: number;
  responseRate: number;
  averageResponseSeconds: number;
  availabilityStatus: string;
  chatAvailable: boolean;
  audioAvailable: boolean;
  videoAvailable: boolean;
  chatPrice: number;
  audioPricePerMinute: number;
  videoPricePerMinute: number;
  schedule?: { workingDays?: string[]; startTime?: string; endTime?: string; breakTime?: string };
  maximumDailySessions?: number;
};
