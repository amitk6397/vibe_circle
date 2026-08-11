import api from './api';

export const communitiesService = {
  list: (params) => api.get('/admin/communities', { params }),
  update: (id, data) => api.patch(`/admin/communities/${id}`, data),
  delete: (id) => api.delete(`/admin/communities/${id}`),
};
