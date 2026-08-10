import { useCallback, useEffect, useState } from 'react';
import { reports } from '@/api/modules';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import ReportHeader, { ReportFooter, useSocietyInfo } from '@/components/ReportDocument.jsx';
import { EmptyState, ErrorNotice, Field, Spinner } from '@/components/ui.jsx';

const money = (v) =>
  v == null || v === ''
    ? ''
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const n = (v) => Number(v || 0);

// The report covers a financial year, April to March.
const financialYearStart = () => {
  const now = new Date();
  const year = now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1;
  return `${year}-04-01`;
};
const today = () => new Date().toISOString().slice(0, 10);

const longDay = (v) => {
  if (!v) return '';
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return String(v);
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
};

/**
 * v_profite_loss.aspx — "Annual income and expenditure".
 *
 * The legacy grid put income and expenditure side by side in one table rather
 * than stacking them, because the two are read against each other:
 *
 *     Income | Amount | Expense | Amount
 *
 * sp_auditor_question_master's Grid_Bind_CD branch already returns rows in
 * that shape — it full-outer-joins yearwise_income to yearwise_expense, so a
 * row carries one head from each side and NULLs where a side has run out.
 * Rendering it as two separate tables would undo that pairing.
 *
 * creditDebitGridBind() appended a blank row and then a totals row, summing
 * only the current-year columns. Both are reproduced here, though the totals
 * are computed as a footer rather than pushed into the data.
 */
export default function IncomeExpenditureReport() {
  const society = useSocietyInfo();
  const [from, setFrom] = useState(financialYearStart);
  const [to, setTo] = useState(today);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const run = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const d = await reports.incomeExpense();
      setRows(d.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    run();
  }, [run]);

  // The legacy totals covered the current year only; the previous-year columns
  // were shown for comparison and left unsummed.
  const totalIncome = rows.reduce((s, r) => s + n(r.current_year_income), 0);
  const totalExpense = rows.reduce((s, r) => s + n(r.current_year_expense), 0);

  // The four BoundFields the legacy grid declared. The SP also returns
  // prev_year_income / prev_year_expense, which that grid did not bind.
  const columns = [
    { key: 'INCOME', label: 'Income' },
    { key: 'current_year_income', label: 'Amount', align: 'right', exportValue: (r) => money(r.current_year_income) },
    { key: 'EXPENSE', label: 'Expense' },
    { key: 'current_year_expense', label: 'Amount', align: 'right', exportValue: (r) => money(r.current_year_expense) },
  ];

  const reportFilters = [
    { label: 'Period', value: from && to ? `${longDay(from)} to ${longDay(to)}` : '' },
  ];

  // Appended so the totals reach the PDF and the CSV, which export the rows
  // they are given rather than reading the footer off the DOM.
  const exportRows = rows.length
    ? [
        ...rows,
        {
          INCOME: 'Total Income',
          current_year_income: totalIncome,
          EXPENSE: 'Total Expense',
          current_year_expense: totalExpense,
          _total: true,
        },
      ]
    : [];

  return (
    <section>
      <header className="mb-4 print:hidden">
        <h1 className="text-lg font-semibold text-slate-800">Annual income and expenditure</h1>
        <p className="text-sm text-slate-500">
          {loading ? 'Loading…' : `${rows.length} head(s)`}
        </p>
      </header>

      {/* Same filter bar the other reports carry. The dates label the period on
          the printed copy; the figures themselves come from yearwise_income and
          yearwise_expense, which derive the financial year from the current
          date rather than taking one — so changing these does not refetch. */}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          run();
        }}
        className="card mb-4 flex flex-wrap items-end gap-3 p-4 print:hidden"
      >
        <div className="w-44">
          <Field label="From Date">
            <input
              className="field-input"
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
            />
          </Field>
        </div>
        <div className="w-44">
          <Field label="To Date">
            <input
              className="field-input"
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
            />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Show'}
        </button>
      </form>

      <ErrorNotice error={error} onRetry={run} />

      {loading ? (
        <Spinner />
      ) : rows.length === 0 ? (
        <EmptyState title="No income or expenditure recorded" />
      ) : (
        <div className="card overflow-hidden print:border-0 print:shadow-none">
          <ExportToolbar
            columns={columns}
            rows={exportRows}
            exportName="annual-income-expenditure"
            exportTitle="Annual Income and Expenditure"
            emphasiseRow={(r) => (r._total ? 'total' : null)}
            accent={[44, 82, 130]}
            filters={reportFilters}
          />
          <div className="px-4 print:px-0">
            <ReportHeader
              title="Annual Income and Expenditure"
              info={society}
              accent="#2c5282"
              filters={reportFilters}
            />
          </div>
          {/* .gv-container from the legacy page: a bordered "government form"
              grid in navy, rather than the app's borderless list style. Amounts
              are monospaced there so the columns of figures align. */}
          <div className="overflow-x-auto px-4 pb-4 print:px-0 print:pb-0">
            <table className="w-full border-collapse border-2 border-[#2c5282] text-[14px] text-[#333]">
              <thead>
                <tr>
                  {columns.map((c, i) => (
                    <th
                      key={`${c.key}-${i}`}
                      className={`border border-[#2c5282] bg-[#2c5282] px-4 py-3 text-[13px] font-semibold uppercase tracking-wide text-white ${
                        c.align === 'right' ? 'text-right' : 'text-left'
                      }`}
                    >
                      {c.label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={i} className={i % 2 === 1 ? 'bg-[#f9fafb]' : 'bg-white'}>
                    <td className="border border-[#d1d5db] px-4 py-2.5 align-middle">
                      {r.INCOME ?? ''}
                    </td>
                    <td className="border border-[#d1d5db] px-4 py-2.5 text-right font-mono align-middle">
                      {money(r.current_year_income)}
                    </td>
                    <td className="border border-[#d1d5db] px-4 py-2.5 align-middle">
                      {r.EXPENSE ?? ''}
                    </td>
                    <td className="border border-[#d1d5db] px-4 py-2.5 text-right font-mono align-middle">
                      {money(r.current_year_expense)}
                    </td>
                  </tr>
                ))}
                {/* The legacy grid inserted a blank spacer row before the
                    totals, styled borderless — it separates the heads from
                    the summary without a rule. */}
                <tr>
                  <td className="bg-white p-1.5" colSpan={4} />
                </tr>
                <tr className="border-y-2 border-[#2c5282] bg-[#e6f2ff] text-[15px] font-bold text-[#1a365d]">
                  <td className="px-4 py-2.5">Total Income</td>
                  <td className="px-4 py-2.5 text-right font-mono">{money(totalIncome)}</td>
                  <td className="px-4 py-2.5">Total Expense</td>
                  <td className="px-4 py-2.5 text-right font-mono">{money(totalExpense)}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div className="px-4 print:px-0">
            <ReportFooter />
          </div>
        </div>
      )}
    </section>
  );
}
