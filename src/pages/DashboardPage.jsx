import { lazy, Suspense, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

/*
 * ApexCharts is ~240KB gzipped — more than twice the rest of the app — and it
 * draws exactly one panel on one tab. Loading it lazily keeps that weight off
 * every other screen; the dashboard shows a skeleton for the moment it takes.
 */
const ReactApexChart = lazy(() => import('react-apexcharts'));
import { reports } from '@/api/modules';
import { buildings, flats, wings } from '@/api/masters';
import { pdc } from '@/api/onboarding';
import { useAuth } from '@/auth/AuthContext.jsx';
import { EmptyState, ErrorNotice } from '@/components/ui.jsx';
import { PageHeader, Tabs } from '@/components/FormControls.jsx';

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
  alert: { d: 'M12 3 2 20h20L12 3Zm0 6v5m0 3v.01', grad: 'var(--grad-danger)' },
  userX: { d: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM2 21a7 7 0 0 1 14 0M17 8l4 4m0-4-4 4', grad: 'var(--grad-success)' },
  users: {
    d: 'M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM2 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M16 20h6a5 5 0 0 0-4-4.9',
    grad: 'var(--grad-accent)',
  },
};

/**
 * Headline tile from dashboard.aspx: label top-left, large value bottom-left,
 * glyph on the right. The gradient wash and the watermark glyph are new; the
 * content and its ordering are the legacy tile's.
 */
function HeadlineTile({ label, value, icon, hint }) {
  const g = TILE_ICONS[icon] ?? TILE_ICONS.users;
  return (
    <div
      className="stat-tile stat-tile-compact flex h-full flex-col justify-between gap-2"
      style={{ '--tile-grad': g.grad }}
    >
      <div className="flex items-start justify-between gap-2">
        <p className="text-[11px] font-semibold uppercase tracking-wide text-white/85">{label}</p>
        {/* Glassy plate behind the glyph so it reads against either gradient. */}
        <span
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg"
          style={{ background: 'rgba(255,255,255,0.2)' }}
          aria-hidden="true"
        >
          <svg
            viewBox="0 0 24 24"
            width="18"
            height="18"
            fill="none"
            stroke="#fff"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d={g.d} />
          </svg>
        </span>
      </div>
      <div className="min-w-0">
        <p className="truncate text-2xl font-bold leading-tight">{value}</p>
        {hint ? <p className="mt-0.5 truncate text-[11px] text-white/70">{hint}</p> : null}
      </div>
    </div>
  );
}

/** Tone ramps for the charts — [top of gradient, base, soft tint]. */
const CHART_TONES = {
  blue: ['#7d97ea', '#4e73df', 'rgba(78,115,223,0.12)'],
  green: ['#4ee0ae', '#1cc88a', 'rgba(28,200,138,0.12)'],
  red: ['#ff8a7d', '#e74a3b', 'rgba(231,74,59,0.12)'],
};

/** Axis ticks rounded up to a readable step, so the top gridline is a whole number. */
const niceMax = (raw) => {
  if (raw <= 0) return 1;
  const mag = 10 ** Math.floor(Math.log10(raw));
  return Math.ceil(raw / mag) * mag;
};
/**
 * Maintenance Tracker chart — ApexCharts, the same library dashboard.aspx
 * loaded, driven by the same options object (dashboard.aspx:904).
 *
 * The legacy page pulled Apex from cdn.jsdelivr.net. It is bundled here
 * instead: nothing in this app may depend on an external host, which is why
 * every icon is inline SVG rather than a Font Awesome kit.
 *
 * `series` is [{ key, label, color, data, valueKey }] — one entry per line,
 * each naming the column it plots out of the shared row set.
 */
function AreaChart({ series, labelKey, valueKey, height = 350 }) {
  const live = (series ?? []).filter((s) => s.data?.length);
  if (!live.length) return <EmptyState title="No data for this period" />;

  // The longest series supplies the category axis, so series of equal months
  // overlay on one axis rather than running end to end.
  const spine = live.reduce((a, b) => (b.data.length > a.data.length ? b : a)).data;
  const categories = spine.map((d) => String(d[labelKey]));

  const apexSeries = live.map((s) => ({
    name: s.label,
    data: s.data.map((d) => Number(d[s.valueKey ?? valueKey] || 0)),
  }));

  /*
   * dashboard.aspx's options object, carried over verbatim apart from the two
   * notes below. Apex reads `colors` positionally, so the series order above
   * has to stay Due / Collection / Total to keep yellow / green / blue.
   */
  const options = {
    chart: {
      type: 'area',
      toolbar: { show: false },
      // The legacy chart was destroyed and re-created on every checkbox change,
      // so it always animated in. This component re-renders in place instead,
      // and animating each refetch would make the toggles feel sluggish.
      animations: { enabled: false },
      fontFamily: 'inherit',
    },
    markers: { size: 4 },
    colors: live.map((s) => s.color),
    fill: {
      type: 'gradient',
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.3,
        opacityTo: 0.4,
        stops: [0, 90, 100],
      },
    },
    dataLabels: { enabled: false },
    stroke: { curve: 'smooth', width: 2 },
    xaxis: { type: 'category', categories },
    // `tooltip: { x: { format: 'MMM' } }` in the legacy config was inert — the
    // x axis is category-typed, and Apex applies that format only to datetime
    // axes. Dropped rather than carried over as a no-op.
    legend: { position: 'bottom', horizontalAlign: 'center' },
  };

  return (
    <Suspense fallback={<div className="skeleton" style={{ height }} />}>
      <ReactApexChart type="area" height={height} series={apexSeries} options={options} />
    </Suspense>
  );
}

/**
 * Bar chart in inline SVG — replaces the legacy chart controls without pulling
 * in a charting library. Values are normalised against a rounded-up maximum so
 * the gridlines land on readable numbers.
 *
 * Drawn in a real 1000×400 coordinate space rather than the old
 * `preserveAspectRatio="none"` 100-unit box: stretching the viewBox also
 * stretched the corner radii and stroke widths, so bars came out with skewed,
 * lopsided tops at wide sizes.
 */
function BarChart({ data, labelKey, valueKey, height = 200, tone = 'blue' }) {
  const [hover, setHover] = useState(null);
  if (!data?.length) return <EmptyState title="No data for this period" />;

  const [light, base, tint] = CHART_TONES[tone] ?? CHART_TONES.blue;
  const gradId = `bar-${tone}`;

  const W = 1000;
  const H = 400;
  const padL = 4; // gridline labels sit above the line, so no left gutter is needed
  const padB = 28;
  const plotH = H - padB;

  const max = niceMax(Math.max(...data.map((d) => Number(d[valueKey] || 0)), 1));
  const slot = (W - padL) / data.length;
  // Wide bars look like blocks once there are only a handful; cap the width so
  // a 3-point series does not become three billboards.
  const barW = Math.min(slot * 0.6, 56);

  return (
    <div>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        className="w-full"
        style={{ height }}
        preserveAspectRatio="none"
        role="img"
        aria-label="Bar chart"
      >
        <defs>
          <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={light} />
            <stop offset="100%" stopColor={base} />
          </linearGradient>
        </defs>

        {/* Gridlines at quarters, with the value written above each line. */}
        {[0, 0.25, 0.5, 0.75, 1].map((f) => {
          const y = plotH - f * plotH;
          return (
            <g key={f}>
              <line x1={padL} y1={y} x2={W} y2={y} stroke="#eef1f7" strokeWidth="2" />
              {f > 0 ? (
                <text x={padL + 2} y={y - 6} fontSize="18" fill="#9aa4b8">
                  {shortNumber(max * f)}
                </text>
              ) : null}
            </g>
          );
        })}

        {data.map((d, i) => {
          const value = Number(d[valueKey] || 0);
          const h = (value / max) * plotH;
          const x = padL + i * slot + (slot - barW) / 2;
          const active = hover === i;
          return (
            <g
              key={i}
              onMouseEnter={() => setHover(i)}
              onMouseLeave={() => setHover(null)}
              style={{ cursor: 'default' }}
            >
              {/* Full-height hit area, so the tooltip appears anywhere in the
                  column rather than only over a short bar. */}
              <rect x={padL + i * slot} y={0} width={slot} height={plotH} fill="transparent" />
              {active ? <rect x={padL + i * slot} y={0} width={slot} height={plotH} fill={tint} /> : null}
              <rect
                x={x}
                y={plotH - h}
                width={barW}
                height={Math.max(h, value > 0 ? 3 : 0)}
                fill={`url(#${gradId})`}
                rx="6"
                opacity={hover === null || active ? 1 : 0.55}
                style={{ transition: 'opacity 0.15s ease' }}
              >
                <title>{`${d[labelKey]}: ${money(value)}`}</title>
              </rect>
              {active ? (
                <text
                  x={padL + i * slot + slot / 2}
                  y={Math.max(plotH - h - 10, 16)}
                  textAnchor="middle"
                  fontSize="20"
                  fontWeight="700"
                  fill={base}
                >
                  {shortNumber(value)}
                </text>
              ) : null}
            </g>
          );
        })}

        <line x1={padL} y1={plotH} x2={W} y2={plotH} stroke="#dfe4ee" strokeWidth="2" />
      </svg>

      {/* Labels live in HTML, not SVG: the viewBox is stretched to fit the
          container, which would squash SVG text horizontally. */}
      <div className="mt-2 flex text-[11px] font-medium text-slate-500">
        {data.map((d, i) => (
          <span
            key={i}
            className="flex-1 truncate text-center transition-colors"
            style={{ color: hover === i ? base : undefined }}
            title={String(d[labelKey])}
          >
            {String(d[labelKey]).slice(0, 3)}
          </span>
        ))}
      </div>
    </div>
  );
}

/**
 * Donut for the due/collection split. The total sits in the hole and each
 * legend row carries its share, so the split is readable without measuring
 * arcs by eye.
 */
function DonutChart({ segments, centerLabel = 'Total' }) {
  const total = segments.reduce((s, x) => s + Number(x.value || 0), 0);
  if (!total) return <EmptyState title="No data" />;

  let offset = 0;
  const R = 15.9155;
  const circumference = 2 * Math.PI * R;

  return (
    <div className="flex flex-wrap items-center gap-6">
      <div className="relative shrink-0">
        <svg viewBox="0 0 42 42" className="h-36 w-36 -rotate-90" role="img" aria-label="Split chart">
          <circle cx="21" cy="21" r={R} fill="none" stroke="#eef1f7" strokeWidth="5" />
          {segments.map((s, i) => {
            const pct = (Number(s.value || 0) / total) * 100;
            const dash = `${(pct / 100) * circumference} ${circumference}`;
            const el = (
              <circle
                key={i}
                cx="21"
                cy="21"
                r={R}
                fill="none"
                stroke={s.color}
                strokeWidth="5"
                strokeLinecap="round"
                strokeDasharray={dash}
                strokeDashoffset={-((offset / 100) * circumference)}
              >
                <title>{`${s.label}: ${money(s.value)}`}</title>
              </circle>
            );
            offset += pct;
            return el;
          })}
        </svg>
        {/* Centre readout. Pointer events off so it never blocks the arc tooltips. */}
        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">{centerLabel}</span>
          <span className="text-lg font-bold" style={{ color: 'var(--ink)' }}>
            ₹{shortNumber(total)}
          </span>
        </div>
      </div>

      <ul className="min-w-0 flex-1 space-y-3">
        {segments.map((s) => {
          const pct = Math.round((Number(s.value || 0) / total) * 100);
          return (
            <li key={s.label}>
              <div className="flex items-center justify-between gap-3 text-sm">
                <span className="flex items-center gap-2 text-slate-600">
                  <span className="inline-block h-2.5 w-2.5 rounded-full" style={{ background: s.color }} />
                  {s.label}
                </span>
                <span className="font-semibold" style={{ color: 'var(--ink)' }}>
                  ₹{money(s.value)}
                </span>
              </div>
              {/* Share bar — the same proportion the arc shows, read linearly. */}
              <div className="mt-1.5 flex items-center gap-2">
                <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-slate-100">
                  <div className="h-full rounded-full" style={{ width: `${pct}%`, background: s.color }} />
                </div>
                <span className="w-9 text-right text-xs font-medium text-slate-400">{pct}%</span>
              </div>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

/** Panel shell — title row plus body, the dashboard's repeating container. */
function Panel({ title, actions, children, className = '', bodyClass = '' }) {
  return (
    <section className={`panel ${className}`}>
      <div className="panel-title">
        <h6>{title}</h6>
        {actions}
      </div>
      <div className={`panel-body ${bodyClass}`}>{children}</div>
    </section>
  );
}

/** Placeholder grid shown while the dashboard payload is in flight. */
function DashboardSkeleton() {
  return (
    <div className="grid gap-5" aria-busy="true" aria-label="Loading dashboard">
      <div className="grid gap-5 sm:grid-cols-3">
        {[0, 1, 2].map((i) => (
          <div key={i} className="skeleton h-[104px]" />
        ))}
      </div>
      <div className="grid gap-5 lg:grid-cols-[2fr_1fr]">
        <div className="skeleton h-[320px]" />
        <div className="skeleton h-[320px]" />
      </div>
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
  /*
   * Maintenance Tracker — CheckBox1 / CheckBox2 on dashboard.aspx.
   *
   * These are NOT series toggles. getSelectedCheckboxValue() in the legacy page
   * folded the pair into one number and posted it as ExpenseType:
   *
   *   both ticked -> 2   (sp_dashboard/ExpenseChart returns every bill_type)
   *   Regular     -> 1   (bill_type = 1)
   *   Add on      -> 0   (bill_type = 0)
   *   neither     -> 3   (no bill_type matches, so the SP returns 12 zeroed months)
   *
   * The chart always plots the same three series — Due, Collection and Total —
   * over all twelve months; the checkboxes only change which bills are counted.
   * Both boxes started ticked (`checked="checked"` on CheckBox1, and the legacy
   * page's own screenshot shows Add on ticked too).
   */
  const [showRegular, setShowRegular] = useState(true);
  const [showAddOn, setShowAddOn] = useState(true);
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
      safe(pdc.list(), { items: [] }),
    ])
      .then(([dash, b, w, f, pdcRows]) => {
        if (cancelled) return;
        setData(dash);
        setMasters({ buildings: b.count, wings: w.count, flats: f.count });
        setPdcCount((pdcRows.items ?? []).length);
      })
      .catch((err) => !cancelled && setError(err));

    return () => {
      cancelled = true;
    };
  }, []);

  /*
   * Maintenance Tracker data — the port of loadExpenseChart(). The checkbox
   * pair is a server-side filter (ExpenseType), not a client-side one, so
   * changing it has to refetch rather than slice the rows already held.
   */
  useEffect(() => {
    let cancelled = false;
    const type = showRegular && showAddOn ? 2 : showRegular ? 1 : showAddOn ? 0 : 3;

    reports
      .expenseChart(type)
      .then((r) => !cancelled && setExpenseChart(r.items ?? []))
      .catch(() => !cancelled && setExpenseChart([]));

    return () => {
      cancelled = true;
    };
  }, [showRegular, showAddOn]);

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

  if (!data && !masters && !error) return <DashboardSkeleton />;

  // Until a period is picked, the donut uses the figures the dashboard call
  // already returned; after that it follows the selection.
  const split = incomeSplit ?? data?.incomeSplit ?? [];
  const collection = split.find((r) => r.category === 'Collection')?.amount ?? 0;
  const due = split.find((r) => r.category === 'Due')?.amount ?? 0;
  // The Due Payments tile shows the IncomeChart 'Due' figure — the same number
  // the donut plots — not the defaulters roll-up.
  const dues = due;

  /*
   * The tracker's three series, in the legacy page's own order and colours
   * (dashboard.aspx: colors: ['#ffc107', '#28a745', '#4154f1']). Every series
   * shares the twelve months ExpenseChart returns, zero-filled — which is why
   * the legacy chart runs flat along the axis for months with no bills rather
   * than stopping early.
   */
  const trackerSeries = [
    { key: 'due', label: 'Due', color: '#ffc107', data: expenseChart },
    { key: 'collection', label: 'Collection', color: '#28a745', data: expenseChart },
    { key: 'total', label: 'Total', color: '#4154f1', data: expenseChart },
  ].map((s) => ({ ...s, valueKey: { due: 'Due', collection: 'Collection', total: 'expense' }[s.key] }));

  return (
    <section>
      <PageHeader
        title={`Welcome${user?.name ? `, ${user.name.split(' ')[0]}` : ''}`}
        subtitle={user?.society_name || user?.village_name || ''}
      >
        {/* Today's date, the one bit of context the legacy header lacked. */}
        <span className="hidden text-sm text-slate-500 sm:inline">
          {new Date().toLocaleDateString(undefined, {
            weekday: 'long',
            day: 'numeric',
            month: 'long',
            year: 'numeric',
          })}
        </span>
      </PageHeader>

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
        /*
         * .layout-container — 2fr 1fr on desktop. The three headline tiles sit
         * at the top of the left column rather than spanning the full width, so
         * Recent Activity rises to sit level with them on the right instead of
         * starting a screen below.
         */
        <div className="grid gap-5">
          <div className="grid gap-5 lg:grid-cols-[2fr_1fr]">
            {/* .layout-left */}
            <div className="grid content-start gap-5">
              {/* Compact tiles: side by side once there is room, stacked on a
                  phone. Only Due Payments and Total Members were links in the
                  legacy page. */}
              <div className="grid gap-4 sm:grid-cols-3">
                <Link to="/billing/defaulters" className="block h-full">
                  <HeadlineTile label="Due Payments" value={`₹ ${shortNumber(dues)}`} icon="alert" />
                </Link>
                <HeadlineTile label="Defaulters" value={data?.defaulters?.count ?? 0} icon="userX" />
                <Link to="/masters/owners" className="block h-full">
                  <HeadlineTile label="Total Members" value={data?.residentCount ?? 0} icon="users" />
                </Link>
              </div>

              <Panel
                title="Maintenance Tracker"
                actions={
                  /* Regular / Add on toggles the expense series, as on the legacy
                     page — restyled as pill switches with a colour key. */
                  /* Regular / Add on pick which bill_type the server counts —
                     they are not series toggles, so they carry no series colour.
                     Kept as plain checkboxes, as the legacy page had them. */
                  <div className="flex items-center gap-4">
                    {[
                      { on: showRegular, set: setShowRegular, label: 'Regular' },
                      { on: showAddOn, set: setShowAddOn, label: 'Add on' },
                    ].map((s) => (
                      <label
                        key={s.label}
                        className="flex cursor-pointer select-none items-center gap-2 text-sm font-medium"
                        style={{ color: 'var(--ink)' }}
                      >
                        <input
                          type="checkbox"
                          className="h-4 w-4 rounded border-slate-300"
                          checked={s.on}
                          onChange={(e) => s.set(e.target.checked)}
                        />
                        {s.label}
                      </label>
                    ))}
                  </div>
                }
              >
                {/* height: 350, as the legacy ApexCharts config set. */}
                <AreaChart series={trackerSeries} labelKey="expense_month" height={350} />
              </Panel>

              <div className="grid gap-5 sm:grid-cols-2">
                <Panel title="PDC Clearing" className="panel-interactive">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="text-3xl font-bold" style={{ color: 'var(--ink)' }}>
                        {pdcCount}
                      </p>
                      <p className="mt-1 text-xs text-slate-500">cheques awaiting clearing</p>
                    </div>
                    <span
                      className="flex h-11 w-11 items-center justify-center rounded-xl"
                      style={{ background: 'rgba(246,194,62,0.14)', color: '#d9a406' }}
                      aria-hidden="true"
                    >
                      <svg
                        viewBox="0 0 24 24"
                        width="22"
                        height="22"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <path d="M2 6h20v12H2zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM6 9v.01M18 15v.01" />
                      </svg>
                    </span>
                  </div>
                  <Link
                    to="/billing/pdc/clearing"
                    className="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-blue-600 hover:gap-2 hover:underline"
                    style={{ transition: 'gap 0.15s ease' }}
                  >
                    Open <span aria-hidden="true">→</span>
                  </Link>
                </Panel>

                <Panel title="Weekly Updates">
                  {(data?.weeklyUpdates ?? []).length === 0 ? (
                    <p className="text-sm text-slate-500">No Updates</p>
                  ) : (
                    <ul className="space-y-2 overflow-auto pr-1" style={{ maxHeight: 160 }}>
                      {(data?.weeklyUpdates ?? []).map((u, i) => (
                        <li
                          key={i}
                          className="flex items-center justify-between gap-2 rounded-lg px-3 py-2"
                          style={{ background: '#f7f9fc' }}
                        >
                          <span className="truncate text-sm font-medium" style={{ color: 'var(--ink)' }}>
                            {u.name}
                          </span>
                          {u.type ? (
                            <span className="shrink-0 rounded-full bg-white px-2 py-0.5 text-[11px] text-slate-500">
                              {u.type}
                            </span>
                          ) : null}
                        </li>
                      ))}
                    </ul>
                  )}
                </Panel>

                <Panel title="HelpDesk Ticket" className="sm:col-span-2">
                  <div className="grid grid-cols-2 gap-4">
                    <div
                      className="stat-chip"
                      style={{ '--chip-bg': '#fef3f2', '--chip-border': 'rgba(231,74,59,0.15)' }}
                    >
                      <p className="text-xs font-medium text-slate-500">Open Ticket</p>
                      <p className="mt-1 text-2xl font-bold" style={{ color: 'var(--danger)' }}>
                        {data?.tickets?.opened ?? 0}
                      </p>
                    </div>
                    <div
                      className="stat-chip"
                      style={{ '--chip-bg': '#effaf5', '--chip-border': 'rgba(28,200,138,0.18)' }}
                    >
                      <p className="text-xs font-medium text-slate-500">Resolve Tickets</p>
                      <p className="mt-1 text-2xl font-bold" style={{ color: 'var(--success)' }}>
                        {data?.tickets?.resolved ?? 0}
                      </p>
                    </div>
                  </div>
                  <Link
                    to="/community/helpdesk"
                    className="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-blue-600 hover:gap-2 hover:underline"
                    style={{ transition: 'gap 0.15s ease' }}
                  >
                    Open <span aria-hidden="true">→</span>
                  </Link>
                </Panel>
              </div>
            </div>

            {/* .layout-right */}
            <div className="grid content-start gap-5">
              <Panel title="Recent Activity">
                {(data?.recentActivity ?? []).length === 0 ? (
                  <p className="text-sm text-slate-500">No Updates</p>
                ) : (
                  /* Legacy scrolled this list at a fixed 226px. */
                  <ul className="space-y-1 overflow-auto pr-1" style={{ maxHeight: 260 }}>
                    {(data?.recentActivity ?? []).map((a, i) => {
                      // Icon and amount colour keyed off paid_amount, as the
                      // GridView's inline Eval did: 0.00 => blue tools, else green tick.
                      const paid = Number(a.paid_amount || 0);
                      const isPayment = paid !== 0;
                      const tone = isPayment ? '#1cc88a' : '#4e73df';
                      return (
                        <li
                          key={i}
                          className="flex items-start justify-between gap-3 rounded-lg p-2 transition-colors hover:bg-slate-50"
                        >
                          <div className="flex min-w-0 items-start gap-2.5">
                            <span
                              className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold"
                              style={{ background: `${tone}1f`, color: tone }}
                              aria-hidden="true"
                            >
                              {isPayment ? '✓' : '⚒'}
                            </span>
                            <div className="min-w-0">
                              <p className="truncate text-sm font-medium" style={{ color: 'var(--ink)' }}>
                                {a.particular}
                              </p>
                              <p className="mt-0.5 text-xs text-slate-400">{a.timestamp}</p>
                            </div>
                          </div>
                          <span className="shrink-0 text-sm font-semibold" style={{ color: tone }}>
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
                <Link
                  to="/reports/activity"
                  className="mt-3 inline-flex items-center gap-1 text-sm font-semibold text-blue-600 hover:gap-2 hover:underline"
                  style={{ transition: 'gap 0.15s ease' }}
                >
                  See All <span aria-hidden="true">→</span>
                </Link>
              </Panel>

              <Panel
                title="Income Tracker"
                actions={
                  /* ⋮ menu — This Month / Last Month / This Year, as on dashboard.aspx. */
                  <div className="relative">
                    <button
                      type="button"
                      className="flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors hover:bg-slate-100"
                      style={{ background: '#f4f6fa', color: 'var(--ink)' }}
                      aria-label="Change period"
                      aria-expanded={periodOpen}
                      onClick={() => setPeriodOpen((v) => !v)}
                    >
                      {(INCOME_PERIODS.find((p) => p.id === period) ?? INCOME_PERIODS[2]).label}
                      <span aria-hidden="true" style={{ fontSize: 9 }}>
                        ▼
                      </span>
                    </button>
                    {periodOpen ? (
                      <>
                        <div className="fixed inset-0 z-40" onClick={() => setPeriodOpen(false)} aria-hidden="true" />
                        <div
                          role="menu"
                          className="absolute right-0 z-50 mt-1 bg-white py-1"
                          style={{ width: 160, borderRadius: 12, boxShadow: 'var(--shadow-lg)' }}
                        >
                          {INCOME_PERIODS.map((p) => (
                            <button
                              key={p.id}
                              type="button"
                              role="menuitem"
                              className="block w-full px-4 py-2 text-left text-sm hover:bg-slate-50"
                              style={{
                                color: period === p.id ? '#1d4ed8' : '#012970',
                                fontWeight: period === p.id ? 600 : 400,
                              }}
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
                }
              >
                <DonutChart
                  centerLabel="Total"
                  segments={[
                    { label: 'Collection', value: collection, color: '#4e73df' },
                    { label: 'Due', value: due, color: '#f6c23e' },
                  ]}
                />
              </Panel>

              {/* Property counts — already fetched for the masters call, but the
                  legacy page never surfaced them. */}
              <Panel title="Property Summary">
                <dl className="grid grid-cols-3 gap-3 text-center">
                  {[
                    { label: 'Buildings', value: masters?.buildings, to: '/masters/buildings' },
                    { label: 'Wings', value: masters?.wings, to: '/masters/wings' },
                    { label: 'Flats', value: masters?.flats, to: '/masters/flats' },
                  ].map((m) => (
                    <Link
                      key={m.label}
                      to={m.to}
                      className="rounded-xl px-2 py-3 transition-colors hover:bg-slate-50"
                    >
                      <dt className="text-[11px] font-medium uppercase tracking-wide text-slate-400">{m.label}</dt>
                      <dd className="mt-1 text-xl font-bold" style={{ color: 'var(--ink)' }}>
                        {m.value ?? '—'}
                      </dd>
                    </Link>
                  ))}
                </dl>
              </Panel>
            </div>
          </div>
        </div>
      ) : null}

      {tab === 'financial' ? (
        <div className="grid gap-5 lg:grid-cols-2">
          <Panel title="Dues vs collection">
            <DonutChart
              centerLabel="Billed"
              segments={[
                { label: 'Collected', value: collection, color: '#1cc88a' },
                { label: 'Outstanding', value: due, color: '#e74a3b' },
              ]}
            />
          </Panel>

          <Panel title="Monthly dues">
            <BarChart data={data?.monthlyDues ?? []} labelKey="month_name" valueKey="amount" />
          </Panel>

          <Panel title="Expenses by month" className="lg:col-span-2">
            <BarChart data={expenseChart} labelKey="expense_month" valueKey="expense" tone="red" height={240} />
          </Panel>
        </div>
      ) : null}

      {tab === 'activity' ? (
        <div className="panel overflow-hidden">
          {(data?.recentActivity ?? []).length === 0 ? (
            <EmptyState title="No recent activity" />
          ) : (
            <ul className="divide-y divide-slate-100">
              {data.recentActivity.map((a, i) => (
                <li
                  key={i}
                  className="flex items-start justify-between gap-4 px-5 py-4 transition-colors hover:bg-slate-50"
                >
                  <div className="min-w-0">
                    <p className="text-sm font-medium" style={{ color: 'var(--ink)' }}>
                      {a.particular}
                    </p>
                    <p className="mt-0.5 text-xs text-slate-400">{a.timestamp}</p>
                  </div>
                  <span className="shrink-0 whitespace-nowrap rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600">
                    {a.type}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : null}

      {tab === 'village' ? (
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { to: '/village/houses', label: 'Houses', hint: 'Open the houses register' },
            { to: '/village/house-tax', label: 'House tax', hint: 'Open house tax' },
            { to: '/village/water-tax', label: 'Water tax', hint: 'Open water tax' },
            { to: '/village/payments', label: 'Pending payments', hint: 'Open pending charges' },
          ].map((v) => (
            <Link key={v.to} to={v.to} className="panel panel-interactive block p-5">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{v.label}</p>
              <p className="mt-1 text-2xl font-bold" style={{ color: 'var(--ink)' }}>
                —
              </p>
              <p className="mt-1 text-xs text-slate-500">{v.hint}</p>
            </Link>
          ))}
        </div>
      ) : null}
    </section>
  );
}
