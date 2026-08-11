import React, { useCallback, useState } from 'react';
import { Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { safetyApi } from '../../../services/api';

export function ReportsScreen({ navigation }: any) {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await safetyApi.myReports();
      setReports(data);
    } catch (reason: any) {
      setError(reason.message);
    } finally {
      setLoading(false);
    }
  }, []);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  return (
    <Screen>
      <Header
        title="My reports"
        subtitle="Track safety-team review status"
        onBack={() => navigation.goBack()}
      />
      {!!error && (
        <EmptyState
          icon="alert-circle-outline"
          title="Reports unavailable"
          text={error}
          action="Retry"
          onAction={() => void load()}
        />
      )}
      {!loading && !error && !reports.length && (
        <EmptyState
          icon="shield-checkmark-outline"
          title="No reports"
          text="Reports you submit will appear here."
        />
      )}
      {reports.map((item) => (
        <Card key={item.id}>
          <Text style={ui.h2}>{item.reason}</Text>
          <Text style={ui.body}>
            {item.target_type.replaceAll('_', ' ')} · {item.status}
          </Text>
          <Text style={ui.muted}>{new Date(item.created_at).toLocaleString()}</Text>
        </Card>
      ))}
    </Screen>
  );
}
export default ReportsScreen;
