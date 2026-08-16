import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';

/*
 * The Income Tracker donut and its legend.
 *
 * The chart sits in the dashboard's narrow right-hand column, which on a phone
 * is the full width of a small card. The donut is a fixed 128–144px square, so
 * whatever shares its row gets what is left — and the legend carries rupee
 * figures that must be read exactly.
 *
 * This is asserted against the source rather than a render: the failure is a
 * layout one (a flex item shrinking instead of wrapping), and jsdom computes
 * no layout, so a render test would pass either way.
 */
const SRC = readFileSync('src/pages/DashboardPage.jsx', 'utf8');
const CSS = readFileSync('src/index.css', 'utf8');

/** The DonutChart function body. */
const donut = (() => {
  const start = SRC.indexOf('function DonutChart(');
  expect(start).toBeGreaterThan(-1);
  // Up to the next top-level `function ` declaration.
  const next = SRC.indexOf('\nfunction ', start + 1);
  return SRC.slice(start, next === -1 ? undefined : next);
})();

describe('income tracker donut', () => {
  /*
   * The regression this guards.
   *
   * The donut and legend were one `flex-wrap` row. A wrap only happens once an
   * item cannot shrink any further, and the legend had `flex-1` — so it never
   * wrapped, it just shrank beside the 144px donut and the amounts were
   * clipped mid-figure ("₹23…" for ₹238,470).
   *
   * The first fix keyed the switch on `sm:` — a 640px VIEWPORT — which was the
   * wrong measurement and left the bug in place: this chart renders inside the
   * dashboard's right-hand `1fr` column, which is ~227px wide on a 1024px
   * screen and never exceeds ~525px. So `sm:flex-row` was always on, the donut
   * and gap took 168px of a 185px row, the legend got 17px, and "₹235,291"
   * spilled 30px past the panel's edge.
   *
   * It is a CONTAINER query now: the layout asks how wide its own box is, not
   * how wide the window is. These assert the component opted into that and did
   * not quietly regain a viewport breakpoint.
   */
  it('lays the donut out against its container, not the viewport', () => {
    // The row carries the component class the container query targets...
    expect(donut).toMatch(/className="donut-chart"/);
    // ...and no `sm:` breakpoint decides its direction any more. Checked
    // against the className attributes only — the comment above the element
    // explains the old `sm:flex-row` and must not trip this.
    const classNames = [...donut.matchAll(/className="([^"]*)"/g)].map((m) => m[1]).join(' ');
    expect(classNames).not.toMatch(/sm:flex-row/);
  });

  it('defines the donut layout as a container query on the panel', () => {
    // The panel must BE a container, or the query below can never match.
    expect(CSS).toMatch(/container-type:\s*inline-size/);
    expect(CSS).toMatch(/container-name:\s*panel/);
    // The row/column switch is driven by the container's width.
    expect(CSS).toMatch(/@container panel \(min-width:[^)]+\)/);
  });

  it('stacks by default so a narrow panel never squeezes the legend', () => {
    // `.donut-chart` is column-first; the row layout is the opt-in inside the
    // container query. If that inverted, a narrow panel would clip again.
    const base = CSS.match(/\.donut-chart\s*\{([^}]*)\}/)?.[1] ?? '';
    expect(base).toMatch(/flex-direction:\s*column/);
  });

  it('does not let the legend shrink instead of stacking', () => {
    const legend = donut.match(/<ul className="([^"]*)"/)?.[1] ?? '';
    expect(legend).toContain('w-full');
    // `flex-1` must not sit on the element unconditionally — it belongs inside
    // the container query, where the row genuinely has room for both.
    expect(legend).not.toMatch(/(^|\s)flex-1(\s|$)/);
    expect(legend).not.toMatch(/sm:flex-1/);
  });

  /*
   * Which side gives way when the row is still tight. A truncated "Collection"
   * is still readable; a truncated amount is a different number, so the figure
   * holds its width and the label yields.
   */
  it('keeps the amount whole and truncates the label instead', () => {
    // The figure never wraps or shrinks.
    expect(donut).toMatch(/shrink-0 whitespace-nowrap font-semibold/);
    // The label is the part allowed to give.
    expect(donut).toMatch(/<span className="truncate">\{s\.label\}<\/span>/);
    // A shrinking flex child needs a zero floor or it refuses to give at all.
    expect(donut).toMatch(/flex min-w-0 items-center/);
  });

  it('keeps the colour dot from being squeezed by a long label', () => {
    expect(donut).toMatch(/h-2\.5 w-2\.5 shrink-0 rounded-full/);
  });
});

/*
 * The three headline tiles — Due Payments / Defaulters / Total Members.
 *
 * They sit three-across inside the dashboard's `2fr` column, so each is about
 * 140px wide on a 1024px screen. At that width a two-word uppercase label beside
 * a 36px glyph plate had ~58px to live in, so it wrapped to a second line and
 * ran under the plate — which is what cut "DEFAULTERS" in half.
 *
 * Like the donut, the fix is a container query: the label sizes against the
 * TILE. These assert the mechanism stays in place, and — importantly — that the
 * size properties are NOT set with Tailwind utilities, which sit in a later
 * cascade layer than `components` and would silently outrank the query.
 */
describe('dashboard headline tiles', () => {
  const tile = (() => {
    const start = SRC.indexOf('function HeadlineTile(');
    expect(start).toBeGreaterThan(-1);
    const next = SRC.indexOf('\nfunction ', start + 1);
    return SRC.slice(start, next === -1 ? undefined : next);
  })();

  it('makes each tile a query container', () => {
    expect(CSS).toMatch(/container-name:\s*tile/);
    expect(CSS).toMatch(/@container tile \(max-width:[^)]+\)/);
  });

  it('lets the label size come from CSS, not a utility that would outrank it', () => {
    const label = tile.match(/<p className="(stat-tile-label[^"]*)"/)?.[1] ?? '';
    expect(label).toContain('stat-tile-label');
    // A `text-*` utility here would win over the container query and the label
    // would go on wrapping however narrow the tile got.
    expect(label).not.toMatch(/\btext-(xs|sm|base|\[\d+px\])\b/);
    expect(label).not.toMatch(/\btracking-\w+/);
  });

  it('lets the glyph plate shrink, so the label keeps its width', () => {
    const glyph = tile.match(/className="(stat-tile-glyph[^"]*)"/)?.[1] ?? '';
    expect(glyph).toContain('stat-tile-glyph');
    // Same reasoning: `h-9 w-9` would pin the plate and starve the label.
    expect(glyph).not.toMatch(/\bh-\d+\b/);
    expect(glyph).not.toMatch(/\bw-\d+\b/);
    // The plate is decoration and must never push the label out of the tile.
    expect(glyph).toContain('shrink-0');
  });
});
