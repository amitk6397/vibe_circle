import api from './api';

export const commerceService = {
  // Subscription Plans
  listPlans: () => api.get('/admin/subscription-plans'),
  createPlan: (data) => api.post('/admin/subscription-plans', data),
  updatePlan: (id, data) => api.patch(`/admin/subscription-plans/${id}`, data),
  deletePlan: (id) => api.delete(`/admin/subscription-plans/${id}`),

  // Coin Packages
  listPackages: () => api.get('/admin/coin-packages'),
  createPackage: (data) => api.post('/admin/coin-packages', data),
  updatePackage: (id, data) => api.patch(`/admin/coin-packages/${id}`, data),

  // Transactions
  listTransactions: (params) => api.get('/admin/transactions', { params }),

  // Revenue Summary
  revenueSummary: (period = '30d') => api.get('/admin/revenue-summary', { params: { period } }),

  // Special Offers
  listOffers: () => api.get('/admin/offers'),
  createOffer: (data) => api.post('/admin/offers', data),
  updateOffer: (id, data) => api.patch(`/admin/offers/${id}`, data),
  deleteOffer: (id) => api.delete(`/admin/offers/${id}`),
};
