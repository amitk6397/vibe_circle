import React, { useState } from 'react';
import { ScrollView, Text, View } from 'react-native';
import { Button, Card, EmptyState, Header, Screen, ui, Pill } from '../../../components/ui';
import { useWalletViewModel } from '../viewmodels/useWalletViewModel';
import { colors } from '../../../theme';

export function TransactionHistoryScreen({ navigation }: any) {
  const { transactions, loading, hasMoreTransactions, loadMoreTransactions } = useWalletViewModel();
  const [filter, setFilter] = useState<'all' | 'credit' | 'debit'>('all');

  const filteredTransactions = transactions.filter((item) => {
    if (filter === 'credit') return item.amount > 0;
    if (filter === 'debit') return item.amount < 0;
    return true;
  });

  return (
    <Screen scroll={false}>
      <Header title="Transactions" onBack={() => navigation.goBack()} />
      <View style={{ flexDirection: 'row', gap: 8, paddingHorizontal: 16, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: colors.border, backgroundColor: colors.bg }}>
        <Pill label="All" selected={filter === 'all'} onPress={() => setFilter('all')} />
        <Pill label="Received" selected={filter === 'credit'} onPress={() => setFilter('credit')} />
        <Pill label="Spent" selected={filter === 'debit'} onPress={() => setFilter('debit')} />
      </View>
      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ padding: 16, gap: 12 }}>
        {filteredTransactions.map((item) => (
          <Card key={item.id} style={{ padding: 14 }}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
              <Text style={[ui.h2, { textTransform: 'capitalize' }]}>{item.transaction_type.replaceAll('_', ' ')}</Text>
              <Text style={[ui.body, { fontWeight: '900', color: item.amount > 0 ? colors.success : colors.text }]}>
                {item.amount > 0 ? '+' : ''}{item.amount}
              </Text>
            </View>
            <Text style={ui.muted}>
              {new Date(item.created_at).toLocaleString()} · {item.status}
            </Text>
            <Text style={[ui.muted, { fontSize: 11, marginTop: 4 }]}>Transaction ID: {item.id}</Text>
            <Text style={[ui.muted, { fontSize: 11 }]}>Payment: {item.payment_method || 'wallet credit'}</Text>
          </Card>
        ))}
        {hasMoreTransactions && (
          <Button title="Load more" tone="ghost" onPress={() => void loadMoreTransactions()} />
        )}
        {!loading && !filteredTransactions.length && (
          <EmptyState
            icon="receipt-outline"
            title="No transactions"
            text="No transactions match this filter."
          />
        )}
      </ScrollView>
    </Screen>
  );
}

export default TransactionHistoryScreen;
