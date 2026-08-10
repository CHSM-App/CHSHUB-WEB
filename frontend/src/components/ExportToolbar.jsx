import { useState } from 'react';

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
  // Report screens pass these so the PDF carries the same run criteria and
  // balance-row shading the printed page shows. Plain grids omit them.
  filters,
  emphasiseRow,
  // [r, g, b] for the PDF's header fill and title rule, matching the accent
  // the report uses on screen.
  accent,
}) {
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
    const blob = new Blob([`${head}\n${body}`], { type: 'text/csv;charset=utf-8;' });
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
    <div className="flex justify-end gap-2 border-b border-slate-200 px-4 py-2 print:hidden">
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
