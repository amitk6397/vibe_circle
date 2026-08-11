import api from './api';

export const contentService = {
  // Support Articles
  listArticles: () => api.get('/admin/support-articles'),
  createArticle: (data) => api.post('/admin/support-articles', data),
  updateArticle: (id, data) => api.patch(`/admin/support-articles/${id}`, data),
  deleteArticle: (id) => api.delete(`/admin/support-articles/${id}`),

  // Virtual Gifts
  listGifts: () => api.get('/admin/gifts'),
  createGift: (data) => api.post('/admin/gifts', data),
  updateGift: (id, data) => api.patch(`/admin/gifts/${id}`, data),
  deleteGift: (id) => api.delete(`/admin/gifts/${id}`),

  // Platform Settings
  getSettings: () => api.get('/admin/settings'),
  updateSettings: (data) => api.patch('/admin/settings', data),
};
