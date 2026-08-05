import { describe, it, expect, vi, beforeEach } from 'vitest';
import { tableToPdf } from './pdf.js';

// jsPDF writes a real file in the browser; in jsdom we only care that the
// document is built and saved with the expected name.
const saved = [];
const text = [];

vi.mock('jspdf', () => ({
  jsPDF: class {
    internal = { pageSize: { getWidth: () => 842, getHeight: () => 595 } };
    setFontSize() {}
    setTextColor() {}
    setFillColor() {}
    rect() {}
    addPage() {
      this.pages = (this.pages ?? 1) + 1;
    }
    text(t) {
      text.push(String(t));
    }
    save(name) {
      saved.push(name);
    }
  },
}));

describe('tableToPdf', () => {
  beforeEach(() => {
    saved.length = 0;
    text.length = 0;
  });

  it('writes headers, rows and a dated filename', async () => {
    await tableToPdf({
      columns: [
        { key: 'name', label: 'Name' },
        { key: 'due', label: 'Due' },
      ],
      rows: [
        { name: 'A Sharma', due: 1200 },
        { name: 'B Patil', due: 950 },
      ],
      title: 'Defaulters',
      filename: 'defaulters',
    });

    expect(saved).toHaveLength(1);
    expect(saved[0]).toMatch(/^defaulters-\d{4}-\d{2}-\d{2}\.pdf$/);
    expect(text).toContain('Defaulters');
    expect(text).toContain('Name');
    expect(text).toContain('A Sharma');
    expect(text).toContain('950');
  });

  it('uses exportValue when a column defines one', async () => {
    await tableToPdf({
      columns: [{ key: 'amount', label: 'Amount', exportValue: (r) => `Rs ${r.amount}` }],
      rows: [{ amount: 500 }],
      filename: 'x',
    });
    expect(text).toContain('Rs 500');
  });

  it('handles an empty row set without throwing', async () => {
    await expect(
      tableToPdf({ columns: [{ key: 'a', label: 'A' }], rows: [], filename: 'empty' }),
    ).resolves.not.toThrow();
    expect(saved[0]).toMatch(/^empty-/);
  });
});
