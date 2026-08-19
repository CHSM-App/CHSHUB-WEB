import { useCallback, useEffect, useState } from 'react';
import { reports } from '@/api/modules';
import DataGrid from '@/components/DataGrid.jsx';
import ReportHeader, { ReportFooter, useSocietyInfo } from '@/components/ReportDocument.jsx';
import { ErrorNotice, Field } from '@/components/ui.jsx';

const money = (v) =>
  v == null || v === ''
    ? '—'
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/**
 * printshop.aspx — "Shop Maintenance Reports" under Reports & Analytics.
 *
 * The legacy page had a payment-method type-ahead, a date box, and Load /
 * Download buttons that both ran the same query into an RDLC ReportViewer
 * (ledger.rdlc). DataGrid carries the equivalent export actions, so the two
 * buttons collapse into one "Load report" and the toolbar's Excel / PDF /
 * Print.
 *
 * Columns and headings are ledger.rdlc's, in its order. One quirk is kept: the
 * report's last two columns are headed "Payment Method" and "Cheque Date" but
 * bound to pay_method and cheq_no — so the cheque number printed under a
 * "Cheque Date" heading, and cheq_date never appeared. Here the heading matches
 * what the column actually holds, and the date is given its own column.
 */
export default function ShopMaintenanceReport() {
  const society = useSocietyInfo();
  const [payMethod, setPayMethod] = useState('');
  const [date, setDate] = useState('');
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const run = useCallback(async (method, on) => {
    setLoading(true);
    setError(null);
    try {
      setData(await reports.shopMaintenance({ payMethod: method || undefined, date: on || undefined }));
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  // Page_Load bound the report empty and filled the method dropdown; the first
  // load here doubles as the "no filters" report the Load button produced.
  useEffect(() => {
    run('', '');
  }, [run]);

  const items = data?.items ?? [];

  const columns = [
    // Kept rather than using DataGrid's built-in serial column (switched off
    // below): the export needs the number too, and this one comes off the row's
    // position in the loaded list rather than the rendered one — ledger.rdlc
    // numbered its rows the same way, off the dataset order.
    {
      key: '_sr',
      label: 'Sr.No',
      render: (_v, r) => items.indexOf(r) + 1,
      exportValue: (_r, i) => i + 1,
      sortable: false,
    },
    { key: 'mrep_no', label: 'Receipt No' },
    { key: 'led_description', label: 'Ledger Details' },
    { key: 'm_date', label: 'Maintenance Date', render: day, exportValue: (r) => day(r.m_date) },
    { key: 'other_details', label: 'Other Details' },
    { key: 'amt', label: 'Amount', render: money, exportValue: (r) => money(r.amt), align: 'right' },
    { key: 'pay_method', label: 'Payment Method' },
    { key: 'cheq_no', label: 'Cheque/UPI No' },
    { key: 'cheq_date', label: 'Cheque Date', render: day, exportValue: (r) => day(r.cheq_date) },
  ];

  const reportFilters = [
    { label: 'Payment Method', value: payMethod || 'All' },
    { label: 'Maintenance Date', value: date ? new Date(date).toLocaleDateString('en-GB') : 'All' },
  ];

  return (
    <section>
      <header className="mb-4 print:mb-2">
        <h1 className="text-lg font-semibold text-slate-800">Shop Maintenance Reports</h1>
        <p className="text-sm text-slate-500">
          {loading ? 'Loading…' : `${data?.count ?? 0} record(s) · total ${money(data?.total)}`}
        </p>
      </header>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          run(payMethod, date);
        }}
        className="card mb-4 flex flex-wrap items-end gap-3 p-4 print:hidden"
      >
        <div className="w-56">
          <Field label="Payment Method">
            {/* filldrop() listed the distinct pay_method values already on the
                society's rows, so the report cannot be filtered to an empty
                result by picking a method nobody used. */}
            <select
              className="field-input"
              value={payMethod}
              onChange={(e) => setPayMethod(e.target.value)}
            >
              <option value="">All</option>
              {(data?.payMethods ?? []).map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))}
            </select>
          </Field>
        </div>
        <div className="w-44">
          <Field label="Maintenance Date">
            <input
              className="field-input"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Load report'}
        </button>
        {/* The legacy "Download Report" button re-ran the same query rather
            than downloading anything; the grid's toolbar does the export. */}
        {payMethod || date ? (
          <button
            type="button"
            className="btn-secondary"
            onClick={() => {
              setPayMethod('');
              setDate('');
              run('', '');
            }}
            disabled={loading}
          >
            Clear
          </button>
        ) : null}
      </form>

      <ErrorNotice error={error} onRetry={() => run(payMethod, date)} />

      {/* Letterhead prints above the grid; on screen the page header and the
          filter form already carry this, so it stays hidden there. */}
      <ReportHeader title="Shop Maintenance Report" info={society} filters={reportFilters} />

      <DataGrid
        columns={columns}
        rows={items}
        idKey="shop_maint_id"
        loading={loading}
        // This screen supplies its own Sr.No above.
        serialColumn={false}
        emptyTitle="No shop maintenance records found"
        emptyHint="Try clearing the payment method or date filter."
        exportName="shop-maintenance-report"
        exportTitle="Shop Maintenance Report"
        filters={reportFilters}
        // Totals the rows the grid is actually showing, so a search inside the
        // grid narrows the total with it.
        footer={(shown) => (
          <tr>
            <td className="table-cell font-medium" colSpan={5}>
              Total
            </td>
            <td className="table-cell text-right font-semibold">
              {money(shown.reduce((s, r) => s + Number(r.amt || 0), 0))}
            </td>
            <td className="table-cell" colSpan={3} />
          </tr>
        )}
      />
    </section>
  );
}
