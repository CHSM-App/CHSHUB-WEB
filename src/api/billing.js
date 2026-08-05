import { api } from './client';

const params = (p) => (p && Object.keys(p).length ? { params: p } : undefined);

export const bills = {
  list: (p) => api.get('/billing/bills', params(p)),
  get: (billId, p) => api.get(`/billing/bills/${billId}`, params(p)),
  forFlat: (billId, flatId) => api.get(`/billing/bills/${billId}/flat/${flatId}`),
  defaulters: () => api.get('/billing/bills/reports/defaulters'),
};

export const receipts = {
  list: () => api.get('/billing/receipts'),
  get: (id) => api.get(`/billing/receipts/${id}`),
  residents: () => api.get('/billing/receipts/residents'),
  outstanding: (flatId) => api.get('/billing/receipts/outstanding', { params: { flatId } }),
  pdc: (flatId) => api.get('/billing/receipts/pdc', { params: { flatId } }),

  // Financial writes. Not called by any screen yet — bill generation and
  // payment recording stay disabled until they have been exercised against a
  // test database. See docs/proposed-sql/ and the Billing generation page.
  create: (body) => api.post('/billing/receipts', body),
  cancel: (id, body) => api.post(`/billing/receipts/${id}/cancel`, body),
};

export const generation = {
  preview: () => api.get('/billing/generate/preview'),
  runRegular: (body) => api.post('/billing/generate/regular', body),
  runAddOn: (body) => api.post('/billing/generate/addon', body),
};
