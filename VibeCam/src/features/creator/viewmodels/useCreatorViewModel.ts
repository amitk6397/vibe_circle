import { useCallback, useEffect, useState } from 'react';
import { earningsApi } from '../../../services/api';

export function useEarningsDashboardViewModel() {
  const [dashboard, setDashboard] = useState<any>(null);
  const [earnings, setEarnings] = useState<any[]>([]);
  const [withdrawals, setWithdrawals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMoreEarnings, setHasMoreEarnings] = useState(true);
  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [d, e, w] = await Promise.all([
        earningsApi.dashboard(),
        earningsApi.history(),
        earningsApi.withdrawals(),
      ]);
      setDashboard(d.data);
      setEarnings(e.data);
      setHasMoreEarnings(e.data.length === 30);
      setWithdrawals(w.data);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Earnings dashboard unavailable.');
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    void refresh();
  }, [refresh]);
  const loadMoreEarnings = useCallback(async () => {
    if (!earnings.length || !hasMoreEarnings) return;
    const { data } = await earningsApi.history(earnings[earnings.length - 1].id);
    setEarnings((items) => [...items, ...data]);
    setHasMoreEarnings(data.length === 30);
  }, [earnings, hasMoreEarnings]);
  return {
    dashboard,
    earnings,
    withdrawals,
    loading,
    error,
    refresh,
    loadMoreEarnings,
    hasMoreEarnings,
  };
}
