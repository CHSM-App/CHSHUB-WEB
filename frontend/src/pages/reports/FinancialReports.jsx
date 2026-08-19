import { Fragment } from 'react';
import { extraReports } from '@/api/onboarding';
import DateRangeReport, { money, day } from '../DateRangeReport.jsx';
import { EmptyState } from '@/components/ui.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';

/**
 * The financial reports that replace the RDLC report definitions:
 * Paid_amountreport, agm_report, Profit_loss_report / v_profite_loss,
 * BalanceSheet. Each renders inside DateRangeReport and prints via the browser.
 */

/*
 * `render` is a prop, not a component, so paging state cannot live inside it —
 * the collections grid is its own component so it can hold the hook.
 */
function CollectionsGrid({ d }) {
  const paging = usePaging(d.items.length, 25);
  const pageRows = d.items.slice(paging.first, paging.first + paging.size);

  return (
    <div className="card overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full stacked-table">
          <thead>
            <tr>
              {/* Row number, as every other list carries. */}
              <th className="table-head w-px whitespace-nowrap">No.</th>
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
            {pageRows.map((r, i) => (
              <tr key={paging.first + i}>
                {/* Counts from the row's place in the whole list, so page 2
                    carries on rather than restarting at 1. */}
                <td className="table-cell w-px whitespace-nowrap text-slate-500" data-label="No.">
                  {paging.first + i + 1}
                </td>
                <td className="table-cell font-medium text-slate-800" data-label="Receipt">{r.receipt_no}</td>
                <td className="table-cell" data-label="Date">{day(r.date)}</td>
                <td className="table-cell" data-label="Resident">{r.name}</td>
                <td className="table-cell" data-label="Unit">{r.unit}</td>
                <td className="table-cell" data-label="Bill">{r.Billno || '—'}</td>
                <td className="table-cell" data-label="Mode">{r.pay_mode}</td>
                <td className="table-cell text-right" data-label="Amount">{money(r.paid_amount)}</td>
              </tr>
            ))}
            {/* The total is the period's, not the page's — it stays put. */}
            <tr className="bg-slate-50 font-semibold">
              <td className="table-cell" colSpan={7}>
                Total collected ({d.count} receipts)
              </td>
              <td className="table-cell text-right" data-label="Total">{money(d.total)}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <Pager
        page={paging.page}
        pageCount={paging.pageCount}
        first={paging.first}
        last={paging.last}
        total={d.items.length}
        onPage={paging.setPage}
      />
    </div>
  );
}

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
          <CollectionsGrid d={d} />
        )
      }
    />
  );
}

/*
 * A date-range profit & loss page stood here. The legacy app has no such
 * report — v_profite_loss.aspx ("Annual income and expenditure") compares the
 * previous year against the current one from a different source — so keeping
 * both put two similar-sounding entries in the menu whose figures disagreed.
 *
 * That report is reports/IncomeExpenditureReport.jsx, and /reports/profit-loss
 * now redirects onto it. GET /reports/profit-loss is still served by the API.
 */

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
            <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  <th className="table-head">Charge head</th>
                  <th className="table-head text-right">Total</th>
                </tr>
              </thead>
              <tbody>
                {d.items.map((r, i) => (
                  <tr key={i}>
                    <td className="table-cell font-medium text-slate-800" data-label="Charge head">{r.charges}</td>
                    <td className="table-cell text-right" data-label="Total">{money(r.total)}</td>
                  </tr>
                ))}
                <tr className="bg-slate-50 font-semibold">
                  <td className="table-cell" data-label="Charge head">Total</td>
                  <td className="table-cell text-right" data-label="Total">
                    {money(d.items.reduce((s, r) => s + Number(r.total || 0), 0))}
                  </td>
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
            <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  <th className="table-head">Head / sub-point</th>
                  <th className="table-head text-right">Amount</th>
                </tr>
              </thead>
              <tbody>
                {/*
                  Keyed on the Fragment, not on the <tr> inside it. The key has
                  to sit on the element the map returns, and a shorthand <>
                  cannot carry one — so every head rendered keyless and React
                  re-created the whole group on each load.
                */}
                {d.heads.map((h) => (
                  <Fragment key={`h${h.bal_head_id}`}>
                    <tr className="bg-slate-50">
                      <td className="table-cell font-semibold text-slate-800" data-label="Head / sub-point">{h.bal_header_desc}</td>
                      <td className="table-cell text-right font-semibold" data-label="Amount">{money(h.amount)}</td>
                    </tr>
                    {subsFor(h.bal_head_id).map((s) => (
                      <tr key={`s${s.bal_sub_id}`}>
                        <td className="table-cell pl-8" data-label="Head / sub-point">{s.bal_sub_desc}</td>
                        <td className="table-cell text-right" data-label="Amount">{money(s.amount)}</td>
                      </tr>
                    ))}
                  </Fragment>
                ))}
              </tbody>
            </table>
            </div>
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
