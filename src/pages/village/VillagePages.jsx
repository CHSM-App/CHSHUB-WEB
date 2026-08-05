import { useCallback, useEffect, useMemo, useState } from 'react';
import { village } from '@/api/modules';
import { api } from '@/api/client';
import DataGrid from '@/components/DataGrid.jsx';
import { ConfirmDialog, EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import {
  FileUploadField,
  ModeSwitch,
  PageHeader,
  SelectField,
  StatCard,
  Tabs,
  TextField,
} from '@/components/FormControls.jsx';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/** Charge types, matching Village_payment_type. */
const CHARGE_TYPES = [
  { value: '1', label: 'Property tax' },
  { value: '2', label: 'Water charges' },
  { value: '3', label: 'Waste charges' },
];

/**
 * Village residents — replaces village_owner_master.aspx and v_resident.aspx.
 * The owner record is separate from the house record, so this edits
 * house_owner while the houses page edits `house`.
 */
export function VillageResidentsPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState(null);
  const [confirming, setConfirming] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await village.owners();
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const save = async (event) => {
    event.preventDefault();
    if (!form.name.trim()) {
      setError(new Error('Owner name is required'));
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const body = {
        name: form.name,
        houseId: Number(form.houseId),
        address: form.address,
        mobile: form.mobile,
        altMobile: form.altMobile,
        idProofPath: form.idProofPath,
      };
      if (form.__id) await village.updateOwner(form.__id, body);
      else await village.createOwner(body);
      setForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  return (
    <section>
      <PageHeader title="Village residents" subtitle={`${rows.length} resident(s)`}>
        <button
          type="button"
          className="btn-primary"
          onClick={() =>
            setForm({ name: '', houseId: '', address: '', mobile: '', altMobile: '', idProofPath: '' })
          }
        >
          Add resident
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Residents" value={rows.length} />
        <StatCard
          label="Property tax due"
          value={money(rows.reduce((s, r) => s + Number(r.gharpatti_charges || 0), 0))}
        />
        <StatCard
          label="Water charges"
          value={money(rows.reduce((s, r) => s + Number(r.water_charges || 0), 0))}
        />
      </div>

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={[
            { key: 'name', label: 'Owner' },
            { key: 'house_no', label: 'House no.' },
            { key: 'house_type', label: 'Type' },
            { key: 'address', label: 'Address' },
            { key: 'pre_mob', label: 'Contact' },
            { key: 'area', label: 'Area', align: 'right' },
            { key: 'gharpatti_charges', label: 'Property tax', align: 'right', render: money },
          ]}
          rows={rows}
          idKey="house_id"
          loading={loading}
          exportName="village-residents"
          emptyTitle="No residents recorded"
          actions={(row) => (
            <>
              <button
                type="button"
                className="btn-secondary mr-2"
                onClick={() =>
                  setForm({
                    __id: row.village_owner_id,
                    name: row.name ?? '',
                    houseId: row.house_id ?? '',
                    address: row.address ?? '',
                    mobile: row.pre_mob ?? '',
                    altMobile: '',
                    idProofPath: '',
                  })
                }
              >
                Edit
              </button>
              <button
                type="button"
                className="btn-danger"
                onClick={() =>
                  setConfirming({
                    title: 'Delete resident',
                    message: `Delete ${row.name}?`,
                    run: () => village.removeOwner(row.village_owner_id),
                  })
                }
              >
                Delete
              </button>
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(form)}
        title={form?.__id ? 'Edit resident' : 'Add resident'}
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="vres-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="vres-form" onSubmit={save} className="grid gap-4 sm:grid-cols-2" noValidate>
            {[
              ['name', 'Owner name', true, 'text'],
              ['houseId', 'House ID', true, 'number'],
              ['mobile', 'Mobile number', false, 'text'],
              ['altMobile', 'Alternate mobile', false, 'text'],
            ].map(([key, label, required, type]) => (
              <TextField
                key={key}
                label={label}
                name={key}
                type={type}
                required={required}
                value={form[key]}
                onChange={(e) => {
                  const { value } = e.target;
                  setForm((p) => ({ ...p, [key]: value }));
                }}
              />
            ))}
            <TextField
              label="Address"
              name="address"
              className="sm:col-span-2"
              value={form.address}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, address: value }));
              }}
            />
            <FileUploadField
              label="ID proof"
              category="owner-documents"
              className="sm:col-span-2"
              currentPath={form.idProofPath}
              onUploaded={(f) => f && setForm((p) => ({ ...p, idProofPath: f.path }))}
            />
            <div className="sm:col-span-2">
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

/**
 * Payment modes offered by v_tax_payment.aspx's ddlPaymentMethod. The values
 * are the pay_mode ids the SP stores, not display order.
 */
const PAY_METHODS = [
  { value: 1, label: 'Cash' },
  { value: 4, label: 'UPI' },
  { value: 2, label: 'Cheque' },
];

const EMPTY_PAYMENT = { payMode: 1, transactionRef: '', chequeNo: '', chequeDate: '', remark: '' };

/**
 * Taking money is guarded the same way bill generation and receipt entry are:
 * the API is built and validated, but the button stays disabled until the flow
 * has been exercised against a test database.
 * Set VITE_ENABLE_VILLAGE_PAYMENTS=true to enable it.
 */
const PAYMENTS_ENABLED = import.meta.env.VITE_ENABLE_VILLAGE_PAYMENTS === 'true';

/**
 * Village payments — replaces v_payments.aspx, v_tax_payment.aspx and
 * house_tax_receipt.aspx. Pending charges by type, plus the paid receipts log.
 */
export function VillagePaymentsPage() {
  const [tab, setTab] = useState('pending');
  const [chargeType, setChargeType] = useState('1');
  const [pending, setPending] = useState([]);
  const [receipts, setReceipts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [viewing, setViewing] = useState(null);

  // Pay modal: which house, its unpaid bills, and which are ticked.
  const [paying, setPaying] = useState(null); // { house, bills, selected:Set }
  const [payForm, setPayForm] = useState({ ...EMPTY_PAYMENT });
  const [payBusy, setPayBusy] = useState(false);
  const [payError, setPayError] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [p, r] = await Promise.all([
        village.houseTaxPending().catch(() => ({ items: [] })),
        village.houseTaxReceipts().catch(() => ({ items: [] })),
      ]);
      setPending(p.items ?? []);
      setReceipts(r.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  /** Open the pay modal for a house, loading its unpaid bills of this type. */
  const openPay = async (house) => {
    setPayError(null);
    setPayForm({ ...EMPTY_PAYMENT });
    setPaying({ house, bills: [], selected: new Set(), loading: true });
    try {
      const d = await village.houseTaxBills(house.house_id, Number(chargeType));
      const bills = (d.items ?? []).filter((b) => Number(b.payment_status) !== 1);
      setPaying({
        house,
        bills,
        // Legacy pre-ticked nothing; "Pay All" is the select-all box below.
        selected: new Set(),
        loading: false,
      });
    } catch (err) {
      setPayError(err);
      setPaying({ house, bills: [], selected: new Set(), loading: false });
    }
  };

  const toggleBill = (id) =>
    setPaying((p) => {
      const next = new Set(p.selected);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return { ...p, selected: next };
    });

  const toggleAll = () =>
    setPaying((p) => ({
      ...p,
      selected:
        p.selected.size === p.bills.length
          ? new Set()
          : new Set(p.bills.map((b) => Number(b.house_receipt_id))),
    }));

  const selectedTotal = paying
    ? paying.bills
        .filter((b) => paying.selected.has(Number(b.house_receipt_id)))
        .reduce((s, b) => s + Number(b.pending_amount || 0), 0)
    : 0;

  const submitPayment = async (e) => {
    e.preventDefault();
    setPayBusy(true);
    setPayError(null);
    try {
      await village.payHouseTax({
        receiptIds: [...paying.selected],
        payMode: Number(payForm.payMode),
        transactionRef: payForm.transactionRef,
        chequeNo: payForm.chequeNo,
        chequeDate: payForm.chequeDate,
        remark: payForm.remark,
      });
      setPaying(null);
      await load();
    } catch (err) {
      setPayError(err);
    } finally {
      setPayBusy(false);
    }
  };

  const totals = useMemo(
    () => ({
      property: pending.reduce((s, r) => s + Number(r.pending_property_tax || 0), 0),
      water: pending.reduce((s, r) => s + Number(r.pending_water_charges || 0), 0),
      waste: pending.reduce((s, r) => s + Number(r.pending_waste_charges || 0), 0),
      collected: receipts.reduce((s, r) => s + Number(r.Amount_paid || 0), 0),
    }),
    [pending, receipts],
  );

  return (
    <section>
      <PageHeader title="Village payments" subtitle="Pending charges and collected receipts">
        <button type="button" className="btn-secondary" onClick={() => window.print()}>
          Print
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-4">
        <StatCard label="Property tax due" value={money(totals.property)} tone="negative" />
        <StatCard label="Water charges due" value={money(totals.water)} tone="negative" />
        <StatCard label="Waste charges due" value={money(totals.waste)} tone="negative" />
        <StatCard label="Collected" value={money(totals.collected)} tone="positive" />
      </div>

      <Tabs
        tabs={[
          { id: 'pending', label: 'Pending charges', count: pending.length },
          { id: 'receipts', label: 'Receipts', count: receipts.length },
        ]}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      <ErrorNotice error={error} onRetry={load} />

      {tab === 'pending' ? (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              { key: 'owner_name', label: 'Owner' },
              { key: 'house_no', label: 'House' },
              { key: 'pre_mob', label: 'Contact' },
              { key: 'pending_property_tax', label: 'Property tax', align: 'right', render: money },
              { key: 'pending_water_charges', label: 'Water', align: 'right', render: money },
              { key: 'pending_waste_charges', label: 'Waste', align: 'right', render: money },
              {
                key: 'house_id',
                label: 'Total due',
                align: 'right',
                render: (_v, r) =>
                  money(
                    Number(r.pending_property_tax || 0) +
                      Number(r.pending_water_charges || 0) +
                      Number(r.pending_waste_charges || 0),
                  ),
              },
            ]}
            rows={pending}
            idKey="house_id"
            loading={loading}
            exportName="village-pending-charges"
            emptyTitle="No pending charges"
            actions={(row) => (
              <button
                type="button"
                className="btn-primary"
                disabled={!PAYMENTS_ENABLED}
                title={
                  PAYMENTS_ENABLED
                    ? undefined
                    : 'Payments are disabled until the flow has been run against a test database (VITE_ENABLE_VILLAGE_PAYMENTS)'
                }
                onClick={() => openPay(row)}
              >
                Pay
              </button>
            )}
          />
        </div>
      ) : (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              { key: 'receipt_no', label: 'Receipt' },
              { key: 'name', label: 'Owner' },
              { key: 'house_no', label: 'House' },
              { key: 'payment_type_name', label: 'Charge type' },
              { key: 'pay_date', label: 'Date', render: day },
              { key: 'pay_mode', label: 'Mode' },
              { key: 'Amount_paid', label: 'Amount', align: 'right', render: money },
            ]}
            rows={receipts}
            idKey="house_receipt_id"
            loading={loading}
            exportName="village-receipts"
            emptyTitle="No receipts recorded"
            actions={(row) => (
              <button type="button" className="btn-secondary" onClick={() => setViewing(row)}>
                View
              </button>
            )}
          />
        </div>
      )}

      <Modal
        open={Boolean(viewing)}
        title={`Receipt ${viewing?.receipt_no ?? ''}`}
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
        {viewing ? (
          <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
            {[
              ['Receipt number', viewing.receipt_no],
              ['Owner', viewing.name],
              ['House number', viewing.house_no],
              ['Address', viewing.address],
              ['Contact', viewing.pre_mob],
              ['Charge type', viewing.payment_type_name],
              ['Payment date', day(viewing.pay_date)],
              ['Payment mode', viewing.pay_mode],
              ['Cheque number', viewing.chqno],
              ['Cheque date', day(viewing.chqdate)],
              ['Amount paid', money(viewing.Amount_paid)],
            ].map(([label, value]) => (
              <div key={label}>
                <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
                <dd className="mt-0.5 text-slate-800">{value || '—'}</dd>
              </div>
            ))}
          </dl>
        ) : null}
      </Modal>

      {/* Pay modal — v_tax_payment.aspx's #taxModal. */}
      <Modal
        open={Boolean(paying)}
        title={`Pay charges — ${paying?.house?.owner_name ?? ''} (house ${paying?.house?.house_no ?? ''})`}
        onClose={() => setPaying(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setPaying(null)}>
              Cancel
            </button>
            <button
              type="submit"
              form="village-pay-form"
              className="btn-primary"
              disabled={payBusy || !paying?.selected?.size}
            >
              {payBusy ? 'Processing…' : `Process Payment (${money(selectedTotal)})`}
            </button>
          </>
        }
      >
        {paying?.loading ? (
          <Spinner label="Loading pending bills…" />
        ) : paying ? (
          <form id="village-pay-form" onSubmit={submitPayment} className="space-y-4">
            {paying.bills.length === 0 ? (
              <EmptyState title="No unpaid bills of this type for this house" />
            ) : (
              <div className="overflow-hidden rounded border" style={{ borderColor: '#e3e6f0' }}>
                <table className="min-w-full">
                  <thead>
                    <tr>
                      <th className="table-head w-10">
                        <input
                          type="checkbox"
                          aria-label="Select all bills"
                          checked={paying.selected.size === paying.bills.length && paying.bills.length > 0}
                          onChange={toggleAll}
                        />
                      </th>
                      <th className="table-head">Period</th>
                      <th className="table-head">Type</th>
                      <th className="table-head text-right">Pending</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paying.bills.map((b) => {
                      const id = Number(b.house_receipt_id);
                      return (
                        <tr key={id}>
                          <td className="table-cell">
                            <input
                              type="checkbox"
                              aria-label={`Select bill ${b.receipt_no}`}
                              checked={paying.selected.has(id)}
                              onChange={() => toggleBill(id)}
                            />
                          </td>
                          <td className="table-cell">
                            {b.Month} {b.year}
                          </td>
                          <td className="table-cell">{b.payment_type_name}</td>
                          <td className="table-cell text-right">{money(b.pending_amount)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            <p className="text-sm" style={{ color: '#012970' }}>
              Selected: <strong>{paying.selected.size}</strong> bill(s) ·{' '}
              <strong>{money(selectedTotal)}</strong>
            </p>
            <p className="text-xs" style={{ color: '#6b7280' }}>
              Each selected bill is settled in full — the stored procedure does not
              support part payment.
            </p>

            <div className="grid gap-3 sm:grid-cols-2">
              <SelectField
                label="Payment method"
                name="payMode"
                required
                placeholder=""
                options={PAY_METHODS}
                value={String(payForm.payMode)}
                onChange={(e) => setPayForm((p) => ({ ...p, payMode: Number(e.target.value) }))}
              />
              {Number(payForm.payMode) !== 1 ? (
                <TextField
                  label="Transaction reference"
                  name="transactionRef"
                  required
                  value={payForm.transactionRef}
                  onChange={(e) => setPayForm((p) => ({ ...p, transactionRef: e.target.value }))}
                />
              ) : null}
              {Number(payForm.payMode) === 2 ? (
                <>
                  <TextField
                    label="Cheque number"
                    name="chequeNo"
                    required
                    value={payForm.chequeNo}
                    onChange={(e) => setPayForm((p) => ({ ...p, chequeNo: e.target.value }))}
                  />
                  <TextField
                    label="Cheque date"
                    name="chequeDate"
                    type="date"
                    value={payForm.chequeDate}
                    onChange={(e) => setPayForm((p) => ({ ...p, chequeDate: e.target.value }))}
                  />
                </>
              ) : null}
              <TextField
                label="Remarks"
                name="remark"
                className="sm:col-span-2"
                value={payForm.remark}
                onChange={(e) => setPayForm((p) => ({ ...p, remark: e.target.value }))}
              />
            </div>

            <ErrorNotice error={payError} />
          </form>
        ) : null}
      </Modal>
    </section>
  );
}

/**
 * House tax and water tax registers. Both read through application-level
 * fallbacks because `house_owner.house_no` does not exist — see
 * docs/MIGRATION-MAP.md §7.1. Village bill generation stays disabled until
 * that defect is resolved.
 */
export function VillageTaxPage({ kind = 'house' }) {
  const isWater = kind === 'water';
  const [rows, setRows] = useState([]);
  const [source, setSource] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = isWater ? await village.waterTax() : await village.houseTax();
      setRows(data.items ?? []);
      setSource(data.source ?? '');
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [isWater]);

  useEffect(() => {
    load();
  }, [load]);

  const columns = isWater
    ? [
        { key: 'house_no', label: 'House no.' },
        { key: 'owner_name', label: 'Owner' },
        { key: 'connection_type', label: 'Connection' },
        { key: 'water_connection_size', label: 'Size' },
        { key: 'water_tax_amount', label: 'Amount', align: 'right', render: money },
        { key: 'due', label: 'Due', align: 'right', render: money },
      ]
    : [
        { key: 'house_no', label: 'House no.' },
        { key: 'owner_name', label: 'Owner' },
        { key: 'house_tax_bill_no', label: 'Bill no.' },
        { key: 'from_date', label: 'From', render: day },
        { key: 'to_date', label: 'To', render: day },
        { key: 'house_tax_amount', label: 'Amount', align: 'right', render: money },
        { key: 'due', label: 'Due', align: 'right', render: money },
      ];

  const totalDue = rows.reduce((s, r) => s + Number(r.due || 0), 0);

  return (
    <section>
      <PageHeader
        title={isWater ? 'Water tax' : 'House tax'}
        subtitle={`${rows.length} record(s) · ${money(totalDue)} outstanding`}
      >
        <button type="button" className="btn-secondary" onClick={() => window.print()}>
          Print
        </button>
      </PageHeader>

      <ErrorNotice error={error} onRetry={load} />

      {/* Surfaced rather than hidden: the screen is reading around a known
          database defect, and generation is unavailable because of it. */}
      <div className="mb-4 rounded-md border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
        <p className="font-medium">Bill generation unavailable</p>
        <p className="mt-1">
          {isWater ? 'sp_water_tax' : 'sp_house_tax'} and its view both join{' '}
          <code>house_owner.house_no</code>, a column that does not exist. This register reads the
          underlying table directly instead. Generating village bills additionally needs
          <code> house_owner.house_type</code>, which is also absent — see the pending SQL items.
        </p>
      </div>

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={rows}
          idKey={isWater ? 'water_tax_id' : 'house_tax_id'}
          loading={loading}
          exportName={isWater ? 'water-tax' : 'house-tax'}
          emptyTitle={`No ${isWater ? 'water tax' : 'house tax'} records`}
          emptyHint="Generated bills will appear here once generation is available."
        />
      </div>

      {source ? <p className="mt-2 text-xs text-slate-400">Source: {source}</p> : null}
    </section>
  );
}
