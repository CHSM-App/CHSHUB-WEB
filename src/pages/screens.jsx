import { useState } from 'react';
import GenericCrudPage from './GenericCrudPage.jsx';
import ExcelImport from './settings/ExcelImport.jsx';
import { StoredFileModal } from './masters/MasterPages.jsx';
import { Modal } from '@/components/ui.jsx';
import * as M from '@/api/modules';

// Declarative screen definitions. Each entry describes a legacy ASPX page as
// columns + form fields; GenericCrudPage renders it. Screens with bespoke
// behaviour (bills, receipts, helpdesk, dashboards) have their own components.

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');
// The legacy grids that formatted a date as {0:dd-MMM-yyyy}, e.g. 09-Aug-2026.
const dmy = (v) =>
  v
    ? new Date(v)
        .toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
        .replace(/ /g, '-')
    : '—';
const yesNo = (v) => (v ? 'Yes' : 'No');

/**
 * The hour and minute out of a stored time.
 *
 * These columns are DATETIME, so the value arrives as a full timestamp on
 * 1900-01-01. Only the clock part means anything, and it is read off the ISO
 * string rather than a local Date so the browser's timezone cannot shift it.
 */
function timeParts(v) {
  if (!v) return null;
  const s = String(v);
  const m = /(?:T|\s)(\d{2}):(\d{2})/.exec(s) ?? /^(\d{1,2}):(\d{2})/.exec(s);
  return m ? { h: Number(m[1]), min: m[2] } : null;
}

/** "2:30 pm" for display. */
const clockTime = (v) => {
  const t = timeParts(v);
  if (!t) return '—';
  const suffix = t.h < 12 ? 'am' : 'pm';
  const hour12 = t.h % 12 === 0 ? 12 : t.h % 12;
  return `${hour12}:${t.min} ${suffix}`;
};

/** "14:30" — what <input type="time"> expects. */
const inputTime = (v) => {
  const t = timeParts(v);
  return t ? `${String(t.h).padStart(2, '0')}:${t.min}` : '';
};

/**
 * Text out of a value that may carry HTML.
 *
 * The legacy meeting editor was TinyMCE, so rows saved through it hold markup.
 * Parsed rather than regex-stripped so entities decode and nothing injectable
 * survives — the result is only ever rendered as text.
 */
const plainText = (v) => {
  const s = String(v ?? '').trim();
  if (!s) return '';
  if (!/<[a-z!/]/i.test(s)) return s;
  const doc = new DOMParser().parseFromString(s, 'text/html');
  return (doc.body.textContent ?? '').replace(/\s+/g, ' ').trim();
};

const toDateInput = (v) => (v ? String(v).slice(0, 10) : '');

// ddl_noc on loan.aspx. The value is stored verbatim in noc_issued, so the
// wording has to match; its "select" placeholder is left out because
// SelectField supplies one of its own.
const NOC_ISSUERS = [
  { id: 'Society', name: 'Society' },
  { id: 'Builder', name: 'Builder' },
];

// The three ddl_method entries the legacy accounting pages offered. The values
// are stored verbatim in pay_method, so the wording has to match exactly.
const PAY_METHODS = [
  { id: 'Cash', name: 'Cash' },
  { id: 'UPI Payment', name: 'UPI Payment' },
  { id: 'Cheque No', name: 'Cheque No' },
];

/* -------------------------------------------------------------- masters */

/**
 * NOT ROUTED — `/masters/staff` renders `MasterPages.StaffMasterPage`, which is
 * the maintained version (it already carries the photo and ID-proof uploads).
 * Left in place rather than deleted because several screens here are in the
 * same position; see docs/PAGE-AUDIT.md.
 */
export const StaffPage = () => (
  <GenericCrudPage
    title="Staff"
    resource={M.staff}
    idKey="staff_id"
    columns={[
      { key: 'name', label: 'Name' },
      { key: 'role', label: 'Role' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'email', label: 'Email' },
      { key: 'date_of_join', label: 'Joined', format: day },
      { key: 'salary', label: 'Salary', format: money },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'address', label: 'Address' },
      { name: 'dateOfJoin', label: 'Date of joining', type: 'date' },
      { name: 'salary', label: 'Salary', type: 'number' },
      { name: 'roleId', label: 'Role', type: 'select', lookup: 'roles', optionValue: 'role_id', optionLabel: 'role' },
    ]}
    lookups={{ roles: M.lookups.staffRoles }}
    toForm={(r) => ({
      name: r.name ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      address: r.address ?? '',
      dateOfJoin: r.date_of_join ? String(r.date_of_join).slice(0, 10) : '',
      salary: r.salary ?? '',
      roleId: r.role_id ?? '',
    })}
  />
);

export const CaretakersPage = () => (
  <GenericCrudPage
    title="Caretakers"
    resource={M.caretakers}
    idKey="caretaker_id"
    columns={[
      { key: 'c_name', label: 'Name' },
      { key: 'mobile_no', label: 'Mobile' },
      { key: 'c_address', label: 'Address' },
      { key: 'city', label: 'City' },
      { key: 'flat_no', label: 'Flat' },
    ]}
    // Order follows caretaker.aspx: flat > name > address > area > mobile >
    // email > city > pincode > doc executed.
    fields={[
      { name: 'flatNo', label: 'Flat number' },
      { name: 'name', label: 'Name', required: true },
      { name: 'address', label: 'Address' },
      { name: 'area', label: 'Area' },
      { name: 'mobile', label: 'Mobile' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'city', label: 'City' },
      { name: 'pincode', label: 'Pincode' },
      { name: 'docExecuted', label: 'Document executed' },
    ]}
    toForm={(r) => ({
      flatNo: r.flat_no ?? '',
      name: r.c_name ?? '',
      address: r.c_address ?? '',
      area: r.area ?? '',
      mobile: r.mobile_no ?? '',
      email: r.email ?? '',
      city: r.city ?? '',
      pincode: r.pincode ?? '',
      docExecuted: r.doc_executed ?? '',
    })}
  />
);

export const HelpersPage = () => (
  <GenericCrudPage
    title="Helpers"
    resource={M.helpers}
    idKey="servent_id"
    columns={[
      { key: 's_name', label: 'Name' },
      { key: 'mobile_no1', label: 'Mobile' },
      { key: 's_address_1', label: 'Address' },
      { key: 'remark', label: 'Remark' },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'mobile1', label: 'Mobile' },
      { name: 'mobile2', label: 'Alternate mobile' },
      { name: 'address1', label: 'Address line 1' },
      { name: 'address2', label: 'Address line 2' },
      { name: 'remark', label: 'Remark', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.s_name ?? '',
      mobile1: r.mobile_no1 ?? '',
      mobile2: r.mobile_no2 ?? '',
      address1: r.s_address_1 ?? '',
      address2: r.s_address_2 ?? '',
      remark: r.remark ?? '',
    })}
  />
);

export const ContactsPage = () => (
  <GenericCrudPage
    title="Useful contacts"
    resource={M.contacts}
    idKey="usefull_contact_id"
    columns={[
      { key: 'p_name', label: 'Name' },
      { key: 'p_type_name', label: 'Type' },
      { key: 'org_name', label: 'Organisation' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'contact_address', label: 'Address' },
    ]}
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'typeId', label: 'Type', type: 'select', lookup: 'types', optionValue: 'p_type_id', optionLabel: 'p_type_name' },
      { name: 'orgName', label: 'Organisation' },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'address', label: 'Address line 1' },
      { name: 'address2', label: 'Address line 2' },
      { name: 'remark', label: 'Remark', span: 2 },
    ]}
    lookups={{ types: M.lookups.contactTypes }}
    toForm={(r) => ({
      name: r.p_name ?? '',
      typeId: r.p_type ?? '',
      orgName: r.org_name ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      address: r.contact_address ?? '',
      address2: r.address2 ?? '',
      remark: r.remark ?? '',
    })}
  />
);

export const DocTypesPage = () => (
  <GenericCrudPage
    title="Document types"
    resource={M.docTypes}
    idKey="doc_id"
    columns={[{ key: 'doc_name', label: 'Document type' }]}
    fields={[{ name: 'name', label: 'Document type', required: true, span: 2 }]}
    toForm={(r) => ({ name: r.doc_name ?? '' })}
  />
);

/**
 * Parking places. park_place_search.aspx carried an "import data" button whose
 * handler is live (OLEDB over the uploaded workbook), so it is reproduced here
 * through the shared ExcelImport modal.
 */
export const ParkingPlacesPage = () => {
  const [importing, setImporting] = useState(false);
  return (
  <GenericCrudPage
    title="Parking places"
    resource={M.parkingPlaces}
    idKey="place_id"
    headerActions={
      <button type="button" className="btn-primary" onClick={() => setImporting(true)}>
        Import Data
      </button>
    }
    columns={[
      { key: 'parking_no', label: 'Parking number' },
      { key: 'park_for', label: 'For' },
    ]}
    fields={[
      { name: 'parkingNo', label: 'Parking number', required: true },
      {
        name: 'parkFor',
        label: 'Vehicle type',
        type: 'select',
        options: [
          { id: '0', name: 'Bike' },
          { id: '1', name: 'Car' },
        ],
      },
    ]}
    toForm={(r) => ({ parkingNo: r.parking_no ?? '', parkFor: r.park_for === 'Car' ? '1' : '0' })}
  >
    <Modal open={importing} title="Import Data" onClose={() => setImporting(false)}>
      <ExcelImport defaultType="parking" onDone={() => setImporting(false)} />
    </Modal>
  </GenericCrudPage>
  );
};

export const CarPoolingPage = () => (
  <GenericCrudPage
    title="Car pooling"
    resource={M.carPooling}
    idKey="car_id"
    columns={[
      { key: 'c_name', label: 'Name' },
      { key: 'vehical_no', label: 'Vehicle' },
      { key: 'destination', label: 'Destination' },
      { key: 'seat', label: 'Seats' },
      { key: 'date', label: 'Date', format: day },
      { key: 'charges', label: 'Charges' },
    ]}
    // Order follows car_polling.aspx: name > vehicle > seat > time > date >
    // destination > charges.
    fields={[
      { name: 'name', label: 'Name', required: true },
      { name: 'vehicleNo', label: 'Vehicle number' },
      { name: 'seats', label: 'Seats' },
      { name: 'time', label: 'Time', type: 'time' },
      { name: 'date', label: 'Date', type: 'date' },
      { name: 'destination', label: 'Destination' },
      { name: 'charges', label: 'Charges' },
    ]}
    toForm={(r) => ({
      name: r.c_name ?? '',
      vehicleNo: r.vehical_no ?? '',
      seats: r.seat ?? '',
      // time comes back as a full datetime; the input wants HH:MM.
      time: r.time ? String(r.time).slice(11, 16) : '',
      date: r.date ? String(r.date).slice(0, 10) : '',
      destination: r.destination ?? '',
      charges: r.charges ?? '',
    })}
  />
);

export const LoansPage = () => (
  <GenericCrudPage
    title="Loan & lien"
    resource={M.loans}
    idKey="loan_id"
    // loan.aspx's grid was bank and clearance date; flat and loan type are
    // added because a bank name alone does not identify the row.
    columns={[
      { key: 'flat_no', label: 'Flat' },
      { key: 'bank', label: 'Bank' },
      { key: 'loan_type', label: 'Loan type' },
      { key: 'noc_issued', label: 'First NOC by' },
      { key: 'society_noc', label: 'Society NOC', format: day },
      { key: 'loan_clearance', label: 'Loan clearance', format: day },
    ]}
    lookups={{
      flats: () => M.loanLookups().then((d) => d.flats),
      loanTypes: () => M.loanLookups().then((d) => d.loanTypes),
      certificates: () => M.loanLookups().then((d) => d.certificates),
    }}
    // Field order follows loan.aspx's modal.
    fields={[
      // The legacy page used a type-ahead over flat_master and stored flat_id.
      // A select carries the same value without the free-text box that let an
      // unknown id through.
      {
        name: 'flatId',
        label: 'Flat number',
        type: 'select',
        required: true,
        lookup: 'flats',
        optionValue: 'flat_id',
        optionLabel: 'flat_no',
      },
      { name: 'bank', label: 'Name of the bank', required: true },
      {
        name: 'typeId',
        label: 'Type of loan',
        type: 'select',
        required: true,
        lookup: 'loanTypes',
        optionValue: 'type_id',
        optionLabel: 'loan_type',
      },
      {
        name: 'nocIssued',
        label: 'First NOC issued by',
        type: 'select',
        required: true,
        options: NOC_ISSUERS,
      },
      { name: 'societyNocDate', label: 'Society NOC date', type: 'date', required: true },
      { name: 'loanClearanceDate', label: 'Date of loan clearance', type: 'date' },
      {
        name: 'certificateId',
        label: 'Share certificate with',
        type: 'select',
        required: true,
        lookup: 'certificates',
        optionValue: 'cert_id',
        optionLabel: 'c_name',
      },
    ]}
    deleteMessage={(r) => `Delete the ${r.bank} loan on flat ${r.flat_no ?? r.flat_id}?`}
    toForm={(r) => ({
      flatId: r.flat_id ?? '',
      bank: r.bank ?? '',
      // typeId and certificateId were absent from the form, so editing a loan
      // sent 0 for both — losing the loan type and who holds the certificate.
      typeId: r.type_id ?? '',
      nocIssued: r.noc_issued ?? '',
      societyNocDate: toDateInput(r.society_noc),
      loanClearanceDate: toDateInput(r.loan_clearance),
      certificateId: r.cert_id ?? '',
    })}
  />
);

/* ------------------------------------------------------------- accounts */

export const ExpensesPage = () => (
  <GenericCrudPage
    title="Expenses"
    resource={M.expenses}
    idKey="expense_id"
    columns={[
      { key: 'invoice_no', label: 'Invoice' },
      { key: 'date', label: 'Date', format: day },
      { key: 'ex_name', label: 'Expense' },
      { key: 'ex_details', label: 'Details' },
      { key: 'f_amount', label: 'Amount', format: money },
      { key: 'expense_status', label: 'Status' },
    ]}
    fields={[
      { name: 'name', label: 'Expense name', required: true },
      { name: 'date', label: 'Date', type: 'date' },
      { name: 'amount', label: 'Amount', type: 'number', required: true },
      { name: 'tax', label: 'Tax', type: 'number' },
      { name: 'tds', label: 'TDS', type: 'number' },
      { name: 'finalAmount', label: 'Final amount', type: 'number', required: true },
      { name: 'details', label: 'Details', type: 'textarea', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.ex_name ?? '',
      date: r.date ? String(r.date).slice(0, 10) : '',
      amount: r.amount ?? '',
      tax: r.tax ?? '',
      tds: r.tds ?? '',
      finalAmount: r.f_amount ?? '',
      details: r.ex_details ?? '',
    })}
  />
);

export const LedgerPage = () => (
  <GenericCrudPage
    title="Ledger"
    resource={M.ledger}
    idKey="led_id"
    columns={[
      { key: 'led_description', label: 'Description' },
      { key: 'led_status', label: 'Status' },
      { key: 'date', label: 'Date', format: day },
    ]}
    fields={[
      { name: 'description', label: 'Description', required: true, span: 2 },
      { name: 'status', label: 'Status' },
    ]}
    toForm={(r) => ({ description: r.led_description ?? '', status: r.led_status ?? '' })}
  />
);

/**
 * shop_maintenance.aspx's Print button, which redirected to printshop.aspx —
 * discarding whatever was typed in the modal. That report now lives at
 * /reports/shop-maintenance; this button prints the entry in front of you as a
 * receipt, which is what the redirect appeared to promise.
 *
 * Disabled until the entry has the fields a receipt needs; printing a blank
 * form is what the legacy page did and it was never useful.
 */
function PrintReceiptButton({ form, lookups }) {
  const ready = Boolean(form?.reportNo && form?.amount);

  const print = () => {
    // The form holds led_id; the receipt has to name the ledger, so it is
    // resolved against the same list the dropdown was filled from.
    const ledger = (lookups?.ledgers ?? []).find(
      (l) => String(l.led_id) === String(form.ledgerId),
    );

    const rows = [
      ['Receipt no.', form.reportNo],
      ['Date', form.date ? new Date(form.date).toLocaleDateString() : '—'],
      ['Ledger', ledger?.led_description || '—'],
      ['Ledger details', form.details || '—'],
      ['Payment method', form.payMethod || '—'],
      form.payMethod === 'Cheque No' && ['Cheque/draft no.', form.chequeNo || '—'],
      form.payMethod === 'Cheque No' && [
        'Cheque date',
        form.chequeDate ? new Date(form.chequeDate).toLocaleDateString() : '—',
      ],
      form.payMethod === 'UPI Payment' && ['UPI reference', form.upiRef || '—'],
      ['Amount', money(form.amount)],
    ].filter(Boolean);

    // Escaped because every value here is user-entered.
    const esc = (v) =>
      String(v ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

    const win = window.open('', '_blank', 'width=720,height=800');
    if (!win) {
      window.alert('The print window was blocked. Allow pop-ups for this site and try again.');
      return;
    }
    win.document.write(`<!doctype html><html><head><title>Receipt ${esc(form.reportNo)}</title>
<style>
  body { font-family: system-ui, sans-serif; color: #1a1a1a; padding: 32px; }
  h1 { color: #012970; font-size: 20px; margin: 0 0 24px; }
  table { border-collapse: collapse; width: 100%; max-width: 520px; }
  th, td { border: 1px solid #e3e6f0; padding: 8px 12px; text-align: left; font-size: 14px; }
  th { background: #f8f9fa; width: 40%; font-weight: 600; }
</style></head><body>
<h1>Shop Maintenance Receipt</h1>
<table>${rows.map(([k, v]) => `<tr><th>${esc(k)}</th><td>${esc(v)}</td></tr>`).join('')}</table>
</body></html>`);
    win.document.close();
    win.focus();
    win.print();
  };

  return (
    <button type="button" className="btn-secondary" onClick={print} disabled={!ready}>
      Print
    </button>
  );
}

export const ShopMaintenancePage = () => (
  <GenericCrudPage
    title="Shop maintenance"
    resource={M.shopMaintenance}
    idKey="shop_maint_id"
    columns={[
      { key: 'mrep_no', label: 'Report no.' },
      { key: 'm_date', label: 'Date', format: day },
      { key: 'led_description', label: 'Ledger' },
      { key: 'amt', label: 'Amount', format: money },
      { key: 'pay_method', label: 'Pay method' },
    ]}
    // Field order and wording follow shop_maintenance.aspx's modal.
    lookups={{ ledgers: () => M.ledger.list() }}
    fields={[
      { name: 'reportNo', label: 'Receipt no.', required: true },
      { name: 'date', label: 'Date', type: 'date', required: true },
      // The legacy page used a type-ahead over the ledger list, which stored
      // led_id — a select carries the same value without the free-text box
      // that let an unknown id through.
      {
        name: 'ledgerId',
        label: 'Ledger',
        type: 'select',
        required: true,
        lookup: 'ledgers',
        optionValue: 'led_id',
        optionLabel: 'led_description',
      },
      {
        name: 'payMethod',
        label: 'Payment method',
        type: 'select',
        required: true,
        options: PAY_METHODS,
      },
      // paystatus_check() swapped these two panels in as the method changed:
      // cheque number and date for "Cheque No", the UPI reference for
      // "UPI Payment", neither for cash.
      {
        name: 'chequeNo',
        label: 'Cheque/draft no.',
        required: true,
        showIf: (f) => f.payMethod === 'Cheque No',
      },
      {
        name: 'chequeDate',
        label: 'Cheque date',
        type: 'date',
        required: true,
        showIf: (f) => f.payMethod === 'Cheque No',
      },
      {
        name: 'upiRef',
        label: 'UPI reference',
        required: true,
        span: 2,
        showIf: (f) => f.payMethod === 'UPI Payment',
      },
      { name: 'details', label: 'Ledger details', required: true, span: 2 },
      { name: 'amount', label: 'Amount', type: 'number', required: true },
    ]}
    // Legacy delete wrote to shop_vw and always failed, so it was left off.
    // FIX_shop_maintenance.sql soft-deletes the base row instead.
    deleteMessage={(r) => `Delete receipt ${r.mrep_no}? It will no longer appear in the list.`}
    toForm={(r) => ({
      reportNo: r.mrep_no ?? '',
      date: r.m_date ? String(r.m_date).slice(0, 10) : '',
      ledgerId: r.led_id ?? '',
      amount: r.amt ?? '',
      payMethod: r.pay_method ?? '',
      details: r.other_details ?? '',
      // Both methods write cheq_no; which field it belongs in depends on the
      // method the row was saved with.
      chequeNo: r.pay_method === 'Cheque No' ? (r.cheq_no ?? '') : '',
      upiRef: r.pay_method === 'UPI Payment' ? (r.cheq_no ?? '') : '',
      chequeDate: r.cheq_date ? String(r.cheq_date).slice(0, 10) : '',
    })}
    // runproc_save() put the UPI reference in cheq_no too, so the API's single
    // chequeNo parameter carries whichever one the method calls for.
    toBody={(form) => ({
      ...form,
      chequeNo: form.payMethod === 'UPI Payment' ? form.upiRef : form.chequeNo,
    })}
    // shop_maintenance.aspx put a Print button beside Save.
    formActions={(form, { lookups }) => <PrintReceiptButton form={form} lookups={lookups} />}
  />
);

export const OtherCreditsPage = () => (
  <GenericCrudPage
    title="Other credits"
    resource={M.otherCredits}
    idKey="Id"
    // sp_ManageOtherCredits SELECT takes no search parameter, so — as in the
    // legacy page's filterTable(), which hid grid rows in the browser — the
    // term narrows the loaded rows here rather than going to the server. It
    // matches against the displayed cells, the date in its displayed form.
    filterRow={(r, term) =>
      [r.Description, r.Amount, r.PaymentDate ? dmy(r.PaymentDate) : '']
        .join(' ')
        .toLowerCase()
        .includes(term)
    }
    // other_credits.aspx had no delete path — its DeleteCredit() was commented
    // out and the grid carried an Edit icon only.
    canDelete={false}
    columns={[
      // No backing field — the legacy grid numbered rows by grid position.
      // exportValue keeps the CSV/PDF columns in step with what is displayed,
      // since the export reads the row rather than the rendered cell.
      {
        key: 'no',
        label: 'No',
        format: (_v, _r, i) => i + 1,
        exportValue: (_r, i) => (i ?? 0) + 1,
      },
      { key: 'Description', label: 'Description' },
      { key: 'Amount', label: 'Amount', format: money, exportValue: (r) => money(r.Amount) },
      { key: 'PaymentDate', label: 'Date', format: dmy, exportValue: (r) => dmy(r.PaymentDate) },
    ]}
    fields={[
      {
        name: 'description',
        label: 'Description',
        required: true,
        span: 2,
        placeholder: 'e.g. Hoardings, Bhangar Sell',
      },
      { name: 'amount', label: 'Payment', type: 'number', required: true },
      // Required on the legacy form (txtDate carried `required`), even though
      // the SP leaves @payment_date nullable.
      { name: 'paymentDate', label: 'Date', type: 'date', required: true },
    ]}
    toForm={(r) => ({
      description: r.Description ?? '',
      amount: r.Amount ?? '',
      paymentDate: r.PaymentDate ? String(r.PaymentDate).slice(0, 10) : '',
    })}
  />
);

export const VendorsPage = () => (
  <GenericCrudPage
    title="Vendors"
    resource={M.vendors}
    idKey="vendor_id"
    columns={[
      { key: 'vendor_name', label: 'Vendor' },
      { key: 'contact_person', label: 'Contact person' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'service_type', label: 'Service' },
      { key: 'gst_no', label: 'GST' },
    ]}
    fields={[
      { name: 'name', label: 'Vendor name', required: true },
      { name: 'contactPerson', label: 'Contact person' },
      { name: 'contactNo', label: 'Contact number' },
      { name: 'email', label: 'Email', type: 'email' },
      { name: 'serviceType', label: 'Service type' },
      { name: 'gstNo', label: 'GST number' },
      { name: 'address', label: 'Address', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.vendor_name ?? '',
      contactPerson: r.contact_person ?? '',
      contactNo: r.contact_no ?? '',
      email: r.email ?? '',
      serviceType: r.service_type ?? '',
      gstNo: r.gst_no ?? '',
      address: r.address ?? '',
    })}
  />
);

/* ------------------------------------------------------------ community */

/*
 * Notices — the society's notice_search.aspx and, for a village account, the
 * "Announcements" v_announcement.aspx put in the village menu.
 *
 * The legacy village page split its list across three tabs (General, Meeting,
 * Work & Budget) and held everything in a `static List<Announcement>` in
 * memory: nothing was written to a database, so an app restart lost the lot and
 * every village shared one list. notice_master has no category column to
 * reproduce those tabs with, and inventing one would mean a schema change to
 * mimic a page that stored nothing. This keeps the real, per-tenant notices the
 * society side already had, which is what the announcements were meant to be.
 */
export const NoticesPage = () => (
  <GenericCrudPage
    title="Announcements"
    resource={M.notices}
    idKey="notice_id"
    columns={[
      { key: 'name', label: 'Title' },
      { key: 'description', label: 'Description' },
      { key: 'date', label: 'Date', format: day },
      { key: 'valid_to', label: 'Valid to', format: day },
    ]}
    fields={[
      // The legacy modal's own fields and placeholders, less Category.
      { name: 'title', label: 'Title', required: true, span: 2, placeholder: 'Enter announcement title' },
      { name: 'description', label: 'Description', type: 'textarea', span: 2, placeholder: 'Enter description' },
      { name: 'validTo', label: 'Valid until', type: 'date' },
      { name: 'recipientsId', label: 'Recipients', type: 'select', lookup: 'recipients', optionValue: 'recipients_id', optionLabel: 'recipients' },
    ]}
    lookups={{ recipients: M.community.noticeRecipients }}
    toForm={(r) => ({
      title: r.name ?? '',
      description: r.description ?? '',
      validTo: r.valid_to ? String(r.valid_to).slice(0, 10) : '',
      recipientsId: r.recipients_id ?? '',
    })}
  />
);

export const EventsPage = () => (
  <GenericCrudPage
    title="Events"
    resource={M.events}
    idKey="event_id"
    searchable={false}
    columns={[
      { key: 'event_name', label: 'Event' },
      { key: 'description', label: 'Description' },
      { key: 'from_date', label: 'From', format: day },
      { key: 'to_date', label: 'To', format: day },
    ]}
    fields={[
      { name: 'name', label: 'Event name', required: true, span: 2 },
      { name: 'description', label: 'Description', type: 'textarea', span: 2 },
      { name: 'fromDate', label: 'From', type: 'date', required: true },
      { name: 'toDate', label: 'To', type: 'date', required: true },
    ]}
    toForm={(r) => ({
      name: r.event_name ?? '',
      description: r.description ?? '',
      fromDate: r.from_date ? String(r.from_date).slice(0, 10) : '',
      toDate: r.to_date ? String(r.to_date).slice(0, 10) : '',
    })}
  />
);

export const MeetingsPage = () => (
  <GenericCrudPage
    title="Meetings"
    resource={M.meetings}
    idKey="meet_id"
    // Columns follow meeting_search.aspx's grid: subject, date, time.
    columns={[
      { key: 'subject', label: 'Subject' },
      { key: 'meeting_date', label: 'Meeting date', format: day },
      { key: 'meeting_time', label: 'Meeting time', format: clockTime },
      // The legacy editor was TinyMCE, so older rows hold HTML. Showing the
      // tags raw is worse than showing the text, and the column is a preview
      // either way — the full details are in the form.
      { key: 'details', label: 'Details', format: (v) => plainText(v) || '—' },
    ]}
    fields={[
      { name: 'subject', label: 'Subject', required: true, span: 2 },
      { name: 'meetingDate', label: 'Meeting date', type: 'date', required: true },
      // meeting_search.aspx marked time required and the SP stores it; the
      // form here never carried it, so every save wrote a null over it.
      { name: 'meetingTime', label: 'Meeting time', type: 'time', required: true },
      // The legacy modal's TinyMCE box. meeting_master.details is nvarchar(300)
      // and the markup counts against it, so the limit shown is the column's
      // rather than the API's more generous 1000.
      {
        name: 'details',
        label: 'Details',
        type: 'richtext',
        span: 2,
        maxLength: 300,
        hint: 'Agenda or notes for the meeting.',
      },
    ]}
    toForm={(r) => ({
      subject: r.subject ?? '',
      // Kept as HTML — the editor reads and writes markup.
      details: r.details ?? '',
      meetingDate: r.meeting_date ? String(r.meeting_date).slice(0, 10) : '',
      meetingTime: inputTime(r.meeting_time),
    })}
  />
);

export const FacilitiesPage = () => (
  <GenericCrudPage
    title="Facilities"
    resource={M.facilities}
    idKey="facility_id"
    searchable={false}
    columns={[
      { key: 'name', label: 'Facility' },
      { key: 'cost', label: 'Cost', format: money },
      { key: 'capacity', label: 'Capacity' },
      { key: 'slot', label: 'Slots' },
      { key: 'isActive', label: 'Bookable', format: yesNo },
    ]}
    fields={[
      { name: 'name', label: 'Facility name', required: true },
      { name: 'cost', label: 'Cost', type: 'number' },
      { name: 'capacity', label: 'Capacity', type: 'number' },
      { name: 'slots', label: 'Slots', type: 'number' },
      { name: 'description', label: 'Description', span: 2 },
      { name: 'isActive', label: 'Available for booking', type: 'checkbox', span: 2 },
    ]}
    toForm={(r) => ({
      name: r.name ?? '',
      cost: r.cost ?? '',
      capacity: r.capacity ?? '',
      slots: r.slot ?? '',
      description: r.description ?? '',
      isActive: Boolean(r.isActive),
    })}
  />
);

// suggestion_request.aspx — grid of Subject/Details with an Add/Edit modal
// carrying those same two required fields, and a soft delete.
export const SuggestionsPage = () => (
  <GenericCrudPage
    title="Suggestion/Request"
    resource={M.suggestions}
    idKey="sug_id"
    columns={[
      { key: 'sug_id', label: 'No', format: (_v, _r, i) => i + 1 },
      { key: 'subject', label: 'Subject' },
      { key: 'details', label: 'Details' },
    ]}
    fields={[
      { name: 'subject', label: 'Subject', required: true, placeholder: 'Enter Subject', span: 2 },
      {
        name: 'details',
        label: 'Suggestions/Requests',
        type: 'textarea',
        required: true,
        placeholder: 'Enter Suggestion/Request',
        span: 2,
      },
    ]}
    toForm={(r) => ({ subject: r.subject ?? '', details: r.details ?? '' })}
  />
);

export const DocumentsPage = () => (
  <GenericCrudPage
    title="Documents"
    resource={M.documents}
    idKey="file_id"
    columns={[
      { key: 'doc_name', label: 'Document' },
      { key: 'Tag', label: 'Tag' },
      { key: 'Description', label: 'Description' },
      { key: 'date', label: 'Uploaded', format: day },
    ]}
    canCreate={false}
    canEdit={false}
  />
);

/* -------------------------------------------------------------- village */

export const VillageHousesPage = () => (
  <GenericCrudPage
    title="Houses"
    resource={{
      list: M.village.houses,
      create: M.village.createHouse,
      update: M.village.updateHouse,
      remove: () => Promise.reject(new Error('Houses cannot be deleted')),
    }}
    idKey="house_id"
    searchable={false}
    canDelete={false}
    columns={[
      { key: 'house_no', label: 'House no.' },
      { key: 'name', label: 'Owner' },
      { key: 'house_type', label: 'Type' },
      { key: 'area', label: 'Area' },
      { key: 'gharpatti_charges', label: 'Property tax', format: money },
      { key: 'water_charges', label: 'Water', format: money },
      { key: 'waste_charges', label: 'Waste', format: money },
    ]}
    fields={[
      { name: 'houseNo', label: 'House number', type: 'number', required: true },
      { name: 'houseType', label: 'House type ID', type: 'number', required: true },
      { name: 'area', label: 'Area', type: 'number' },
      { name: 'propertyTax', label: 'Property tax', type: 'number' },
      { name: 'tapCount', label: 'Number of taps', type: 'number' },
      { name: 'waterCharges', label: 'Water charges', type: 'number' },
      { name: 'wasteCharges', label: 'Waste charges', type: 'number' },
    ]}
    toForm={(r) => ({
      houseNo: r.house_no ?? '',
      houseType: r.house_type ?? '',
      area: r.area ?? '',
      propertyTax: r.gharpatti_charges ?? '',
      tapCount: r.no_of_tab ?? '',
      waterCharges: r.water_charges ?? '',
      wasteCharges: r.waste_charges ?? '',
    })}
  />
);

export const VillageStaffPage = () => {
  const [viewingFile, setViewingFile] = useState(null);
  return (
  <GenericCrudPage
    title="Village staff"
    resource={{
      list: M.village.staff,
      create: M.village.createStaff,
      update: M.village.updateStaff,
      remove: M.village.removeStaff,
    }}
    idKey="staff_id"
    // sp_Village_staff's Grid_Show takes no search parameter, so — as in
    // v_staff_management.aspx's filterTable(), which hid grid rows in the
    // browser — the term narrows the loaded rows here rather than going to
    // the server. It matches against the displayed cells.
    filterRow={(r, term) =>
      [r.staff_name, r.role, r.contact_no, r.email, r.address]
        .join(' ')
        .toLowerCase()
        .includes(term)
    }
    columns={[
      { key: 'staff_name', label: 'Name' },
      { key: 'role', label: 'Role' },
      { key: 'contact_no', label: 'Contact' },
      { key: 'email', label: 'Email' },
      { key: 'address', label: 'Address' },
      { key: 'joined_date', label: 'Joined', format: day },
      { key: 'salary', label: 'Salary', format: money },
      {
        // v_staff_management.aspx's per-row view button, which opened id_path
        // in a modal. GenericCrudPage has no extra-actions slot, so it rides
        // in as a column.
        key: 'id_path',
        label: 'ID proof',
        // Nothing but a button, so on paper the column was a ruled empty
        // strip. The PDF keeps it — exportValue below prints Yes/No.
        printHidden: true,
        format: (v, row) =>
          v ? (
            <button
              type="button"
              className="btn-secondary px-2 text-xs print:hidden"
              title={`View ID proof for ${row.staff_name}`}
              onClick={() => setViewingFile({ path: v, name: row.staff_name, label: 'ID proof' })}
            >
              View
            </button>
          ) : (
            '—'
          ),
        // The CSV and PDF read exportValue (or the raw cell) rather than
        // `format`, so without this the exports carried the stored file path.
        // A sheet says whether the document is on file, not where it lives.
        exportValue: (row) => (row.id_path ? 'Yes' : 'No'),
      },
    ]}
    // Field order and the required marks follow v_staff_management.aspx's
    // modal: one field per row, Role directly under Name, and everything it
    // marked with a red asterisk — all but Email — required here too. The
    // required ones run first, each below the last, with the optional pair at
    // the end; span 2 keeps them stacked rather than pairing up across the
    // two-column grid.
    fields={[
      { name: 'name', label: 'Name', required: true, span: 2 },
      { name: 'roleId', label: 'Role', type: 'select', lookup: 'roles', optionValue: 'role_id', optionLabel: 'role', required: true, span: 2 },
      // MaxLength="10" plus the digits-only onkeypress the legacy field
      // carried, and what Village_staff.contact_no holds.
      { name: 'contactNo', label: 'Contact number', required: true, span: 2, digits: true, maxLength: 10 },
      { name: 'address', label: 'Address', required: true, span: 2 },
      { name: 'salary', label: 'Salary', type: 'number', required: true, span: 2 },
      { name: 'joinedDate', label: 'Joined date', type: 'date', required: true, span: 2 },
      { name: 'email', label: 'Email', type: 'email', span: 2 },
      { name: 'idPath', label: 'ID proof', type: 'file', category: 'staff', span: 2 },
    ]}
    lookups={{ roles: M.village.staffRoles }}
    toForm={(r) => ({
      name: r.staff_name ?? '',
      roleId: r.role_id ?? '',
      contactNo: r.contact_no ?? '',
      address: r.address ?? '',
      salary: r.salary ?? '',
      joinedDate: r.joined_date ? String(r.joined_date).slice(0, 10) : '',
      email: r.email ?? '',
      idPath: r.id_path ?? '',
    })}
  >
    <StoredFileModal file={viewingFile} onClose={() => setViewingFile(null)} />
  </GenericCrudPage>
  );
};
