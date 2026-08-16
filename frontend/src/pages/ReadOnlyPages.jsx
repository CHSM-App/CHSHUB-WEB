import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import * as M from '@/api/modules';
import { EmptyState, ErrorNotice, Spinner } from '@/components/ui.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import useSortedRows from '@/components/useSortedRows.js';
import { SortableHead, SortControl } from '@/components/SortableHead.jsx';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/**
 * A read-only table driven by a loader function. Covers the legacy report and
 * listing pages that have no create/edit path.
 */
function DataTable({
  title,
  subtitle,
  load,
  columns,
  emptyHint,
  extract = (d) => d.items ?? [],
  // Screens whose legacy page carried a search box. Narrows the loaded rows in
  // the browser, as those pages' own filterTable() did — these endpoints take
  // no search parameter.
  filterRow,
}) {
  const [allRows, setAllRows] = useState([]);
  const [search, setSearch] = useState('');
  const deferred = useDeferredValue(search);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    load()
      .then((data) => {
        if (!cancelled) setAllRows(extract(data) ?? []);
      })
      .catch((err) => {
        if (!cancelled) setError(err);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
    // `load` is a stable module-level function per page.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    const term = deferred.trim().toLowerCase();
    if (!filterRow || !term) return allRows;
    return allRows.filter((r) => filterRow(r, term));
  }, [allRows, deferred, filterRow]);

  const { sorted: rows, sort, toggleSort } = useSortedRows(filtered, columns);

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        {/* On paper the title heads the sheet, so it centres over the table;
            on screen it stays left, beside the search box. */}
        <div className="print:w-full print:text-center">
          <h1 className="text-lg font-semibold text-slate-800">{title}</h1>
          <p className="text-sm text-slate-500 print:hidden">
            {subtitle ??
              (rows.length === allRows.length
                ? `${allRows.length} record(s)`
                : `${rows.length} of ${allRows.length} record(s)`)}
          </p>
        </div>
        {filterRow ? (
          <input
            className="field-input w-56 print:hidden"
            placeholder="Search…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            aria-label={`Search ${title}`}
          />
        ) : null}
      </header>

      <ErrorNotice error={error} />

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : rows.length === 0 ? (
          <EmptyState title={`No ${title.toLowerCase()} found`} hint={emptyHint} />
        ) : (
          <>
            {/* Export to Excel / Download PDF / Print, as the grids elsewhere
                carry. Outside the scroll box so it stays put on a narrow
                screen. */}
            <ExportToolbar
              columns={columns}
              rows={rows}
              exportName={title.toLowerCase().replace(/\s+/g, '-')}
              exportTitle={title}
            />
            {/* The table's headings are what sort on a wide screen; below `sm`
                the stacked card view hides them, so the same sort is offered
                as a control above the cards. */}
            <SortControl columns={columns} sort={sort} onSort={toggleSort} className="px-4 pb-2" />
            <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {columns.map((c) => (
                    <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row, i) => (
                  <tr key={row.id ?? i} className="hover:bg-slate-50">
                    {columns.map((c, ci) => (
                      <td
                        key={c.key}
                        className={ci === 0 ? 'table-cell font-medium text-slate-800' : 'table-cell'}
                        /* Names the line in the phone card view, from the same
                           column that titles it on a wide screen. */
                        data-label={c.label}
                      >
                        {/* `i` is passed for the legacy grids' serial-number
                            column, which numbered rows off the grid position
                            rather than any field on the row. */}
                        {c.format ? c.format(row[c.key], row, i) : (row[c.key] ?? '—')}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
            </div>
          </>
        )}
      </div>
    </section>
  );
}

/* ------------------------------------------------------------- accounts */

export const VendorBillsPage = () => (
  <DataTable
    title="Vendor bills"
    load={M.vendors.bills}
    columns={[
      { key: 'bill_number', label: 'Bill no.' },
      { key: 'vendor_name', label: 'Vendor' },
      { key: 'bill_date', label: 'Date', format: day },
      { key: 'total_amount', label: 'Total', format: money },
      { key: 'paid_amount', label: 'Paid', format: money },
      { key: 'remaining_amount', label: 'Outstanding', format: money },
      { key: 'payment_status', label: 'Status' },
    ]}
  />
);

export const VendorPaymentsPage = () => (
  <DataTable
    title="Vendor payments"
    load={M.vendors.payments}
    columns={[
      { key: 'payment_no', label: 'Payment no.' },
      { key: 'vendor_name', label: 'Vendor' },
      { key: 'payment_date', label: 'Date', format: day },
      { key: 'paid_amount', label: 'Amount', format: money },
      { key: 'transaction_ref', label: 'Reference' },
      { key: 'bill_status', label: 'Status' },
    ]}
  />
);

export const SocietyReceiptsPage = () => (
  <DataTable
    title="Society receipts"
    load={M.accounts.societyReceipts}
    columns={[
      { key: 'receipt_id', label: 'Receipt' },
      { key: 'date', label: 'Date', format: day },
      { key: 'bill_no', label: 'Bill no.' },
      { key: 'total_amount', label: 'Total', format: money },
      { key: 'paid_amount', label: 'Paid', format: money },
      { key: 'paymode', label: 'Pay mode' },
    ]}
  />
);

export const InventoryPage = () => (
  <DataTable
    title="Inventory"
    load={M.lookups.inventory}
    columns={[
      { key: 'item_name', label: 'Item' },
      { key: 'quantity', label: 'Qty' },
      { key: 'unit', label: 'Unit' },
      { key: 'vendor_name', label: 'Vendor' },
      { key: 'purchase_date', label: 'Purchased', format: day },
      { key: 'total_amount', label: 'Value', format: money },
      { key: 'warranty_last_date', label: 'Warranty until', format: day },
    ]}
  />
);

export const ParkingAllotmentPage = () => (
  <DataTable
    title="Parking allotment"
    load={M.lookups.parkingAllotment}
    columns={[
      { key: 'parking_no', label: 'Parking' },
      { key: 'name', label: 'Resident' },
      { key: 'vehicle_no', label: 'Vehicle' },
      { key: 'model_name', label: 'Model' },
      { key: 'park_for', label: 'Type' },
      { key: 'pre_mob', label: 'Contact' },
    ]}
  />
);

export const CommitteePage = () => (
  <DataTable
    title="Committee members"
    load={M.lookups.members}
    columns={[
      { key: 'name', label: 'Name' },
      { key: 'UserTypeName', label: 'Role' },
      { key: 'username', label: 'Username' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'email', label: 'Email' },
    ]}
  />
);

/* ------------------------------------------------------------ community */

export const FacilityBookingsPage = () => (
  <DataTable
    title="Facility bookings"
    load={M.community.facilityBookings}
    columns={[
      { key: 'facility_name', label: 'Facility' },
      { key: 'name', label: 'Booked by' },
      { key: 'Unit', label: 'Unit' },
      { key: 'from_date', label: 'From', format: day },
      { key: 'to_date', label: 'To', format: day },
      { key: 'amount', label: 'Amount', format: money },
    ]}
  />
);

export const VisitorsPage = () => (
  <DataTable
    title="Visitors"
    load={M.community.visitors}
    columns={[
      { key: 'v_name', label: 'Visitor' },
      { key: 'type', label: 'Type' },
      { key: 'unit', label: 'Unit' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'in_date', label: 'In' },
      { key: 'in_time', label: 'Time' },
      { key: 'purpose', label: 'Purpose' },
    ]}
    emptyHint="Visitors from the last 30 days appear here."
  />
);

export const HelpdeskPage = () => (
  <DataTable
    title="Helpdesk tickets"
    load={M.community.helpdesk}
    columns={[
      { key: 'helpdesk_id', label: 'Ticket' },
      { key: 'query', label: 'Query' },
      { key: 'p_type_name', label: 'Category' },
      { key: 'name', label: 'Raised by' },
      { key: 'flat_no', label: 'Flat' },
      { key: 'date', label: 'Date' },
    ]}
  />
);

export const PollsPage = () => (
  <DataTable
    title="Polls"
    load={M.community.polls}
    columns={[
      { key: 'Topic', label: 'Topic' },
      { key: 'Description', label: 'Description' },
      { key: 'ExpiryDate', label: 'Expires', format: day },
      { key: 'total_votes', label: 'Votes' },
    ]}
  />
);

/* -------------------------------------------------------------- reports */

export const ActivityPage = () => (
  <DataTable
    title="Recent activity"
    load={M.reports.activity}
    columns={[
      { key: 'particular', label: 'Activity' },
      { key: 'type', label: 'Type' },
      { key: 'timestamp', label: 'When' },
      { key: 'paid_amount', label: 'Amount', format: money },
    ]}
  />
);

/*
 * Income & expenditure lives in reports/IncomeExpenditureReport.jsx. It was
 * here as a plain DataTable, which showed the same SP rows but without the
 * totals row the legacy grid appended, or a print and PDF layout.
 */

export const AuditPage = () => (
  <DataTable
    title="Audit questions"
    load={M.reports.auditQuestions}
    columns={[
      { key: 'question_desc', label: 'Question' },
      { key: 'answer_desc', label: 'Answer' },
    ]}
  />
);

/* -------------------------------------------------------------- village */

export const VillageOwnersPage = () => (
  <DataTable
    title="Village residents"
    load={M.village.owners}
    columns={[
      { key: 'name', label: 'Owner' },
      { key: 'house_no', label: 'House no.' },
      { key: 'house_type', label: 'Type' },
      { key: 'address', label: 'Address' },
      { key: 'pre_mob', label: 'Contact' },
    ]}
  />
);

export const VillageHouseTaxPage = () => (
  <DataTable
    title="House tax"
    load={M.village.houseTax}
    columns={[
      { key: 'house_no', label: 'House no.' },
      { key: 'owner_name', label: 'Owner' },
      { key: 'house_tax_amount', label: 'Amount', format: money },
      { key: 'due', label: 'Due', format: money },
      { key: 'from_date', label: 'From', format: day },
      { key: 'to_date', label: 'To', format: day },
    ]}
    emptyHint="Generated house-tax bills appear here."
  />
);

export const VillageWaterTaxPage = () => (
  <DataTable
    title="Water tax"
    load={M.village.waterTax}
    columns={[
      { key: 'house_no', label: 'House no.' },
      { key: 'owner_name', label: 'Owner' },
      { key: 'connection_type', label: 'Connection' },
      { key: 'water_tax_amount', label: 'Amount', format: money },
      { key: 'due', label: 'Due', format: money },
    ]}
  />
);

export const VillageRatesPage = () => (
  <DataTable
    title="Square-foot rates"
    load={M.village.rates}
    columns={[
      { key: 'house_type', label: 'House type' },
      { key: 'rate', label: 'Rate', format: money },
      { key: 'applied_date', label: 'Applied', format: day },
    ]}
  />
);

/*
 * The village balance sheet has been removed. It listed accounting heads and
 * their amounts — of no use to a panchayat clerk, who needs to know what was
 * billed, what came in, and who owes. /village/reports answers those from the
 * bills themselves.
 *
 * The society balance sheet is unaffected; it is a different page against
 * different data.
 */

export const VillageHouseTaxReceiptsPage = () => (
  <DataTable
    title="House tax receipts"
    load={M.village.houseTaxReceipts}
    columns={[
      { key: 'receipt_no', label: 'Receipt' },
      { key: 'name', label: 'Owner' },
      { key: 'house_no', label: 'House' },
      { key: 'payment_type_name', label: 'Type' },
      { key: 'Amount_paid', label: 'Amount', format: money },
      { key: 'pay_date', label: 'Date', format: day },
    ]}
  />
);

/* -------------------------------------------------- village extra pages */

export const VillagePaymentsPage = () => (
  <DataTable
    title="Village payments"
    load={M.village.houseTaxPending}
    columns={[
      { key: 'owner_name', label: 'Owner' },
      { key: 'house_no', label: 'House' },
      { key: 'pending_property_tax', label: 'Property tax', format: money },
      { key: 'pending_water_charges', label: 'Water', format: money },
      { key: 'pending_waste_charges', label: 'Waste', format: money },
      { key: 'pre_mob', label: 'Contact' },
    ]}
    emptyHint="Outstanding village charges appear here."
  />
);

/*
 * v_history_table.aspx — the house$ARC audit rows behind sp_house's
 * 'house_history'. Its grid's own columns and their headings, in its order:
 * a serial number, then house, who changed it, when, and the figures as they
 * stood after the change.
 *
 * One correction to the legacy markup, which its own SELECT contradicts: Waste
 * Charges bound Eval("water_charges"), a copy-paste that printed the water
 * figure twice. The SP also selects action_type, which that grid did not show
 * and neither does this.
 */
export const VillageHistoryPage = () => (
  <DataTable
    title="History"
    load={M.village.houseHistory}
    // The legacy page's own search box, which hid grid rows in the browser —
    // sp_house's 'house_history' takes no search parameter.
    filterRow={(r, term) =>
      [r.house_no, r.updated_by, r.modification_date ? day(r.modification_date) : '']
        .join(' ')
        .toLowerCase()
        .includes(term)
    }
    columns={[
      // No backing field — the number is the row's position, so the exports
      // need it spelled out as well as the cell.
      { key: 'no', label: 'No', format: (_v, _r, i) => i + 1, exportValue: (_r, i) => i + 1 },
      { key: 'house_no', label: 'House No' },
      { key: 'updated_by', label: 'Updated By' },
      { key: 'modification_date', label: 'Modification Date', format: day },
      { key: 'area', label: 'Area' },
      { key: 'gharpatti_charges', label: 'Property Tax', format: money },
      { key: 'no_of_tab', label: 'No. of Taps' },
      { key: 'water_charges', label: 'Water Charges', format: money },
      { key: 'waste_charges', label: 'Waste Charges', format: money },
    ]}
    emptyHint="Edits to house records appear here."
  />
);
