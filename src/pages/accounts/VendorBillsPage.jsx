import { useCallback, useEffect, useMemo, useState } from 'react';
import { vendorBills } from '@/api/ownerExtras';
import { vendors } from '@/api/modules';
import DataGrid from '@/components/DataGrid.jsx';
import { ConfirmDialog, EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import {
  CheckboxField,
  FileUploadField,
  ModeSwitch,
  PageHeader,
  SelectField,
  StatCard,
  Tabs,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';

const money = (v) =>
  v == null ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

// Mirrors ddlSevice on VendorBill.aspx.
const SERVICE = { STAFF: 0, DAILY: 1, INVENTORY: 2, SERVICE: 3 };

const PAY_MODES = [
  { value: 'Cheque', label: 'Cheque' },
  { value: 'Online', label: 'Online' },
  { value: 'Cash', label: 'Cash' },
];

const EMPTY_BILL = {
  serviceType: '',
  billNumber: '',
  billDate: new Date().toISOString().slice(0, 10),
  vendorId: '',
  description: '',
  serviceCost: '',
  subtotal: '',
  taxAmount: '',
  totalAmount: '',
  notes: '',
};

const EMPTY_PAYMENT = {
  mode: 'Cheque',
  transactionRef: '',
  chequeNo: '',
  chequeDate: '',
  bankName: '',
  amount: '',
  remarks: '',
  filePath: '',
};

const EMPTY_VENDOR = {
  name: '',
  contactPerson: '',
  contactNo: '',
  email: '',
  gstNo: '',
  serviceType: '',
  address: '',
};

/**
 * Vendor bills — full parity with Society2024/VendorBill.aspx.
 *
 * That page combined four workflows behind one screen; they are kept together
 * here so the flow matches what users know:
 *   1. raise a bill, with the sub-form switching on service type
 *   2. quick-add a vendor without leaving the page
 *   3. pick approvers, then approve/reject
 *   4. record a payment in one of three modes
 */
export default function VendorBillsPage() {
  const [bills, setBills] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const [form, setForm] = useState(null); // create/edit bill
  const [detail, setDetail] = useState(null); // view bill
  const [vendorForm, setVendorForm] = useState(null); // quick-add vendor
  const [confirming, setConfirming] = useState(null);

  const [lookups, setLookups] = useState({
    vendors: [],
    staff: [],
    staffRoles: [],
    approvers: [],
    chargeHeads: [],
  });

  // Sub-form state for the create modal.
  const [selectedStaff, setSelectedStaff] = useState({}); // staff_id -> salary
  const [staffRoleFilter, setStaffRoleFilter] = useState('');
  const [items, setItems] = useState([]); // inventory line items
  const [payment, setPayment] = useState({ ...EMPTY_PAYMENT });
  const [approverIds, setApproverIds] = useState([]);
  const [formTab, setFormTab] = useState('details');

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await vendorBills.list();
      setBills(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    vendorBills
      .formData()
      .then(setLookups)
      .catch(() => {});
  }, [load]);

  const serviceType = Number(form?.serviceType);
  const isStaff = serviceType === SERVICE.STAFF;
  const isInventory = serviceType === SERVICE.INVENTORY;
  const needsVendor = serviceType === SERVICE.INVENTORY || serviceType === SERVICE.SERVICE;

  /** Staff filtered by the role dropdown, as ddlStaffType did. */
  const staffOptions = useMemo(() => {
    const all = lookups.staff ?? [];
    return staffRoleFilter ? all.filter((s) => String(s.role_id) === staffRoleFilter) : all;
  }, [lookups.staff, staffRoleFilter]);

  /** Totals recompute exactly as the legacy page did on each change. */
  const computed = useMemo(() => {
    let subtotal = 0;
    if (isStaff) {
      subtotal = Object.values(selectedStaff).reduce((s, v) => s + Number(v || 0), 0);
    } else if (isInventory) {
      subtotal = items.reduce((s, it) => s + Number(it.totalAmount || 0), 0);
    } else {
      subtotal = Number(form?.serviceCost || 0);
    }
    const tax = Number(form?.taxAmount || 0);
    return { subtotal, tax, total: subtotal + tax };
  }, [isStaff, isInventory, selectedStaff, items, form?.serviceCost, form?.taxAmount]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const openCreate = () => {
    setForm({ ...EMPTY_BILL });
    setSelectedStaff({});
    setItems([]);
    setPayment({ ...EMPTY_PAYMENT });
    setApproverIds([]);
    setStaffRoleFilter('');
    setFormTab('details');
    setError(null);
  };

  const toggleStaff = (staffId, salary) => {
    setSelectedStaff((prev) => {
      const next = { ...prev };
      if (staffId in next) delete next[staffId];
      else next[staffId] = salary ?? 0;
      return next;
    });
  };

  const addItem = () =>
    setItems((prev) => [...prev, { name: '', quantity: 1, unit: '', totalAmount: '', tax: '', warrantyMonths: '' }]);

  const setItemField = (index, key, value) =>
    setItems((prev) => prev.map((it, i) => (i === index ? { ...it, [key]: value } : it)));

  /** Same rule as IsPaymentDataFilled(): any one mode with a positive amount. */
  const paymentFilled = Number(payment.amount || 0) > 0;

  const validate = () => {
    if (!form.serviceType) return 'Select a service type';
    if (!form.billNumber.trim()) return 'Bill number is required';
    if (!form.billDate) return 'Bill date is required';
    if (isStaff && Object.keys(selectedStaff).length === 0) return 'Select at least one staff member';
    if (isStaff && !paymentFilled) {
      return 'Payment is mandatory for a staff payment — enter an amount';
    }
    if (needsVendor && !form.vendorId) return 'Select a vendor';
    if (isInventory && items.length === 0) return 'Add at least one item';
    if (computed.total <= 0) return 'The bill total must be greater than zero';
    return null;
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    const message = validate();
    if (message) {
      setError(new Error(message));
      return;
    }

    setBusy(true);
    setError(null);
    try {
      const vendorIds = isStaff ? Object.keys(selectedStaff) : [String(form.vendorId)];
      await vendorBills.create({
        serviceType: Number(form.serviceType),
        billNumber: form.billNumber,
        billDate: form.billDate,
        vendorIds,
        subtotal: computed.subtotal,
        taxAmount: computed.tax,
        totalAmount: computed.total,
        description: form.description,
        notes: form.notes,
        items: isInventory ? items : [],
        approverIds,
        payment: paymentFilled ? payment : undefined,
      });
      setForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const saveVendor = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await vendors.create(vendorForm);
      const fresh = await vendorBills.formData();
      setLookups(fresh);
      setVendorForm(null);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const openDetail = async (row) => {
    setDetail({ loading: true, bill: row });
    try {
      const data = await vendorBills.get(row.bill_id);
      setDetail({ loading: false, ...data });
    } catch (err) {
      setError(err);
      setDetail(null);
    }
  };

  const decide = async (approvalId, decision, remarks) => {
    setBusy(true);
    try {
      await vendorBills.decide(approvalId, { decision, remarks });
      if (detail?.bill) await openDetail(detail.bill);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const totals = useMemo(
    () => ({
      count: bills.length,
      billed: bills.reduce((s, b) => s + Number(b.total_amount || 0), 0),
      paid: bills.reduce((s, b) => s + Number(b.paid_amount || 0), 0),
      due: bills.reduce((s, b) => s + Number(b.remaining_amount || 0), 0),
    }),
    [bills],
  );

  const columns = [
    { key: 'bill_number', label: 'Bill no.' },
    { key: 'vendor_name', label: 'Vendor / staff' },
    { key: 'bill_date', label: 'Date', render: day },
    { key: 'total_amount', label: 'Total', align: 'right', render: money },
    { key: 'paid_amount', label: 'Paid', align: 'right', render: money },
    { key: 'remaining_amount', label: 'Outstanding', align: 'right', render: money },
    {
      key: 'payment_status',
      label: 'Payment',
      render: (v) => (
        <span
          className={`rounded px-2 py-0.5 text-xs font-medium ${
            v === 'Paid'
              ? 'bg-green-50 text-green-700'
              : v === 'Unpaid'
                ? 'bg-red-50 text-red-700'
                : 'bg-amber-50 text-amber-700'
          }`}
        >
          {v}
        </span>
      ),
    },
    { key: 'bill_status', label: 'Status' },
  ];

  return (
    <section>
      <PageHeader title="Vendor bills" subtitle={`${totals.count} bill(s)`}>
        <button type="button" className="btn-secondary" onClick={() => setVendorForm({ ...EMPTY_VENDOR })}>
          Add vendor
        </button>
        <button type="button" className="btn-primary" onClick={openCreate}>
          New bill
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Total billed" value={money(totals.billed)} />
        <StatCard label="Paid" value={money(totals.paid)} tone="positive" />
        <StatCard label="Outstanding" value={money(totals.due)} tone={totals.due > 0 ? 'negative' : 'default'} />
      </div>

      {!form && !detail ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={bills}
          idKey="bill_id"
          loading={loading}
          exportName="vendor-bills"
          emptyTitle="No vendor bills"
          emptyHint="Raise the first bill to get started."
          actions={(row) => (
            <>
              <button type="button" className="btn-secondary mr-2" onClick={() => openDetail(row)}>
                View
              </button>
              <button
                type="button"
                className="btn-danger"
                onClick={() =>
                  setConfirming({
                    title: 'Delete bill',
                    message: `Delete bill ${row.bill_number}?`,
                    run: () => vendorBills.remove(row.bill_id),
                  })
                }
              >
                Delete
              </button>
            </>
          )}
        />
      </div>

      {/* ---------------------------------------------------- create bill */}
      <Modal
        open={Boolean(form)}
        title="New vendor bill"
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="bill-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save bill'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="bill-form" onSubmit={onSubmit} noValidate>
            <Tabs
              tabs={[
                { id: 'details', label: 'Bill details' },
                { id: 'approvers', label: 'Approvers', count: approverIds.length },
                { id: 'payment', label: 'Payment' },
              ]}
              active={formTab}
              onChange={setFormTab}
              className="mb-4"
            />

            {formTab === 'details' ? (
              <div className="space-y-4">
                {/* Order follows VendorBill.aspx: bill number > bill date > service type. */}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <TextField
                      label="Bill number"
                      name="billNumber"
                      required
                      value={form.billNumber}
                      onChange={setField('billNumber')}
                    />
                    {isStaff ? (
                      // VendorBill.aspx built this for staff runs rather than
                      // asking for it: STAFF-{roleId}-{yyyyMM}-{HHmmss}.
                      <button
                        type="button"
                        className="mt-1 text-xs text-blue-600 hover:underline"
                        onClick={() => {
                          const d = form.billDate ? new Date(form.billDate) : new Date();
                          const stamp = new Date();
                          const pad = (n) => String(n).padStart(2, '0');
                          const yyyyMM = `${d.getFullYear()}${pad(d.getMonth() + 1)}`;
                          const hhmmss = `${pad(stamp.getHours())}${pad(stamp.getMinutes())}${pad(stamp.getSeconds())}`;
                          setForm((p) => ({
                            ...p,
                            billNumber: `STAFF-${staffRoleFilter || 0}-${yyyyMM}-${hhmmss}`,
                          }));
                        }}
                      >
                        Generate staff bill number
                      </button>
                    ) : null}
                  </div>
                  <TextField
                    label="Bill date"
                    name="billDate"
                    type="date"
                    required
                    value={form.billDate}
                    onChange={setField('billDate')}
                  />
                  <SelectField
                    label="Service type"
                    name="serviceType"
                    required
                    options={[
                      { value: '0', label: 'Staff Payment' },
                      { value: '1', label: 'Daily Expense' },
                      { value: '2', label: 'Vendor-Inventory Payment' },
                      { value: '3', label: 'Vendor-Service Payment' },
                    ]}
                    value={form.serviceType}
                    onChange={setField('serviceType')}
                  />
                  {needsVendor ? (
                    <SelectField
                      label="Vendor"
                      name="vendorId"
                      required
                      options={lookups.vendors}
                      valueKey="vendor_id"
                      labelKey="vendor_name"
                      value={form.vendorId}
                      onChange={setField('vendorId')}
                    />
                  ) : null}
                </div>

                {/* Staff payment sub-form */}
                {isStaff ? (
                  <div className="rounded-md border border-slate-200 p-3">
                    <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
                      <SelectField
                        label="Filter by role"
                        name="roleFilter"
                        className="w-56"
                        options={lookups.staffRoles}
                        valueKey="role_id"
                        labelKey="role"
                        placeholder="All roles"
                        value={staffRoleFilter}
                        onChange={(e) => setStaffRoleFilter(e.target.value)}
                      />
                      <p className="text-sm text-slate-600">
                        {Object.keys(selectedStaff).length} selected · {money(computed.subtotal)}
                      </p>
                    </div>

                    {staffOptions.length === 0 ? (
                      <EmptyState title="No staff found for this role" />
                    ) : (
                      <div className="max-h-64 overflow-y-auto">
                        <table className="min-w-full">
                          <thead>
                            <tr>
                              <th className="table-head w-10">Select</th>
                              <th className="table-head">Staff name</th>
                              <th className="table-head">Role</th>
                              <th className="table-head text-right">Salary</th>
                            </tr>
                          </thead>
                          <tbody>
                            {staffOptions.map((s) => {
                              const picked = s.staff_id in selectedStaff;
                              return (
                                <tr key={s.staff_id}>
                                  <td className="table-cell">
                                    <input
                                      type="checkbox"
                                      className="h-4 w-4 rounded border-slate-300"
                                      checked={picked}
                                      onChange={() => toggleStaff(s.staff_id, s.salary)}
                                      aria-label={`Select ${s.name}`}
                                    />
                                  </td>
                                  <td className="table-cell font-medium text-slate-800">{s.name}</td>
                                  <td className="table-cell">{s.role}</td>
                                  <td className="table-cell text-right">
                                    <input
                                      className="field-input w-28 text-right"
                                      type="number"
                                      step="0.01"
                                      disabled={!picked}
                                      value={picked ? selectedStaff[s.staff_id] : (s.salary ?? '')}
                                      onChange={(e) => {
                                        const { value } = e.target;
                                        setSelectedStaff((p) => ({ ...p, [s.staff_id]: value }));
                                      }}
                                      aria-label={`Salary for ${s.name}`}
                                    />
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    )}
                    <p className="mt-2 text-xs text-amber-700">
                      Payment details are mandatory for a staff payment. A salary already raised for the
                      same month will be rejected.
                    </p>
                  </div>
                ) : null}

                {/* Inventory line items */}
                {isInventory ? (
                  <div className="rounded-md border border-slate-200 p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <h3 className="text-sm font-semibold text-slate-800">Items</h3>
                      <button type="button" className="btn-secondary text-xs" onClick={addItem}>
                        Add item
                      </button>
                    </div>
                    {items.length === 0 ? (
                      <p className="py-4 text-sm text-slate-500">
                        Add the items received. Each becomes an inventory record.
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {items.map((it, i) => (
                          <div key={i} className="grid gap-2 sm:grid-cols-6">
                            <TextField
                              label="Item"
                              name={`it-name-${i}`}
                              className="sm:col-span-2"
                              value={it.name}
                              onChange={(e) => setItemField(i, 'name', e.target.value)}
                            />
                            <TextField
                              label="Qty"
                              name={`it-qty-${i}`}
                              type="number"
                              value={it.quantity}
                              onChange={(e) => setItemField(i, 'quantity', e.target.value)}
                            />
                            <TextField
                              label="Unit"
                              name={`it-unit-${i}`}
                              value={it.unit}
                              onChange={(e) => setItemField(i, 'unit', e.target.value)}
                            />
                            <TextField
                              label="Amount"
                              name={`it-amt-${i}`}
                              type="number"
                              value={it.totalAmount}
                              onChange={(e) => setItemField(i, 'totalAmount', e.target.value)}
                            />
                            <div className="flex items-end">
                              <button
                                type="button"
                                className="btn-danger w-full"
                                onClick={() => setItems((p) => p.filter((_, x) => x !== i))}
                              >
                                Remove
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ) : null}

                {/* Daily expense / service */}
                {serviceType === SERVICE.DAILY || serviceType === SERVICE.SERVICE ? (
                  <div className="grid gap-4 sm:grid-cols-2">
                    <TextAreaField
                      label="Service description"
                      name="description"
                      className="sm:col-span-2"
                      value={form.description}
                      onChange={setField('description')}
                    />
                    <TextField
                      label="Service cost"
                      name="serviceCost"
                      type="number"
                      step="0.01"
                      required
                      value={form.serviceCost}
                      onChange={setField('serviceCost')}
                    />
                  </div>
                ) : null}

                <div className="grid gap-4 border-t border-slate-200 pt-4 sm:grid-cols-3">
                  <TextField label="Subtotal" name="subtotal" value={money(computed.subtotal)} readOnly />
                  <TextField
                    label="Tax"
                    name="taxAmount"
                    type="number"
                    step="0.01"
                    value={form.taxAmount}
                    onChange={setField('taxAmount')}
                  />
                  <TextField label="Grand total" name="total" value={money(computed.total)} readOnly />
                </div>

                <TextAreaField label="Notes" name="notes" rows={2} value={form.notes} onChange={setField('notes')} />
              </div>
            ) : null}

            {formTab === 'approvers' ? (
              <div>
                {(lookups.approvers ?? []).length === 0 ? (
                  <EmptyState title="No approvers available" hint="Add committee members first." />
                ) : (
                  <div className="space-y-2">
                    {lookups.approvers.map((a) => (
                      <CheckboxField
                        key={a.user_id}
                        label={a.name}
                        checked={approverIds.includes(a.user_id)}
                        onChange={() =>
                          setApproverIds((p) =>
                            p.includes(a.user_id) ? p.filter((x) => x !== a.user_id) : [...p, a.user_id],
                          )
                        }
                      />
                    ))}
                  </div>
                )}
              </div>
            ) : null}

            {formTab === 'payment' ? (
              <div className="space-y-4">
                <ModeSwitch
                  label="Payment mode"
                  options={PAY_MODES}
                  value={payment.mode}
                  onChange={(mode) => setPayment((p) => ({ ...p, mode }))}
                />

                <div className="grid gap-4 sm:grid-cols-2">
                  {payment.mode === 'Online' ? (
                    <TextField
                      label="Transaction reference"
                      name="txnRef"
                      value={payment.transactionRef}
                      onChange={(e) => setPayment((p) => ({ ...p, transactionRef: e.target.value }))}
                    />
                  ) : null}
                  {payment.mode === 'Cheque' ? (
                    <>
                      <TextField
                        label="Cheque number"
                        name="cheqNo"
                        value={payment.chequeNo}
                        onChange={(e) => setPayment((p) => ({ ...p, chequeNo: e.target.value }))}
                      />
                      <TextField
                        label="Cheque date"
                        name="cheqDate"
                        type="date"
                        value={payment.chequeDate}
                        onChange={(e) => setPayment((p) => ({ ...p, chequeDate: e.target.value }))}
                      />
                      <TextField
                        label="Bank name"
                        name="bank"
                        value={payment.bankName}
                        onChange={(e) => setPayment((p) => ({ ...p, bankName: e.target.value }))}
                      />
                    </>
                  ) : null}
                  <TextField
                    label="Amount"
                    name="payAmt"
                    type="number"
                    step="0.01"
                    required={isStaff}
                    value={payment.amount}
                    onChange={(e) => setPayment((p) => ({ ...p, amount: e.target.value }))}
                    hint={isStaff ? 'Mandatory for a staff payment' : undefined}
                  />
                  <TextAreaField
                    label="Remarks"
                    name="payRemarks"
                    rows={2}
                    className="sm:col-span-2"
                    value={payment.remarks}
                    onChange={(e) => setPayment((p) => ({ ...p, remarks: e.target.value }))}
                  />
                  <FileUploadField
                    label="Attachment"
                    category="vendor-bills"
                    className="sm:col-span-2"
                    onUploaded={(f) => f && setPayment((p) => ({ ...p, filePath: f.path }))}
                  />
                </div>
              </div>
            ) : null}

            <div className="mt-4">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      {/* -------------------------------------------------- quick-add vendor */}
      <Modal
        open={Boolean(vendorForm)}
        title="Add vendor"
        onClose={() => setVendorForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setVendorForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="vendor-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save vendor'}
            </button>
          </>
        }
      >
        {vendorForm ? (
          <form id="vendor-form" onSubmit={saveVendor} className="grid gap-4 sm:grid-cols-2" noValidate>
            {[
              ['name', 'Vendor name', true],
              ['contactPerson', 'Contact person', false],
              ['contactNo', 'Contact number', false],
              ['email', 'Email', false],
              ['gstNo', 'GST number', false],
              ['serviceType', 'Service type', false],
            ].map(([key, label, required]) => (
              <TextField
                key={key}
                label={label}
                name={key}
                required={required}
                value={vendorForm[key]}
                onChange={(e) => {
                  const { value } = e.target;
                  setVendorForm((p) => ({ ...p, [key]: value }));
                }}
              />
            ))}
            <TextAreaField
              label="Address"
              name="address"
              rows={2}
              className="sm:col-span-2"
              value={vendorForm.address}
              onChange={(e) => {
                const { value } = e.target;
                setVendorForm((p) => ({ ...p, address: value }));
              }}
            />
            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      {/* ------------------------------------------------------ bill detail */}
      <Modal
        open={Boolean(detail)}
        title={`Bill ${detail?.bill?.bill_number ?? ''}`}
        onClose={() => setDetail(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
            Close
          </button>
        }
      >
        {detail?.loading ? (
          <Spinner />
        ) : detail ? (
          <div className="space-y-5">
            <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm sm:grid-cols-3">
              {[
                ['Vendor / staff', detail.bill?.vendor_name],
                ['Bill date', day(detail.bill?.bill_date)],
                ['Subtotal', money(detail.bill?.subtotal)],
                ['Tax', money(detail.bill?.tax_amount)],
                ['Total', money(detail.bill?.total_amount)],
                ['Status', detail.bill?.bill_status],
              ].map(([label, value]) => (
                <div key={label}>
                  <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
                  <dd className="mt-0.5 text-slate-800">{value ?? '—'}</dd>
                </div>
              ))}
            </dl>

            {detail.items?.length ? (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Items</h3>
                <table className="min-w-full">
                  <thead>
                    <tr>
                      <th className="table-head">Item</th>
                      <th className="table-head">Qty</th>
                      <th className="table-head text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.items.map((it) => (
                      <tr key={it.item_id}>
                        <td className="table-cell font-medium text-slate-800">{it.item_name}</td>
                        <td className="table-cell">{it.quantity}</td>
                        <td className="table-cell text-right">{money(it.total_amount)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : null}

            <div>
              <h3 className="mb-2 text-sm font-semibold text-slate-800">Approvals</h3>
              {detail.approvals?.length ? (
                <table className="min-w-full">
                  <thead>
                    <tr>
                      <th className="table-head">Approver</th>
                      <th className="table-head">Status</th>
                      <th className="table-head">Date</th>
                      <th className="table-head sr-only">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.approvals.map((a) => (
                      <tr key={a.approval_id}>
                        <td className="table-cell font-medium text-slate-800">{a.name}</td>
                        <td className="table-cell">
                          {Number(a.approval_status) === 2
                            ? 'Approved'
                            : Number(a.approval_status) === 4
                              ? 'Rejected'
                              : 'Pending'}
                        </td>
                        <td className="table-cell">{day(a.approval_date)}</td>
                        <td className="table-cell text-right">
                          {Number(a.approval_status) === 1 ? (
                            <>
                              <button
                                type="button"
                                className="btn-secondary mr-2"
                                disabled={busy}
                                onClick={() => decide(a.approval_id, 'approve')}
                              >
                                Approve
                              </button>
                              <button
                                type="button"
                                className="btn-danger"
                                disabled={busy}
                                onClick={() => {
                                  const remarks = window.prompt('Reason for rejection (required):');
                                  if (remarks) decide(a.approval_id, 'reject', remarks);
                                }}
                              >
                                Reject
                              </button>
                            </>
                          ) : null}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <p className="text-sm text-slate-500">No approvers assigned.</p>
              )}
            </div>

            {detail.payments?.length ? (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Payments</h3>
                <table className="min-w-full">
                  <thead>
                    <tr>
                      <th className="table-head">Payment no.</th>
                      <th className="table-head">Date</th>
                      <th className="table-head">Mode</th>
                      <th className="table-head text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.payments.map((p) => (
                      <tr key={p.payment_id}>
                        <td className="table-cell font-medium text-slate-800">{p.payment_no}</td>
                        <td className="table-cell">{day(p.payment_date)}</td>
                        <td className="table-cell">{p.pay_mode}</td>
                        <td className="table-cell text-right">{money(p.paid_amount)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : null}

            <ErrorNotice error={error} />
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
          } catch (err) {
            setError(err);
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
