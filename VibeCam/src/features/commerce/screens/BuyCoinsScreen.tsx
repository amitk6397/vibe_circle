import React, { useState } from 'react';
import { Text } from 'react-native';
import { Button, Card, Header, Screen, ui } from '../../../components/ui';
import { environment } from '../../../config/environment';
import { useWalletViewModel } from '../viewmodels/useWalletViewModel';

export function BuyCoinsScreen({ navigation }: any) {
  const { packages, buy } = useWalletViewModel();
  const [buying, setBuying] = useState('');
  return (
    <Screen>
      <Header
        title="Buy coins"
        subtitle="Development payment simulator"
        onBack={() => navigation.goBack()}
      />
      {!environment.dummyPayments && (
        <Card>
          <Text style={ui.body}>Purchases are disabled until store billing is configured.</Text>
        </Card>
      )}
      {packages.map((item) => (
        <Card key={item.id}>
          <Text style={ui.h2}>{item.name}</Text>
          <Text style={ui.body}>
            {item.purchasedCoins} purchased coins
            {item.bonusCoins ? ` + ${item.bonusCoins} bonus` : ''}
          </Text>
          <Text style={ui.title}>
            {item.currency} {item.price}
          </Text>
          <Button
            title="Simulate purchase"
            loading={buying === item.id}
            disabled={!environment.dummyPayments || !!buying}
            onPress={async () => {
              setBuying(item.id);
              try {
                await buy(item.id);
                navigation.replace('PaymentSuccess', { kind: 'coins' });
              } catch (error: any) {
                navigation.replace('PaymentFailure', { message: error.message });
              } finally {
                setBuying('');
              }
            }}
          />
        </Card>
      ))}
    </Screen>
  );
}
export default BuyCoinsScreen;
