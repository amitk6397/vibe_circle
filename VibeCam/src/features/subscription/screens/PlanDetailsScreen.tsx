import React, { useEffect, useState } from 'react';
import { Alert, Text } from 'react-native';
import { Button, Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { subscriptionApi } from '../../../services/api';
import { SubscriptionPlan } from '../models/Subscription';

export function PlanDetailsScreen({ navigation, route }: any) {
  const [plan, setPlan] = useState<SubscriptionPlan | null>(null);
  useEffect(() => {
    void subscriptionApi
      .plans()
      .then(({ data }) => setPlan(data.find((item) => item.id === route.params.planId) || null))
      .catch((error) => Alert.alert('Plan unavailable', error.message));
  }, [route.params.planId]);
  if (!plan)
    return (
      <Screen>
        <Header title="Plan details" onBack={() => navigation.goBack()} />
        <EmptyState
          icon="card-outline"
          title="Plan unavailable"
          text="This plan may no longer be offered."
        />
      </Screen>
    );
  return (
    <Screen>
      <Header title={plan.name} onBack={() => navigation.goBack()} />
      <Card>
        <Text style={ui.title}>
          {plan.currency} {plan.price}/{plan.interval}
        </Text>
        {plan.features.map((item) => (
          <Text key={item} style={[ui.body, { marginTop: 10 }]}>
            • {item}
          </Text>
        ))}
      </Card>
      <Button
        title="Continue"
        onPress={() => navigation.navigate('PurchaseConfirmation', { planId: plan.id })}
      />
    </Screen>
  );
}
export default PlanDetailsScreen;
