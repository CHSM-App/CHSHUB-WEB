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
   * wrapped, it just shrank to about 120px beside the 144px donut, and the
   * amounts were clipped mid-figure ("₹23…" for ₹238,470).
   */
  it('stacks the donut above its legend on a phone', () => {
    expect(donut).toMatch(/className="flex flex-col[^"]*sm:flex-row/);
  });

  it('does not let the legend shrink instead of stacking', () => {
    // `flex-1` may only apply from `sm` up, where the row has room for both.
    const legend = donut.match(/<ul className="([^"]*)"/)?.[1] ?? '';
    expect(legend).toContain('w-full');
    expect(legend).toMatch(/sm:flex-1/);
    expect(legend).not.toMatch(/(^|\s)flex-1(\s|$)/);
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
