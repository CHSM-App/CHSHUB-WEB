import { useEffect, useState } from 'react';
import * as M from '@/api/modules';
import { EmptyState, ErrorNotice, Spinner } from '@/components/ui.jsx';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/**
 * A read-only table driven by a loader function. Covers the legacy report and
 * listing pages that have no create/edit path.
 */
function DataTable({ title, subtitle, load, columns, emptyHint, extract = (d) => d.items ?? [] }) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    load()
      .then((data) => {
        if (!cancelled) setRows(extract(data) ?? []);
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

  return (
    <section>
      <header className="mb-4">
        <h1 className="text-lg font-semibold text-slate-800">{title}</h1>
        <p className="text-sm text-slate-500">{subtitle ?? `${rows.length} record(s)`}</p>
      </header>

      <ErrorNotice error={error} />

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : rows.length === 0 ? (
          <EmptyState title={`No ${title.toLowerCase()} found`} hint={emptyHint} />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  {columns.map((c) => (
                    <th key={c.key} className="table-head">
                      {c.label}
                    </th>
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
                      >
                        {c.format ? c.format(row[c.key], row) : (row[c.key] ?? '—')}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
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

export const IncomeExpensePage = () => (
  <DataTable
    title="Income & expenditure"
    load={M.reports.incomeExpense}
    columns={[
      { key: 'INCOME', label: 'Income head' },
      { key: 'prev_year_income', label: 'Prev year', format: money },
      { key: 'current_year_income', label: 'Current year', format: money },
      { key: 'EXPENSE', label: 'Expense head' },
      { key: 'prev_year_expense', label: 'Prev year', format: money },
      { key: 'current_year_expense', label: 'Current year', format: money },
    ]}
  />
);

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

export const VillageBalanceSheetPage = () => (
  <DataTable
    title="Balance sheet"
    load={M.village.balanceSheet}
    extract={(d) => d.heads ?? []}
    columns={[
      { key: 'bal_header_desc', label: 'Head' },
      { key: 'amount', label: 'Amount', format: money },
      { key: 'Seq_order', label: 'Order' },
    ]}
  />
);

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

export const VillageHistoryPage = () => (
  <DataTable
    title="House change history"
    load={M.village.houseHistory}
    columns={[
      { key: 'house_no', label: 'House' },
      { key: 'updated_by', label: 'Updated by' },
      { key: 'action_type', label: 'Action' },
      { key: 'modification_date', label: 'When', format: day },
      { key: 'gharpatti_charges', label: 'Property tax', format: money },
      { key: 'water_charges', label: 'Water', format: money },
    ]}
  />
);
