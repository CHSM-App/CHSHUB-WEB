import { api } from './client';

export const onboarding = {
  societies: () => api.get('/onboarding/societies'),
  userTypes: () => api.get('/onboarding/user-types'),
  checkUsername: (username) => api.get('/onboarding/check-username', { params: { username } }),
  checkEmail: (email) => api.get('/onboarding/check-email', { params: { email } }),
  register: (body) => api.post('/onboarding/register', body),
  forgotPassword: (body) => api.post('/onboarding/forgot-password', body),
  changePassword: (body) => api.post('/onboarding/change-password', body),
  /** The signed-in user's own account — the Profile modal from Site.Master. */
  profile: () => api.get('/onboarding/profile'),
  saveProfile: (body) => api.put('/onboarding/profile', body),
  saveSociety: (id, body) => api.put(`/onboarding/societies/${id}`, body),
  saveVillage: (id, body) => api.put(`/onboarding/villages/${id}`, body),
};

export const pdc = {
  list: (params) => api.get('/billing/pdc', params ? { params } : undefined),
  clearing: (from, to) => api.get('/billing/pdc/clearing', { params: { from, to } }),
  forOwner: (ownerId) => api.get(`/billing/pdc/owner/${ownerId}`),
  /** Contact block the legacy form filled from the chosen owner. */
  ownerDetails: (ownerId) => api.get(`/billing/pdc/owner/${ownerId}/details`),
  create: (body) => api.post('/billing/pdc', body),
  update: (id, body) => api.put(`/billing/pdc/${id}`, body),
  clear: (id, body) => api.post(`/billing/pdc/${id}/clear`, body),
  remove: (id) => api.delete(`/billing/pdc/${id}`),
};

export const extraReports = {
  adminDashboard: () => api.get('/reports/admin-dashboard'),
  updates: () => api.get('/reports/updates'),
  profitLoss: (from, to) => api.get('/reports/profit-loss', { params: { from, to } }),
  paidAmounts: (from, to) => api.get('/reports/paid-amounts', { params: { from, to } }),
  balanceSheet: () => api.get('/reports/balance-sheet'),
  agm: (from, to) => api.get('/reports/agm', { params: { from, to } }),
};
