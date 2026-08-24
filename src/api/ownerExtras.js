import { api } from './client';

const p = (params) => ({ params });

export const ownerExtras = {
  hobbies: (ownerId, kind = 'owner') => api.get('/masters/owner-extras/hobbies', p({ ownerId, kind })),
  addHobby: (body) => api.post('/masters/owner-extras/hobbies', body),
  clearHobbies: (ownerId, kind = 'owner') =>
    api.delete('/masters/owner-extras/hobbies', p({ ownerId, kind })),

  workAreas: (ownerId, kind = 'owner') => api.get('/masters/owner-extras/work-areas', p({ ownerId, kind })),
  addWorkArea: (body) => api.post('/masters/owner-extras/work-areas', body),
  clearWorkAreas: (ownerId, kind = 'owner') =>
    api.delete('/masters/owner-extras/work-areas', p({ ownerId, kind })),

  documents: (flatId) => api.get('/masters/owner-extras/documents', p({ flatId })),
  removeDocument: (documentId) => api.delete(`/masters/owner-extras/documents/${documentId}`),
  recordDocument: (body) => api.post('/uploads/record/owner-document', body),

  vehicles: (flatId) => api.get('/masters/owner-extras/vehicles', p({ flatId })),
  addVehicle: (body) => api.post('/masters/owner-extras/vehicles', body),
  removeVehicle: (vehicleId) => api.delete(`/masters/owner-extras/vehicles/${vehicleId}`),

  dues: (flatId) => api.get('/masters/owner-extras/dues', p({ flatId })),
  directory: () => api.get('/masters/owner-extras/directory'),
  ownerList: () => api.get('/masters/owner-extras/owner-list'),

  saveSettings: (ownerId, body) => api.put(`/masters/owner-extras/${ownerId}/settings`, body),
  saveNotifications: (ownerId, body) => api.put(`/masters/owner-extras/${ownerId}/notifications`, body),
  deactivate: (ownerId, body) => api.post(`/masters/owner-extras/${ownerId}/deactivate`, body),
};

export const vendorBills = {
  list: () => api.get('/accounts/vendor-bills'),
  get: (id) => api.get(`/accounts/vendor-bills/${id}`),
  serviceTypes: () => api.get('/accounts/vendor-bills/service-types'),
  formData: () => api.get('/accounts/vendor-bills/form-data'),
  staff: (roleId) => api.get('/accounts/vendor-bills/staff', roleId ? p({ roleId }) : undefined),
  create: (body) => api.post('/accounts/vendor-bills', body),
  update: (id, body) => api.put(`/accounts/vendor-bills/${id}`, body),
  remove: (id) => api.delete(`/accounts/vendor-bills/${id}`),
  approvals: (id) => api.get(`/accounts/vendor-bills/${id}/approvals`),
  addApprovers: (id, userIds) => api.post(`/accounts/vendor-bills/${id}/approvers`, { userIds }),
  // The bill is in the path so the API can check the approval belongs to the
  // caller — only the approver it was asked of may answer it.
  decide: (billId, approvalId, body) =>
    api.post(`/accounts/vendor-bills/${billId}/approvals/${approvalId}`, body),
  pay: (id, body) => api.post(`/accounts/vendor-bills/${id}/payments`, body),
};
