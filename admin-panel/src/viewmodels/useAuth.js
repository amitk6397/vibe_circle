import { useState, useCallback } from 'react';
import { authService } from '../services/authService';

export function useAuth() {
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('admin_user')); } catch { return null; }
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const login = useCallback(async (email, password) => {
    setLoading(true);
    setError(null);
    try {
      const res = await authService.login(email, password);
      const { access_token, refresh_token, user: userData } = res.data;

      // Store token first so /users/me call works
      localStorage.setItem('admin_token', access_token);
      localStorage.setItem('admin_refresh', refresh_token);

      // If role is missing from login response, fetch it from /users/me
      let finalUser = userData;
      if (!userData.role) {
        try {
          const meRes = await authService.me();
          finalUser = { ...userData, ...meRes.data };
        } catch (_) { /* use userData as-is */ }
      }

      // Only allow admin/moderator roles
      if (!['admin', 'moderator'].includes(finalUser.role)) {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_refresh');
        setError('Access denied. Admin credentials required.');
        return false;
      }

      localStorage.setItem('admin_user', JSON.stringify(finalUser));
      setUser(finalUser);
      return true;
    } catch (err) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_refresh');
      setError(err.response?.data?.detail || 'Login failed. Please check your credentials.');
      return false;
    } finally {
      setLoading(false);
    }
  }, []);

  const register = useCallback(async (name, age, email, password) => {
    setLoading(true);
    setError(null);
    try {
      const res = await authService.register(name, age, email, password);
      // Clean up token storage so the guest status is preserved
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_refresh');
      localStorage.removeItem('admin_user');
      return { success: true, data: res.data };
    } catch (err) {
      setError(err.response?.data?.detail || 'Registration failed.');
      return { success: false };
    } finally {
      setLoading(false);
    }
  }, []);

  const forgotPassword = useCallback(async (email) => {
    setLoading(true);
    setError(null);
    try {
      const res = await authService.forgotPassword(email);
      return { success: true, data: res.data };
    } catch (err) {
      setError(err.response?.data?.detail || 'Forgot password request failed.');
      return { success: false };
    } finally {
      setLoading(false);
    }
  }, []);

  const resetPassword = useCallback(async (token, password) => {
    setLoading(true);
    setError(null);
    try {
      await authService.resetPassword(token, password);
      return { success: true };
    } catch (err) {
      setError(err.response?.data?.detail || 'Reset password failed.');
      return { success: false };
    } finally {
      setLoading(false);
    }
  }, []);

  const logout = useCallback(async () => {
    const refresh = localStorage.getItem('admin_refresh');
    try { if (refresh) await authService.logout(refresh); } catch (_) { /* ignore */ }
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_refresh');
    localStorage.removeItem('admin_user');
    setUser(null);
  }, []);

  return {
    user,
    loading,
    error,
    login,
    logout,
    register,
    forgotPassword,
    resetPassword,
    isLoggedIn: !!user,
  };
}
