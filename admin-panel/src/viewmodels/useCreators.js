import { useState, useCallback } from 'react';
import { creatorsService } from '../services/creatorsService';

export function useCreators() {
  const [applications, setApplications] = useState([]);
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchApplications = useCallback(async (status) => {
    setLoading(true);
    setError(null);
    try {
      const params = status ? { status } : {};
      const res = await creatorsService.listApplications(params);
      setApplications(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load applications.');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchWithdrawals = useCallback(async (status) => {
    setLoading(true);
    setError(null);
    try {
      const params = status ? { status } : {};
      const res = await creatorsService.listWithdrawals(params);
      setWithdrawals(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load withdrawals.');
    } finally {
      setLoading(false);
    }
  }, []);

  const reviewApplication = useCallback(async (id, action, note) => {
    try {
      await creatorsService.reviewApplication(id, { action, note });
      await fetchApplications();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to review application.');
      return false;
    }
  }, [fetchApplications]);

  const reviewWithdrawal = useCallback(async (id, status, reason) => {
    try {
      await creatorsService.reviewWithdrawal(id, { status, reason: reason || '' });
      await fetchWithdrawals();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to process withdrawal.');
      return false;
    }
  }, [fetchWithdrawals]);

  return {
    applications, withdrawals, loading, error,
    fetchApplications, fetchWithdrawals,
    reviewApplication, reviewWithdrawal,
  };
}
