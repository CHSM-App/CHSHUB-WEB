import { useCallback, useEffect, useMemo, useState } from 'react';
import { village } from '@/api/modules';
import { EmptyState, ErrorNotice, Spinner } from '@/components/ui.jsx';
import { PageHeader, StatCard, Tabs } from '@/components/FormControls.jsx';
import DataGrid from '@/components/DataGrid.jsx';

/*
 * Village billing reports.
 *
 * Analytics & Reports used to open the balance sheet — a list of accounting
 * heads, which answers none of the questions a panchayat clerk has. These four
 * are those questions: what was billed against what came in, who owes, what
 * was collected each month, and one household's history.
 *
 * Every figure comes from sp_village_report, so the tabs cannot disagree about
 * what "collected" means.
 */

const money = (v) =>
  v == null || v === ''
    ? '—'
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/** "2026" for a yearly charge, "January 2026" for a monthly one. */
const periodLabel = (year, month) =>
  month ? `${MONTHS[month - 1]} ${year}` : String(year ?? '');

const TABS = [
  { id: 'collection', label: 'Collection' },
  { id: 'defaulters', label: 'Defaulters' },
  { id: 'monthly', label: 'Monthly collection' },
  { id: 'ledger', label: 'House ledger' },
];

export default function VillageReportsPage() {
  const [tab, setTab] = useState('collection');
  const [collection, setCollection] = useState([]);
  const [defaulters, setDefaulters] = useState([]);
  const [monthly, setMonthly] = useState([]);
  const [ledger, setLedger] = useState(null);
  const [houseId, setHouseId] = useState('');
  const [houses, setHouses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    Promise.all([
      village.reportCollection(),
      village.reportDefaulters(),
      village.reportMonthly(),
      // The ledger picker needs house numbers; the defaulters list only has
      // the ones that owe.
      village.houses(),
    ])
      .then(([c, d, m, h]) => {
        if (cancelled) return;
        setCollection(c.items ?? []);
        setDefaulters(d.items ?? []);
        setMonthly(m.items ?? []);
        setHouses(h.items ?? []);
      })
      .catch((err) => !cancelled && setError(err))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  const loadLedger = useCallback(async (id) => {
    setHouseId(id);
    setLedger(null);
    if (!id) return;
    try {
      const data = await village.reportLedger(id);
      setLedger(data);
    } catch (err) {
      setError(err);
    }
  }, []);

  const totals = useMemo(
    () => ({
      billed: collection.reduce((s, r) => s + Number(r.billed || 0), 0),
      collected: collection.reduce((s, r) => s + Number(r.collected || 0), 0),
      outstanding: collection.reduce((s, r) => s + Number(r.outstanding || 0), 0),
    }),
    [collection],
  );

  if (loading) return <Spinner />;

  return (
    <section>
      <PageHeader title="Reports" subtitle="What was billed, what came in, and who still owes" />

      <ErrorNotice error={error} />

      {/* The three figures every tab is a different view of. */}
      <div className="mb-4 grid gap-3 sm:grid-cols-3 print:hidden">
        <StatCard label="Billed" value={money(totals.billed)} />
        <StatCard label="Collected" value={money(totals.collected)} tone="positive" />
        <StatCard label="Outstanding" value={money(totals.outstanding)} tone="negative" />
      </div>

      <Tabs tabs={TABS} active={tab} onChange={setTab} className="mb-4" />

      {tab === 'collection' ? (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              { key: 'payment_type_name', label: 'Charge' },
              {
                key: 'frequency',
                label: 'Raised',
                render: (v) => (v === 'Y' ? 'Yearly' : 'Monthly'),
                exportValue: (r) => (r.frequency === 'Y' ? 'Yearly' : 'Monthly'),
              },
              { key: 'bills', label: 'Bills', align: 'right' },
              {
                key: 'billed',
                label: 'Billed',
                align: 'right',
                render: money,
                exportValue: (r) => money(r.billed),
              },
              {
                key: 'collected',
                label: 'Collected',
                align: 'right',
                render: money,
                exportValue: (r) => money(r.collected),
              },
              {
                key: 'outstanding',
                label: 'Outstanding',
                align: 'right',
                render: money,
                exportValue: (r) => money(r.outstanding),
              },
              {
                /*
                 * How much of what was billed has come in. Shown because two
                 * charges can owe similar amounts while one is nearly settled
                 * and the other has barely started.
                 */
                key: 'rate',
                label: 'Collected %',
                align: 'right',
                render: (_v, r) =>
                  Number(r.billed) > 0
                    ? `${Math.round((Number(r.collected) / Number(r.billed)) * 100)}%`
                    : '—',
                exportValue: (r) =>
                  Number(r.billed) > 0
                    ? `${Math.round((Number(r.collected) / Number(r.billed)) * 100)}%`
                    : '',
              },
            ]}
            rows={collection}
            idKey="payment_type"
            exportName="village-collection"
            exportTitle="Collection by charge"
            emptyTitle="Nothing billed yet"
          />
        </div>
      ) : null}

      {tab === 'defaulters' ? (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              { key: 'house_no', label: 'House' },
              { key: 'owner_name', label: 'Owner' },
              { key: 'contact', label: 'Contact' },
              { key: 'unpaid_bills', label: 'Unpaid bills', align: 'right' },
              {
                // How far behind, which is what decides whether a reminder or
                // a notice is called for.
                key: 'periods',
                label: 'Periods owed',
                align: 'right',
              },
              { key: 'oldest_period', label: 'Owing since' },
              {
                key: 'outstanding',
                label: 'Outstanding',
                align: 'right',
                render: money,
                exportValue: (r) => money(r.outstanding),
              },
            ]}
            rows={defaulters}
            idKey="house_id"
            searchable
            searchPlaceholder="Search house or owner…"
            exportName="village-defaulters"
            exportTitle="Outstanding by household"
            emptyTitle="Nothing outstanding"
          />
        </div>
      ) : null}

      {tab === 'monthly' ? (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              {
                key: 'm',
                label: 'Month',
                render: (_v, r) => periodLabel(r.y, r.m),
                exportValue: (r) => periodLabel(r.y, r.m),
              },
              { key: 'receipts', label: 'Payments', align: 'right' },
              {
                key: 'collected',
                label: 'Collected',
                align: 'right',
                render: money,
                exportValue: (r) => money(r.collected),
              },
            ]}
            rows={monthly}
            idKey="m"
            exportName="village-monthly-collection"
            exportTitle="Collection by month"
            emptyTitle="Nothing collected yet"
          />
        </div>
      ) : null}

      {tab === 'ledger' ? (
        <div>
          <div className="card mb-4 p-4 print:hidden">
            <label className="block">
              <span className="field-label">House</span>
              <select
                className="field-input w-64"
                value={houseId}
                onChange={(e) => loadLedger(e.target.value)}
              >
                <option value="">Choose a house…</option>
                {houses.map((h) => (
                  <option key={h.house_id} value={h.house_id}>
                    {h.house_no} — {h.name ?? ''}
                  </option>
                ))}
              </select>
            </label>
          </div>

          {!houseId ? (
            <div className="card">
              <EmptyState
                title="Choose a house"
                hint="Its bills and payments are listed here, oldest first."
              />
            </div>
          ) : !ledger ? (
            <Spinner />
          ) : (
            <>
              <div className="mb-4 grid gap-3 sm:grid-cols-3">
                <StatCard label="Billed" value={money(ledger.totals?.billed)} />
                <StatCard label="Paid" value={money(ledger.totals?.paid)} tone="positive" />
                <StatCard
                  label="Outstanding"
                  value={money(ledger.totals?.outstanding)}
                  tone="negative"
                />
              </div>

              <div className="card overflow-hidden">
                <DataGrid
                  columns={[
                    {
                      key: 'bill_year',
                      label: 'Period',
                      render: (_v, r) => periodLabel(r.bill_year, r.bill_month),
                      exportValue: (r) => periodLabel(r.bill_year, r.bill_month),
                    },
                    { key: 'payment_type_name', label: 'Charge' },
                    {
                      key: 'amount',
                      label: 'Amount',
                      align: 'right',
                      render: money,
                      exportValue: (r) => money(r.amount),
                    },
                    { key: 'status', label: 'Status' },
                    {
                      key: 'paid_on',
                      label: 'Paid on',
                      render: day,
                      exportValue: (r) => (r.paid_on ? day(r.paid_on) : ''),
                    },
                    { key: 'receipt_no', label: 'Receipt' },
                  ]}
                  rows={ledger.items ?? []}
                  idKey="house_receipt_id"
                  exportName={`village-ledger-${houseId}`}
                  exportTitle="House ledger"
                  emptyTitle="No bills for this house"
                />
              </div>
            </>
          )}
        </div>
      ) : null}
    </section>
  );
}
