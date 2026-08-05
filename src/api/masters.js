import { api } from './client';

// Thin wrappers over the website API's master-data endpoints. Keeping URL
// construction here means screens never hand-build paths or query strings.

const listParams = (params = {}) => {
  const clean = Object.fromEntries(
    Object.entries(params).filter(([, v]) => v !== undefined && v !== null && v !== ''),
  );
  return Object.keys(clean).length ? { params: clean } : undefined;
};

export const buildings = {
  list: (params) => api.get('/masters/buildings', listParams(params)),
  get: (id) => api.get(`/masters/buildings/${id}`),
  create: (body) => api.post('/masters/buildings', body),
  update: (id, body) => api.put(`/masters/buildings/${id}`, body),
  remove: (id) => api.delete(`/masters/buildings/${id}`),
};

export const wings = {
  list: (params) => api.get('/masters/wings', listParams(params)),
  get: (id) => api.get(`/masters/wings/${id}`),
  create: (body) => api.post('/masters/wings', body),
  update: (id, body) => api.put(`/masters/wings/${id}`, body),
  remove: (id) => api.delete(`/masters/wings/${id}`),
};

// Owners and tenants share one endpoint, distinguished by ?type=Owner|Rent.
export const residents = {
  list: (params) => api.get('/masters/owners', listParams(params)),
  get: (id) => api.get(`/masters/owners/${id}`),
  lookups: (type = 'Owner') => api.get('/masters/owners/lookups', { params: { type } }),
  defaulters: () => api.get('/masters/owners/defaulters'),
  family: (id) => api.get(`/masters/owners/${id}/family`),
  create: (body) => api.post('/masters/owners', body),
  update: (id, body) => api.put(`/masters/owners/${id}`, body),
  remove: (id) => api.delete(`/masters/owners/${id}`),
};

export const family = {
  list: (ownerId) => api.get('/masters/family', { params: { ownerId } }),
  create: (body) => api.post('/masters/family', body),
  update: (id, body) => api.put(`/masters/family/${id}`, body),
  remove: (id, ownerId) => api.delete(`/masters/family/${id}`, { params: { ownerId } }),
};

export const flats = {
  list: (params) => api.get('/masters/flats', listParams(params)),
  get: (id) => api.get(`/masters/flats/${id}`),
  lookups: () => api.get('/masters/flats/lookups'),
  count: () => api.get('/masters/flats/count'),
  create: (body) => api.post('/masters/flats', body),
  update: (id, body) => api.put(`/masters/flats/${id}`, body),
  remove: (id) => api.delete(`/masters/flats/${id}`),
};
