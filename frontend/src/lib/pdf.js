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
 * Render each node onto a page of its own.
 *
 * elementToPdf captures one tall image and slices it at fixed intervals, so a
 * document made of separate sheets — a bill per flat — gets cut wherever the
 * page happens to end, mid-table. Capturing sheet by sheet keeps each one
 * whole, which is what the legacy print CSS achieved with page-break rules.
 *
 * A sheet taller than a page is still split, but only that sheet.
 */
export async function elementsToPdf(nodes, filename = 'report') {
  const sheets = Array.from(nodes ?? []).filter(Boolean);
  if (!sheets.length) throw new Error('Nothing to export');

  const [{ default: html2canvas }, JsPDF] = await Promise.all([
    import('html2canvas'),
    loadJsPdf(),
  ]);

  const pdf = new JsPDF({ orientation: 'portrait', unit: 'pt', format: 'a4' });
  const pageW = pdf.internal.pageSize.getWidth();
  const pageH = pdf.internal.pageSize.getHeight();
  const margin = 24;
  const usableW = pageW - margin * 2;
  const usableH = pageH - margin * 2;

  for (const [i, node] of sheets.entries()) {
    const canvas = await html2canvas(node, { scale: 2, backgroundColor: '#ffffff', useCORS: true });
    const image = canvas.toDataURL('image/png');
    const scaled = (canvas.height * usableW) / canvas.width;

    if (i > 0) pdf.addPage();

    let remaining = scaled;
    let offset = 0;
    while (remaining > 0) {
      if (offset > 0) pdf.addPage();
      pdf.addImage(image, 'PNG', margin, margin - offset, usableW, scaled, undefined, 'FAST');
      remaining -= usableH;
      offset += usableH;
    }
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
export async function tableToPdf({
  columns,
  rows,
  title,
  filename = 'export',
  // Run criteria shown in the box under the title.
  filters = [],
  // Rows the report computes rather than lists (opening / total / closing).
  // Returns the kind so each keeps the colour it has on screen.
  emphasiseRow,
  // A4 fits about six columns upright before text starts being clipped, so
  // wider reports ask for landscape. Nothing here scales to the screen — the
  // page is the fixed target, which is why the on-screen table can scroll
  // sideways while the PDF must not.
  orientation = columns.length > 6 ? 'landscape' : 'portrait',
  // Accent colour as [r, g, b] — #667eea by default, matching the indigo the
  // ownerwise report uses on screen.
  accent = [102, 126, 234],
}) {
  const JsPDF = await loadJsPdf();
  const pdf = new JsPDF({ orientation, unit: 'pt', format: 'a4' });

  const pageW = pdf.internal.pageSize.getWidth();
  const pageH = pdf.internal.pageSize.getHeight();
  const margin = 40;
  const lineH = 20;
  const usableW = pageW - margin * 2;
  const bottom = pageH - margin - 18; // room for the page footer

  // Palette from ownerwise_maintenance.aspx's print stylesheet.
  // Header fill and title rule. Each legacy report had its own: indigo on
  // ownerwise_maintenance.aspx, a darker navy on v_profite_loss.aspx.
  const INDIGO = accent;
  const GREEN = [232, 245, 233]; // #e8f5e9 — opening balance
  const BLUE = [227, 242, 253]; // #e3f2fd — total balance
  const ORANGE = [255, 243, 224]; // #fff3e0 — closing balance
  const ZEBRA = [248, 249, 250]; // #f8f9fa — alternating rows
  const GRID = [222, 226, 230]; // #dee2e6 — cell borders

  let y = margin;

  /* ---- title, centred, with the accent rule under it ---- */
  if (title) {
    pdf.setFont(undefined, 'bold');
    pdf.setFontSize(17);
    pdf.setTextColor(51);
    pdf.text(String(title), pageW / 2, y + 6, { align: 'center' });
    pdf.setFont(undefined, 'normal');
    y += 18;
    pdf.setDrawColor(...INDIGO);
    pdf.setLineWidth(1.5);
    pdf.line(margin, y, pageW - margin, y);
    y += 22;
  }

  /* ---- run criteria, tinted box with a left accent bar ---- */
  const shown = (filters ?? []).filter((f) => f && f.value !== '' && f.value != null);
  if (shown.length) {
    const rowH = 15;
    const boxH = shown.length * rowH + 14;
    pdf.setFillColor(248, 249, 250);
    pdf.rect(margin, y, usableW, boxH, 'F');
    pdf.setFillColor(...INDIGO);
    pdf.rect(margin, y, 4, boxH, 'F');

    // Label column is wide enough for the longest label, so the values line up.
    const labelW =
      Math.max(...shown.map((f) => String(f.label).length)) * 5.6 + 16;

    let ly = y + 17;
    shown.forEach((f) => {
      pdf.setFont(undefined, 'bold');
      pdf.setFontSize(9.5);
      pdf.setTextColor(33);
      pdf.text(`${f.label}:`, margin + 16, ly);
      pdf.setFont(undefined, 'normal');
      pdf.setTextColor(73);
      pdf.text(String(f.value), margin + 16 + labelW, ly);
      ly += rowH;
    });
    y += boxH + 20;
  }

  /* ---- column widths ----
     Numeric columns get a narrower share: an equal split left long
     descriptions truncated while amounts sat in white space.

     A numeric column still has to fit its own heading, though — squeezing
     "Paid Maintenance" into 0.62 of a share wrapped it onto two lines. The
     floor scales the share back up for a long label. */
  const isNum = (c) => c.align === 'right' || c.numeric;
  const weights = columns.map((c) =>
    isNum(c) ? Math.max(0.62, String(c.label).length / 17) : 1,
  );
  const totalWeight = weights.reduce((s, w) => s + w, 0) || 1;
  const widths = weights.map((w) => (w / totalWeight) * usableW);
  const xAt = (i) => margin + widths.slice(0, i).reduce((s, w) => s + w, 0);

  const PAD = 5;
  const LINE = 10; // leading between wrapped lines within a cell

  /**
   * Wrap to the column's real width.
   *
   * An earlier version divided the width by an average character width and
   * cut with an ellipsis, which truncated "August Maintenance Creat…" while
   * leaving the narrow columns half empty. splitTextToSize measures the
   * actual glyphs, so a long value wraps onto a second line instead of
   * losing its tail.
   */
  const wrap = (text, i) => {
    const s = String(text ?? '');
    if (!s) return [''];
    return pdf.splitTextToSize(s, widths[i] - PAD * 2);
  };

  /** Height a row needs, given the tallest cell in it. */
  const rowHeight = (cells) =>
    Math.max(lineH, Math.max(...cells.map((l) => l.length)) * LINE + 9);

  /** Cell borders for one row, drawn as a grid like the legacy table. */
  const rule = (top, h) => {
    pdf.setDrawColor(...GRID);
    pdf.setLineWidth(0.5);
    columns.forEach((_, i) => pdf.rect(xAt(i), top, widths[i], h));
  };

  const drawCells = (cells, top, h) => {
    cells.forEach((lines, i) => {
      // Vertically centre a single line; stack from the top when wrapped.
      let ty = lines.length === 1 ? top + h / 2 + 3 : top + 12;
      lines.forEach((line) => {
        if (isNum(columns[i])) {
          pdf.text(line, xAt(i) + widths[i] - PAD, ty, { align: 'right' });
        } else {
          pdf.text(line, xAt(i) + PAD, ty);
        }
        ty += LINE;
      });
    });
  };

  const header = () => {
    pdf.setFont(undefined, 'bold');
    pdf.setFontSize(8.5);
    const cells = columns.map((c, i) => wrap(c.label, i));
    const h = rowHeight(cells);

    pdf.setFillColor(...INDIGO);
    pdf.rect(margin, y, usableW, h, 'F');
    // Cell rules a shade darker than the fill, so the columns stay separable.
    pdf.setDrawColor(...INDIGO.map((c) => Math.max(0, c - 20)));
    pdf.setLineWidth(0.5);
    columns.forEach((_, i) => pdf.rect(xAt(i), y, widths[i], h));

    pdf.setTextColor(255, 255, 255);
    drawCells(cells, y, h);
    pdf.setFont(undefined, 'normal');
    y += h;
  };

  header();

  // rowIndex is tracked separately from the column index, for a serial-number
  // column whose value comes from the row's position.
  let rowIndex = 0;
  for (const row of rows) {
    // emphasiseRow returns a kind — 'opening' | 'total' | 'closing' | true —
    // so the balance rows keep the colours the on-screen report gives them.
    const kind = emphasiseRow?.(row);

    // Measure with the weight the row will be drawn in: bold text is wider,
    // so measuring in regular would under-count the lines a total row needs.
    pdf.setFont(undefined, kind ? 'bold' : 'normal');
    pdf.setFontSize(8);
    const cells = columns.map((c, i) =>
      wrap(c.exportValue ? c.exportValue(row, rowIndex) : row[c.key], i),
    );
    const h = rowHeight(cells);

    // Break before the row rather than through it, so a wrapped cell is never
    // split across two pages.
    if (y + h > bottom) {
      pdf.addPage();
      y = margin;
      header();
      pdf.setFont(undefined, kind ? 'bold' : 'normal');
      pdf.setFontSize(8);
    }

    const fill =
      kind === 'opening' ? GREEN
      : kind === 'total' ? BLUE
      : kind === 'closing' ? ORANGE
      : kind ? BLUE
      : rowIndex % 2 === 1 ? ZEBRA
      : null;

    if (fill) {
      pdf.setFillColor(...fill);
      pdf.rect(margin, y, usableW, h, 'F');
    }
    rule(y, h);

    pdf.setTextColor(51);
    drawCells(cells, y, h);
    pdf.setFont(undefined, 'normal');

    y += h;
    rowIndex += 1;
  }

  /* ---- footer on every page ---- */
  const pages = pdf.internal.getNumberOfPages();
  for (let i = 1; i <= pages; i += 1) {
    pdf.setPage(i);
    pdf.setDrawColor(...GRID);
    pdf.setLineWidth(0.5);
    pdf.line(margin, pageH - margin - 2, pageW - margin, pageH - margin - 2);
    pdf.setFontSize(7.5);
    pdf.setTextColor(108);
    // Spelled-out month, matching the period line and the on-screen footer.
    pdf.text(
      `Generated on: ${new Date()
        .toLocaleString('en-GB', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          hour12: true,
        })
        .replace(/\bam\b/i, 'am')
        .replace(/\bpm\b/i, 'pm')}`,
      margin,
      pageH - margin + 8,
    );
    pdf.text(`Page ${i} of ${pages}`, pageW - margin, pageH - margin + 8, { align: 'right' });
  }

  pdf.save(`${filename}-${stamp()}.pdf`);
}
