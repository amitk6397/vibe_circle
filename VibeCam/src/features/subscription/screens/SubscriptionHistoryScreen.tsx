import React, { useCallback, useState } from 'react';
import { Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { subscriptionApi } from '../../../services/api';
import { UserSubscription } from '../models/Subscription';

export function SubscriptionHistoryScreen({ navigation }: any) {
  const [items, setItems] = useState<UserSubscription[]>([]);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await subscriptionApi.history();
      setItems(data);
    } catch (reason: any) {
      setError(reason.message);
    }
  }, []);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  return (
    <Screen>
      <Header title="Subscription history" onBack={() => navigation.goBack()} />
      {!!error && (
        <EmptyState
          title="History unavailable"
          text={error}
          action="Retry"
          onAction={() => void load()}
        />
      )}
      {items.map((item) => (
        <Card key={item.id}>
          <Text style={ui.h2}>{item.plan.name}</Text>
          <Text style={ui.body}>
            {item.status} · {new Date(item.startsAt).toLocaleDateString()} to{' '}
            {new Date(item.expiresAt).toLocaleDateString()}
          </Text>
        </Card>
      ))}
      {!error && !items.length && (
        <EmptyState title="No subscription history" text="Completed purchases will appear here." />
      )}
    </Screen>
  );
}
export default SubscriptionHistoryScreen;
