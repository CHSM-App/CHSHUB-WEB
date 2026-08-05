import { useCallback, useEffect, useMemo, useState } from 'react';
import { receipts } from '@/api/billing';
import DataGrid from '@/components/DataGrid.jsx';
import { ConfirmDialog, EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import {
  ModeSwitch,
  PageHeader,
  SelectField,
  StatCard,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';

const money = (v) =>
  v == null ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

const PAY_MODES = [
  { value: 'Cash', label: 'Cash' },
  { value: 'Cheque', label: 'Cheque' },
  { value: 'Online', label: 'Online' },
  { value: 'PDC', label: 'PDC cheque' },
];

const EMPTY = {
  flatId: '',
  payMode: 'Cash',
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
  const [selectedBills, setSelectedBills] = useState([]);
  const [loadingBills, setLoadingBills] = useState(false);
  const [viewing, setViewing] = useState(null);
  const [confirming, setConfirming] = useState(null);

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
  const onResidentChange = async (flatId) => {
    setForm((p) => ({ ...p, flatId }));
    setSelectedBills([]);
    setOutstanding([]);
    setPdcCheques([]);
    if (!flatId) return;

    setLoadingBills(true);
    try {
      const [bills, pdc] = await Promise.all([
        receipts.outstanding(flatId).catch(() => ({ items: [] })),
        receipts.pdc(flatId).catch(() => ({ items: [] })),
      ]);
      setOutstanding(bills.items ?? []);
      setPdcCheques(pdc.items ?? []);
    } finally {
      setLoadingBills(false);
    }
  };

  /** Amount owed by the bills currently ticked. */
  const selectedTotal = useMemo(
    () =>
      outstanding
        .filter((b) => selectedBills.includes(b.BillNo ?? b.bill_no))
        .reduce((s, b) => s + Number(b.Amount || 0), 0),
    [outstanding, selectedBills],
  );

  // Ticking a bill proposes the amount; the user can still edit it for a
  // part payment, exactly as the legacy screen allowed.
  useEffect(() => {
    if (selectedBills.length) {
      setForm((p) => (p ? { ...p, paidAmount: selectedTotal.toFixed(2) } : p));
    }
  }, [selectedTotal, selectedBills.length]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const toggleBill = (billNo) =>
    setSelectedBills((prev) =>
      prev.includes(billNo) ? prev.filter((b) => b !== billNo) : [...prev, billNo],
    );

  const validate = () => {
    if (!form.flatId) return 'Select a resident';
    if (!selectedBills.length) return 'Select at least one bill to settle';
    if (Number(form.paidAmount || 0) <= 0) return 'Enter an amount greater than zero';
    if (form.payMode === 'Cheque' && !form.chequeNo.trim()) return 'Cheque number is required';
    if (form.payMode === 'Online' && !form.transactionRef.trim()) {
      return 'Transaction reference is required';
    }
    if (form.payMode === 'PDC' && !form.pdcId) return 'Select a post-dated cheque';
    // receipt.bill_details is nvarchar(20); a longer list would be truncated
    // and the payment would under-settle.
    if (selectedBills.join(',').length > 20) {
      return 'Too many bills selected for one receipt — record the payment across several receipts';
    }
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
      await receipts.create({
        flatId: Number(form.flatId),
        payMode: form.payMode === 'PDC' ? 'Cheque' : form.payMode,
        chequeNo: form.chequeNo,
        chequeDate: form.chequeDate || undefined,
        bankName: form.bankName,
        transactionRef: form.transactionRef,
        paidAmount: Number(form.paidAmount),
        remarks: form.remarks,
        receiptDate: form.receiptDate,
        billNos: selectedBills,
      });
      setForm(null);
      await load();
    } catch (err) {
      setError(err);
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

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={rows}
          idKey="receipt_id"
          loading={loading}
          exportName="receipts"
          emptyTitle="No receipts recorded"
          actions={(row) => (
            <>
              <button
                type="button"
                className="btn-secondary mr-2"
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
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
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
            <SelectField
              label="Resident"
              name="flatId"
              required
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
                {outstanding.length === 0 ? (
                  <p className="py-3 text-sm text-slate-500">No outstanding bills for this resident.</p>
                ) : (
                  <table className="min-w-full">
                    <thead>
                      <tr>
                        <th className="table-head w-10">Pay</th>
                        <th className="table-head">Bill no.</th>
                        <th className="table-head">Due date</th>
                        <th className="table-head">Status</th>
                        <th className="table-head text-right">Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      {outstanding.map((b) => {
                        const key = b.BillNo ?? b.bill_no;
                        return (
                          <tr key={key}>
                            <td className="table-cell">
                              <input
                                type="checkbox"
                                className="h-4 w-4 rounded border-slate-300"
                                checked={selectedBills.includes(key)}
                                onChange={() => toggleBill(key)}
                                aria-label={`Select bill ${key}`}
                              />
                            </td>
                            <td className="table-cell font-medium text-slate-800">{b.BillNo}</td>
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
                            <td className="table-cell text-right">{money(b.Amount)}</td>
                          </tr>
                        );
                      })}
                      <tr className="bg-slate-50 font-semibold">
                        <td className="table-cell" colSpan={4}>
                          Selected ({selectedBills.length})
                        </td>
                        <td className="table-cell text-right">{money(selectedTotal)}</td>
                      </tr>
                    </tbody>
                  </table>
                )}
              </div>
            ) : null}

            <ModeSwitch
              label="Payment mode"
              options={PAY_MODES}
              value={form.payMode}
              onChange={(v) => setForm((p) => ({ ...p, payMode: v }))}
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
                    setForm((p) => ({
                      ...p,
                      pdcId: value,
                      chequeNo: cheque?.chqno ?? '',
                      chequeDate: cheque?.che_date ? String(cheque.che_date).slice(0, 10) : '',
                      bankName: cheque?.bank_name ?? '',
                      paidAmount: cheque?.che_amount ?? p.paidAmount,
                    }));
                  }}
                  placeholder={pdcCheques.length ? 'Select a cheque…' : 'No cheques on file'}
                />
              ) : null}

              {form.payMode === 'Cheque' ? (
                <>
                  <TextField
                    label="Cheque number"
                    name="chequeNo"
                    required
                    value={form.chequeNo}
                    onChange={setField('chequeNo')}
                  />
                  <TextField
                    label="Cheque date"
                    name="chequeDate"
                    type="date"
                    value={form.chequeDate}
                    onChange={setField('chequeDate')}
                  />
                  <TextField
                    label="Bank name"
                    name="bankName"
                    value={form.bankName}
                    onChange={setField('bankName')}
                  />
                </>
              ) : null}

              {form.payMode === 'Online' ? (
                <TextField
                  label="Transaction reference"
                  name="transactionRef"
                  required
                  value={form.transactionRef}
                  onChange={setField('transactionRef')}
                />
              ) : null}

              <TextField
                label="Amount received"
                name="paidAmount"
                type="number"
                step="0.01"
                required
                value={form.paidAmount}
                onChange={setField('paidAmount')}
                hint="Editable for a part payment"
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
          <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
            {[
              ['Receipt no.', viewing.receipt.receipt_no],
              ['Date', day(viewing.receipt.date)],
              ['Resident', viewing.receipt.name],
              ['Unit', viewing.receipt.unit],
              ['Pay mode', viewing.receipt.pay_mode],
              ['Reference', viewing.receipt.transaction_ref],
              ['Bill', viewing.receipt.bill_ref || viewing.receipt.Billno],
              ['Amount paid', money(viewing.receipt.paid_amount)],
              ['Status', viewing.receipt.bill_status],
              ['Society', viewing.receipt.society_name],
            ].map(([label, value]) => (
              <div key={label}>
                <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
                <dd className="mt-0.5 text-slate-800">{value ?? '—'}</dd>
              </div>
            ))}
          </dl>
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
