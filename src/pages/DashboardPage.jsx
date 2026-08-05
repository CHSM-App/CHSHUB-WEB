import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { reports } from '@/api/modules';
import { buildings, flats, wings } from '@/api/masters';
import { pdc } from '@/api/onboarding';
import { useAuth } from '@/auth/AuthContext.jsx';
import { EmptyState, ErrorNotice, Spinner } from '@/components/ui.jsx';
import { PageHeader, StatCard, Tabs } from '@/components/FormControls.jsx';

const money = (v) =>
  v == null ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 });

/**
 * Port of ToShortNumber() in dashboard.aspx.cs — k/M/B, truncated to one
 * decimal rather than rounded (`Math.Floor(n / 1000 * 10) / 10`), so 288638
 * reads "288.6k" exactly as the legacy tile did.
 */
const shortNumber = (v) => {
  const n = Math.floor(Number(v || 0));
  const cut = (unit, label) => `${Math.floor((n / unit) * 10) / 10}${label}`;
  if (n >= 1_000_000_000) return cut(1_000_000_000, 'B');
  if (n >= 1_000_000) return cut(1_000_000, 'M');
  if (n >= 1_000) return cut(1_000, 'k');
  return String(n);
};

/**
 * Income Tracker periods — the ⋮ menu on dashboard.aspx. Each supplies the
 * upper bound only: sp_dashboard/IncomeChart overrides the start with
 * MIN(gen_date) and ignores @date1, so only the end date varies.
 * This Year is the default, as Page_Load called due_this_year_Click.
 */
const INCOME_PERIODS = [
  {
    id: 'month',
    label: 'This Month',
    to: () => {
      const n = new Date();
      return new Date(n.getFullYear(), n.getMonth() + 1, 0);
    },
  },
  {
    // due_last_month_Click passes the same end date as This Month (it varies
    // only date1, which the SP discards), so the two options return identical
    // figures. Reproduced rather than corrected — changing it would make the
    // dashboard disagree with the legacy one.
    id: 'last',
    label: 'Last Month',
    to: () => {
      const n = new Date();
      return new Date(n.getFullYear(), n.getMonth() + 1, 0);
    },
  },
  {
    id: 'year',
    label: 'This Year',
    to: () => new Date(new Date().getFullYear(), 11, 31),
  },
];

// Tile glyphs, drawn inline so nothing is fetched from a CDN.
const TILE_ICONS = {
  alert: { d: 'M12 3 2 20h20L12 3Zm0 6v5m0 3v.01', color: '#e74a3b' },
  userX: { d: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM2 21a7 7 0 0 1 14 0M17 8l4 4m0-4-4 4', color: '#1cc88a' },
  users: { d: 'M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM2 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M16 20h6a5 5 0 0 0-4-4.9', color: '#4e73df' },
};

/**
 * Headline tile from dashboard.aspx: label top-left, large value bottom-left,
 * tinted glyph on the right.
 */
function HeadlineTile({ label, value, icon }) {
  const g = TILE_ICONS[icon] ?? TILE_ICONS.users;
  return (
    <div className="card flex h-full items-center justify-between p-5">
      <div className="min-w-0">
        <p className="text-sm font-medium" style={{ color: '#012970' }}>
          {label}
        </p>
        <p className="mt-2 truncate text-2xl font-bold" style={{ color: '#012970' }}>
          {value}
        </p>
      </div>
      <svg
        viewBox="0 0 24 24"
        width="40"
        height="40"
        fill="none"
        stroke={g.color}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="ml-3 shrink-0"
        aria-hidden="true"
      >
        <path d={g.d} />
      </svg>
    </div>
  );
}

/**
 * Simple bar chart in inline SVG — replaces the legacy chart controls without
 * pulling in a charting library. Values are normalised against the largest bar.
 */
function BarChart({ data, labelKey, valueKey, height = 160, tone = 'blue' }) {
  if (!data?.length) return <EmptyState title="No data for this period" />;

  const max = Math.max(...data.map((d) => Number(d[valueKey] || 0)), 1);
  const colours = { blue: 'fill-blue-600', green: 'fill-green-500', red: 'fill-red-500' };
  const barW = 100 / data.length;

  return (
    <div>
      <svg
        viewBox={`0 0 100 ${height / 4}`}
        preserveAspectRatio="none"
        className="w-full"
        style={{ height }}
        role="img"
        aria-label="Bar chart"
      >
        {data.map((d, i) => {
          const value = Number(d[valueKey] || 0);
          const h = (value / max) * (height / 4 - 2);
          return (
            <rect
              key={i}
              x={i * barW + barW * 0.15}
              y={height / 4 - h}
              width={barW * 0.7}
              height={h}
              className={colours[tone]}
              rx="0.5"
            >
              <title>{`${d[labelKey]}: ${money(value)}`}</title>
            </rect>
          );
        })}
      </svg>
      <div className="mt-1 flex text-[10px] text-slate-500">
        {data.map((d, i) => (
          <span key={i} className="flex-1 truncate text-center" title={String(d[labelKey])}>
            {String(d[labelKey]).slice(0, 3)}
          </span>
        ))}
      </div>
    </div>
  );
}

/** Donut for the due/collection split. */
function DonutChart({ segments }) {
  const total = segments.reduce((s, x) => s + Number(x.value || 0), 0);
  if (!total) return <EmptyState title="No data" />;

  let offset = 0;
  const circumference = 2 * Math.PI * 15.9155;

  return (
    <div className="flex items-center gap-4">
      <svg viewBox="0 0 42 42" className="h-32 w-32" role="img" aria-label="Split chart">
        <circle cx="21" cy="21" r="15.9155" fill="none" className="stroke-slate-100" strokeWidth="6" />
        {segments.map((s, i) => {
          const pct = (Number(s.value || 0) / total) * 100;
          const dash = `${(pct / 100) * circumference} ${circumference}`;
          const el = (
            <circle
              key={i}
              cx="21"
              cy="21"
              r="15.9155"
              fill="none"
              className={s.className}
              strokeWidth="6"
              strokeDasharray={dash}
              strokeDashoffset={-((offset / 100) * circumference)}
              transform="rotate(-90 21 21)"
            >
              <title>{`${s.label}: ${money(s.value)}`}</title>
            </circle>
          );
          offset += pct;
          return el;
        })}
      </svg>
      <ul className="space-y-1 text-sm">
        {segments.map((s) => (
          <li key={s.label} className="flex items-center gap-2">
            <span className={`inline-block h-2.5 w-2.5 rounded-full ${s.dot}`} />
            <span className="text-slate-600">{s.label}</span>
            <span className="font-medium text-slate-800">{money(s.value)}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

/**
 * Society dashboard — replaces dashboard.aspx, Admin_Dashboard.aspx and
 * village_dashboard.aspx (the Village tab appears only for village accounts).
 */
export default function DashboardPage() {
  const { user, villageId } = useAuth();
  const [data, setData] = useState(null);
  const [masters, setMasters] = useState(null);
  const [expenseChart, setExpenseChart] = useState([]);
  const [error, setError] = useState(null);
  const [tab, setTab] = useState('overview');
  // Maintenance Tracker series toggles — CheckBox1 / CheckBox2 on the legacy page.
  const [showRegular, setShowRegular] = useState(true);
  const [showAddOn, setShowAddOn] = useState(false);
  const [pdcCount, setPdcCount] = useState(0);
  // Income Tracker period — legacy defaulted to This Year on page load.
  const [period, setPeriod] = useState('year');
  const [periodOpen, setPeriodOpen] = useState(false);
  const [incomeSplit, setIncomeSplit] = useState(null); // null = use dashboard payload

  useEffect(() => {
    let cancelled = false;
    const safe = (p, fallback) => p.catch(() => fallback);

    Promise.all([
      safe(reports.dashboard(), null),
      safe(buildings.list(), { count: 0 }),
      safe(wings.list(), { count: 0 }),
      safe(flats.count(), { count: 0 }),
      safe(reports.expenseChart(2), { items: [] }),
      safe(pdc.list(), { items: [] }),
    ])
      .then(([dash, b, w, f, chart, pdcRows]) => {
        if (cancelled) return;
        setData(dash);
        setMasters({ buildings: b.count, wings: w.count, flats: f.count });
        setExpenseChart(chart.items ?? []);
        setPdcCount((pdcRows.items ?? []).length);
      })
      .catch((err) => !cancelled && setError(err));

    return () => {
      cancelled = true;
    };
  }, []);

  // Refetch the donut when the period changes. Skipped on the initial 'year'
  // selection, which the dashboard payload already covers.
  useEffect(() => {
    if (period === 'year' && incomeSplit === null) return undefined;
    let cancelled = false;
    const to = (INCOME_PERIODS.find((p) => p.id === period) ?? INCOME_PERIODS[2]).to();

    reports
      .incomeSplit(to.toISOString().slice(0, 10))
      .then((r) => !cancelled && setIncomeSplit(r.items ?? []))
      .catch(() => {});

    return () => {
      cancelled = true;
    };
    // incomeSplit is deliberately not a dependency: including it would refetch
    // in response to its own result.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [period]);

  if (!data && !masters && !error) return <Spinner label="Loading dashboard…" />;

  // Until a period is picked, the donut uses the figures the dashboard call
  // already returned; after that it follows the selection.
  const split = incomeSplit ?? data?.incomeSplit ?? [];
  const collection = split.find((r) => r.category === 'Collection')?.amount ?? 0;
  const due = split.find((r) => r.category === 'Due')?.amount ?? 0;
  // The Due Payments tile shows the IncomeChart 'Due' figure — the same number
  // the donut plots — not the defaulters roll-up.
  const dues = due;

  // Regular = the generated maintenance series (Get_Month); Add on = expenses.
  // Unticking both leaves an empty chart, which is what the legacy page did.
  const trackerSeries = [
    ...(showRegular ? (data?.monthlyDues ?? []) : []),
    ...(showAddOn
      ? expenseChart.map((r) => ({ month_name: r.expense_month, amount: r.expense }))
      : []),
  ];

  return (
    <section>
      <PageHeader
        title={`Welcome${user?.name ? `, ${user.name.split(' ')[0]}` : ''}`}
        subtitle={user?.society_name || user?.village_name || ''}
      />

      <ErrorNotice error={error} />

      <Tabs
        tabs={[
          { id: 'overview', label: 'Overview' },
          { id: 'financial', label: 'Financial' },
          { id: 'activity', label: 'Activity' },
          ...(villageId ? [{ id: 'village', label: 'Village' }] : []),
        ]}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      {tab === 'overview' ? (
        /*
         * Layout mirrors dashboard.aspx: three headline tiles across the top,
         * the Maintenance Tracker on the left, and Recent Activity plus the
         * Income Tracker stacked in a right-hand column.
         */
        /* .layout-container — grid-template-columns: 2fr 1fr, gap 16px. */
        <div className="grid gap-4 lg:grid-cols-[2fr_1fr]">
          {/* .layout-left */}
          <div className="grid content-start gap-4">
            <div className="grid gap-5 sm:grid-cols-3">
              {/* Only Due Payments and Total Members were links in the legacy page. */}
              <Link to="/billing/defaulters">
                <HeadlineTile label="Due Payments" value={`₹ ${shortNumber(dues)}`} icon="alert" />
              </Link>
              <HeadlineTile label="Defaulters" value={data?.defaulters?.count ?? 0} icon="userX" />
              <Link to="/masters/owners">
                <HeadlineTile label="Total Members" value={data?.residentCount ?? 0} icon="users" />
              </Link>
            </div>

            <div className="card p-5">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <h6 className="text-sm font-semibold" style={{ color: '#012970' }}>
                  Maintenance Tracker
                </h6>
                {/* Regular / Add on toggles the expense series, as on the legacy page. */}
                <div className="flex items-center gap-4 text-sm">
                  <label className="flex items-center gap-1.5" style={{ color: '#012970' }}>
                    <input
                      type="checkbox"
                      checked={showRegular}
                      onChange={(e) => setShowRegular(e.target.checked)}
                    />
                    Regular
                  </label>
                  <label className="flex items-center gap-1.5" style={{ color: '#012970' }}>
                    <input
                      type="checkbox"
                      checked={showAddOn}
                      onChange={(e) => setShowAddOn(e.target.checked)}
                    />
                    Add on
                  </label>
                </div>
              </div>
              <div className="my-3 border-t" style={{ borderColor: '#e3e6f0' }} />
              <BarChart data={trackerSeries} labelKey="month_name" valueKey="amount" />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="card p-5">
                <h6 className="text-sm font-semibold" style={{ color: '#012970' }}>
                  PDC Clearing
                </h6>
                <div className="my-3 border-t" style={{ borderColor: '#e3e6f0' }} />
                <p className="text-2xl font-bold" style={{ color: '#012970' }}>
                  {pdcCount}
                </p>
                <p className="text-xs" style={{ color: '#6b7280' }}>
                  cheques awaiting clearing
                </p>
                <Link to="/billing/pdc/clearing" className="mt-3 inline-block text-sm text-blue-600 hover:underline">
                  Open
                </Link>
              </div>

              <div className="card p-5">
                <h6 className="text-sm font-semibold" style={{ color: '#012970' }}>
                  Weekly Updates
                </h6>
                <div className="my-3 border-t" style={{ borderColor: '#e3e6f0' }} />
                {(data?.weeklyUpdates ?? []).length === 0 ? (
                  <p className="text-sm" style={{ color: '#6b7280' }}>
                    No Updates
                  </p>
                ) : (
                  <ul className="space-y-2 overflow-auto" style={{ maxHeight: 160 }}>
                    {(data?.weeklyUpdates ?? []).map((u, i) => (
                      <li key={i} className="text-sm" style={{ color: '#012970' }}>
                        <span className="font-medium">{u.name}</span>
                        {u.type ? (
                          <span className="ml-2 text-xs" style={{ color: '#6b7280' }}>
                            {u.type}
                          </span>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="card p-5 sm:col-span-2">
                <h6 className="text-sm font-semibold" style={{ color: '#012970' }}>
                  HelpDesk Ticket
                </h6>
                <div className="my-3 border-t" style={{ borderColor: '#e3e6f0' }} />
                <div className="grid grid-cols-2 gap-3">
                  <div className="rounded-lg p-3" style={{ background: '#fdf3f3' }}>
                    <p className="text-xs" style={{ color: '#6b7280' }}>
                      Open Ticket
                    </p>
                    <p className="text-xl font-bold" style={{ color: '#e74a3b' }}>
                      {data?.tickets?.opened ?? 0}
                    </p>
                  </div>
                  <div className="rounded-lg p-3" style={{ background: '#eefaf4' }}>
                    <p className="text-xs" style={{ color: '#6b7280' }}>
                      Resolve Tickets
                    </p>
                    <p className="text-xl font-bold" style={{ color: '#1cc88a' }}>
                      {data?.tickets?.resolved ?? 0}
                    </p>
                  </div>
                </div>
                <Link to="/community/helpdesk" className="mt-3 inline-block text-sm text-blue-600 hover:underline">
                  Open
                </Link>
              </div>
            </div>
          </div>

          {/* .layout-right */}
          <div className="grid content-start gap-4">
            <div className="card p-5">
              <h6 className="text-sm font-semibold" style={{ color: '#012970' }}>
                Recent Activity
              </h6>
              <div className="my-3 border-t" style={{ borderColor: '#e3e6f0' }} />
              {(data?.recentActivity ?? []).length === 0 ? (
                <p className="text-sm" style={{ color: '#6b7280' }}>
                  No Updates
                </p>
              ) : (
                /* Legacy scrolled this list at a fixed 226px. */
                <ul className="space-y-3 overflow-auto pr-1" style={{ maxHeight: 226 }}>
                  {(data?.recentActivity ?? []).map((a, i) => {
                    // Icon and amount colour keyed off paid_amount, as the
                    // GridView's inline Eval did: 0.00 => blue tools, else green tick.
                    const paid = Number(a.paid_amount || 0);
                    const isPayment = paid !== 0;
                    return (
                      <li key={i} className="flex items-start justify-between gap-3">
                        <div className="flex min-w-0 items-start gap-2">
                          <span
                            className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs text-white"
                            style={{ background: isPayment ? '#1cc88a' : '#4e73df' }}
                            aria-hidden="true"
                          >
                            {isPayment ? '✓' : '⚒'}
                          </span>
                          <div className="min-w-0">
                            <p className="text-sm" style={{ color: '#012970' }}>
                              {a.particular}
                            </p>
                            <p className="text-xs" style={{ color: '#9B9B9B' }}>
                              {a.timestamp}
                            </p>
                          </div>
                        </div>
                        <span
                          className="shrink-0 text-sm font-medium"
                          style={{ color: isPayment ? '#1cc88a' : '#4e73df' }}
                        >
                          {isPayment
                            ? money(paid)
                            : a.date
                              ? new Date(a.date).toLocaleDateString(undefined, { month: 'short', day: '2-digit' })
                              : ''}
                        </span>
                      </li>
                    );
                  })}
                </ul>
              )}
              <Link to="/reports/activity" className="mt-3 inline-block text-sm text-blue-600 hover:underline">
                See All
              </Link>
            </div>

            <div className="card p-5">
              <div className="flex items-start justify-between">
                <h6 className="text-sm font-semibold" style={{ color: '#012970' }}>
                  Income Tracker
                </h6>
                {/* ⋮ menu — This Month / Last Month / This Year, as on dashboard.aspx. */}
                <div className="relative">
                  <button
                    type="button"
                    className="px-2 leading-none"
                    style={{ color: '#b7b9cc' }}
                    aria-label="Change period"
                    aria-expanded={periodOpen}
                    onClick={() => setPeriodOpen((v) => !v)}
                  >
                    ⋮
                  </button>
                  {periodOpen ? (
                    <>
                      <div
                        className="fixed inset-0 z-40"
                        onClick={() => setPeriodOpen(false)}
                        aria-hidden="true"
                      />
                      <div
                        role="menu"
                        className="absolute right-0 z-50 mt-1 bg-white py-1"
                        style={{ width: 150, borderRadius: 8, boxShadow: '0 0.5rem 1rem rgba(0,0,0,.15)' }}
                      >
                        {INCOME_PERIODS.map((p) => (
                          <button
                            key={p.id}
                            type="button"
                            role="menuitem"
                            className="block w-full px-4 py-2 text-left text-sm hover:bg-slate-50"
                            style={{ color: period === p.id ? '#1d4ed8' : '#012970' }}
                            onClick={() => {
                              setPeriod(p.id);
                              setPeriodOpen(false);
                            }}
                          >
                            {p.label}
                          </button>
                        ))}
                      </div>
                    </>
                  ) : null}
                </div>
              </div>
              <div className="my-3 border-t" style={{ borderColor: '#e3e6f0' }} />
              <DonutChart
                segments={[
                  { label: 'Collection', value: collection, className: 'stroke-blue-600', dot: 'bg-blue-600' },
                  { label: 'Due', value: due, className: 'stroke-blue-300', dot: 'bg-blue-300' },
                ]}
              />
            </div>
          </div>
        </div>
      ) : null}

      {tab === 'financial' ? (
        <div className="grid gap-4 lg:grid-cols-2">
          <div className="card p-5">
            <h2 className="mb-3 text-sm font-semibold text-slate-800">Dues vs collection</h2>
            <DonutChart
              segments={[
                { label: 'Collected', value: collection, className: 'stroke-green-500', dot: 'bg-green-500' },
                { label: 'Outstanding', value: due, className: 'stroke-red-500', dot: 'bg-red-500' },
              ]}
            />
          </div>

          <div className="card p-5">
            <h2 className="mb-3 text-sm font-semibold text-slate-800">Monthly dues</h2>
            <BarChart data={data?.monthlyDues ?? []} labelKey="month_name" valueKey="amount" />
          </div>

          <div className="card p-5 lg:col-span-2">
            <h2 className="mb-3 text-sm font-semibold text-slate-800">Expenses by month</h2>
            <BarChart data={expenseChart} labelKey="expense_month" valueKey="expense" tone="red" />
          </div>
        </div>
      ) : null}

      {tab === 'activity' ? (
        <div className="card overflow-hidden">
          {(data?.recentActivity ?? []).length === 0 ? (
            <EmptyState title="No recent activity" />
          ) : (
            <ul className="divide-y divide-slate-100">
              {data.recentActivity.map((a, i) => (
                <li key={i} className="flex items-start justify-between gap-4 p-4">
                  <div>
                    <p className="text-sm text-slate-800">{a.particular}</p>
                    <p className="text-xs text-slate-500">{a.timestamp}</p>
                  </div>
                  <span className="whitespace-nowrap rounded bg-slate-100 px-2 py-0.5 text-xs text-slate-600">
                    {a.type}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}

      {tab === 'village' ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <Link to="/village/houses">
            <StatCard label="Houses" value="—" hint="Open the houses register" />
          </Link>
          <Link to="/village/house-tax">
            <StatCard label="House tax" value="—" hint="Open house tax" />
          </Link>
          <Link to="/village/water-tax">
            <StatCard label="Water tax" value="—" hint="Open water tax" />
          </Link>
          <Link to="/village/payments">
            <StatCard label="Pending payments" value="—" hint="Open pending charges" />
          </Link>
        </div>
      ) : null}
    </section>
  );
}
