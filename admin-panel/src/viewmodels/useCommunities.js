import { useState, useCallback } from 'react';
import { communitiesService } from '../services/communitiesService';

export function useCommunities() {
  const [communities, setCommunities] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ search: '', status: '' });

  const fetchCommunities = useCallback(async (overrideFilters) => {
    setLoading(true);
    setError(null);
    const params = overrideFilters || filters;
    const cleanParams = Object.fromEntries(Object.entries(params).filter(([, v]) => v));
    try {
      const res = await communitiesService.list(cleanParams);
      setCommunities(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load communities.');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  const updateCommunity = useCallback(async (id, data) => {
    try {
      await communitiesService.update(id, data);
      await fetchCommunities();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update community.');
      return false;
    }
  }, [fetchCommunities]);

  const deleteCommunity = useCallback(async (id) => {
    try {
      await communitiesService.delete(id);
      await fetchCommunities();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to delete community.');
      return false;
    }
  }, [fetchCommunities]);

  const applyFilters = useCallback((newFilters) => {
    setFilters(newFilters);
    fetchCommunities(newFilters);
  }, [fetchCommunities]);

  return { communities, loading, error, filters, applyFilters, fetchCommunities, updateCommunity, deleteCommunity };
}
