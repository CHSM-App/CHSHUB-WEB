import { api } from './client';

export const accountSettings = {
  get: () => api.get('/settings/account'),
  save: (body) => api.put('/settings/account', body),
};

export const charges = {
  list: (params) => api.get('/settings/charges', params ? { params } : undefined),
  get: (id) => api.get(`/settings/charges/${id}`),
  create: (body) => api.post('/settings/charges', body),
  update: (id, body) => api.put(`/settings/charges/${id}`, body),
  remove: (id) => api.delete(`/settings/charges/${id}`),
};

export const terms = {
  get: () => api.get('/settings/terms'),
  save: (body) => api.put('/settings/terms', body),
};

export const societyCharges = {
  get: () => api.get('/settings/society-charges'),
  save: (body) => api.put('/settings/society-charges', body),
};
