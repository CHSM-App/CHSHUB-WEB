import { useState } from 'react';
import { useOptionalUser } from '@/auth/AuthContext.jsx';

/**
 * The three export actions every legacy grid page carried — "Export to Excel",
 * "Download PDF" and Print.
 *
 * DataGrid and GenericCrudPage both render tables from a `columns` + `rows`
 * pair, and both legacy originals offered these buttons, so the toolbar lives
 * here rather than being written twice.
 *
 * `print:hidden` keeps the toolbar itself out of the printed page.
 */
export default function ExportToolbar({
  columns,
  rows,
  exportName,
  exportTitle,
  // Whose records these are, printed under the report title. Defaults to the
  // signed-in society or village, so every export says whose sheet it is
  // without each page having to pass it.
  exportSubtitle,
  // Report screens pass these so the PDF carries the same run criteria and
  // balance-row shading the printed page shows. Plain grids omit them.
  filters,
  emphasiseRow,
  // [r, g, b] for the PDF's header fill and title rule, matching the accent
  // the report uses on screen.
  accent,
}) {
  // Optional: a grid rendered without an AuthProvider (as tests do) still
  // exports, just without the tenant line.
  const user = useOptionalUser();
  const tenantName = user?.society_name || user?.village_name || '';
  const [pdfBusy, setPdfBusy] = useState(false);

  /** CSV export — the legacy pages' "Export to Excel" button. */
  const exportCsv = () => {
    const head = columns.map((c) => `"${c.label}"`).join(',');
    const body = rows
      .map((r, i) =>
        columns
          .map((c) => {
            // The index is passed too, for a serial-number column that has no
            // backing field on the row.
            const v = c.exportValue ? c.exportValue(r, i) : r[c.key];
            return `"${String(v ?? '').replace(/"/g, '""')}"`;
          })
          .join(','),
      )
      .join('\n');
    /*
     * The same heading the PDF carries — report name, then whose records these
     * are — so a spreadsheet opened weeks later still says what it is. Both are
     * quoted single-cell rows, followed by a blank line, so the column headers
     * still land on their own row for a parser.
     */
    const heading = [
      `"${String(exportTitle ?? exportName ?? 'Export').replace(/"/g, '""')}"`,
      tenantName ? `"${tenantName.replace(/"/g, '""')}"` : null,
      `"Printed ${new Date().toLocaleDateString()}"`,
      '',
    ]
      .filter((l) => l !== null)
      .join('\n');

    const blob = new Blob([`${heading}\n${head}\n${body}`], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `${exportName || 'export'}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  /** PDF export — the legacy pages' "Download PDF" button. */
  const exportPdf = async () => {
    setPdfBusy(true);
    try {
      const { tableToPdf } = await import('@/lib/pdf');
      await tableToPdf({
        columns,
        rows,
        title: exportTitle ?? exportName,
        subtitle: exportSubtitle ?? tenantName,
        filename: exportName || 'export',
        filters,
        emphasiseRow,
        ...(accent ? { accent } : {}),
      });
    } catch (err) {
      // A failed export should report itself, not disappear into the console.
      window.alert(`Could not create the PDF: ${err.message}`);
    } finally {
      setPdfBusy(false);
    }
  };

  return (
    <div className="flex flex-wrap justify-end gap-2 border-b border-slate-200 px-4 py-2 print:hidden">
      <button type="button" className="btn-secondary text-xs" onClick={exportCsv}>
        Export to Excel
      </button>
      <button type="button" className="btn-secondary text-xs" onClick={exportPdf} disabled={pdfBusy}>
        {pdfBusy ? 'Preparing…' : 'Download PDF'}
      </button>
      <button type="button" className="btn-secondary text-xs" onClick={() => window.print()}>
        Print
      </button>
    </div>
  );
}
