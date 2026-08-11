export type SubscriptionPlan = {
  id: string;
  name: string;
  description?: string;
  price: number;
  currency: string;
  interval: 'day' | 'week' | 'month';
  features: string[];
  highlighted?: boolean;
};

export type UserSubscription = {
  id: string;
  plan: SubscriptionPlan;
  startsAt: string;
  expiresAt: string;
  autoRenews: boolean;
  status: 'active' | 'cancelled' | 'expired' | 'pending';
};
