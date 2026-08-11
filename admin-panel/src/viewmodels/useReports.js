import { useState, useEffect, useCallback } from 'react';
import { reportsService } from '../services/reportsService';

export function useReports() {
  const [reports, setReports] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchReports = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await reportsService.list();
      setReports(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load reports.');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchAuditLogs = useCallback(async () => {
    try {
      const res = await reportsService.auditLogs();
      setAuditLogs(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load audit logs.');
    }
  }, []);

  const reviewReport = useCallback(async (id, status, action) => {
    try {
      await reportsService.review(id, { status, action });
      await fetchReports();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to review report.');
      return false;
    }
  }, [fetchReports]);

  useEffect(() => { fetchReports(); }, [fetchReports]);

  return { reports, auditLogs, loading, error, fetchReports, fetchAuditLogs, reviewReport };
}
