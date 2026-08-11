import React from 'react';
import { Text } from 'react-native';
import { Button, Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { useWalletViewModel } from '../viewmodels/useWalletViewModel';

export function TransactionHistoryScreen({ navigation }: any) {
  const { transactions, loading, hasMoreTransactions, loadMoreTransactions } = useWalletViewModel();
  return (
    <Screen>
      <Header title="Transactions" onBack={() => navigation.goBack()} />
      {transactions.map((item) => (
        <Card key={item.id}>
          <Text style={ui.h2}>{item.transaction_type.replaceAll('_', ' ')}</Text>
          <Text style={ui.body}>
            {item.amount > 0 ? '+' : ''}
            {item.amount} · {item.balance_type.replaceAll('_', ' ')}
          </Text>
          <Text style={ui.muted}>
            {new Date(item.created_at).toLocaleString()} · {item.status}
          </Text>
          <Text style={ui.muted}>Transaction ID: {item.id}</Text>
          {!!item.reference_type && (
            <Text style={ui.muted}>
              Related: {item.reference_type} {item.reference_id || ''}
            </Text>
          )}
          <Text style={ui.muted}>Payment method: {item.payment_method || 'wallet credit'}</Text>
        </Card>
      ))}
      {hasMoreTransactions && (
        <Button title="Load more" tone="ghost" onPress={() => void loadMoreTransactions()} />
      )}
      {!loading && !transactions.length && (
        <EmptyState
          icon="receipt-outline"
          title="No transactions"
          text="Wallet activity will appear here."
        />
      )}
    </Screen>
  );
}
export default TransactionHistoryScreen;
