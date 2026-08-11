import React, { useState } from 'react';
import { Alert, Text } from 'react-native';
import { Button, Card, Field, Header, Screen, ui } from '../../../components/ui';
import { earningsApi } from '../../../services/api';
import { useEarningsDashboardViewModel } from '../viewmodels/useCreatorViewModel';

export function WithdrawalScreen({ navigation }: any) {
  const { dashboard, withdrawals, refresh } = useEarningsDashboardViewModel();
  const [amount, setAmount] = useState('');
  const [reference, setReference] = useState('');
  const [saving, setSaving] = useState(false);
  const submit = async () => {
    setSaving(true);
    try {
      await earningsApi.requestWithdrawal(Number(amount), reference.trim());
      Alert.alert('Withdrawal requested', 'Your request is pending review.');
      setAmount('');
      await refresh();
    } catch (error: any) {
      Alert.alert('Request failed', error.message);
    } finally {
      setSaving(false);
    }
  };
  return (
    <Screen>
      <Header
        title="Withdrawal"
        subtitle={`Available: ${dashboard?.availableBalance || 0}`}
        onBack={() => navigation.goBack()}
      />
      <Card>
        <Text style={ui.body}>
          Payout processing is currently manual/dummy. No bank transfer is claimed until an
          administrator marks it paid.
        </Text>
      </Card>
      <Field label="Amount" value={amount} onChangeText={setAmount} keyboardType="numeric" />
      <Field label="Payout account reference" value={reference} onChangeText={setReference} />
      <Button
        title="Request withdrawal"
        loading={saving}
        disabled={!Number(amount) || !reference.trim()}
        onPress={() => void submit()}
      />
      {withdrawals.map((item) => (
        <Card key={item.id}>
          <Text style={ui.h2}>{item.amount}</Text>
          <Text style={ui.muted}>
            {item.status} · {new Date(item.created_at).toLocaleString()}
          </Text>
        </Card>
      ))}
    </Screen>
  );
}
export default WithdrawalScreen;
