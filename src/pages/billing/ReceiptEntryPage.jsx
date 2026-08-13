import { useCallback, useEffect, useMemo, useState } from 'react';
import { receipts } from '@/api/billing';
import DataGrid from '@/components/DataGrid.jsx';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  FormErrorSummary,
  InfoNotice,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import {
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

// Legacy maintenance_receipt.aspx offers exactly these two modes.
const PAY_MODES = [
  { value: 'Cheque', label: 'Cheque' },
  { value: 'PDC', label: 'PDC cheque' },
];

/**
 * GetBills returns bill_type 1 = Regular, 0 = Add-On, 2 = a carried charge that
 * is shown for information but never settled directly (the CHS app lists it as
 * a note and leaves it out of both the payable total and the bill list).
 */
const REGULAR = 1;
const ADDON = 0;
const NOTE_ONLY = 2;

const EMPTY = {
  flatId: '',
  payMode: 'Cheque',
  chequeNo: '',
  chequeDate: '',
  bankName: '',
  transactionRef: '',
  paidAmount: '',
  remarks: '',
  receiptDate: new Date().toISOString().slice(0, 10),
  pdcId: '',
};

/**
 * The settlement proc matches on the raw `bill_no`, not the formatted `BillNo`
 * display string, so selection has to be keyed on the raw value.
 */
const billKey = (b) => String(b.bill_no);

/** A titled group of fields in the receipt view. */
function ReceiptSection({ title, children }) {
  return (
    <div>
      <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">{title}</h4>
      <dl className="grid grid-cols-2 gap-x-6 gap-y-3 rounded-md border border-slate-200 p-3">
        {children}
      </dl>
    </div>
  );
}

function ReceiptField({ label, value }) {
  return (
    <div>
      <dt className="text-xs text-slate-500">{label}</dt>
      <dd className="mt-0.5 text-slate-800">{value == null || value === '' ? '—' : value}</dd>
    </div>
  );
}

/**
 * Maintenance receipts — full parity with Society2024/maintenance_receipt.aspx.
 *
 * Records a payment against one or more outstanding bills. Picking a resident
 * loads their unpaid bills and any post-dated cheques on file; selecting bills
 * sets the amount, which stays editable for a part payment.
 *
 * Recording a payment writes to `receipt` and then settles the selected bills
 * through sp_SettleMaintenancePayment, so the save button is disabled until the
 * write paths have been verified against a test database.
 */
const WRITES_ENABLED = import.meta.env.VITE_ENABLE_RECEIPT_ENTRY === 'true';

/* The one unconditional empty-check; see validate() for the rest. */
const RECEIPT_FIELDS = [{ name: 'flatId', label: 'Resident', type: 'select', required: true }];

export default function ReceiptEntryPage() {
  const [rows, setRows] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const [form, setForm] = useState(null);
  const [residents, setResidents] = useState([]);
  const [outstanding, setOutstanding] = useState([]);
  const [pdcCheques, setPdcCheques] = useState([]);
  const [advance, setAdvance] = useState(null);
  const [notice, setNotice] = useState(null);
  const [selectedBills, setSelectedBills] = useState([]);
  const [loadingBills, setLoadingBills] = useState(false);
  const [viewing, setViewing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const toast = useToast();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await receipts.list();
      setRows(data.items ?? []);
      setTotal(data.totalCollected ?? 0);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    receipts
      .residents()
      .then((d) => setResidents(d.items ?? []))
      .catch(() => {});
  }, [load]);

  /** Selecting a resident loads their outstanding bills and PDC cheques. */
  const clearFieldError = (key) =>
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));

  const onResidentChange = async (flatId) => {
    setForm((p) => ({ ...p, flatId }));
    // The complaint goes as soon as it is answered.
    clearFieldError('flatId');
    setSelectedBills([]);
    setOutstanding([]);
    setPdcCheques([]);
    setAdvance(null);
    if (!flatId) return;

    setLoadingBills(true);
    try {
      // Bills must surface their error: swallowing it renders an empty list that
      // is indistinguishable from "this resident owes nothing", which would
      // invite recording a payment against bills that simply failed to load.
      const [bills, pdc, adv] = await Promise.all([
        receipts.outstanding(flatId),
        receipts.pdc(flatId).catch(() => ({ items: [] })),
        // Older databases lack the GetAdvance action; the credit notice is
        // simply omitted there rather than failing the whole form.
        receipts.advance(flatId).catch(() => null),
      ]);
      setOutstanding(bills.items ?? []);
      setPdcCheques(pdc.items ?? []);
      setAdvance(adv);
    } catch (err) {
      setError(err);
    } finally {
      setLoadingBills(false);
    }
  };

  /** bill_type 2 rows are informational, so they are never offered for payment. */
  const payableBills = useMemo(
    () => outstanding.filter((b) => Number(b.BillType) !== NOTE_ONLY),
    [outstanding],
  );

  /** The ticked bills, in the order the settlement proc should see them. */
  const selectedRows = useMemo(
    () => payableBills.filter((b) => selectedBills.includes(billKey(b))),
    [payableBills, selectedBills],
  );

  /**
   * How much the ticked bills come to, and how far the amount may be reduced.
   *
   * This mirrors _calculatePaymentDetails() in the CHS app: a Regular bill has
   * to be cleared in full, so selecting only Regular bills fixes the amount
   * outright; Add-On bills may be part paid, so as soon as one is in the
   * selection the box opens up with the Regular portion as its floor.
   */
  const { selectedTotal, minimumAmount, amountEditable } = useMemo(() => {
    const sumOf = (type) =>
      selectedRows
        .filter((b) => Number(b.BillType) === type)
        .reduce((s, b) => s + Number(b.Amount || 0), 0);

    const regular = sumOf(REGULAR);
    const addon = sumOf(ADDON);
    const hasRegular = selectedRows.some((b) => Number(b.BillType) === REGULAR);
    const hasAddon = selectedRows.some((b) => Number(b.BillType) === ADDON);

    return {
      selectedTotal: regular + addon,
      minimumAmount: hasRegular ? regular : 0,
      amountEditable: hasAddon,
    };
  }, [selectedRows]);

  /** Informational bill_type 2 charges on the account, shown but never settled. */
  const noteOnlyTotal = useMemo(
    () =>
      outstanding
        .filter((b) => Number(b.BillType) === NOTE_ONLY)
        .reduce((s, b) => s + Number(b.Amount || 0), 0),
    [outstanding],
  );

  // Ticking a bill proposes the amount; the user can still edit it for a
  // part payment, exactly as the legacy screen allowed. A PDC cheque supplies
  // its own amount, so the proposal must not overwrite it.
  useEffect(() => {
    if (!selectedBills.length) return;
    setForm((p) =>
      p && !(p.payMode === 'PDC' && p.pdcId) ? { ...p, paidAmount: selectedTotal.toFixed(2) } : p,
    );
  }, [selectedTotal, selectedBills.length]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const toggleBill = (key) =>
    setSelectedBills((prev) =>
      prev.includes(key) ? prev.filter((b) => b !== key) : [...prev, key],
    );

  /** A picked PDC supplies the cheque details, so they stop being editable. */
  const pdcLocked = form?.payMode === 'PDC' && Boolean(form?.pdcId);

  /** Regular bills settle before Add-On ones, matching the legacy screen. */
  const orderedBillNos = useMemo(
    () =>
      [...selectedRows]
        .sort((a, b) => Number(b.BillType) - Number(a.BillType))
        .map(billKey),
    [selectedRows],
  );

  /*
   * Cross-field rules only. The resident moved to RECEIPT_FIELDS so it marks
   * the box; the rest depend on pay mode, the bills ticked, or a column width,
   * so they stay as one banner.
   */
  const validate = () => {
    if (!selectedBills.length) return 'Select at least one bill to settle';
    if (Number(form.paidAmount || 0) <= 0) return 'Enter an amount greater than zero';
    if (Number(form.paidAmount) < minimumAmount) {
      return `Amount entered is less than the minimum amount ${money(minimumAmount)} — regular bills must be paid in full`;
    }
    // String(...) guards against SQL handing back a numeric cheque number.
    if (!String(form.chequeNo ?? '').trim()) return 'Cheque number is required';
    if (!form.chequeDate) return 'Cheque date is required';
    if (!String(form.bankName ?? '').trim()) return 'Bank name is required';
    if (form.payMode === 'PDC' && !form.pdcId) return 'Select a post-dated cheque';
    // receipt.bill_details is nvarchar(20); a longer list would be truncated
    // and the payment would under-settle.
    if (orderedBillNos.join(',').length > 20) {
      return 'Too many bills selected for one receipt — record the payment across several receipts';
    }
    return null;
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      // Inside the try so a fault in validation surfaces as a message rather
      // than escaping the handler and leaving the button silently dead.
      const missing = validateFields(RECEIPT_FIELDS, form);
      setFieldErrors(missing);
      if (Object.keys(missing).length) {
        focusFirstInvalid(RECEIPT_FIELDS, missing);
        return;
      }

      const message = validate();
      if (message) {
        setError(new Error(message));
        return;
      }
      const created = await receipts.create({
        flatId: Number(form.flatId),
        payMode: form.payMode,
        chequeNo: form.chequeNo,
        chequeDate: form.chequeDate || undefined,
        bankName: form.bankName,
        transactionRef: form.transactionRef,
        paidAmount: Number(form.paidAmount),
        remarks: form.remarks,
        receiptDate: form.receiptDate,
        billNos: orderedBillNos,
      });
      // The legacy page popped a "✅ Approved!" dialog on save; without any
      // acknowledgement the modal just vanishes and it is unclear whether the
      // payment was recorded.
      setNotice(
        created?.receipt_id
          ? `Payment recorded — receipt ${created.receipt_id}.`
          : 'Payment recorded.',
      );
      // The banner above stays for the receipt number; the toast is what every
      // other screen shows on a save, so the two agree.
      toast.success(
        created?.receipt_id
          ? `Receipt ${created.receipt_id} recorded successfully.`
          : 'Payment recorded successfully.',
        { title: 'Receipt saved' },
      );
      setForm(null);
      await load();
    } catch (err) {
      setError(err);
      toast.error('The receipt could not be saved. Please check the form and try again.');
    } finally {
      setBusy(false);
    }
  };

  const columns = [
    { key: 'receipt_no', label: 'Receipt no.' },
    { key: 'receipt_date', label: 'Date', render: day },
    { key: 'owner', label: 'Resident' },
    { key: 'transaction_ref', label: 'Reference' },
    { key: 'paid_amount', label: 'Amount', align: 'right', render: money },
    { key: 'bill_status', label: 'Status' },
  ];

  return (
    <section>
      <PageHeader title="Maintenance receipts" subtitle={`${rows.length} receipt(s) · ${money(total)} collected`}>
        <button
          type="button"
          className="btn-primary"
          onClick={() => {
            setForm({ ...EMPTY });
            setSelectedBills([]);
            setOutstanding([]);
            setPdcCheques([]);
            setError(null);
          }}
        >
          Record payment
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Receipts" value={rows.length} />
        <StatCard label="Collected" value={money(total)} tone="positive" />
        <StatCard label="Residents" value={residents.length} />
      </div>

      {!form ? (
        <div className="space-y-3">
          <InfoNotice message={notice} tone="success" onDismiss={() => setNotice(null)} />
          <ErrorNotice error={error} onRetry={load} />
        </div>
      ) : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={rows}
          idKey="receipt_id"
          loading={loading}
          searchable
          searchPlaceholder="Search receipts…"
          exportName="receipts"
          emptyTitle="No receipts recorded"
          actions={(row) => (
            <>
              <button
                type="button"
                className="btn-secondary"
                onClick={async () => {
                  setViewing({ loading: true });
                  try {
                    const d = await receipts.get(row.receipt_id);
                    setViewing({ loading: false, ...d });
                  } catch (err) {
                    setError(err);
                    setViewing(null);
                  }
                }}
              >
                View
              </button>
              <button
                type="button"
                className="btn-danger"
                onClick={() =>
                  setConfirming({
                    title: 'Cancel receipt',
                    message: `Cancel receipt ${row.receipt_no}? The bills it settled will remain settled.`,
                    run: () => receipts.cancel(row.receipt_id, { remarks: 'Cancelled from web' }),
                  })
                }
              >
                Cancel
              </button>
            </>
          )}
        />
      </div>

      {/* ------------------------------------------------- record a payment */}
      <Modal
        open={Boolean(form)}
        title="Record a payment"
        // Also clear the error: it is shared with the page-level notice, so a
        // validation message left behind would resurface under the header.
        onClose={() => {
          setForm(null);
          setError(null);
        }}
        footer={
          <>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => {
                setForm(null);
                setError(null);
              }}
              disabled={busy}
            >
              Cancel
            </button>
            <button
              type="submit"
              form="receipt-form"
              className="btn-primary"
              disabled={busy || !WRITES_ENABLED}
              title={WRITES_ENABLED ? undefined : 'Enabled once the write paths are verified'}
            >
              {busy ? 'Saving…' : 'Save receipt'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="receipt-form" onSubmit={onSubmit} className="space-y-4" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <SelectField
              label="Resident"
              name="flatId"
              required
              error={fieldErrors.flatId}
              options={residents}
              valueKey="flat_id"
              labelKey="resident_name"
              value={form.flatId}
              onChange={(e) => onResidentChange(e.target.value)}
            />

            {loadingBills ? (
              <Spinner label="Loading bills…" />
            ) : form.flatId ? (
              <div className="rounded-md border border-slate-200 p-3">
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Outstanding bills</h3>

                {/* Surplus from an earlier overpayment. gen_bill subtracts it from
                    the next monthly bill before interest, so this is shown for
                    information only — collecting less here as well would credit
                    the resident twice. */}
                {advance && advance.advanceAvailable > 0 ? (
                  <p className="mb-3 rounded-md border border-sky-200 bg-sky-50 p-2 text-xs text-sky-900">
                    This flat holds {money(advance.advanceAvailable)} in credit from an earlier
                    overpayment. It comes off the next monthly bill automatically — collect the
                    full amount shown below.
                  </p>
                ) : null}
                {payableBills.length === 0 ? (
                  <p className="py-3 text-sm text-slate-500">No outstanding bills for this resident.</p>
                ) : (
                  <table className="min-w-full">
                    <thead>
                      <tr>
                        <th className="table-head w-10">Pay</th>
                        <th className="table-head">Bill no.</th>
                        <th className="table-head">Due date</th>
                        <th className="table-head">Status</th>
                        <th className="table-head text-right">Outstanding</th>
                      </tr>
                    </thead>
                    <tbody>
                      {payableBills.map((b) => {
                        const key = billKey(b);
                        return (
                          <tr key={key}>
                            <td className="table-cell">
                              <input
                                type="checkbox"
                                className="h-4 w-4 rounded border-slate-300"
                                checked={selectedBills.includes(key)}
                                onChange={() => toggleBill(key)}
                                aria-label={`Select bill ${b.BillNo}`}
                              />
                            </td>
                            <td className="table-cell font-medium text-slate-800">
                              {b.BillNo}
                              <span className="ml-2 text-xs font-normal text-slate-500">
                                {Number(b.BillType) === REGULAR ? 'Regular' : 'Add-On'}
                              </span>
                            </td>
                            <td className="table-cell">{day(b.DueDate)}</td>
                            <td className="table-cell">
                              <span
                                className={`rounded px-2 py-0.5 text-xs ${
                                  b.Status === 'Overdue'
                                    ? 'bg-red-50 text-red-700'
                                    : 'bg-amber-50 text-amber-700'
                                }`}
                              >
                                {b.Status}
                              </span>
                            </td>
                            {/* Only the outstanding amount is shown. maintenance_cal.total_amount
                                is a running account total that rolls forward earlier arrears
                                (amt_forward / interest_forward), not the value of this charge,
                                so displaying it next to the bill would misread as its price. */}
                            <td className="table-cell text-right">{money(b.Amount)}</td>
                          </tr>
                        );
                      })}
                      <tr className="bg-slate-50 font-semibold">
                        <td className="table-cell" colSpan={4}>
                          Selected ({selectedBills.length})
                          {minimumAmount > 0 ? (
                            <span className="ml-2 text-xs font-normal text-red-600">
                              Minimum amount is {money(minimumAmount)}
                            </span>
                          ) : null}
                        </td>
                        <td className="table-cell text-right">{money(selectedTotal)}</td>
                      </tr>
                    </tbody>
                  </table>
                )}
                {noteOnlyTotal > 0 ? (
                  <p className="mt-2 text-xs text-slate-500">
                    Note: an additional {money(noteOnlyTotal)} is carried on this account and is
                    not settled by this receipt.
                  </p>
                ) : null}
              </div>
            ) : null}

            <ModeSwitch
              label="Payment mode"
              options={PAY_MODES}
              value={form.payMode}
              // Switching mode clears the cheque details, as the legacy
              // btnChequeMode_Click / btnPDCMode_Click handlers did.
              onChange={(v) =>
                setForm((p) => ({
                  ...p,
                  payMode: v,
                  pdcId: '',
                  chequeNo: '',
                  chequeDate: '',
                  bankName: '',
                  // Back to the selection total, so an amount a PDC put here does
                  // not survive the switch (legacy ClearChequeDetails cleared it).
                  paidAmount: selectedBills.length ? selectedTotal.toFixed(2) : '',
                }))
              }
            />

            <div className="grid gap-4 sm:grid-cols-2">
              {form.payMode === 'PDC' ? (
                <SelectField
                  label="Post-dated cheque"
                  name="pdcId"
                  required
                  className="sm:col-span-2"
                  options={pdcCheques.map((c) => ({
                    value: c.pdc_rem_id,
                    label: `${c.chqno} · ${money(c.che_amount)} · ${day(c.che_date)} · ${c.bank_name ?? ''}`,
                  }))}
                  value={form.pdcId}
                  onChange={(e) => {
                    const { value } = e.target;
                    const cheque = pdcCheques.find((c) => String(c.pdc_rem_id) === value);
                    // chqno and che_amount come back as SQL numbers, and these
                    // fields are read as text (trimmed, fed to inputs), so they
                    // are normalised to strings here rather than at every use.
                    setForm((p) => ({
                      ...p,
                      pdcId: value,
                      chequeNo: cheque?.chqno == null ? '' : String(cheque.chqno),
                      chequeDate: cheque?.che_date ? String(cheque.che_date).slice(0, 10) : '',
                      bankName: cheque?.bank_name == null ? '' : String(cheque.bank_name),
                      paidAmount:
                        cheque?.che_amount == null ? p.paidAmount : String(cheque.che_amount),
                    }));
                  }}
                  placeholder={pdcCheques.length ? 'Select a cheque…' : 'No cheques on file'}
                />
              ) : null}

              {/* A chosen PDC fills these in and locks them, as the legacy page did. */}
              <TextField
                label="Transaction ID / cheque no."
                name="chequeNo"
                required
                disabled={pdcLocked}
                value={form.chequeNo}
                onChange={setField('chequeNo')}
              />
              <TextField
                label="Payment date"
                name="chequeDate"
                type="date"
                required
                disabled={pdcLocked}
                value={form.chequeDate}
                onChange={setField('chequeDate')}
              />
              <TextField
                label="Bank name"
                name="bankName"
                required
                disabled={pdcLocked}
                value={form.bankName}
                onChange={setField('bankName')}
              />
              <TextField
                label="Amount received"
                name="paidAmount"
                type="number"
                step="0.01"
                required
                disabled={pdcLocked || !amountEditable}
                value={form.paidAmount}
                onChange={setField('paidAmount')}
                hint={
                  !amountEditable
                    ? 'Regular bills must be cleared in full'
                    : minimumAmount > 0
                      ? `Minimum ${money(minimumAmount)} — only add-on bills may be part paid`
                      : 'Editable for a part payment'
                }
              />
              <TextField
                label="Receipt date"
                name="receiptDate"
                type="date"
                value={form.receiptDate}
                onChange={setField('receiptDate')}
              />
              <TextAreaField
                label="Remarks"
                name="remarks"
                rows={2}
                className="sm:col-span-2"
                value={form.remarks}
                onChange={setField('remarks')}
              />
            </div>

            {!WRITES_ENABLED ? (
              <p className="rounded-md border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
                Saving is disabled in this build. Recording a receipt settles bills through
                sp_SettleMaintenancePayment and cannot be undone from the application, so it is
                enabled only after being verified against a test database.
              </p>
            ) : null}

            <ErrorNotice error={error} />
          </form>
        ) : null}
      </Modal>

      {/* ------------------------------------------------------ view receipt */}
      <Modal
        open={Boolean(viewing)}
        title="Receipt"
        onClose={() => setViewing(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => window.print()}>
              Print
            </button>
            <button type="button" className="btn-secondary" onClick={() => setViewing(null)}>
              Close
            </button>
          </>
        }
      >
        {viewing?.loading ? (
          <Spinner />
        ) : viewing?.receipt ? (
          <div className="space-y-5 text-sm">
            {/* Receipt identity first, then who paid, then how, then what it
                cleared — the order the legacy Payment Summary modal used. */}
            <ReceiptSection title="Receipt">
              <ReceiptField label="Receipt no." value={viewing.receipt.receipt_no} />
              <ReceiptField label="Date" value={day(viewing.receipt.date)} />
              <ReceiptField label="Status" value={viewing.receipt.bill_status} />
            </ReceiptSection>

            <ReceiptSection title="Resident information">
              <ReceiptField label="Resident" value={viewing.receipt.name} />
              <ReceiptField label="Unit" value={viewing.receipt.unit} />
              <ReceiptField label="Society" value={viewing.receipt.society_name} />
            </ReceiptSection>

            <ReceiptSection title="Payment details">
              <ReceiptField label="Pay mode" value={viewing.receipt.pay_mode} />
              <ReceiptField label="Cheque / reference" value={viewing.receipt.transaction_ref} />
              <ReceiptField label="Bank" value={viewing.receipt.bank_name} />
              <ReceiptField label="Amount paid" value={money(viewing.receipt.paid_amount)} />
            </ReceiptSection>

            {/* GETRECEIPT returns one row per settled bill. Showing only the
                first hid the rest of a multi-bill receipt. */}
            <div>
              <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Bills settled{viewing.lines?.length ? ` (${viewing.lines.length})` : ''}
              </h4>
              {viewing.lines?.length ? (
                <div className="overflow-x-auto rounded-md border border-slate-200">
                  <table className="min-w-full">
                    <thead>
                      <tr>
                        <th className="table-head">Bill no.</th>
                        <th className="table-head">Period</th>
                        <th className="table-head">Due date</th>
                        <th className="table-head text-right">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      {viewing.lines.map((l, i) => (
                        <tr key={`${l.Billno ?? l.bill_ref}-${i}`}>
                          <td className="table-cell font-medium text-slate-800">
                            {l.Billno ?? '—'}
                          </td>
                          <td className="table-cell">{l.bill_ref ?? '—'}</td>
                          <td className="table-cell">{l.gen_date ? day(l.gen_date) : '—'}</td>
                          <td className="table-cell text-right">{money(l.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-sm text-slate-500">No bill lines recorded for this receipt.</p>
              )}
            </div>
          </div>
        ) : (
          <EmptyState title="Receipt details unavailable" />
        )}
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
            toast.success('Receipt cancelled.', { title: 'Cancelled' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The receipt could not be cancelled. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
