import api from './api';

export const authService = {
  login: (email, password) =>
    api.post('/auth/login', { email, password }),

  logout: (refreshToken) =>
    api.post('/auth/logout', { refresh_token: refreshToken }),

  register: (name, age, email, password) =>
    api.post('/auth/register', { name, age: Number(age), email, password }),

  forgotPassword: (email) =>
    api.post('/auth/forgot-password', { email }),

  resetPassword: (token, password) =>
    api.post('/auth/reset-password', { token, password }),

  me: () =>
    api.get('/users/me'),
};
