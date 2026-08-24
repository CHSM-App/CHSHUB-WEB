import { useCallback, useEffect, useMemo, useState } from 'react';
import { vendorBills } from '@/api/ownerExtras';
import { vendors } from '@/api/modules';
import { useOptionalUser } from '@/auth/AuthContext.jsx';
import DataGrid from '@/components/DataGrid.jsx';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  FormErrorSummary,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import {
  CheckboxField,
  FileUploadField,
  ModeSwitch,
  PageHeader,
  SelectField,
  StatCard,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

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

// VendorBill.aspx's four service types, in its order. The value is what the
// SP stores in service_type.
const SERVICE_TYPES = [
  { value: '0', label: 'Staff Payment' },
  { value: '1', label: 'Daily Expense' },
  { value: '2', label: 'Vendor-Inventory Payment' },
  { value: '3', label: 'Vendor-Service Payment' },
];

/** Bill-number prefix per service type, so each kind is told apart at a glance. */
const BILL_PREFIX = {
  [SERVICE.STAFF]: 'STAFF',
  [SERVICE.DAILY]: 'EXP',
  [SERVICE.INVENTORY]: 'INV',
  [SERVICE.SERVICE]: 'SRV',
};

/**
 * A bill number for a service type: PREFIX-YYYYMM-HHMMSS.
 *
 * The legacy page only offered this for staff bills, and only on demand. The
 * shape is kept — month from the bill date, time from now, which is what made
 * repeated numbers unlikely — and applied to every type.
 */
function generateBillNumber(serviceTypeValue, billDate) {
  const prefix = BILL_PREFIX[Number(serviceTypeValue)];
  if (!prefix) return '';
  const pad = (n) => String(n).padStart(2, '0');
  const d = billDate ? new Date(billDate) : new Date();
  const when = Number.isNaN(d.getTime()) ? new Date() : d;
  const now = new Date();
  return [
    prefix,
    `${when.getFullYear()}${pad(when.getMonth() + 1)}`,
    `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`,
  ].join('-');
}

const EMPTY_PAYMENT = {
  // No mode until one is picked — VendorBill.aspx opened with all three
  // payment panels hidden and revealed one on the mode button.
  mode: '',
  transactionRef: '',
  chequeNo: '',
  chequeDate: '',
  bankName: '',
  amount: '',
  remarks: '',
  filePath: '',
};

/** Approval status codes, as UPDATE_STATUS writes them. */
const approvalLabel = (v) =>
  Number(v) === 2 ? 'Approved' : Number(v) === 4 ? 'Rejected' : 'Pending';

/** True when a bill number looks like one this page stamped. */
function isGeneratedBillNumber(value) {
  const prefixes = Object.values(BILL_PREFIX).join('|');
  return new RegExp(`^(${prefixes})-\\d{6}-\\d{6}$`).test(String(value ?? '').trim());
}

/**
 * One item line's amount: quantity × unit price, plus that line's tax.
 * The same expression the legacy items grid evaluated per row.
 */
function lineTotal(item) {
  const base = Number(item?.quantity || 0) * Number(item?.purchaseCost || 0);
  return base + (base * Number(item?.tax || 0)) / 100;
}

/** Escaped because every value below is user-entered. */
const esc = (v) =>
  String(v ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

/**
 * Opens a printable copy of a bill — header, items and approvals.
 *
 * Rendered into a popup rather than printing the page, so the surrounding app
 * chrome and the modal's own buttons stay out of the printout.
 */
function printBill(detail) {
  const bill = detail?.bill ?? {};
  const items = detail?.items ?? [];
  const approvals = detail?.approvals ?? [];
  const payments = detail?.payments ?? [];

  const summary = [
    ['Bill number', bill.bill_number],
    ['Bill date', day(bill.bill_date)],
    ['Vendor / staff', bill.vendor_name],
    ['Subtotal', money(bill.subtotal)],
    ['Tax', money(bill.tax_amount)],
    ['Total', money(bill.total_amount)],
    ['Paid', money(bill.paid_amount)],
    ['Outstanding', money(bill.remaining_amount)],
    ['Status', bill.bill_status],
  ];

  const win = window.open('', '_blank', 'width=900,height=900');
  if (!win) {
    window.alert('The print window was blocked. Allow pop-ups for this site and try again.');
    return;
  }

  const itemRows = items
    .map(
      (it) => `<tr>
        <td>${esc(it.item_name)}</td>
        <td class="r">${esc(it.quantity)}</td>
        <td class="r">${esc(money(it.purchase_cost))}</td>
        <td class="r">${esc(it.tax ?? '—')}</td>
        <td class="r">${it.warranty ? esc(it.warranty) + ' mo' : '—'}</td>
        <td class="r">${esc(money(it.total_amount))}</td>
      </tr>`,
    )
    .join('');

  const approvalRows = approvals
    .map(
      (a) => `<tr>
        <td>${esc(a.name)}</td>
        <td>${esc(approvalLabel(a.approval_status))}</td>
        <td>${esc(a.approval_date ? day(a.approval_date) : '—')}</td>
        <td>${esc(a.remarks || '—')}</td>
      </tr>`,
    )
    .join('');

  // Cheque and online payments each carry their own reference; cash has none.
  const paymentRows = payments
    .map(
      (p) => `<tr>
        <td>${esc(p.payment_no)}</td>
        <td>${esc(day(p.payment_date))}</td>
        <td>${esc(p.pay_mode ?? '—')}</td>
        <td>${esc(p.cheque_no || p.transaction_ref || '—')}</td>
        <td class="r">${esc(money(p.paid_amount))}</td>
      </tr>`,
    )
    .join('');

  win.document.write(`<!doctype html><html><head><title>Bill ${esc(bill.bill_number)}</title>
<style>
  body { font-family: system-ui, sans-serif; color: #1a1a1a; padding: 32px; }
  h1 { color: #1f2937; font-size: 20px; margin: 0 0 20px; }
  h2 { font-size: 14px; margin: 24px 0 8px; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #e3e6f0; padding: 6px 10px; text-align: left; font-size: 13px; }
  th { background: #f8f9fa; font-weight: 600; }
  td.r, th.r { text-align: right; }
  dl { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px 16px; margin: 0; }
  dt { font-size: 11px; text-transform: uppercase; color: #6c757d; }
  dd { margin: 2px 0 0; font-size: 13px; }
</style></head><body>
<h1>Vendor Bill</h1>
<dl>${summary.map(([k, v]) => `<div><dt>${esc(k)}</dt><dd>${esc(v ?? '—')}</dd></div>`).join('')}</dl>
${
  itemRows
    ? `<h2>Items</h2><table><thead><tr><th>Item</th><th class="r">Qty</th><th class="r">Unit price</th>
       <th class="r">Tax %</th><th class="r">Warranty</th><th class="r">Amount</th></tr></thead>
       <tbody>${itemRows}</tbody></table>`
    : ''
}
${
  approvalRows
    ? `<h2>Approvals</h2><table><thead><tr><th>Approver</th><th>Status</th><th>Date</th><th>Reason</th></tr></thead>
       <tbody>${approvalRows}</tbody></table>`
    : ''
}
${
  paymentRows
    ? `<h2>Payments</h2><table><thead><tr><th>Payment no.</th><th>Date</th><th>Mode</th>
       <th>Reference</th><th class="r">Amount</th></tr></thead>
       <tbody>${paymentRows}</tbody></table>`
    : ''
}
</body></html>`);
  win.document.close();
  win.focus();
  win.print();
}

/** A titled block on the single-page bill form. */
function FormSection({ title, subtitle, className = '', children }) {
  return (
    <section className="border-t border-slate-200 pt-4 first:border-0 first:pt-0">
      <header className="mb-3 flex items-baseline justify-between gap-3">
        <h3 className="text-sm font-semibold text-slate-800">{title}</h3>
        {subtitle ? <p className="text-xs text-slate-500">{subtitle}</p> : null}
      </header>
      <div className={className}>{children}</div>
    </section>
  );
}

/*
 * What a payment must carry, by mode. Cash needs nothing beyond the amount;
 * the other two are only traceable if their identifying details are there —
 * a cheque with no number cannot be matched to a bank statement, and an
 * online transfer with no reference cannot be found at all.
 *
 * Shared by the create form and the Pay dialog, so both ask the same thing.
 */
const PAYMENT_FIELDS_BY_MODE = {
  Online: [{ name: 'transactionRef', label: 'Transaction reference', required: true }],
  Cheque: [
    { name: 'chequeNo', label: 'Cheque number', required: true },
    { name: 'chequeDate', label: 'Cheque date', required: true },
    { name: 'bankName', label: 'Bank name', required: true },
  ],
};

/** The complaints a payment has, or an empty object when it is complete. */
function validatePayment(payment) {
  const fields = PAYMENT_FIELDS_BY_MODE[payment?.mode];
  if (!fields) return {};
  return validateFields(fields, payment);
}

/**
 * Cheque / online / cash inputs, shared by the create form's payment section
 * and the Pay dialog. VendorBill.aspx used the same three panels in both.
 */
function PaymentFields({
  payment,
  setPayment,
  amountRequired,
  amountHint,
  amountMax,
  idPrefix = '',
  errors = {},
  clearError,
}) {
  const set = (key) => (e) => {
    const { value } = e.target;
    setPayment((p) => ({ ...p, [key]: value }));
    // The complaint goes as soon as it is being answered.
    clearError?.(key);
  };
  // TextField derives its input id from `name`, so the create form's payment
  // tab and the Pay dialog would otherwise share ids while both are mounted —
  // and a label would point at whichever input rendered first.
  const n = (base) => `${idPrefix}${base}`;

  return (
    <div className="space-y-4">
      <ModeSwitch
        label="Payment mode"
        options={PAY_MODES}
        value={payment.mode}
        onChange={(mode) => {
          setPayment((p) => ({ ...p, mode }));
          // Switching mode swaps the inputs, so the old mode's complaints go
          // with them rather than hanging over boxes that are no longer shown.
          clearError?.('transactionRef');
          clearError?.('chequeNo');
          clearError?.('chequeDate');
          clearError?.('bankName');
        }}
      />

      {!payment.mode ? (
        <p className="text-sm text-slate-500">Pick a payment mode to enter the details.</p>
      ) : null}

      <div className={payment.mode ? 'grid gap-4 sm:grid-cols-2' : 'hidden'}>
        {payment.mode === 'Online' ? (
          <TextField
            label="Transaction reference"
            data-field="transactionRef"
            name={n('txnRef')}
            required
            error={errors.transactionRef}
            value={payment.transactionRef}
            onChange={set('transactionRef')}
          />
        ) : null}
        {payment.mode === 'Cheque' ? (
          <>
            <TextField
              label="Cheque number"
              data-field="chequeNo"
              name={n('cheqNo')}
              required
              error={errors.chequeNo}
              value={payment.chequeNo}
              onChange={set('chequeNo')}
            />
            <TextField
              label="Cheque date"
              data-field="chequeDate"
              name={n('cheqDate')}
              type="date"
              required
              error={errors.chequeDate}
              value={payment.chequeDate}
              onChange={set('chequeDate')}
            />
            <TextField
              label="Bank name"
              data-field="bankName"
              name={n('bank')}
              required
              error={errors.bankName}
              value={payment.bankName}
              onChange={set('bankName')}
            />
          </>
        ) : null}
        <TextField
          label="Amount"
          name={n('payAmt')}
          type="number"
          step="0.01"
          max={amountMax}
          required={amountRequired}
          value={payment.amount}
          onChange={set('amount')}
          hint={amountHint}
        />
        <TextAreaField
          label="Remarks"
          name={n('payRemarks')}
          rows={2}
          className="sm:col-span-2"
          value={payment.remarks}
          onChange={set('remarks')}
        />
        <FileUploadField
          label="Attachment"
          category="vendor-bills"
          className="sm:col-span-2"
          onUploaded={(f) => f && setPayment((p) => ({ ...p, filePath: f.path }))}
        />
      </div>
    </div>
  );
}

const EMPTY_VENDOR = {
  name: '',
  contactPerson: '',
  contactNo: '',
  email: '',
  gstNo: '',
  serviceType: '',
  address: '',
};

/*
 * The quick-add vendor form, in the shape validateFields expects. It is also
 * what the dialog renders, so the boxes and the rules cannot drift apart.
 *
 * Nothing checked this form at all — not even the starred vendor name, which
 * saved blank — so the contact number and e-mail took any text.
 */
const VENDOR_FIELDS = [
  { name: 'name', label: 'Vendor name', required: true },
  { name: 'contactPerson', label: 'Contact person' },
  { name: 'contactNo', label: 'Contact number', phone: true, digits: true, maxLength: 10 },
  { name: 'email', label: 'Email', type: 'email' },
  { name: 'gstNo', label: 'GST number' },
  { name: 'serviceType', label: 'Service type' },
];

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
/*
 * The empty-checks that can actually fail, in the shape validateFields
 * expects.
 *
 * Service type, bill number and bill date are deliberately absent: the Save
 * button is not rendered until a service type is picked, picking one fills the
 * bill number, and the date defaults to today — so none of the three can reach
 * a submit empty, and listing them would be validation that never fires.
 *
 * Vendor can. It is asked for on Daily, Inventory and Service bills and left
 * out of a staff run, so it carries the same showIf the sub-form does.
 */
const BILL_FIELDS = [
  {
    name: 'vendorId',
    label: 'Vendor name',
    type: 'select',
    required: true,
    showIf: (f) => [SERVICE.DAILY, SERVICE.INVENTORY, SERVICE.SERVICE].includes(Number(f.serviceType)),
  },
];

export default function VendorBillsPage() {
  const [bills, setBills] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const [form, setForm] = useState(null); // create/edit bill
  const [detail, setDetail] = useState(null); // view bill
  const [vendorForm, setVendorForm] = useState(null); // quick-add vendor
  const [confirming, setConfirming] = useState(null);
  const toast = useToast();
  // Whose decisions these are: an approval may only be answered by the
  // approver it was asked of.
  const user = useOptionalUser();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  // The payment section's own complaints, kept apart from the bill's because
  // the Pay dialog has a payment but no bill fields.
  const [paymentErrors, setPaymentErrors] = useState({});
  const [payErrors, setPayErrors] = useState({});
  // The quick-add vendor dialog's own, kept apart for the same reason.
  const [vendorErrors, setVendorErrors] = useState({});

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
  // The Pay dialog's own state, so it cannot disturb the create form's tab.
  const [paying, setPaying] = useState(null);
  const [payForm, setPayForm] = useState({ ...EMPTY_PAYMENT });
  const [approverIds, setApproverIds] = useState([]);
  const [pickingApprovers, setPickingApprovers] = useState(false);

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
  // Which sections a bill shows, from ddlSevice_SelectedIndexChanged:
  //   0 Staff     — staff list + payment
  //   1 Daily     — vendor + items + approvers + payment
  //   2 Inventory — same as Daily
  //   3 Service   — vendor + service description + payment
  // Daily Expense was treated as vendor-less here, so it offered neither the
  // vendor nor the line items the legacy form asked for.
  const hasItems = serviceType === SERVICE.DAILY || serviceType === SERVICE.INVENTORY;
  const isInventory = hasItems;
  const needsVendor =
    serviceType === SERVICE.DAILY ||
    serviceType === SERVICE.INVENTORY ||
    serviceType === SERVICE.SERVICE;
  const hasApprovers = serviceType === SERVICE.DAILY || serviceType === SERVICE.INVENTORY;
  const isService = serviceType === SERVICE.SERVICE;

  /** The picked vendor's row, for the read-only GST box beside it. */
  const selectedVendor = useMemo(
    () => (lookups.vendors ?? []).find((v) => String(v.vendor_id) === String(form?.vendorId)),
    [lookups.vendors, form?.vendorId],
  );

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
      subtotal = items.reduce((s, it) => s + lineTotal(it), 0);
    } else {
      subtotal = Number(form?.serviceCost || 0);
    }
    const tax = Number(form?.taxAmount || 0);
    return { subtotal, tax, total: subtotal + tax };
  }, [isStaff, isInventory, selectedStaff, items, form?.serviceCost, form?.taxAmount]);

  const setField = (key) => (e) => {
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  /**
   * Switching service type re-stamps the bill number for the new type.
   *
   * Only when the current number is one this page generated — recognised by
   * the PREFIX-YYYYMM-HHMMSS shape. A number typed in, or one off a
   * supplier's invoice, is left alone. Without this a bill switched from
   * Staff to Inventory kept its STAFF- number.
   */
  const changeServiceType = (e) => {
    const { value } = e.target;
    setForm((p) => {
      const generated = !p.billNumber || isGeneratedBillNumber(p.billNumber);
      return {
        ...p,
        serviceType: value,
        billNumber: generated ? generateBillNumber(value, p.billDate) : p.billNumber,
      };
    });
  };

  const openCreate = () => {
    // A fresh dialog must not inherit the last one's complaints.
    setFieldErrors({});
    setPaymentErrors({});
    setForm({ ...EMPTY_BILL });
    setSelectedStaff({});
    setItems([]);
    setPayment({ ...EMPTY_PAYMENT });
    setApproverIds([]);
    setStaffRoleFilter('');
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
    setItems((prev) => [
      ...prev,
      { name: '', quantity: 1, unit: '', purchaseCost: '', tax: '', warrantyMonths: '' },
    ]);

  const setItemField = (index, key, value) =>
    setItems((prev) => prev.map((it, i) => (i === index ? { ...it, [key]: value } : it)));

  /** Same rule as IsPaymentDataFilled(): a mode picked, with a positive amount. */
  const paymentFilled = Boolean(payment.mode) && Number(payment.amount || 0) > 0;

  /*
   * Cross-field rules only. The three plain empty-checks moved to BILL_FIELDS
   * so they report against the box at fault rather than one at a time.
   */
  const validate = () => {
    if (isStaff && Object.keys(selectedStaff).length === 0) return 'Select at least one staff member';
    if (isStaff && !paymentFilled) {
      return 'Payment is mandatory for a staff payment — pick a mode and enter an amount';
    }
    // An amount with no mode would be dropped rather than saved, so it is
    // caught here instead of silently going nowhere.
    if (!payment.mode && Number(payment.amount || 0) > 0) {
      return 'Pick a payment mode for the amount entered';
    }
    if (isInventory && items.length === 0) return 'Add at least one item';
    if (computed.total <= 0) return 'The bill total must be greater than zero';
    return null;
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    const missing = validateFields(BILL_FIELDS, form);
    setFieldErrors(missing);
    // The payment section is optional here — but once a mode is picked, its
    // details are not.
    const payMissing = validatePayment(payment);
    setPaymentErrors(payMissing);
    if (Object.keys(missing).length || Object.keys(payMissing).length) {
      setError(null);
      if (Object.keys(missing).length) focusFirstInvalid(BILL_FIELDS, missing);
      return;
    }
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
        // The API stores a per-item total, which is derived here rather than
        // typed — see lineTotal.
        items: hasItems ? items.map((it) => ({ ...it, totalAmount: lineTotal(it) })) : [],
        approverIds,
        payment: paymentFilled ? payment : undefined,
      });
      setForm(null);
      await load();
      toast.success('Vendor bill saved successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error('The bill could not be saved. Please check the form and try again.');
    } finally {
      setBusy(false);
    }
  };

  /*
   * Opening and closing both drop the complaints, so a dialog dismissed with
   * errors up does not reopen still showing them.
   */
  const openVendorForm = () => {
    setVendorErrors({});
    setVendorForm({ ...EMPTY_VENDOR });
  };
  const closeVendorForm = () => {
    setVendorErrors({});
    setVendorForm(null);
  };

  const saveVendor = async (event) => {
    event.preventDefault();

    // The form carries noValidate, so the asterisk on Vendor name was the only
    // sign it was mandatory and an empty save wrote a blank vendor.
    const missing = validateFields(VENDOR_FIELDS, vendorForm);
    setVendorErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(VENDOR_FIELDS, missing);
      return;
    }

    setBusy(true);
    setError(null);
    try {
      await vendors.create(vendorForm);
      const fresh = await vendorBills.formData();
      setLookups(fresh);
      setVendorForm(null);
      toast.success('Vendor added successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error('The vendor could not be saved. Please try again.');
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

  /** VendorBill.aspx's Pay button — settle an outstanding bill. */
  const openPay = (row) => {
    setError(null);
    setPayErrors({});
    setPaying(row);
    // The legacy modal opened with the balance already filled in, which is
    // what is being paid in nearly every case.
    setPayForm({ ...EMPTY_PAYMENT, amount: String(row.remaining_amount ?? '') });
  };

  const submitPay = async (event) => {
    event.preventDefault();
    const amount = Number(payForm.amount || 0);
    const outstanding = Number(paying.remaining_amount ?? 0);
    if (!payForm.mode) {
      setError(new Error('Pick a payment mode'));
      return;
    }

    /*
     * The amount is checked before the mode's own details: paying more than is
     * outstanding is the more consequential mistake, and reporting a missing
     * cheque number first would hide it behind a smaller problem.
     */
    if (amount <= 0) {
      setError(new Error('Enter the amount being paid'));
      return;
    }
    if (amount > outstanding) {
      setError(new Error(`That is more than the ${money(outstanding)} outstanding on this bill`));
      return;
    }

    // A cheque or transfer is only traceable with its own details — a cheque
    // with no number cannot be matched to a bank statement. Cash needs none.
    const payMissing = validatePayment(payForm);
    setPayErrors(payMissing);
    if (Object.keys(payMissing).length) {
      setError(null);
      return;
    }

    setBusy(true);
    setError(null);
    try {
      await vendorBills.pay(paying.bill_id, payForm);
      setPaying(null);
      await load();
      // Money leaving the society account — worth stating plainly.
      toast.success('Payment recorded against the bill.', { title: 'Payment saved' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The payment could not be recorded. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  const decide = async (approvalId, decision, remarks) => {
    setBusy(true);
    try {
      await vendorBills.decide(detail.bill.bill_id, approvalId, { decision, remarks });
      if (detail?.bill) await openDetail(detail.bill);
      await load();
      toast.success(`Bill ${String(decision).toLowerCase() === 'reject' ? 'rejected' : 'approved'}.`, {
        title: 'Decision saved',
      });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The decision could not be saved. Please try again.');
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
        <button type="button" className="btn-secondary" onClick={openVendorForm}>
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

      {!form && !detail && !paying ? <ErrorNotice error={error} onRetry={load} /> : null}

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
              {/* VendorBill.aspx showed Pay only while something was owed —
                  and never on a bill the society rejected (status 4), which
                  the API refuses outright. */}
              {Number(row.remaining_amount ?? 0) > 0 && Number(row.status) !== 4 ? (
                <button type="button" className="btn-primary" onClick={() => openPay(row)}>
                  Pay
                </button>
              ) : null}
              <button type="button" className="btn-secondary" onClick={() => openDetail(row)}>
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
        // Wider than the default: an item line carries seven controls, and at
        // max-w-2xl they wrapped onto a second row however narrow each was cut.
        maxWidth="max-w-5xl"
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Cancel
            </button>
            {/* Nothing can be saved until the service type is known — it
                decides which sub-form the bill even has. */}
            {form?.serviceType ? (
              <button type="submit" form="bill-form" className="btn-primary" disabled={busy}>
                {busy ? 'Saving…' : 'Save bill'}
              </button>
            ) : null}
          </>
        }
      >
        {form ? (
          <form id="bill-form" onSubmit={onSubmit} noValidate className="space-y-5">
            {/* The payment section belongs to this form, so its complaints
                are counted here as well — otherwise the summary said the form
                was clean while a cheque box below it was still marked. */}
            <FormErrorSummary count={countErrors(fieldErrors) + countErrors(paymentErrors)} />

            {!form.serviceType ? (
              <div className="space-y-4">
                <SelectField
                  label="Service type"
                  name="serviceType"
                  required
                  options={SERVICE_TYPES}
                  value={form.serviceType}
                  onChange={changeServiceType}
                  hint="Pick what this bill is for — the rest of the form follows from it."
                />
              </div>
            ) : null}

            {/* VendorBill.aspx laid bill details, approvers and payment out on
                one page rather than behind tabs — a bill is raised in a single
                pass, and hiding the approver or payment section made it easy
                to save without either. */}
            {form.serviceType ? (
              <FormSection title="Bill details" className="space-y-4">
                {/* Order follows VendorBill.aspx: bill number > bill date >
                    service type on one row, vendor and its GST on the next. */}
                <div className="grid gap-4 sm:grid-cols-3">
                  <div>
                    <TextField
                      label="Bill number"
                      name="billNumber"
                      required
                      value={form.billNumber}
                      onChange={setField('billNumber')}
                    />
                    {/* Regenerates for the current type — the legacy page had
                        this for staff runs only. */}
                    <button
                      type="button"
                      className="mt-1 text-xs text-[#b91c1c] hover:underline"
                      onClick={() =>
                        setForm((p) => ({
                          ...p,
                          billNumber: generateBillNumber(p.serviceType, p.billDate),
                        }))
                      }
                    >
                      Generate bill number
                    </button>
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
                    options={SERVICE_TYPES}
                    value={form.serviceType}
                    onChange={changeServiceType}
                  />
                </div>

                {/* Vendor follows the service type that decides whether the
                    bill has one at all, on a row of its own. GST is filled
                    from the chosen vendor and read-only, as on the legacy
                    page. */}
                {needsVendor ? (
                  <div className="grid gap-4 sm:grid-cols-2">
                    <div>
                      <SelectField
                        label="Vendor name"
                        name="vendorId"
                        required
                        error={fieldErrors.vendorId}
                        options={lookups.vendors}
                        valueKey="vendor_id"
                        labelKey="vendor_name"
                        value={form.vendorId}
                        onChange={setField('vendorId')}
                      />
                      <button
                        type="button"
                        className="mt-1 text-xs text-[#b91c1c] hover:underline"
                        onClick={openVendorForm}
                      >
                        Add vendor
                      </button>
                    </div>
                    <TextField
                      label="GST number"
                      name="gstNo"
                      readOnly
                      value={selectedVendor?.gst_no ?? ''}
                      hint="From the selected vendor."
                    />
                  </div>
                ) : null}

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
                      /* overflow-y alone still clipped the columns sideways:
                         the picker is four columns wide inside a dialog, so it
                         needs to scroll on both axes rather than just down. */
                      <div className="max-h-64 overflow-auto">
                        <table className="min-w-full stacked-table">
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
                                  <td className="table-cell" data-label="Select">
                                    <input
                                      type="checkbox"
                                      className="h-4 w-4 rounded border-slate-300"
                                      checked={picked}
                                      onChange={() => toggleStaff(s.staff_id, s.salary)}
                                      aria-label={`Select ${s.name}`}
                                    />
                                  </td>
                                  <td className="table-cell font-medium text-slate-800" data-label="Staff name">{s.name}</td>
                                  <td className="table-cell" data-label="Role">{s.role}</td>
                                  <td className="table-cell text-right" data-label="Salary">
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
                        {/* Columns follow the legacy items grid: description,
                            quantity, unit price, tax %, warranty, amount —
                            one line per item.

                            Laid out with flex and per-field widths rather than
                            a column grid: equal columns made the numeric boxes
                            too narrow to read what had been typed into them,
                            and the fractions never divided evenly enough to
                            keep the remove icon on the same line. Description
                            takes the slack; the rest are sized to their
                            content and wrap together when the row runs out of
                            room. */}
                        {items.map((it, i) => (
                          <div key={i} className="flex flex-wrap items-start gap-2 lg:flex-nowrap">
                            <TextField
                              label="Description"
                              name={`it-name-${i}`}
                              className="min-w-[10rem] flex-1"
                              value={it.name}
                              onChange={(e) => setItemField(i, 'name', e.target.value)}
                            />
                            <TextField
                              label="Qty"
                              name={`it-qty-${i}`}
                              type="number"
                              className="w-20 shrink-0"
                              value={it.quantity}
                              onChange={(e) => setItemField(i, 'quantity', e.target.value)}
                            />
                            <TextField
                              label="Unit price"
                              name={`it-cost-${i}`}
                              type="number"
                              step="0.01"
                              className="w-28 shrink-0"
                              value={it.purchaseCost}
                              onChange={(e) => setItemField(i, 'purchaseCost', e.target.value)}
                            />
                            <TextField
                              label="Tax %"
                              name={`it-tax-${i}`}
                              type="number"
                              step="0.01"
                              className="w-20 shrink-0"
                              value={it.tax}
                              onChange={(e) => setItemField(i, 'tax', e.target.value)}
                            />
                            {/* Months named in the label rather than a hint —
                                a hint sits under the input and made this cell
                                taller than the rest of the row. */}
                            <TextField
                              label="Warranty (months)"
                              name={`it-warr-${i}`}
                              type="number"
                              className="w-36 shrink-0"
                              value={it.warrantyMonths}
                              onChange={(e) => setItemField(i, 'warrantyMonths', e.target.value)}
                            />
                            {/* qty × price + tax, as the legacy grid computed
                                it — entering it by hand let it disagree with
                                the line it was meant to total. */}
                            <TextField
                              label="Amount"
                              name={`it-amt-${i}`}
                              readOnly
                              className="w-28 shrink-0"
                              value={money(lineTotal(it))}
                            />
                            {/* pt-6 clears the labels above, so the icon lines
                                up with the inputs rather than their captions. */}
                            <div className="flex items-start pt-6">
                              <button
                                type="button"
                                className="rounded p-2 text-red-600 hover:bg-red-50"
                                title="Remove item"
                                aria-label={`Remove item ${i + 1}`}
                                onClick={() => setItems((p) => p.filter((_, x) => x !== i))}
                              >
                                <svg
                                  viewBox="0 0 24 24"
                                  width="18"
                                  height="18"
                                  fill="none"
                                  stroke="currentColor"
                                  strokeWidth="2"
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  aria-hidden="true"
                                >
                                  <path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6" />
                                </svg>
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
              </FormSection>
            ) : null}

            {hasApprovers ? (
              <FormSection
                title="Approvers"
                subtitle={approverIds.length ? `${approverIds.length} selected` : 'Optional'}
              >
                {/* VendorBill.aspx put an "Add Approver" button here and
                    listed the chosen approvers beneath it; the full roster
                    lived in a picker rather than on the form. */}
                {(lookups.approvers ?? []).length === 0 ? (
                  <EmptyState title="No approvers available" hint="Add committee members first." />
                ) : (
                  <div className="space-y-3">
                    <button
                      type="button"
                      className="btn-secondary text-xs"
                      onClick={() => setPickingApprovers(true)}
                    >
                      Add approver
                    </button>

                    {approverIds.length === 0 ? (
                      <p className="text-sm text-slate-500">No approvers added yet.</p>
                    ) : (
                      <ul className="divide-y divide-slate-200 rounded border border-slate-200">
                        {approverIds.map((id) => {
                          const a = lookups.approvers.find((x) => x.user_id === id);
                          return (
                            <li key={id} className="flex items-center justify-between gap-3 px-3 py-2">
                              <span className="text-sm text-slate-800">{a?.name ?? `User ${id}`}</span>
                              <button
                                type="button"
                                className="btn-danger px-2 text-xs"
                                onClick={() => setApproverIds((p) => p.filter((x) => x !== id))}
                              >
                                Remove
                              </button>
                            </li>
                          );
                        })}
                      </ul>
                    )}
                  </div>
                )}
              </FormSection>
            ) : null}

            {form.serviceType ? (
              <FormSection
                title="Payment"
                subtitle={isStaff ? 'Required for a staff payment' : 'Optional — can be paid later'}
              >
                <PaymentFields
                  payment={payment}
                  setPayment={setPayment}
                  errors={paymentErrors}
                  clearError={(k) =>
                    setPaymentErrors((p) => (p[k] ? { ...p, [k]: undefined } : p))
                  }
                  amountRequired={isStaff}
                  amountHint={isStaff ? 'Mandatory for a staff payment' : undefined}
                />
              </FormSection>
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
        onClose={closeVendorForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeVendorForm} disabled={busy}>
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
            {VENDOR_FIELDS.map((f) => (
              <TextField
                key={f.name}
                label={f.label}
                name={f.name}
                type={f.type ?? 'text'}
                required={f.required}
                error={vendorErrors[f.name]}
                inputMode={f.digits ? 'numeric' : undefined}
                maxLength={f.maxLength}
                value={vendorForm[f.name]}
                onChange={(e) => {
                  const { value } = e.target;
                  // A `digits` box takes 0-9 only, trimmed to maxLength.
                  const next = f.digits
                    ? value.replace(/\D/g, '').slice(0, f.maxLength)
                    : value;
                  setVendorForm((p) => ({ ...p, [f.name]: next }));
                  // The complaint goes as soon as it is being answered.
                  setVendorErrors((p) => (p[f.name] ? { ...p, [f.name]: undefined } : p));
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
        maxWidth="max-w-4xl"
        footer={
          <>
            {detail && !detail.loading ? (
              <button type="button" className="btn-secondary" onClick={() => printBill(detail)}>
                Print
              </button>
            ) : null}
            <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
              Close
            </button>
          </>
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
                {/* What was billed, as billed. Condition is deliberately not
                    here: it is the item's state today, which the inventory
                    screen owns and changes over time — a bill records what was
                    bought, and should keep reading the same later. */}
                <div className="overflow-x-auto">
                  <table className="min-w-full stacked-table">
                    <thead>
                      <tr>
                        <th className="table-head">Item</th>
                        <th className="table-head text-right">Qty</th>
                        <th className="table-head text-right">Unit price</th>
                        <th className="table-head text-right">Tax %</th>
                        <th className="table-head text-right">Warranty</th>
                        <th className="table-head text-right">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      {detail.items.map((it) => (
                        <tr key={it.item_id}>
                          <td className="table-cell font-medium text-slate-800" data-label="Item">{it.item_name}</td>
                          <td className="table-cell text-right" data-label="Qty">{it.quantity}</td>
                          <td className="table-cell text-right" data-label="Unit price">{money(it.purchase_cost)}</td>
                          <td className="table-cell text-right" data-label="Tax %">{it.tax ?? '—'}</td>
                          <td className="table-cell text-right" data-label="Warranty">
                            {it.warranty ? `${it.warranty} mo` : '—'}
                          </td>
                          <td className="table-cell text-right" data-label="Amount">{money(it.total_amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ) : null}

            <div>
              <h3 className="mb-2 text-sm font-semibold text-slate-800">Approvals</h3>
              {detail.approvals?.length ? (
                <div className="overflow-x-auto">
                <table className="min-w-full stacked-table">
                  <thead>
                    <tr>
                      <th className="table-head">Approver</th>
                      <th className="table-head">Status</th>
                      <th className="table-head">Date</th>
                      {/* A rejection cannot be saved without one, and it was
                          being stored and then never shown — leaving a bill
                          marked Rejected with nothing saying why. */}
                      <th className="table-head">Reason</th>
                      <th className="table-head sr-only">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.approvals.map((a) => (
                      <tr key={a.approval_id}>
                        <td className="table-cell font-medium text-slate-800" data-label="Approver">{a.name}</td>
                        <td className="table-cell" data-label="Status">{approvalLabel(a.approval_status)}</td>
                        <td className="table-cell" data-label="Date">{day(a.approval_date)}</td>
                        <td className="table-cell" data-label="Reason">{a.remarks || '—'}</td>
                        <td className="table-cell text-right" data-actions="">
                          {/* Only the approver it was asked of may answer —
                              the API refuses anyone else, so offering the
                              buttons to everyone promised something that
                              would fail on click. */}
                          {Number(a.approval_status) === 1 &&
                          String(a.user_id) === String(user?.user_id) ? (
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
                </div>
              ) : (
                <p className="text-sm text-slate-500">No approvers assigned.</p>
              )}
            </div>

            {detail.payments?.length ? (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Payments</h3>
                <div className="overflow-x-auto">
                <table className="min-w-full stacked-table">
                  <thead>
                    <tr>
                      <th className="table-head">Payment no.</th>
                      <th className="table-head">Date</th>
                      <th className="table-head">Mode</th>
                      <th className="table-head">Reference</th>
                      <th className="table-head text-right">Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.payments.map((p) => (
                      <tr key={p.payment_id}>
                        <td className="table-cell font-medium text-slate-800" data-label="Payment no.">{p.payment_no}</td>
                        <td className="table-cell" data-label="Date">{day(p.payment_date)}</td>
                        <td className="table-cell" data-label="Mode">{p.pay_mode}</td>
                        {/* Cheque number or transaction reference, whichever
                            the mode carries; cash has neither. */}
                        <td className="table-cell" data-label="Reference">{p.cheque_no || p.transaction_ref || '—'}</td>
                        <td className="table-cell text-right" data-label="Amount">{money(p.paid_amount)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                </div>
              </div>
            ) : null}

            <ErrorNotice error={error} />
          </div>
        ) : null}
      </Modal>

      {/* ------------------------------------------------- approver picker */}
      <Modal
        open={pickingApprovers}
        title="Add approver"
        onClose={() => setPickingApprovers(false)}
        footer={
          <button type="button" className="btn-primary" onClick={() => setPickingApprovers(false)}>
            Done
          </button>
        }
      >
        <div className="space-y-2">
          {(lookups.approvers ?? []).map((a) => (
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
      </Modal>

      {/* ------------------------------------------------------------ pay */}
      <Modal
        open={Boolean(paying)}
        title={`Pay bill ${paying?.bill_number ?? ''}`}
        onClose={() => setPaying(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setPaying(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="pay-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Record payment'}
            </button>
          </>
        }
      >
        {paying ? (
          <form id="pay-form" onSubmit={submitPay} noValidate>
            {/* The legacy modal led with the bill it was about. */}
            <dl className="mb-4 grid grid-cols-2 gap-x-4 gap-y-2 rounded border border-slate-200 bg-slate-50 p-3 text-sm">
              <dt className="text-slate-500">Vendor</dt>
              <dd className="text-right text-slate-800">{paying.vendor_name || '—'}</dd>
              <dt className="text-slate-500">Bill date</dt>
              <dd className="text-right text-slate-800">{day(paying.bill_date)}</dd>
              <dt className="text-slate-500">Bill amount</dt>
              <dd className="text-right text-slate-800">{money(paying.total_amount)}</dd>
              <dt className="text-slate-500">Paid so far</dt>
              <dd className="text-right text-slate-800">{money(paying.paid_amount)}</dd>
              <dt className="font-medium text-slate-700">Outstanding</dt>
              <dd className="text-right font-medium text-slate-900">{money(paying.remaining_amount)}</dd>
            </dl>

            <FormErrorSummary count={countErrors(payErrors)} />
            <PaymentFields
              payment={payForm}
              setPayment={setPayForm}
              errors={payErrors}
              clearError={(k) => setPayErrors((p) => (p[k] ? { ...p, [k]: undefined } : p))}
              idPrefix="settle-"
              amountRequired
              amountMax={paying.remaining_amount ?? undefined}
              amountHint={`Up to ${money(paying.remaining_amount)}`}
            />

            <div className="mt-4">
              <ErrorNotice error={error} />
            </div>
          </form>
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
            toast.success('Vendor bill deleted successfully.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The bill could not be deleted. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
