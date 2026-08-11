import { useState, useCallback } from 'react';
import { usersService } from '../services/usersService';

export function useUsers() {
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const [loading, setLoading] = useState(false);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({ search: '', status: '', role: '' });

  const fetchUsers = useCallback(async (overrideFilters) => {
    setLoading(true);
    setError(null);
    const params = overrideFilters || filters;
    const cleanParams = Object.fromEntries(Object.entries(params).filter(([, v]) => v));
    try {
      const res = await usersService.list(cleanParams);
      setUsers(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load users.');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  const fetchUser = useCallback(async (id) => {
    setDetailLoading(true);
    try {
      const res = await usersService.getById(id);
      setSelectedUser(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load user details.');
    } finally {
      setDetailLoading(false);
    }
  }, []);

  const updateUser = useCallback(async (id, data) => {
    try {
      await usersService.update(id, data);
      await fetchUsers();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update user.');
      return false;
    }
  }, [fetchUsers]);

  const deleteUser = useCallback(async (id) => {
    try {
      await usersService.delete(id);
      await fetchUsers();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to delete user.');
      return false;
    }
  }, [fetchUsers]);

  const applyFilters = useCallback((newFilters) => {
    setFilters(newFilters);
    fetchUsers(newFilters);
  }, [fetchUsers]);

  return {
    users, selectedUser, loading, detailLoading, error,
    filters, applyFilters,
    fetchUsers, fetchUser, updateUser, deleteUser,
    clearSelected: () => setSelectedUser(null),
  };
}
