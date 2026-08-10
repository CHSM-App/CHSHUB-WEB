import { useCallback, useEffect, useMemo, useState } from 'react';
import { reports } from '@/api/modules';
import { buildings as buildingsApi, residents as ownersApi } from '@/api/masters';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import { EmptyState, ErrorNotice, Field, Spinner } from '@/components/ui.jsx';

const money = (v) =>
  v == null || v === ''
    ? '—'
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// The grid printed dd-MM-yyyy; the SP already formats the opening-balance row
// as "01 Apr 2025", so only real dates need converting.
const day = (v) => {
  if (!v) return '';
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? String(v) : d.toLocaleDateString('en-GB');
};

// Page_Load defaulted the period to 1 April of the current year → today.
const financialYearStart = () => `${new Date().getFullYear()}-04-01`;
const today = () => new Date().toISOString().slice(0, 10);

/**
 * The balance rows the SP tags with `seq`: 1 opening, 3 total, 4 closing.
 * The legacy page coloured these with nth-child CSS — light green for the
 * second row, light blue for the second-last, orange for the last — which only
 * held while the row order never changed. `seq` says what each row is, so the
 * colour follows the row itself.
 */
const ROW_STYLE = {
  1: 'bg-emerald-50 font-semibold',
  3: 'bg-sky-50 font-semibold',
  4: 'bg-amber-50 font-semibold',
};

export default function OwnerwiseMaintenanceReport() {
  const [buildingId, setBuildingId] = useState('');
  const [ownerId, setOwnerId] = useState('');
  const [from, setFrom] = useState(financialYearStart);
  const [to, setTo] = useState(today);

  const [buildings, setBuildings] = useState([]);
  const [owners, setOwners] = useState([]);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    buildingsApi
      .list()
      .then((d) => !cancelled && setBuildings(d.items ?? d ?? []))
      .catch(() => !cancelled && setBuildings([]));
    return () => {
      cancelled = true;
    };
  }, []);

  // CategoryRepeater_ItemCommand1 refilled the owner list whenever a building
  // was picked, so an owner from another building can never be selected.
  useEffect(() => {
    setOwnerId('');
    if (!buildingId) {
      setOwners([]);
      return undefined;
    }
    let cancelled = false;
    ownersApi
      .list({ buildingId })
      .then((d) => !cancelled && setOwners(d.items ?? d ?? []))
      .catch(() => !cancelled && setOwners([]));
    return () => {
      cancelled = true;
    };
  }, [buildingId]);

  const run = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setData(await reports.ownerLedger({ ownerId, buildingId, from, to }));
    } catch (err) {
      setError(err);
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [ownerId, buildingId, from, to]);

  const items = data?.items ?? [];
  const ready = Boolean(buildingId && ownerId);

  // Used by the export toolbar and the printed heading.
  const buildingName = useMemo(
    () => buildings.find((b) => String(b.build_id) === String(buildingId))?.name ?? '',
    [buildings, buildingId],
  );
  const ownerName = useMemo(
    () => owners.find((o) => String(o.owner_id) === String(ownerId))?.name ?? '',
    [owners, ownerId],
  );

  // ledger columns as the grid had them, plus Transaction Ref which the grid
  // showed but the RDLC left out.
  const columns = [
    { key: 'date', label: 'Date', exportValue: (r) => day(r.date) },
    { key: 'Particular', label: 'Particular' },
    { key: 'ref', label: 'Transaction Ref' },
    { key: 'Maintenance', label: 'Maintenance', exportValue: (r) => r.Maintenance },
    { key: 'Payment', label: 'Paid Maintenance', exportValue: (r) => r.Payment },
  ];

  return (
    <section>
      <header className="mb-4 print:mb-2">
        <h1 className="text-lg font-semibold text-slate-800">Owner wise Maintenance Bill Reports</h1>
        {/* The legacy print view repeated the filters above the table; kept for
            the printed copy, where the form itself is hidden. */}
        {ready && data ? (
          <p className="text-sm text-slate-500">
            {buildingName} · {ownerName} · {day(from)} to {day(to)}
          </p>
        ) : (
          <p className="text-sm text-slate-500">Choose a building and owner, then a period</p>
        )}
      </header>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (ready) run();
        }}
        className="card mb-4 flex flex-wrap items-end gap-3 p-4 print:hidden"
      >
        <div className="w-56">
          <Field label="Building Name" required>
            <select
              className="field-input"
              value={buildingId}
              onChange={(e) => setBuildingId(e.target.value)}
              required
            >
              <option value="">Select Building</option>
              {buildings.map((b) => (
                <option key={b.build_id} value={b.build_id}>
                  {b.name}
                </option>
              ))}
            </select>
          </Field>
        </div>
        <div className="w-56">
          <Field label="Owner Name" required>
            <select
              className="field-input"
              value={ownerId}
              onChange={(e) => setOwnerId(e.target.value)}
              disabled={!buildingId}
              required
            >
              <option value="">{buildingId ? 'Select Owner' : 'Select a building first'}</option>
              {owners.map((o) => (
                <option key={o.owner_id} value={o.owner_id}>
                  {o.name}
                </option>
              ))}
            </select>
          </Field>
        </div>
        <div className="w-44">
          <Field label="From Date">
            <input className="field-input" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
          </Field>
        </div>
        <div className="w-44">
          <Field label="To Date">
            <input className="field-input" type="date" value={to} onChange={(e) => setTo(e.target.value)} />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={!ready || loading}>
          {loading ? 'Loading…' : 'Search'}
        </button>
      </form>

      <ErrorNotice error={error} onRetry={ready ? run : undefined} />

      {loading ? (
        <Spinner />
      ) : !data ? (
        <EmptyState
          title="No report yet"
          hint="Pick a building and an owner, then choose a period and press Search."
        />
      ) : items.length === 0 ? (
        <EmptyState title="No Record Found" />
      ) : (
        <div className="card overflow-hidden">
          {/* Replaces the page's Print and Download PDF buttons, which built the
              PDF by scraping the rendered table with jsPDF. */}
          <ExportToolbar
            columns={columns}
            rows={items}
            exportName="ownerwise-maintenance"
            exportTitle="Ownerwise Maintenance Bill Report"
          />
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  {columns.map((c) => (
                    <th
                      key={c.key}
                      className={`table-head ${
                        c.key === 'Maintenance' || c.key === 'Payment' ? 'text-right' : ''
                      }`}
                    >
                      {c.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {items.map((r, i) => (
                  <tr key={i} className={ROW_STYLE[Number(r.seq)] ?? 'hover:bg-slate-50'}>
                    <td className="table-cell">{day(r.date)}</td>
                    <td className="table-cell">{r.Particular}</td>
                    {/* Balance rows carry no reference — the SP sends NULL. */}
                    <td className="table-cell">{r.ref || '—'}</td>
                    <td className="table-cell text-right">{money(r.Maintenance)}</td>
                    <td className="table-cell text-right">{money(r.Payment)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </section>
  );
}
