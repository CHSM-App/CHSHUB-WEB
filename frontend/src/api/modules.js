import { api } from './client';

const p = (params) => (params && Object.keys(params).length ? { params } : undefined);

/** Factory for the list/get/create/update/delete shape most screens share. */
const resource = (base, idKey = 'id') => ({
  list: (params) => api.get(base, p(params)),
  get: (id) => api.get(`${base}/${id}`),
  create: (body) => api.post(base, body),
  update: (id, body) => api.put(`${base}/${id}`, body),
  remove: (id) => api.delete(`${base}/${id}`),
  idKey,
});

/* ------------------------------------------------------------- masters */
export const staff = resource('/masters/staff', 'staff_id');
export const caretakers = resource('/masters/caretakers', 'caretaker_id');
export const helpers = resource('/masters/helpers', 'servent_id');
export const contacts = resource('/masters/contacts', 'usefull_contact_id');
export const docTypes = resource('/masters/doc-types', 'doc_id');
export const parkingPlaces = resource('/masters/parking-places', 'place_id');
export const carPooling = resource('/masters/car-pooling', 'car_id');
export const loans = resource('/masters/loans', 'loan_id');
/** Flat, loan-type and share-certificate pickers for the loan form. */
export const loanLookups = () => api.get('/masters/loans-lookups');

export const lookups = {
  staffRoles: () => api.get('/masters/staff-roles'),
  contactTypes: () => api.get('/masters/contact-types'),
  society: () => api.get('/masters/society'),
  members: (params) => api.get('/masters/members', p(params)),
  inventory: (params) => api.get('/masters/inventory', p(params)),
  parkingAllotment: (search) => api.get('/masters/parking-allotment', p({ search })),
  parkingAllotmentLookups: (flatId, vehicleType) =>
    api.get('/masters/parking-allotment/lookups', p({ flatId, vehicleType })),
  staffAttendanceToday: () => api.get('/masters/staff-attendance/today'),
  staffAttendance: (staffId) => api.get(`/masters/staff/${staffId}/attendance`),
};

/* ------------------------------------------------------------ accounts */
export const expenses = resource('/accounts/expenses', 'expense_id');
export const ledger = resource('/accounts/ledger', 'led_id');
export const shopMaintenance = resource('/accounts/shop-maintenance', 'shop_maint_id');
export const otherCredits = resource('/accounts/other-credits', 'Id');

export const accounts = {
  cashbook: (from, to) => api.get('/accounts/cashbook', { params: { from, to } }),
  societyReceipts: () => api.get('/accounts/society-receipts'),
};

export const vendors = {
  ...resource('/accounts/vendors', 'vendor_id'),
  bills: () => api.get('/accounts/vendors/bills/list'),
  bill: (id) => api.get(`/accounts/vendors/bills/${id}`),
  createBill: (body) => api.post('/accounts/vendors/bills', body),
  approveBill: (id) => api.post(`/accounts/vendors/bills/${id}/approve`),
  rejectBill: (id) => api.post(`/accounts/vendors/bills/${id}/reject`),
  payments: () => api.get('/accounts/vendors/payments/list'),
  payable: (vendorId) => api.get('/accounts/vendors/payments/payable', p({ vendorId })),
};

/* ----------------------------------------------------------- community */
export const notices = resource('/community/notices', 'notice_id');
export const events = resource('/community/events', 'event_id');
export const meetings = resource('/community/meetings', 'meet_id');
export const facilities = resource('/community/facilities', 'facility_id');
export const suggestions = resource('/community/suggestions', 'sug_id');
export const documents = resource('/community/documents', 'file_id');

export const community = {
  noticeRecipients: () => api.get('/community/notices/recipients'),
  facilityBookings: (params) => api.get('/community/facility-bookings', p(params)),
  facilityBookingLookups: () => api.get('/community/facility-bookings/lookups'),
  facilityCharge: (facilityId) =>
    api.get('/community/facility-bookings/charge', p({ facilityId })),
  createFacilityBooking: (body) => api.post('/community/facility-bookings', body),
  cancelBooking: (id) => api.delete(`/community/facility-bookings/${id}`),
  visitors: () => api.get('/community/visitors'),
  visitor: (id) => api.get(`/community/visitors/${id}`),
  createVisitor: (body) => api.post('/community/visitors', body),
  updateVisitor: (id, body) => api.put(`/community/visitors/${id}`, body),
  checkoutVisitor: (id) => api.post(`/community/visitors/${id}/checkout`),
  removeVisitor: (id) => api.delete(`/community/visitors/${id}`),
  helpdesk: () => api.get('/community/helpdesk'),
  helpdeskTicket: (id) => api.get(`/community/helpdesk/${id}`),
  helpdeskStatuses: () => api.get('/community/helpdesk/statuses'),
  setHelpdeskStatus: (id, status) => api.put(`/community/helpdesk/${id}/status`, { status }),
  addHelpdeskComment: (id, body) => api.post(`/community/helpdesk/${id}/comments`, body),
  // NOC — the certificates the society has issued, and the requests members
  // have raised that lead to them.
  nocCertificates: (params) => api.get('/community/noc', p(params)),
  nocCertificate: (id) => api.get(`/community/noc/${id}`),
  /** Residents a certificate can be issued to — name, flat and building. */
  nocMembers: () => api.get('/community/noc/members'),
  /**
   * Issue a certificate directly, without a request behind it — for the member
   * who asked at the desk. The reply carries the serial the server allocated,
   * which the form cannot know in advance.
   */
  createNocCertificate: (body) => api.post('/community/noc', body),
  updateNocCertificate: (id, body) => api.put(`/community/noc/${id}`, body),
  removeNocCertificate: (id) => api.delete(`/community/noc/${id}`),
  nocRequests: (params) => api.get('/community/noc-requests', p(params)),
  /** Committee accounts that can be asked to decide, the caller included. */
  nocApproverOptions: () => api.get('/community/noc-requests/approvers'),
  /** One request together with who was asked to decide on it. */
  nocRequest: (id) => api.get(`/community/noc-requests/${id}`),
  createNocRequest: (body) => api.post('/community/noc-requests', body),
  /** The wording, editable only while the request is still pending. */
  saveNocDraft: (id, body) => api.put(`/community/noc-requests/${id}/draft`, body),
  /**
   * Send a request to the officers who sign the society's certificates.
   *
   * Who they are is worked out server-side from the accounts the society has
   * — a secretary and a chairman if it has both, the admin account if it has
   * neither — so there is nothing to pass. Re-sending is safe.
   */
  setNocApprovers: (id) => api.post(`/community/noc-requests/${id}/approvers`),
  /**
   * Approve or reject on behalf of the signed-in approver. Answering the last
   * outstanding approval issues the certificate, and the reply carries its
   * serial.
   */
  decideNocRequest: (id, approvalId, body) =>
    api.post(`/community/noc-requests/${id}/approvals/${approvalId}`, body),
  /** The letter is signed; give the member a collection appointment. */
  setNocReady: (id, body) => api.post(`/community/noc-requests/${id}/ready`, body),
  setNocCollected: (id, body) =>
    api.post(`/community/noc-requests/${id}/collected`, body),
  removeNocRequest: (id) => api.delete(`/community/noc-requests/${id}`),
  polls: () => api.get('/community/polls'),
  pollVotes: (id) => api.get(`/community/polls/${id}/votes`),
  createPoll: (body) => api.post('/community/polls', body),
  /** Cast a vote by clicking an option, as the legacy poll card did. */
  votePoll: (id, optionId) => api.post(`/community/polls/${id}/vote`, { optionId }),
  removePoll: (id) => api.delete(`/community/polls/${id}`),
  // Header bell and envelope — the alerts dropdown and unread count that
  // Site.Master rendered next to the profile menu.
  notifications: () => api.get('/community/notifications'),
  markNotificationSeen: (id) => api.put(`/community/notifications/${id}/seen`),
  messages: () => api.get('/community/messages'),
  messagesCount: () => api.get('/community/messages/count'),
};

/* ------------------------------------------------------------- reports */
export const reports = {
  dashboard: () => api.get('/reports/dashboard'),
  activity: () => api.get('/reports/activity'),
  expenseChart: (type) => api.get('/reports/expense-chart', p({ type })),
  incomeSplit: (to) => api.get('/reports/income-split', p({ to })),
  ownerLedger: (params) => api.get('/reports/owner-ledger', p(params)),
  agm: (from, to) => api.get('/reports/agm', { params: { from, to } }),
  incomeExpense: () => api.get('/reports/income-expense'),
  // printshop.aspx — shop maintenance filtered by payment method and date.
  shopMaintenance: (params) => api.get('/reports/shop-maintenance', p(params)),
  auditHeaders: () => api.get('/reports/audit/headers'),
  auditQuestions: () => api.get('/reports/audit/questions'),
  societyInfo: () => api.get('/reports/audit/society-info'),
  // items: [{ headerId, sequence }] — the dragged order, saved in one call.
  auditHeaderSequence: (items) => api.post('/reports/audit/headers/sequence', { items }),
  balanceSheet: () => api.get('/reports/balance-sheet'),
  saveBalanceHead: (body) => api.post('/reports/balance-sheet/heads', body),
  saveBalanceSubPoint: (body) => api.post('/reports/balance-sheet/sub-points', body),
  removeBalanceSubPoint: (id) => api.delete(`/reports/balance-sheet/sub-points/${id}`),
  // Removes the head and every sub-point under it, in one call.
  removeBalanceHead: (id) => api.delete(`/reports/balance-sheet/heads/${id}`),
  // items: [{ headId, sequence }] — both columns, in the order they were dropped.
  balanceHeadSequence: (items) => api.post('/reports/balance-sheet/heads/sequence', { items }),
};

/* ------------------------------------------------------------- village */
export const village = {
  /** Figures behind village_dashboard.aspx's cards and activity list. */
  dashboard: () => api.get('/village/dashboard'),
  /** v_announcement.aspx — its own table, not the society notice list. */
  announcements: (params) => api.get('/village/announcements', p(params)),
  createAnnouncement: (body) => api.post('/village/announcements', body),
  updateAnnouncement: (id, body) => api.put(`/village/announcements/${id}`, body),
  removeAnnouncement: (id) => api.delete(`/village/announcements/${id}`),
  houses: (params) => api.get('/village/houses', p(params)),
  createHouse: (body) => api.post('/village/houses', body),
  updateHouse: (id, body) => api.put(`/village/houses/${id}`, body),
  houseHistory: () => api.get('/village/houses/history'),
  owners: () => api.get('/village/owners'),
  createOwner: (body) => api.post('/village/owners', body),
  updateOwner: (id, body) => api.put(`/village/owners/${id}`, body),
  removeOwner: (id) => api.delete(`/village/owners/${id}`),
  houseTax: () => api.get('/village/house-tax'),
  houseTaxReceipts: () => api.get('/village/house-tax/receipts'),
  /** One payment and every bill it settled. */
  houseTaxReceipt: (id) => api.get(`/village/house-tax/receipts/${id}`),
  houseTaxPending: () => api.get('/village/house-tax/pending'),
  // Unpaid bills for one house: type 1 property, 2 water, 3 waste.
  houseTaxBills: (houseId, type) =>
    api.get('/village/house-tax/by-type', { params: { houseId, type, paid: false } }),
  payHouseTax: (body) => api.post('/village/house-tax/pay', body),
  waterTax: () => api.get('/village/water-tax'),
  rates: () => api.get('/village/rates'),
  saveRate: (body) => api.post('/village/rates', body),
  staff: () => api.get('/village/staff'),
  staffRoles: () => api.get('/village/staff/roles'),
  createStaff: (body) => api.post('/village/staff', body),
  updateStaff: (id, body) => api.put(`/village/staff/${id}`, body),
  removeStaff: (id) => api.delete(`/village/staff/${id}`),
  /** Billing settings — village_setting, one row per village. */
  settings: () => api.get('/village/settings'),
  saveSettings: (body) => api.put('/village/settings', body),
  /** Which charges apply to which house — house_charge. */
  houseCharges: () => api.get('/village/house-charges'),
  saveHouseCharge: (body) => api.put('/village/house-charges', body),
  /** Billing reports — what was billed, who owes, and what came in. */
  reportCollection: (params) => api.get('/village/reports/collection', p(params)),
  reportDefaulters: (params) => api.get('/village/reports/defaulters', p(params)),
  reportMonthly: (params) => api.get('/village/reports/monthly', p(params)),
  reportLedger: (houseId) => api.get(`/village/reports/ledger/${houseId}`),
  /** Government schemes the village runs. */
  schemes: () => api.get('/village/schemes'),
  createScheme: (body) => api.post('/village/schemes', body),
  updateScheme: (id, body) => api.put(`/village/schemes/${id}`, body),
  removeScheme: (id) => api.delete(`/village/schemes/${id}`),
  /** What a period's bills would come to, and raising them. */
  billRunPreview: (params) => api.get('/village/bill-run/preview', p(params)),
  runBills: (body) => api.post('/village/bill-run', body),
  /** The charges a village levies, and adding one of its own. */
  chargeTypes: () => api.get('/village/charge-types'),
  createChargeType: (body) => api.post('/village/charge-types', body),
  updateChargeType: (id, body) => api.put(`/village/charge-types/${id}`, body),
  removeChargeType: (id) => api.delete(`/village/charge-types/${id}`),
};
