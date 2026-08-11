import React, { useCallback, useState } from 'react';
import { Alert, Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Button, Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { subscriptionApi } from '../../../services/api';
import { UserSubscription } from '../models/Subscription';

export function ActiveSubscriptionScreen({ navigation }: any) {
  const [subscription, setSubscription] = useState<UserSubscription | null>(null);
  const load = useCallback(async () => {
    try {
      const { data } = await subscriptionApi.active();
      setSubscription(data);
    } catch (error: any) {
      Alert.alert('Subscription unavailable', error.message);
    }
  }, []);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  if (!subscription)
    return (
      <Screen>
        <Header title="Active subscription" onBack={() => navigation.goBack()} />
        <EmptyState
          icon="sparkles-outline"
          title="No active pass"
          text="Choose a 1 day, 1 week, or 1 month pass to use paid chat and calls."
          action="View plans"
          onAction={() => navigation.navigate('SubscriptionPlans')}
        />
      </Screen>
    );
  return (
    <Screen>
      <Header title="Active subscription" onBack={() => navigation.goBack()} />
      <Card>
        <Text style={ui.title}>{subscription.plan.name}</Text>
        <Text style={ui.body}>Started: {new Date(subscription.startsAt).toLocaleDateString()}</Text>
        <Text style={ui.body}>
          Expires: {new Date(subscription.expiresAt).toLocaleDateString()}
        </Text>
        <Text style={ui.body}>Auto-renewal: {subscription.autoRenews ? 'On' : 'Off'}</Text>
        <Text style={ui.body}>Private chat, audio, and video access is active.</Text>
        <Text style={ui.muted}>Conversation charges are paid separately with coins.</Text>
      </Card>
      <Button
        title="Cancel renewal"
        tone="ghost"
        onPress={() =>
          Alert.alert('Cancel renewal?', 'Your benefits stay active until the expiry date.', [
            { text: 'Keep plan', style: 'cancel' },
            {
              text: 'Cancel renewal',
              style: 'destructive',
              onPress: () => void subscriptionApi.cancelRenewal().then(load),
            },
          ])
        }
      />
      <Button
        title="Upgrade plan"
        tone="secondary"
        onPress={() => navigation.navigate('SubscriptionPlans')}
      />
      <Button
        title="Subscription history"
        tone="ghost"
        onPress={() => navigation.navigate('SubscriptionHistory')}
      />
    </Screen>
  );
}
export default ActiveSubscriptionScreen;
