import React, { useEffect, useState } from 'react';
import { Text } from 'react-native';
import { Button, Card, Header, Screen, ui } from '../../../components/ui';
import { environment } from '../../../config/environment';
import { subscriptionApi } from '../../../services/api';
import { SubscriptionPlan } from '../models/Subscription';

export function PurchaseConfirmationScreen({ navigation, route }: any) {
  const [plan, setPlan] = useState<SubscriptionPlan | null>(null);
  const [processing, setProcessing] = useState(false);
  useEffect(() => {
    void subscriptionApi
      .plans()
      .then(({ data }) => setPlan(data.find((item) => item.id === route.params.planId) || null));
  }, [route.params.planId]);
  const purchase = async () => {
    if (!plan) return;
    setProcessing(true);
    try {
      if (!environment.dummyPayments)
        throw new Error('A production payment provider has not been configured.');
      await subscriptionApi.purchase(plan.id, `dummy_${Date.now()}_${plan.id}`);
      navigation.replace('PaymentSuccess', { kind: 'subscription' });
    } catch (error: any) {
      navigation.replace('PaymentFailure', { message: error.message });
    } finally {
      setProcessing(false);
    }
  };
  return (
    <Screen>
      <Header title="Purchase confirmation" onBack={() => navigation.goBack()} />
      <Card>
        <Text style={ui.h2}>{plan?.name || 'Loading plan...'}</Text>
        {plan && (
          <>
            <Text style={ui.title}>
              {plan.currency} {plan.price}/{plan.interval}
            </Text>
            <Text style={ui.body}>Unlocks private chat, audio, and video for this period.</Text>
            <Text style={ui.muted}>Coins are charged separately for each paid conversation.</Text>
          </>
        )}
      </Card>
      <Card>
        <Text style={ui.body}>
          {environment.dummyPayments
            ? 'Development mode: this payment is simulated and no real money is charged.'
            : 'Payment verification is unavailable until a provider is configured.'}
        </Text>
      </Card>
      <Button
        title="Confirm purchase"
        loading={processing}
        disabled={!plan || !environment.dummyPayments}
        onPress={() => void purchase()}
      />
    </Screen>
  );
}
export default PurchaseConfirmationScreen;
