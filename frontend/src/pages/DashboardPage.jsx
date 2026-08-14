import { lazy, Suspense, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

/*
 * ApexCharts is ~240KB gzipped — more than twice the rest of the app — and it
 * draws exactly one panel on one tab. Loading it lazily keeps that weight off
 * every other screen; the dashboard shows a skeleton for the moment it takes.
 */
const ReactApexChart = lazy(() => import('react-apexcharts'));
import { reports, village } from '@/api/modules';
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
        <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">{label}</p>
        {/*
          The tile is white now, so the glyph plate is what carries the tile's
          colour: it is filled with the same --tile-grad the tile used to be
          washed with, and the glyph on it stays white.
        */}
        <span
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl"
          style={{
            background: g.grad,
            boxShadow: '0 3px 8px -2px rgba(17,24,39,0.28), inset 0 1px 0 rgba(255,255,255,0.3)',
          }}
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
        <p className="truncate text-2xl font-bold leading-tight" style={{ color: 'var(--ink)' }}>
          {value}
        </p>
        {hint ? <p className="mt-0.5 truncate text-[11px] text-slate-500">{hint}</p> : null}
      </div>
    </div>
  );
}

/*
 * Tone ramps for the charts — [top of gradient, base, soft tint].
 *
 * `brand` is the default series, on the app accent. The expense chart asks for
 * a tone that contrasts with it; that used to be red against a blue accent, but
 * with the accent itself red the two series were near-identical. `amber` is the
 * contrast tone now — it stays distinct from both the accent and the green.
 */
const CHART_TONES = {
  brand: ['#e58a8a', '#c94040', 'rgba(201, 64, 64,0.12)'],
  green: ['#4ee0ae', '#1cc88a', 'rgba(28,200,138,0.12)'],
  amber: ['#ffd071', '#e8a021', 'rgba(232,160,33,0.12)'],
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
   * has to stay Due / Collection / Total to keep yellow / green / red.
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
      /*
       * Apex measures the parent once and keeps that width. On a phone it
       * settled on a box wider than the column, which pushed the dashboard
       * past the viewport — and because the page clips horizontal overflow,
       * the surplus showed up as tiles that reached the left edge but ran off
       * the right. Redrawing on resize keeps the chart inside its column, and
       * `width: '100%'` stops it claiming a fixed pixel width to begin with.
       */
      width: '100%',
      redrawOnParentResize: true,
      redrawOnWindowResize: true,
      parentHeightOffset: 0,
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
    xaxis: {
      type: 'category',
      categories,
      /*
       * Twelve month labels do not fit across a phone — they overlapped into
       * an unreadable band. Apex drops every other tick when it has to, and
       * `hideOverlappingLabels` lets it, rather than drawing them on top of
       * one another.
       */
      labels: { rotate: 0, hideOverlappingLabels: true, trim: true },
      tickPlacement: 'on',
    },
    yaxis: {
      /* Six-figure rupee totals rendered as "120000.00" and ate a third of a
         phone's width in axis labels alone. */
      labels: {
        formatter: (v) => shortNumber(v),
      },
    },
    // `tooltip: { x: { format: 'MMM' } }` in the legacy config was inert — the
    // x axis is category-typed, and Apex applies that format only to datetime
    // axes. Dropped rather than carried over as a no-op.
    legend: { position: 'bottom', horizontalAlign: 'center' },
    /*
     * Below `sm` the chart gets more of the card: the axis labels shrink and
     * the left gutter closes up, so the plot itself keeps a usable width.
     */
    responsive: [
      {
        breakpoint: 640,
        options: {
          chart: { height: 260 },
          markers: { size: 3 },
          grid: { padding: { left: 0, right: 8 } },
          legend: { fontSize: '11px', itemMargin: { horizontal: 6 } },
          yaxis: { labels: { style: { fontSize: '10px' } } },
          xaxis: { labels: { style: { fontSize: '10px' } } },
        },
      },
    ],
  };

  return (
    <Suspense fallback={<div className="skeleton" style={{ height }} />}>
      {/* min-w-0 lets the chart's column shrink below the SVG's measured
          width; without it the grid track keeps the chart's size as its
          floor and the whole row grows instead. */}
      <div className="min-w-0">
        <ReactApexChart type="area" height={height} series={apexSeries} options={options} />
      </div>
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
function BarChart({ data, labelKey, valueKey, height = 200, tone = 'brand' }) {
  const [hover, setHover] = useState(null);
  if (!data?.length) return <EmptyState title="No data for this period" />;

  const [light, base, tint] = CHART_TONES[tone] ?? CHART_TONES.brand;
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
    /*
     * Stacked on a phone, side by side once there is room.
     *
     * This was a single `flex-wrap` row, which never actually wrapped: the
     * legend had `flex-1`, so instead of dropping below the 144px donut it
     * shrank to whatever was left — about 120px inside the dashboard's narrow
     * column — and the amounts were clipped mid-figure ("₹23…").
     *
     * A wrap only happens once an item cannot shrink any further, so the fix
     * is to stop asking it to shrink: the two stack below `sm`, and the legend
     * takes the full width of the card there.
     */
    <div className="flex flex-col items-center gap-5 sm:flex-row sm:items-center sm:gap-6">
      <div className="relative shrink-0">
        <svg viewBox="0 0 42 42" className="h-32 w-32 -rotate-90 sm:h-36 sm:w-36" role="img" aria-label="Split chart">
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

      <ul className="w-full min-w-0 space-y-3 sm:flex-1">
        {segments.map((s) => {
          const pct = Math.round((Number(s.value || 0) / total) * 100);
          return (
            <li key={s.label}>
              <div className="flex items-center justify-between gap-3 text-sm">
                {/* The label gives way, not the figure: truncating "Collection"
                    still reads, but a clipped amount is the wrong number. */}
                <span className="flex min-w-0 items-center gap-2 text-slate-600">
                  <span
                    className="inline-block h-2.5 w-2.5 shrink-0 rounded-full"
                    style={{ background: s.color }}
                  />
                  <span className="truncate">{s.label}</span>
                </span>
                <span
                  className="shrink-0 whitespace-nowrap font-semibold"
                  style={{ color: 'var(--ink)' }}
                >
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
    /*
     * min-w-0 so a panel can shrink inside a grid track. A chart or a wide
     * table inside one otherwise sets the panel's minimum width, and the
     * whole row grows past the screen rather than the panel's own scroller
     * taking the strain.
     */
    <section className={`panel min-w-0 ${className}`}>
      <div className="panel-title">
        <h6 className="min-w-0 break-anywhere">{title}</h6>
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

/*
 * .stat-card-modern's four colour schemes. Each drives the 4px bar across the
 * top of the card, the icon plate behind the glyph, the collection-rate figure
 * and the progress fill — exactly as --card-gradient-start / --card-gradient-end
 * and --icon-bg / --icon-color do in village_dashboard.aspx.
 */
const VILLAGE_TONES = {
  home: { start: '#48bb78', end: '#38a169', iconBg: 'rgba(72,187,120,0.1)' },
  water: { start: '#4299e1', end: '#3182ce', iconBg: 'rgba(66,153,225,0.1)' },
  waste: { start: '#ed8936', end: '#dd6b20', iconBg: 'rgba(237,137,54,0.1)' },
  population: { start: '#9f7aea', end: '#805ad5', iconBg: 'rgba(159,122,234,0.1)' },
};

/**
 * .section-title-modern — a 38px indigo gradient square carrying the section's
 * glyph, with the heading beside it.
 */
function SectionHeading({ title, icon }) {
  return (
    <div className="flex items-center gap-3">
      <span
        className="flex h-[38px] w-[38px] shrink-0 items-center justify-center rounded-[10px] text-white"
        style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}
        aria-hidden="true"
      >
        <svg
          width="17"
          height="17"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          {icon}
        </svg>
      </span>
      {/* 18px/700 in the legacy stylesheet, where .panel-title h6 is 15px. */}
      <h6 style={{ fontSize: '18px', fontWeight: 700, color: '#1a202c' }}>{title}</h6>
    </div>
  );
}

/** The gradient rule across the top of every card (.stat-card-modern::before). */
function CardTopRule({ tone }) {
  return (
    <span
      className="absolute inset-x-0 top-0 h-1"
      style={{ background: `linear-gradient(90deg, ${tone.start}, ${tone.end})` }}
      aria-hidden="true"
    />
  );
}

/** .card-icon-modern — the tinted rounded plate holding the card's glyph. */
function CardIcon({ tone, children }) {
  return (
    <span
      className="flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-[14px]"
      style={{ background: tone.iconBg, color: tone.end }}
      aria-hidden="true"
    >
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.9"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        {children}
      </svg>
    </span>
  );
}

/**
 * One of the three tax cards: icon and trend badge on top, the title, the
 * `paid / total` pair, a Collection Rate bar, then a Paid / Pending footer —
 * the shape of .stat-card-modern in village_dashboard.aspx.
 */
function VillageStatCard({ title, paid, total, paidCount, pendingCount, icon, tone, to, note }) {
  const pct =
    paid == null || !Number(total)
      ? null
      : Math.min(100, Math.round((Number(paid) / Number(total)) * 100));

  return (
    <Link to={to} className="panel panel-interactive relative block overflow-hidden p-6">
      <CardTopRule tone={tone} />

      <div className="flex items-start justify-between gap-2">
        <CardIcon tone={tone}>{icon}</CardIcon>
        {/*
          .card-trend held a hardcoded "8%" / "12%" / "15%" with an up arrow —
          there is no earlier period stored to compare against, so a trend would
          have to be invented. The slot keeps the collection rate instead.
        */}
        {pct != null ? (
          <span
            className="rounded-lg px-3 py-1.5 text-xs font-semibold"
            style={{ background: tone.iconBg, color: tone.end }}
          >
            {pct}%
          </span>
        ) : null}
      </div>

      <p
        className="mt-5 text-[13px] font-semibold uppercase"
        style={{ color: '#718096', letterSpacing: '0.5px' }}
      >
        {title}
      </p>

      {/* .card-value-modern — 32px figure beside a 20px muted total. */}
      <p className="mt-3 flex items-baseline gap-2">
        <span className="text-[32px] font-bold leading-none" style={{ color: '#1a202c' }}>
          {paid == null ? '—' : money(paid)}
        </span>
        <span className="text-xl font-semibold" style={{ color: '#a0aec0' }}>
          / {money(total)}
        </span>
      </p>

      {/* .progress-section */}
      <div className="mt-4">
        <div className="mb-2 flex items-center justify-between">
          <span className="text-[13px] font-medium" style={{ color: '#4a5568' }}>
            Collection Rate
          </span>
          <span className="text-sm font-bold" style={{ color: tone.end }}>
            {pct == null ? '—' : `${pct}%`}
          </span>
        </div>
        <span
          className="block h-2 w-full overflow-hidden rounded-[10px]"
          style={{ background: '#f7fafc' }}
        >
          <span
            className="block h-full rounded-[10px] transition-[width] duration-700"
            style={{
              width: `${pct ?? 0}%`,
              background: `linear-gradient(90deg, ${tone.start}, ${tone.end})`,
            }}
          />
        </span>
      </div>

      {/* .card-footer-modern — the Paid / Pending pair. */}
      <div
        className="mt-4 flex items-center justify-between border-t pt-4"
        style={{ borderColor: '#f1f3f5' }}
      >
        {note ? (
          <span className="text-xs" style={{ color: '#718096' }}>
            {note}
          </span>
        ) : (
          <>
            <span className="text-xs" style={{ color: '#718096' }}>
              {money(paidCount)} Paid
            </span>
            <span className="text-xs" style={{ color: '#718096' }}>
              {money(pendingCount)} Pending
            </span>
          </>
        )}
      </div>
    </Link>
  );
}

/** The Total Population card, which shows counts rather than money. */
function VillagePopulationCard({ residents, houses }) {
  const tone = VILLAGE_TONES.population;

  return (
    <Link to="/village/residents" className="panel panel-interactive relative block overflow-hidden p-6">
      <CardTopRule tone={tone} />

      <div className="flex items-start justify-between gap-2">
        <CardIcon tone={tone}>
          <path d="M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM2 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M16 20h6a5 5 0 0 0-4-4.9" />
        </CardIcon>
      </div>

      <p
        className="mt-5 text-[13px] font-semibold uppercase"
        style={{ color: '#718096', letterSpacing: '0.5px' }}
      >
        Total Population
      </p>
      <p className="mt-3 text-[32px] font-bold leading-none" style={{ color: '#1a202c' }}>
        {money(residents)}
      </p>

      {/*
        .population-grid held two boxes, Male and Female. house_owner has no
        gender column, so that split cannot be derived from the data — these
        report residents and houses, which can.
      */}
      <div className="mt-4 grid grid-cols-2 gap-3">
        {[
          {
            label: 'Residents',
            value: residents,
            colour: '#3182ce',
            icon: <path d="M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM5 21a7 7 0 0 1 14 0" />,
          },
          {
            label: 'Houses',
            value: houses,
            colour: '#d53f8c',
            icon: <path d="M4 20V9l8-5 8 5v11M9 20v-6h6v6" />,
          },
        ].map((b) => (
          <div
            key={b.label}
            className="rounded-xl py-3 text-center"
            style={{ background: tone.iconBg }}
          >
            <span
              className="mx-auto mb-1 block w-fit"
              style={{ color: b.colour }}
              aria-hidden="true"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                {b.icon}
              </svg>
            </span>
            <p className="text-lg font-bold" style={{ color: '#1a202c' }}>
              {money(b.value)}
            </p>
            <p className="text-[11px]" style={{ color: '#718096' }}>
              {b.label}
            </p>
          </div>
        ))}
      </div>
    </Link>
  );
}

/**
 * The banner across the top: the village's name over the figures that answer
 * "how are we doing" — collected this year, still outstanding, and the two
 * counts that size the place.
 *
 * It carries the same deep-blue wash as the signed-out pages, so the first
 * thing a village account sees after signing in is recognisably the same
 * product it signed in through.
 */
function VillageHero({ name, collected, outstanding, houses, staff }) {
  /*
   * A missing figure is shown as zero, not as an em dash. These are counts and
   * sums over the village's own rows: a village with nothing recorded has zero
   * outstanding and zero staff, and "—" made an empty village look like a
   * broken page — particularly beside "₹", which read as "₹—".
   */
  const n = (v) => Number(v ?? 0);

  const FIGURES = [
    {
      label: 'Collected',
      sub: 'last 12 months',
      value: `₹${money(n(collected))}`,
      icon: <path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />,
    },
    {
      label: 'Outstanding',
      sub: 'still due',
      value: `₹${money(n(outstanding))}`,
      icon: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
    },
    {
      label: 'Houses',
      sub: 'on the register',
      value: money(n(houses)),
      icon: <path d="M4 20V9l8-5 8 5v11M9 20v-6h6v6" />,
    },
    {
      label: 'Staff',
      sub: 'on the books',
      value: money(n(staff)),
      icon: <path d="M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM2 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M16 20h6a5 5 0 0 0-4-4.9" />,
    },
  ];

  return (
    <div
      className="relative overflow-hidden rounded-2xl px-6 py-6 text-white sm:px-8"
      style={{
        // Lighter and bluer than the sign-in panel's near-black start: at that
        // depth the village name sat dark-on-dark and barely read.
        background: 'linear-gradient(120deg, #7d1a1a 0%, #c94040 55%, #e06060 100%)',
        /* Coloured fill, so the tinted drop + lit rim the stat tiles use — the
           shared pair's white light-shadow would halo against this red. */
        boxShadow:
          '6px 6px 16px rgba(120,60,60,0.28), -4px -4px 12px rgba(255,255,255,0.5), inset 0 1px 0 rgba(255,255,255,0.3)',
      }}
    >
      {/* Soft blooms so the fill is not a flat diagonal. */}
      <div
        className="pointer-events-none absolute inset-0"
        aria-hidden="true"
        style={{
          backgroundImage:
            'radial-gradient(560px circle at 8% 0%, rgba(147,197,253,0.35), transparent 62%),' +
            'radial-gradient(420px circle at 96% 110%, rgba(167,139,250,0.32), transparent 60%)',
        }}
      />

      <div className="relative">
        <p
          className="text-[11px] font-semibold uppercase tracking-[0.14em]"
          style={{ color: 'rgba(255,255,255,0.75)' }}
        >
          Gram Panchayat
        </p>
        {/* Pure white with a soft shadow, so the name reads at a glance. */}
        <h2
          className="mt-1 text-[26px] font-bold leading-tight tracking-tight text-white sm:text-3xl"
          style={{ textShadow: '0 1px 12px rgba(2,20,60,0.35)' }}
        >
          {name}
        </h2>

        {/* Each figure sits on its own translucent plate rather than floating on
            the gradient, which is what made the row read as unfinished. */}
        <div className="mt-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
          {FIGURES.map((f) => (
            <div
              key={f.label}
              className="rounded-xl px-4 py-3"
              style={{
                background: 'rgba(255,255,255,0.12)',
                border: '1px solid rgba(255,255,255,0.16)',
                backdropFilter: 'blur(6px)',
              }}
            >
              <div className="flex items-center gap-1.5" style={{ color: 'rgba(255,255,255,0.8)' }}>
                <svg
                  width="13"
                  height="13"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  {f.icon}
                </svg>
                <span className="text-[11px] font-semibold uppercase tracking-wide">{f.label}</span>
              </div>
              <p className="mt-1 text-xl font-bold text-white sm:text-2xl">{f.value}</p>
              <p className="text-[11px]" style={{ color: 'rgba(255,255,255,0.6)' }}>
                {f.sub}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/**
 * Twelve months of collection as a bar chart, drawn as plain elements rather
 * than pulled through ApexCharts — this is one series of twelve values, and the
 * society dashboard already pays the 240KB for the charts that need it.
 *
 * The API returns only months that saw receipts, so the run is zero-filled here
 * and the chart shows a continuous year.
 */
function VillageTrend({ trend }) {
  const now = new Date();
  const months = Array.from({ length: 12 }, (_, i) => {
    const d = new Date(now.getFullYear(), now.getMonth() - 11 + i, 1);
    const row = trend?.find((t) => t.y === d.getFullYear() && t.m === d.getMonth() + 1);
    return {
      key: `${d.getFullYear()}-${d.getMonth()}`,
      label: MONTH_LABELS[d.getMonth()],
      collected: Number(row?.collected ?? 0),
      receipts: Number(row?.receipts ?? 0),
    };
  });

  const peak = Math.max(...months.map((m) => m.collected), 1);

  return (
    <div className="flex h-[220px] items-end gap-1.5 sm:gap-2">
      {months.map((m) => (
        <div key={m.key} className="flex min-w-0 flex-1 flex-col items-center gap-2">
          <div className="flex w-full flex-1 items-end">
            <div
              className="w-full rounded-t-md transition-[height] duration-700"
              style={{
                // A month with nothing collected still shows a 2px stub, so the
                // axis reads as twelve months rather than a gap.
                height: `${Math.max(2, (m.collected / peak) * 100)}%`,
                background:
                  m.collected > 0
                    ? 'linear-gradient(180deg, #e06a6a 0%, #c94040 100%)'
                    : '#eef2f9',
              }}
              title={`${m.label}: ₹${money(m.collected)} from ${m.receipts} receipt(s)`}
            />
          </div>
          <span className="text-[10px]" style={{ color: '#a0aec0' }}>
            {m.label}
          </span>
        </div>
      ))}
    </div>
  );
}

/*
 * A colour and glyph per receipt kind, keyed to Village_payment_type's codes —
 * 1 Property Tax, 2 Water Charges, 3 Waste Charges. They match the stat card
 * above that reports the same tax, so a green row in the activity list and the
 * green Property Tax card are recognisably about one thing.
 */
const RECEIPT_TONES = {
  1: {
    fg: '#38a169',
    bg: 'rgba(72,187,120,0.15)',
    icon: <path d="M4 20V9l8-5 8 5v11M9 20v-6h6v6" />,
  },
  2: {
    fg: '#3182ce',
    bg: 'rgba(66,153,225,0.15)',
    icon: <path d="M12 3s6 6.6 6 10.5A6 6 0 0 1 6 13.5C6 9.6 12 3 12 3Z" />,
  },
  3: {
    fg: '#dd6b20',
    bg: 'rgba(237,137,54,0.15)',
    icon: <path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13M10 11v5M14 11v5" />,
  },
  default: {
    fg: '#805ad5',
    bg: 'rgba(159,122,234,0.15)',
    icon: <path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />,
  },
};

/** Collection split by what was paid for, as a labelled share bar. */
function VillageSplit({ split }) {
  const rows = (split ?? []).filter((s) => Number(s.amount) > 0);
  const total = rows.reduce((sum, s) => sum + Number(s.amount), 0);
  const COLOURS = ['#48bb78', '#4299e1', '#ed8936', '#9f7aea'];

  if (!total) return <EmptyState title="Nothing collected yet" />;

  return (
    <div>
      {/* The total leads, so the panel says something before the breakdown. */}
      <p className="text-2xl font-bold leading-none" style={{ color: '#1a202c' }}>
        ₹{money(total)}
      </p>
      <p className="mt-1 text-xs" style={{ color: '#a0aec0' }}>
        across {rows.length} {rows.length === 1 ? 'category' : 'categories'}
      </p>

      {/* One stacked bar, so the shares are comparable at a glance. */}
      <span
        className="mt-4 flex h-2.5 w-full overflow-hidden rounded-full"
        style={{ background: '#f7fafc' }}
      >
        {rows.map((s, i) => (
          <span
            key={s.label ?? i}
            style={{ width: `${(Number(s.amount) / total) * 100}%`, background: COLOURS[i % COLOURS.length] }}
          />
        ))}
      </span>

      <ul className="mt-4 space-y-2.5">
        {rows.map((s, i) => (
          <li key={s.label ?? i} className="flex items-center gap-2.5">
            <span
              className="h-2.5 w-2.5 shrink-0 rounded-full"
              style={{ background: COLOURS[i % COLOURS.length] }}
              aria-hidden="true"
            />
            <span className="min-w-0 flex-1 truncate text-[13px]" style={{ color: '#4a5568' }}>
              {s.label || 'Other'}
            </span>
            <span className="shrink-0 text-[13px] font-bold" style={{ color: '#1a202c' }}>
              ₹{money(s.amount)}
            </span>
            <span className="w-9 shrink-0 text-right text-[11px]" style={{ color: '#a0aec0' }}>
              {Math.round((Number(s.amount) / total) * 100)}%
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

/*
 * village_dashboard.aspx, reproduced against real data and extended.
 *
 * The legacy page's own shape is kept — four stat cards across the top, then
 * Recent Activities beside Quick Actions — with a summary banner above them and
 * a collection trend and split beneath, because the legacy page had no reporting
 * of its own at all.
 *
 * It also had no data source: every figure was a literal in
 * village_dashboard.aspx.cs (`int waterTaxPaid = 27300;`) and its activity list
 * was written by hand. GET /village/dashboard computes all of this from the
 * house, house_tax, water_tax, house_owner, house_tax_receipt, Village_staff and
 * Village_payment_type tables the village screens already write.
 */
function VillageDashboard() {
  const { user } = useAuth();
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    village
      .dashboard()
      .then((d) => !cancelled && setData(d))
      .catch((err) => !cancelled && setError(err));
    return () => {
      cancelled = true;
    };
  }, []);

  /*
   * The four tiles under the legacy "Quick Actions" heading.
   *
   * Each carries a one-line `hint` naming the screen it opens: the legacy tiles
   * were an icon over a label, and "Taxes" or "Analytics & Reports" does not on
   * its own say what pressing it does.
   *
   * The legacy page pointed both "Add Announcement" and "Add Government Scheme"
   * at v_announcement.aspx — schemes were announced as notices. That is kept,
   * and the hints say so rather than implying two separate screens.
   */
  const ACTIONS = [
    {
      label: 'Add Announcement',
      hint: 'Post a notice to the village',
      to: '/community/notices',
      icon: <path d="M3 11v2a1 1 0 0 0 1 1h3l5 4V6L7 10H4a1 1 0 0 0-1 1ZM16 9a4 4 0 0 1 0 6" />,
    },
    {
      /*
       * Tax Payments, not /village/house-tax: that page reads dbo.house_tax,
       * which nothing writes, so it is empty whatever has been billed. Bills
       * live in house_tax_receipt, which is what Tax Payments lists — and it
       * is where a tile called "Taxes" is trying to get to.
       */
      label: 'Taxes',
      hint: 'Bills raised, and payments against them',
      to: '/village/payments',
      icon: <path d="M6 3h9l4 4v14H6V3ZM15 3v4h4M9 12h6M9 16h6" />,
    },
    {
      /*
       * Schemes have a screen of their own now. This pointed at Announcements,
       * where a scheme could only be a notice — with nowhere to record who
       * qualifies, what they get, or when applications close.
       */
      label: 'Add Government Scheme',
      hint: 'Schemes, who can apply, and by when',
      to: '/village/schemes',
      icon: <path d="M5 4h14v16H5V4ZM9 9h6M9 13h6M9 17h3" />,
    },
    {
      /*
       * Reports, not the balance sheet: a list of accounting heads answers
       * none of the questions this tile suggests. The balance sheet is still
       * reachable from the sidebar for anyone who wants it.
       */
      label: 'Analytics & Reports',
      hint: 'Collection, defaulters and house ledgers',
      to: '/village/reports',
      icon: <path d="M4 19h16M7 16V9m5 7V5m5 11v-4" />,
    },
  ];

  if (error) return <ErrorNotice error={error} />;
  if (!data) {
    return (
      <div className="space-y-5">
        <div className="skeleton h-[180px] rounded-2xl" />
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="skeleton h-[168px]" />
          ))}
        </div>
        <div className="grid gap-5 lg:grid-cols-[2fr_1fr]">
          <div className="skeleton h-[320px]" />
          <div className="skeleton h-[320px]" />
        </div>
      </div>
    );
  }

  const collected = (data.trend ?? []).reduce((sum, t) => sum + Number(t.collected ?? 0), 0);

  return (
    <div className="space-y-5">
      <VillageHero
        name={user?.village_name || 'Your village'}
        collected={collected}
        outstanding={data.outstanding}
        houses={data.houses}
        staff={data.staff}
      />

      <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {/*
          All three open Tax Payments, where the bills behind these figures are
          listed and settled. Property and water used to open /village/house-tax
          and /village/water-tax, which read dbo.house_tax and dbo.water_tax —
          tables nothing writes, so both pages are empty whatever has been
          billed. The cards themselves now count house_tax_receipt.
        */}
        <VillageStatCard
          title="Property Tax (Yearly)"
          paid={data.propertyTax?.paid}
          total={data.propertyTax?.total}
          paidCount={data.propertyTax?.paidCount}
          pendingCount={data.propertyTax?.pendingCount}
          to="/village/payments"
          tone={VILLAGE_TONES.home}
          icon={<path d="M4 20V9l8-5 8 5v11M9 20v-6h6v6" />}
        />
        <VillageStatCard
          title="Water Tax (Monthly)"
          paid={data.waterTax?.paid}
          total={data.waterTax?.total}
          paidCount={data.waterTax?.paidCount}
          pendingCount={data.waterTax?.pendingCount}
          to="/village/payments"
          tone={VILLAGE_TONES.water}
          icon={<path d="M12 3s6 6.6 6 10.5A6 6 0 0 1 6 13.5C6 9.6 12 3 12 3Z" />}
        />
        {/* Waste is billed like the other two now, so it carries the same
            paid / pending footer instead of "no collection record". */}
        <VillageStatCard
          title="Waste Tax (Monthly)"
          paid={data.wasteTax?.paid}
          total={data.wasteTax?.total}
          paidCount={data.wasteTax?.paidCount}
          pendingCount={data.wasteTax?.pendingCount}
          to="/village/payments"
          tone={VILLAGE_TONES.waste}
          icon={<path d="M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13M10 11v5M14 11v5" />}
        />
        <VillagePopulationCard residents={data.residents} houses={data.houses} />
      </div>

      {/* Reporting the legacy page had none of: what came in over the year, and
          what it was collected against. */}
      <div className="grid gap-5 lg:grid-cols-[2fr_1fr]">
        <div className="panel">
          <div className="panel-title">
            <SectionHeading
              title="Collection Trend"
              icon={<path d="M4 19h16M7 15l4-5 3 3 5-7" />}
            />
            <span className="text-xs" style={{ color: '#a0aec0' }}>
              Last 12 months
            </span>
          </div>
          <div className="panel-body">
            <VillageTrend trend={data.trend} />
          </div>
        </div>

        {/* Quick Actions sits up here beside the trend, where it is reachable
            without scrolling past the activity list. */}
        <div className="panel">
          <div className="panel-title">
            <SectionHeading
              title="Quick Actions"
              icon={<path d="M13 2 4.5 13H11l-1 9 8.5-11H12l1-9Z" />}
            />
          </div>
          <div className="panel-body">
            {/*
              A row per action — icon, then the label over a line naming the
              screen it opens, then a chevron. The legacy tiles were an icon
              over a bare label, which left "Taxes" and "Analytics & Reports"
              saying nothing about where they lead.
            */}
            <div className="grid gap-2.5 sm:grid-cols-2 lg:grid-cols-1">
              {ACTIONS.map((a) => (
                <Link
                  key={a.label}
                  to={a.to}
                  className="group flex items-center gap-3 rounded-xl p-3 no-underline transition-colors hover:bg-[#eef3fb]"
                  style={{ background: '#f7fafc', border: '1px solid var(--line)' }}
                >
                  <span
                    className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[13px] text-white transition-transform group-hover:scale-105"
                    style={{
                      background: 'linear-gradient(135deg, #e06a6a, #c94040)',
                      boxShadow: '0 4px 12px -2px rgba(201, 64, 64,0.45)',
                    }}
                    aria-hidden="true"
                  >
                    <svg
                      width="19"
                      height="19"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.9"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      {a.icon}
                    </svg>
                  </span>

                  <span className="min-w-0 flex-1">
                    <span
                      className="block truncate text-sm font-semibold"
                      style={{ color: '#2d3748' }}
                    >
                      {a.label}
                    </span>
                    <span className="block truncate text-xs" style={{ color: '#718096' }}>
                      {a.hint}
                    </span>
                  </span>

                  {/* Slides a little on hover, so the row reads as going
                      somewhere rather than toggling something. */}
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="shrink-0 transition-transform group-hover:translate-x-0.5"
                    style={{ color: '#a0aec0' }}
                    aria-hidden="true"
                  >
                    <path d="m9 6 6 6-6 6" />
                  </svg>
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-5 lg:grid-cols-[2fr_1fr]">
        <div className="panel">
          <div className="panel-title">
            <SectionHeading
              title="Recent Activities"
              icon={
                <>
                  <path d="M3 12a9 9 0 1 0 3-6.7L3 8" />
                  <path d="M3 4v4h4M12 8v4l3 2" />
                </>
              }
            />
            {/* .view-all-link, beside the title in the legacy header. */}
            <Link
              to="/village/payments"
              className="text-xs font-semibold no-underline hover:underline"
              style={{ color: 'var(--accent-strong)' }}
            >
              View All →
            </Link>
          </div>
          <div className="panel-body">
            {data.activity?.length ? (
              /*
                Each receipt is its own row, coloured by what was paid for.
                The legacy list was one flat grey block repeated with the same
                green icon and the same "Completed" badge on every line, which
                gave the eye nothing to scan — the amount is the thing being
                reported, so it leads on the right, and the type carries the
                colour.
              */
              <ul className="space-y-2.5">
                {data.activity.map((a, i) => {
                  const t = RECEIPT_TONES[a.typeCode] ?? RECEIPT_TONES.default;
                  return (
                    <li
                      key={`${a.receipt_no}-${i}`}
                      className="group relative flex items-center gap-3.5 overflow-hidden rounded-xl p-3.5 transition-colors hover:bg-[#f1f5fb]"
                      style={{ background: '#f8fafc', border: '1px solid var(--line)' }}
                    >
                      {/* A colour bar down the left edge, so a run of rows reads
                          as a grouped list rather than a wall of grey. */}
                      <span
                        className="absolute inset-y-0 left-0 w-1"
                        style={{ background: t.fg }}
                        aria-hidden="true"
                      />

                      <span
                        className="ml-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl"
                        style={{ background: t.bg, color: t.fg }}
                        aria-hidden="true"
                      >
                        <svg
                          width="18"
                          height="18"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        >
                          {t.icon}
                        </svg>
                      </span>

                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <p
                            className="truncate text-sm font-semibold"
                            style={{ color: '#2d3748' }}
                          >
                            {a.owner_name || 'Unknown'}
                          </p>
                          {a.house_no ? (
                            <span
                              className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-semibold"
                              style={{ background: '#eef2f9', color: '#718096' }}
                            >
                              No. {a.house_no}
                            </span>
                          ) : null}
                        </div>

                        <div className="mt-1 flex items-center gap-2 text-[11px]" style={{ color: '#a0aec0' }}>
                          <span className="font-semibold" style={{ color: t.fg }}>
                            {a.typeName || 'Payment'}
                          </span>
                          <span aria-hidden="true">·</span>
                          <span>
                            {a.pay_date
                              ? new Date(a.pay_date).toLocaleDateString(undefined, {
                                  day: 'numeric',
                                  month: 'short',
                                  year: 'numeric',
                                })
                              : '—'}
                          </span>
                          {a.receipt_no ? (
                            <>
                              <span aria-hidden="true">·</span>
                              <span className="truncate">#{a.receipt_no}</span>
                            </>
                          ) : null}
                        </div>
                      </div>

                      {/* The figure the row exists to report. */}
                      <span
                        className="shrink-0 text-[15px] font-bold tabular-nums"
                        style={{ color: '#1a202c' }}
                      >
                        ₹{money(a.amount)}
                      </span>
                    </li>
                  );
                })}
              </ul>
            ) : (
              <EmptyState title="No recent activity" />
            )}
          </div>
        </div>

        {/*
          The split sits beside the activity list, where both answer the same
          question — what has actually been collected. `self-start` keeps it at
          its own height: a grid item stretches to its row by default, which
          left three short rows of text spread down a panel as tall as the
          eight-item activity list beside it.
        */}
        <div className="panel self-start">
          <div className="panel-title">
            <SectionHeading
              title="Collected By Type"
              icon={<path d="M12 3v9l6.5 3.8A9 9 0 1 0 12 3Z" />}
            />
          </div>
          <div className="panel-body">
            <VillageSplit split={data.split} />
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Society dashboard — replaces dashboard.aspx and Admin_Dashboard.aspx.
 * A village account gets VillageDashboard above instead.
 */
export default function DashboardPage() {
  const { user, villageId } = useAuth();
  const [data, setData] = useState(null);
  const [masters, setMasters] = useState(null);
  const [expenseChart, setExpenseChart] = useState([]);
  const [error, setError] = useState(null);
  /*
   * A village account opens on the Village tab.
   *
   * login1.aspx.cs branched on the account itself — `if (!string.IsNullOrEmpty(
   * result.Village_Id)) Response.Redirect("village_dashboard.aspx")` — so a
   * village login never saw the society dashboard. The two pages are one screen
   * here with village_dashboard.aspx as its Village tab, and defaulting to
   * Overview would land a village account on society figures it has none of.
   */
  const [tab, setTab] = useState(villageId ? 'village' : 'overview');
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
    /*
     * A village account renders VillageDashboard alone, which loads itself from
     * GET /village/dashboard. These are the society panels' sources — bills,
     * buildings, wings, flats, PDC — none of which a village has rows for, and
     * several of which the API refuses outright for a village tenant. Firing
     * them anyway spent five requests per visit to fill panels that never
     * render, and a refusal surfaced as an error banner over a working page.
     */
    if (villageId) return undefined;

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
  }, [villageId]);

  /*
   * Maintenance Tracker data — the port of loadExpenseChart(). The checkbox
   * pair is a server-side filter (ExpenseType), not a client-side one, so
   * changing it has to refetch rather than slice the rows already held.
   */
  useEffect(() => {
    // Society-only, as above: the tracker lives on the Overview tab.
    if (villageId) return undefined;
    let cancelled = false;
    const type = showRegular && showAddOn ? 2 : showRegular ? 1 : showAddOn ? 0 : 3;

    reports
      .expenseChart(type)
      .then((r) => !cancelled && setExpenseChart(r.items ?? []))
      .catch(() => !cancelled && setExpenseChart([]));

    return () => {
      cancelled = true;
    };
  }, [showRegular, showAddOn, villageId]);

  // Refetch the donut when the period changes. Skipped on the initial 'year'
  // selection, which the dashboard payload already covers.
  useEffect(() => {
    if (villageId) return undefined;
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
  }, [period, villageId]);

  /*
   * The skeleton waits on the society payload, which a village account never
   * fetches — so gating on it alone left a village staring at placeholder bars
   * for good. VillageDashboard renders its own loading state.
   */
  if (!villageId && !data && !masters && !error) return <DashboardSkeleton />;

  // Until a period is picked, the donut uses the figures the dashboard call
  // already returned; after that it follows the selection.
  const split = incomeSplit ?? data?.incomeSplit ?? [];
  const collection = split.find((r) => r.category === 'Collection')?.amount ?? 0;
  const due = split.find((r) => r.category === 'Due')?.amount ?? 0;
  // The Due Payments tile shows the IncomeChart 'Due' figure — the same number
  // the donut plots — not the defaulters roll-up.
  const dues = due;

  /*
   * The tracker's three series, in the legacy page's own order
   * (dashboard.aspx: colors: ['#ffc107', '#28a745', '#4154f1']). Due and
   * Collection keep the legacy amber and green — they read as status, not
   * brand — while Total takes the brand red in place of the legacy #4154f1.
   *
   * Every series shares the twelve months ExpenseChart returns, zero-filled —
   * which is why the chart runs flat along the axis for months with no bills
   * rather than stopping early.
   */
  const trackerSeries = [
    { key: 'due', label: 'Due', color: '#ffc107', data: expenseChart },
    { key: 'collection', label: 'Collection', color: '#28a745', data: expenseChart },
    { key: 'total', label: 'Total', color: '#c94040', data: expenseChart },
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

      {/*
        A village account gets the Village panel and nothing else — the legacy
        app sent it to village_dashboard.aspx, a page of its own that never
        carried the society figures. Overview, Financial and Activity are all
        built from bills, flats and maintenance a village does not have, so on
        those accounts they would read as a dashboard reporting zero.
      */}
      {villageId ? null : (
        <Tabs
          tabs={[
            { id: 'overview', label: 'Overview' },
            { id: 'financial', label: 'Financial' },
            { id: 'activity', label: 'Activity' },
          ]}
          active={tab}
          onChange={setTab}
          className="mb-4"
        />
      )}

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
                    className="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-[#a82a2a] hover:gap-2 hover:underline"
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
                    className="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-[#a82a2a] hover:gap-2 hover:underline"
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
                      const tone = isPayment ? '#1cc88a' : '#c94040';
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
                  className="mt-3 inline-flex items-center gap-1 text-sm font-semibold text-[#a82a2a] hover:gap-2 hover:underline"
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
                          /* A floating menu, so a true drop shadow rather than
                             the moulded pair — it is not resting on the page. */
                          style={{
                            width: 160,
                            borderRadius: 14,
                            boxShadow: '0 16px 36px -8px rgba(17,24,39,0.3)',
                          }}
                        >
                          {INCOME_PERIODS.map((p) => (
                            <button
                              key={p.id}
                              type="button"
                              role="menuitem"
                              className="block w-full px-4 py-2 text-left text-sm hover:bg-slate-50"
                              style={{
                                color: period === p.id ? '#a82a2a' : '#5c1414',
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
                    { label: 'Collection', value: collection, color: '#c94040' },
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
            <BarChart data={expenseChart} labelKey="expense_month" valueKey="expense" tone="amber" height={240} />
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

      {tab === 'village' ? <VillageDashboard /> : null}
    </section>
  );
}
