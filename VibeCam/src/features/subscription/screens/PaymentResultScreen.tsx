import React from 'react';
import { Button, EmptyState, Header, Screen } from '../../../components/ui';

export function PaymentSuccessScreen({ navigation }: any) {
  return (
    <Screen>
      <Header title="Payment success" />
      <EmptyState
        icon="checkmark-circle-outline"
        title="Purchase completed"
        text="Your benefits are available now."
        action="View active subscription"
        onAction={() => navigation.replace('ActiveSubscription')}
      />
      <Button title="Open wallet" tone="secondary" onPress={() => navigation.replace('Wallet')} />
    </Screen>
  );
}
export function PaymentFailureScreen({ navigation, route }: any) {
  return (
    <Screen>
      <Header title="Payment failed" />
      <EmptyState
        icon="close-circle-outline"
        title="Purchase was not completed"
        text={route.params?.message || 'No charge was completed. Please try again.'}
        action="Try again"
        onAction={() => navigation.goBack()}
      />
    </Screen>
  );
}
