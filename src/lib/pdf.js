/**
 * PDF export — the legacy pages' "Download PDF" / "Download Report" buttons.
 *
 * Society2024 did this client-side with jsPDF + html2canvas (see
 * Defaulter.aspx, owner_search.aspx and the print* pages), so the same
 * approach is kept rather than adding a server-side renderer.
 *
 * Both libraries are imported dynamically: they are large, and most sessions
 * never export, so they should not sit in the initial bundle.
 */

/** jsPDF's export shape differs between builds; accept either. */
async function loadJsPdf() {
  const mod = await import('jspdf');
  return mod.jsPDF ?? mod.default?.jsPDF ?? mod.default;
}

const stamp = () => new Date().toISOString().slice(0, 10);

/**
 * Render a DOM node into a PDF and download it.
 *
 * Used for report and print views, where the on-screen layout *is* the
 * document — the same thing html2canvas did on the legacy pages.
 */
export async function elementToPdf(node, filename = 'report') {
  if (!node) throw new Error('Nothing to export');

  const [{ default: html2canvas }, JsPDF] = await Promise.all([
    import('html2canvas'),
    loadJsPdf(),
  ]);

  // scale 2 keeps table text legible; white background because the capture
  // would otherwise inherit transparency and print grey.
  const canvas = await html2canvas(node, { scale: 2, backgroundColor: '#ffffff', useCORS: true });
  const image = canvas.toDataURL('image/png');

  const pdf = new JsPDF({ orientation: 'portrait', unit: 'pt', format: 'a4' });
  const pageW = pdf.internal.pageSize.getWidth();
  const pageH = pdf.internal.pageSize.getHeight();
  const margin = 24;

  const usableW = pageW - margin * 2;
  const scaled = (canvas.height * usableW) / canvas.width;

  // Taller-than-a-page captures are sliced across pages rather than squashed.
  let remaining = scaled;
  let offset = 0;
  while (remaining > 0) {
    if (offset > 0) pdf.addPage();
    pdf.addImage(image, 'PNG', margin, margin - offset, usableW, scaled, undefined, 'FAST');
    remaining -= pageH - margin * 2;
    offset += pageH - margin * 2;
  }

  pdf.save(`${filename}-${stamp()}.pdf`);
}

/**
 * Render tabular data straight to a PDF, without going through the DOM.
 *
 * Preferred for grids: the output is selectable text at a predictable width,
 * where an html2canvas capture would be a bitmap of whatever happened to be
 * on screen (including the parts scrolled out of view).
 */
export async function tableToPdf({ columns, rows, title, filename = 'export' }) {
  const JsPDF = await loadJsPdf();
  const pdf = new JsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });

  const pageW = pdf.internal.pageSize.getWidth();
  const pageH = pdf.internal.pageSize.getHeight();
  const margin = 28;
  const lineH = 16;

  let y = margin;

  if (title) {
    pdf.setFontSize(14);
    pdf.setTextColor(1, 41, 112); // #012970, the legacy heading colour
    pdf.text(title, margin, y);
    y += 10;
  }

  pdf.setFontSize(8);
  pdf.setTextColor(60);
  pdf.text(new Date().toLocaleString(), margin, y + 8);
  y += 22;

  const colW = (pageW - margin * 2) / Math.max(columns.length, 1);
  const clip = (text, width) => {
    const s = String(text ?? '');
    const max = Math.floor(width / 4.6); // ~4.6pt per character at size 9
    return s.length > max ? `${s.slice(0, Math.max(max - 1, 1))}…` : s;
  };

  const header = () => {
    pdf.setFillColor(234, 236, 244); // #eaecf4
    pdf.rect(margin, y - 11, pageW - margin * 2, lineH, 'F');
    pdf.setFontSize(9);
    pdf.setTextColor(1, 41, 112);
    columns.forEach((c, i) => pdf.text(clip(c.label, colW), margin + i * colW + 3, y));
    y += lineH;
  };

  header();

  pdf.setTextColor(33);
  for (const row of rows) {
    if (y > pageH - margin) {
      pdf.addPage();
      y = margin;
      header();
      pdf.setTextColor(33);
    }
    columns.forEach((c, i) => {
      const raw = c.exportValue ? c.exportValue(row) : row[c.key];
      pdf.text(clip(raw, colW), margin + i * colW + 3, y);
    });
    y += lineH;
  }

  pdf.save(`${filename}-${stamp()}.pdf`);
}
