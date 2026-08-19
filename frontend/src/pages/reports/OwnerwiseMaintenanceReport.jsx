import { useCallback, useEffect, useMemo, useState } from 'react';
import { reports } from '@/api/modules';
import { buildings as buildingsApi, residents as ownersApi } from '@/api/masters';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import ReportHeader, { ReportFooter, useSocietyInfo } from '@/components/ReportDocument.jsx';
import { EmptyState, ErrorNotice, Field, Spinner } from '@/components/ui.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';

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

// Spelled-out form for the period line — "10 Aug 2026" rather than 10/08/2026,
// which reads as ambiguous next to the American order.
const longDay = (v) => {
  if (!v) return '';
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return String(v);
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
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

  const society = useSocietyInfo();
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

  /*
   * The opening, total and closing rows frame the statement, so they are held
   * out of the paging and kept on every page — a closing balance stranded on
   * page 1 of 6 would read as the balance after 25 transactions. Only seq 2,
   * the transactions themselves, pages. Export and print still take `items`,
   * so the file and the paper keep the whole statement.
   */
  const entries = items.filter((r) => Number(r.seq) === 2);
  const balances = items.filter((r) => Number(r.seq) !== 2);
  const opening = balances.filter((r) => Number(r.seq) === 1);
  const closing = balances.filter((r) => Number(r.seq) !== 1);

  const paging = usePaging(entries.length, 25);
  const pageRows = entries.slice(paging.first, paging.first + paging.size);

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
    { key: 'ref', label: 'Transaction Ref', exportValue: (r) => r.ref ?? '' },
    // align: 'right' also narrows these columns in the PDF and right-aligns
    // the figures, so the decimal points line up.
    {
      key: 'Maintenance',
      label: 'Maintenance',
      align: 'right',
      exportValue: (r) => money(r.Maintenance),
    },
    {
      key: 'Payment',
      label: 'Paid Maintenance',
      align: 'right',
      exportValue: (r) => money(r.Payment),
    },
  ];

  // Opening / Total / Closing are computed rows, not transactions. Naming the
  // kind lets the PDF tint each one the same colour ROW_STYLE gives it on
  // screen, rather than shading all three alike.
  const PDF_ROW_KIND = { 1: 'opening', 3: 'total', 4: 'closing' };
  const balanceRowKind = (r) => PDF_ROW_KIND[Number(r.seq)] ?? null;

  // Labels as the legacy print view wrote them.
  const reportFilters = [
    { label: 'Building Name', value: buildingName },
    { label: 'Owner Name', value: ownerName },
    { label: 'Period', value: from && to ? `${longDay(from)} to ${longDay(to)}` : '' },
  ];

  return (
    <section>
      {/* Screen heading. Hidden on paper, where the report document below
          prints its own title and criteria. */}
      <header className="mb-4 print:hidden">
        <h1 className="text-lg font-semibold text-slate-800">Owner wise Maintenance Bill Reports</h1>
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
        <div className="card overflow-hidden print:border-0 print:shadow-none">
          {/* Replaces the page's Print and Download PDF buttons, which built the
              PDF by scraping the rendered table with jsPDF. */}
          <ExportToolbar
            columns={columns}
            rows={items}
            exportName="ownerwise-maintenance"
            exportTitle="Ownerwise Maintenance Bill Report"
            filters={reportFilters}
            emphasiseRow={balanceRowKind}
          />
          {/* Print only. On screen the page heading and the filter form above
              already say all this, and the grid is what the user came for. */}
          <div className="px-4 print:px-0">
            <ReportHeader
              title="Ownerwise Maintenance Bill Report"
              info={society}
              filters={reportFilters}
            />
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {columns.map((c) => (
                    <th
                      key={c.key}
                      className={`table-head ${c.align === 'right' ? 'text-right' : ''}`}
                    >
                      {c.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {[...opening, ...pageRows, ...closing].map((r, i) => (
                  /*
                    The labels come from `columns`, which is also what draws
                    the headers above — the two cannot drift apart, and the
                    phone card view names each line the same way the column
                    is named on a wide screen.
                  */
                  <tr key={i} className={ROW_STYLE[Number(r.seq)] ?? 'hover:bg-slate-50'}>
                    <td className="table-cell" data-label={columns[0].label}>{day(r.date)}</td>
                    <td className="table-cell" data-label={columns[1].label}>{r.Particular}</td>
                    {/* Balance rows carry no reference — the SP sends NULL. */}
                    <td className="table-cell" data-label={columns[2].label}>{r.ref || '—'}</td>
                    <td className="table-cell text-right" data-label={columns[3].label}>
                      {money(r.Maintenance)}
                    </td>
                    <td className="table-cell text-right" data-label={columns[4].label}>
                      {money(r.Payment)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pager
            page={paging.page}
            pageCount={paging.pageCount}
            first={paging.first}
            last={paging.last}
            total={entries.length}
            onPage={paging.setPage}
          />
          <div className="px-4 print:px-0">
            <ReportFooter />
          </div>
        </div>
      )}
    </section>
  );
}
