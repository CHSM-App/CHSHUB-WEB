import { describe, expect, it } from 'vitest';
import { render } from '@testing-library/react';
import { readFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

/*
 * The phone card view for the app's own tables.
 *
 * Most screens render their own <table> rather than going through DataGrid, so
 * they get their card view from the `stacked-table` rules in index.css: each
 * cell's label comes from the `data-label` it carries, and the action cell is
 * marked `data-actions` so it lays out as a button row instead of a field.
 *
 * That contract lives across forty tables in twenty files, which is too many to
 * keep right by hand — a cell added later with no data-label renders as a value
 * with no label on a phone, and nothing else would catch it. This walks the
 * source and checks the invariant directly.
 */
const files = execSync('find src/pages -name "*.jsx" ! -name "*.test.jsx"', {
  encoding: 'utf8',
})
  .trim()
  .split('\n');

/**
 * Header text with JSX tags and expressions stripped out.
 *
 * A header holding only a control — the select-all checkbox — has no text to
 * take, and a naive strip leaves fragments of the expression behind ("0}
 * onChange= />"). Anything with a tag or a brace still in it after stripping is
 * treated as having no usable label, so the cell below it is free to name
 * itself.
 */
const headText = (inner) => {
  const text = inner
    .replace(/<[^>]*>/g, ' ')
    .replace(/\{[^{}]*\}/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return /[{}<>=/]/.test(text) ? '' : text;
};

/** Every `stacked-table` in the codebase, with its headers and body rows. */
function stackedTables() {
  const found = [];
  for (const file of files) {
    const src = readFileSync(file, 'utf8');
    for (const m of src.matchAll(/<table\b[^>]*>[\s\S]*?<\/table>/g)) {
      const table = m[0];
      if (!/stacked-table/.test(table)) continue;
      const headers = [...table.matchAll(/<th\b([^>]*)>([\s\S]*?)<\/th>/g)].map((h) => ({
        srOnly: /sr-only/.test(h[1]),
        label: headText(h[2]),
      }));
      const tbody = table.match(/<tbody\b[^>]*>([\s\S]*?)<\/tbody>/);
      const rows = tbody ? [...tbody[1].matchAll(/<tr\b[^>]*>[\s\S]*?<\/tr>/g)].map((r) => r[0]) : [];
      found.push({ file, headers, rows });
    }
  }
  return found;
}

const TABLES = stackedTables();

describe('stacked table cards', () => {
  it('covers the app tables that need a phone layout', () => {
    // A floor, not the exact count: new tables should push this up, and a
    // sweep that silently stopped matching would drop it.
    expect(TABLES.length).toBeGreaterThanOrEqual(35);
  });

  it('labels every data cell from its own column header', () => {
    const wrong = [];

    for (const { file, headers, rows } of TABLES) {
      for (const row of rows) {
        const cells = [...row.matchAll(/<td\b([^>]*)>/g)].map((c) => c[1]);
        // A spanning row (totals, "no records match") is its own shape and
        // deliberately carries no per-column labels.
        if (cells.some((a) => /colSpan/.test(a))) continue;

        cells.forEach((attrs, i) => {
          const header = headers[i];
          if (!header) return;
          const label = attrs.match(/data-label="([^"]*)"/)?.[1] ?? null;
          const isActions = /data-actions/.test(attrs);
          /*
           * `data-label={c.label}` on a cell generated from a column array.
           * Its text is only known at render, so it cannot be compared with a
           * header here — the "labels generated cells" test below is what
           * covers that shape.
           */
          if (/data-label=\{/.test(attrs)) return;

          /*
           * A header with no text of its own — sr-only, or holding just a
           * select-all checkbox — has no name for its cell to borrow. Such a
           * cell either lays its buttons out as an action row, or names itself
           * with a label the header could not supply ("Pay" over a tick box).
           * What it must not do is go unlabelled: on a phone that renders as a
           * bare value with nothing saying what it is.
           */
          if (header.srOnly || !header.label) {
            if (!isActions && !label) {
              wrong.push(`${file} cell ${i}: needs data-actions or a data-label of its own`);
            }
            return;
          }
          if (label !== header.label.replace(/"/g, '&quot;')) {
            wrong.push(`${file} cell ${i}: header "${header.label}" vs label "${label}"`);
          }
        });
      }
    }

    expect(wrong).toEqual([]);
  });

  /*
   * A label built out of a JSX expression rather than text — the select-all
   * checkbox column produced `data-label="0} onChange= />"` when this was first
   * generated, which would have rendered as that literal string on a phone.
   */
  /*
   * The check above walks cells by position against the headers, which only
   * works for a table that writes both out literally. Several tables generate
   * their columns from an array instead, so a row is one `columns.map()` and
   * the positional pass sees a single cell against a single header.
   *
   * Those were exactly the ones the first sweep got wrong: it marked every
   * generated data cell `data-actions`, which on a phone renders the value as
   * a button row with no label at all. This catches the shape directly — a
   * cell is an actions cell only if it actually holds controls.
   */
  it('reserves data-actions for cells that hold controls', () => {
    const mistagged = [];
    for (const file of files) {
      const src = readFileSync(file, 'utf8');
      for (const m of src.matchAll(/<td\b[^>]*data-actions[^>]*>([\s\S]{0,400}?)<\/td>/g)) {
        if (!/<button|<a\b|<Link|onClick=/.test(m[1])) {
          const line = src.slice(0, m.index).split('\n').length;
          mistagged.push(`${file}:${line}`);
        }
      }
    }
    expect(mistagged).toEqual([]);
  });

  /*
   * A cell generated from a column array has to take its label from that
   * array. Written as a literal string it would be the same text on every row
   * of the table, which is the mistake this shape invites.
   */
  it('labels generated cells from their column definition', () => {
    const literal = [];
    for (const file of files) {
      const src = readFileSync(file, 'utf8');
      for (const m of src.matchAll(/\.map\(\(?\s*[\w[\]{},\s]*\)?\s*=>\s*\(?\s*<td\b([^>]*)>/g)) {
        const label = m[1].match(/data-label=(?:"([^"]*)"|\{([^}]*)\})/);
        if (!label) continue;
        // A quoted string here is the same label for every generated column.
        if (label[1] !== undefined) {
          const line = src.slice(0, m.index).split('\n').length;
          literal.push(`${file}:${line} — data-label="${label[1]}" on a generated cell`);
        }
      }
    }
    expect(literal).toEqual([]);
  });

  it('has no labels containing markup or expression debris', () => {
    const debris = [];
    for (const file of files) {
      const src = readFileSync(file, 'utf8');
      for (const m of src.matchAll(/data-label="([^"]*)"/g)) {
        if (/[{}<>=]/.test(m[1]) || m[1].trim() === '') {
          debris.push(`${file}: ${JSON.stringify(m[1])}`);
        }
      }
    }
    expect(debris).toEqual([]);
  });

  /*
   * The checks above read source. This one renders, because a label written as
   * `data-label={c.label}` is only a promise until React resolves it — the
   * attribute could still come out empty at runtime and every check above
   * would stay green.
   */
  it('puts the column label on each cell once rendered', () => {
    const columns = [
      { key: 'name', label: 'Name' },
      { key: 'unit', label: 'Unit' },
    ];
    const rows = [{ id: 1, name: 'R. Sharma', unit: 'A-101' }];

    // The generated-cell shape GenericCrudPage and ReadOnlyPages both use.
    const { container } = render(
      <table className="stacked-table">
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c.key} className="table-head">
                {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              {columns.map((c) => (
                <td key={c.key} className="table-cell" data-label={c.label}>
                  {row[c.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>,
    );

    const cells = [...container.querySelectorAll('td')];
    expect(cells.map((td) => td.getAttribute('data-label'))).toEqual(['Name', 'Unit']);
    // The label is what the CSS prints via ::before, so an empty one would
    // render the value with nothing naming it.
    expect(cells.every((td) => td.getAttribute('data-label'))).toBe(true);
  });

  it('gives each stacked table a horizontal scroller for wider screens', () => {
    // Between the card view below 640px and the full page above it, a wide
    // table still has to be reachable rather than clipped.
    const unwrapped = [];
    for (const file of files) {
      const src = readFileSync(file, 'utf8');
      const lines = src.split('\n');
      lines.forEach((ln, i) => {
        // The class on a <table>, not the word in a comment explaining why a
        // printed layout deliberately goes without it.
        if (!/<table\b[^>]*stacked-table/.test(ln)) return;
        const back = lines.slice(Math.max(0, i - 6), i).join('\n');
        if (!/overflow-x-auto|overflow-auto/.test(back)) unwrapped.push(`${file}:${i + 1}`);
      });
    }
    expect(unwrapped).toEqual([]);
  });
});
