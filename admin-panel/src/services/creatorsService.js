import api from './api';

export const creatorsService = {
  // Creator Applications
  listApplications: (params) => api.get('/admin/creator-applications', { params }),
  reviewApplication: (id, data) => api.patch(`/admin/creator-applications/${id}`, data),

  // Withdrawals
  listWithdrawals: (params) => api.get('/admin/withdrawals', { params }),
  reviewWithdrawal: (id, data) => api.patch(`/admin/withdrawals/${id}/review`, data),
};
