import api from './api';

export const reportsService = {
  list: () => api.get('/admin/reports'),
  review: (id, data) => api.patch(`/admin/reports/${id}`, data),
  auditLogs: () => api.get('/admin/audit-logs'),
};
