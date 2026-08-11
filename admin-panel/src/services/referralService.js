import api from './api.js';

export const referralService = {
  /** Get global referral stats */
  stats: () => api.get('/admin/referral-stats'),
  /** Get list of users with their referral info */
  topReferrers: () => api.get('/admin/top-referrers'),
};

export default referralService;
