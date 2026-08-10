import { extraReports } from '@/api/onboarding';
import DateRangeReport, { money, day } from '../DateRangeReport.jsx';
import { EmptyState } from '@/components/ui.jsx';

/**
 * The financial reports that replace the RDLC report definitions:
 * Paid_amountreport, agm_report, Profit_loss_report / v_profite_loss,
 * BalanceSheet. Each renders inside DateRangeReport and prints via the browser.
 */

export function PaidAmountsPage() {
  return (
    <DateRangeReport
      title="Collections"
      subtitle="Receipts recorded in the selected period"
      load={extraReports.paidAmounts}
      render={(d) =>
        d.items.length === 0 ? (
          <EmptyState title="No receipts in this period" />
        ) : (
          <div className="card overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full">
                <thead>
                  <tr>
                    <th className="table-head">Receipt</th>
                    <th className="table-head">Date</th>
                    <th className="table-head">Resident</th>
                    <th className="table-head">Unit</th>
                    <th className="table-head">Bill</th>
                    <th className="table-head">Mode</th>
                    <th className="table-head text-right">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {d.items.map((r, i) => (
                    <tr key={i}>
                      <td className="table-cell font-medium text-slate-800">{r.receipt_no}</td>
                      <td className="table-cell">{day(r.date)}</td>
                      <td className="table-cell">{r.name}</td>
                      <td className="table-cell">{r.unit}</td>
                      <td className="table-cell">{r.Billno || '—'}</td>
                      <td className="table-cell">{r.pay_mode}</td>
                      <td className="table-cell text-right">{money(r.paid_amount)}</td>
                    </tr>
                  ))}
                  <tr className="bg-slate-50 font-semibold">
                    <td className="table-cell" colSpan={6}>
                      Total collected ({d.count} receipts)
                    </td>
                    <td className="table-cell text-right">{money(d.total)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        )
      }
    />
  );
}

export function ProfitLossPage() {
  return (
    <DateRangeReport
      title="Profit &amp; loss"
      subtitle="Income against expenditure for the period"
      load={extraReports.profitLoss}
      render={(d) => (
        <div className="grid gap-4 lg:grid-cols-2">
          {[
            { label: 'Income', rows: d.income, total: d.totalIncome },
            { label: 'Expenditure', rows: d.expense, total: d.totalExpense },
          ].map((side) => (
            <div key={side.label} className="card overflow-hidden">
              <h2 className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">
                {side.label}
              </h2>
              {side.rows.length === 0 ? (
                <p className="px-4 py-6 text-sm text-slate-500">Nothing recorded.</p>
              ) : (
                <table className="min-w-full">
                  <tbody>
                    {side.rows.map((r, i) => (
                      <tr key={i}>
                        <td className="table-cell">{r.description}</td>
                        <td className="table-cell text-right">{money(r.amount)}</td>
                      </tr>
                    ))}
                    <tr className="bg-slate-50 font-semibold">
                      <td className="table-cell">Total {side.label.toLowerCase()}</td>
                      <td className="table-cell text-right">{money(side.total)}</td>
                    </tr>
                  </tbody>
                </table>
              )}
            </div>
          ))}

          <div className="card p-5 lg:col-span-2">
            <p className="text-xs uppercase tracking-wide text-slate-500">
              {d.surplus >= 0 ? 'Surplus' : 'Deficit'}
            </p>
            <p
              className={`mt-1 text-2xl font-semibold ${d.surplus >= 0 ? 'text-green-700' : 'text-red-700'}`}
            >
              {money(Math.abs(d.surplus))}
            </p>
          </div>
        </div>
      )}
    />
  );
}

export function AgmReportPage() {
  return (
    <DateRangeReport
      title="AGM report"
      subtitle="Charge heads collected in the period"
      load={extraReports.agm}
      render={(d) =>
        d.items.length === 0 ? (
          <EmptyState title="No AGM data for this period" />
        ) : (
          <div className="card overflow-hidden">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Charge head</th>
                  <th className="table-head text-right">Total</th>
                </tr>
              </thead>
              <tbody>
                {d.items.map((r, i) => (
                  <tr key={i}>
                    <td className="table-cell font-medium text-slate-800">{r.charges}</td>
                    <td className="table-cell text-right">{money(r.total)}</td>
                  </tr>
                ))}
                <tr className="bg-slate-50 font-semibold">
                  <td className="table-cell">Total</td>
                  <td className="table-cell text-right">
                    {money(d.items.reduce((s, r) => s + Number(r.total || 0), 0))}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        )
      }
    />
  );
}

/** Balance sheet — heads with their sub-points. Not date-ranged. */
export function BalanceSheetPage() {
  return (
    <DateRangeReport
      title="Balance sheet"
      load={() => extraReports.balanceSheet()}
      printable
      render={(d) => {
        const subsFor = (headId) =>
          (d.subPoints ?? []).filter((s) => Number(s.bal_head_id) === Number(headId));
        if (!d.heads?.length) return <EmptyState title="No balance-sheet heads configured" />;
        return (
          <div className="card overflow-hidden">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Head / sub-point</th>
                  <th className="table-head text-right">Amount</th>
                </tr>
              </thead>
              <tbody>
                {d.heads.map((h) => (
                  <>
                    <tr key={`h${h.bal_head_id}`} className="bg-slate-50">
                      <td className="table-cell font-semibold text-slate-800">{h.bal_header_desc}</td>
                      <td className="table-cell text-right font-semibold">{money(h.amount)}</td>
                    </tr>
                    {subsFor(h.bal_head_id).map((s) => (
                      <tr key={`s${s.bal_sub_id}`}>
                        <td className="table-cell pl-8">{s.bal_sub_desc}</td>
                        <td className="table-cell text-right">{money(s.amount)}</td>
                      </tr>
                    ))}
                  </>
                ))}
              </tbody>
            </table>
          </div>
        );
      }}
    />
  );
}

/*
 * The owner ledger lives in OwnerwiseMaintenanceReport.jsx. It used to be here,
 * reading its owner from a ?ownerId= query parameter with no way to pick one in
 * the page and no building filter — which the SP needs to return any
 * transactions at all.
 */
