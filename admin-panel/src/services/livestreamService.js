import api from './api.js';

export const livestreamService = {
  /** List all streams (admin, sorted by started_at desc) */
  listAll: () => api.get('/livestream/admin/streams'),
  /** Force-end a live stream */
  forceEnd: (streamId) => api.post(`/livestream/admin/${streamId}/force-end`),
  /** List currently active streams */
  active: () => api.get('/livestream/active'),
};

export default livestreamService;
