import { useCallback, useEffect, useMemo, useState } from 'react';
import { village } from '@/api/modules';
import { api } from '@/api/client';
import { useOptionalUser } from '@/auth/AuthContext.jsx';
import DataGrid from '@/components/DataGrid.jsx';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  FormErrorSummary,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';
import {
  FileUploadField,
  ModeSwitch,
  PageHeader,
  SelectField,
  StatCard,
  Tabs,
  TextField,
} from '@/components/FormControls.jsx';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/** Charge types, matching Village_payment_type. */
const CHARGE_TYPES = [
  { value: '1', label: 'Property tax' },
  { value: '2', label: 'Water charges' },
  { value: '3', label: 'Waste charges' },
];

/**
 * Village residents — replaces village_owner_master.aspx and v_resident.aspx.
 * The owner record is separate from the house record, so this edits
 * house_owner while the houses page edits `house`.
 */
/*
 * The house columns v_resident.aspx let you edit in the grid itself: its
 * GridView carried an EditItemTemplate for each of these and nothing else, so
 * the owner's own details were read-only there and are edited in the dialog.
 *
 * `key` is the column in the grid row; `field` is what PUT /village/houses/:id
 * expects (see houseParams in routes/village/index.js).
 */
/*
 * Column labels say "Rs." rather than "₹": jsPDF's built-in Helvetica has no
 * rupee glyph, so a ₹ in a header comes out of the PDF export as a blank or a
 * stray quote. The figures inside the cells are plain numbers, so only the
 * headers were affected.
 */
const HOUSE_EDIT_FIELDS = [
  { key: 'area', field: 'area', label: 'House SqFt', step: '0.01' },
  { key: 'gharpatti_charges', field: 'propertyTax', label: 'SqFt Charges (Rs.)', step: '0.01' },
  { key: 'no_of_tab', field: 'tapCount', label: 'No. of Taps', step: '1' },
  { key: 'water_charges', field: 'waterCharges', label: 'Tap Charges (Rs.)', step: '0.01' },
  { key: 'waste_charges', field: 'wasteCharges', label: 'Waste Collection (Rs.)', step: '0.01' },
];

/** The legacy grid's "Total Amount" column — the three charges added up. */
const rowTotal = (row) =>
  Number(row?.gharpatti_charges || 0) +
  Number(row?.water_charges || 0) +
  Number(row?.waste_charges || 0);

/*
 * What Submit insists on, in the shape validateFields expects.
 *
 * Owner Name, Phone and House No. are the three the record cannot be filed
 * without: the grid lists residents by name and house, and the phone is how
 * the panchayat reaches them.
 *
 * House No. carries a showIf because it is only asked for when adding — an
 * existing resident's house is already set, and the dialog does not offer to
 * move them to another one.
 */
const RESIDENT_FIELDS = [
  { name: 'name', label: 'Owner name', required: true },
  { name: 'mobile', label: 'Phone', required: true, phone: true, digits: true, maxLength: 10 },
  { name: 'houseNo', label: 'House no.', required: true, showIf: (f) => !f.__id },
];

export function VillageResidentsPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const toast = useToast();
  /*
   * Two error slots, because they belong to two different places on screen.
   *
   * `error` is the page's own — the list failed to load — and shows above the
   * grid with a Try again button. `formError` belongs to the dialog and shows
   * inside it. Sharing one slot put "Owner Name, Phone, House No. are required"
   * on the page behind the dialog, next to a Try again button that would have
   * reloaded the list rather than resubmitted the form.
   */
  const [error, setError] = useState(null);
  const [formError, setFormError] = useState(null);
  /*
   * Which fields Submit found empty, as { fieldName: message }. Shown against
   * the box itself rather than as one combined sentence — "Owner Name, Phone,
   * House No. are required" makes you match three names back to three boxes,
   * and does not say which of them you already filled.
   */
  const [fieldErrors, setFieldErrors] = useState({});
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState(null);
  const [confirming, setConfirming] = useState(null);
  /*
   * Inline editing, as the legacy GridView did it: Edit swaps one row's charge
   * cells for inputs, Update saves that row, Cancel drops the changes.
   * `editing` holds the house_id being edited and the values typed so far.
   */
  const [editing, setEditing] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await village.owners();
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const save = async (event) => {
    event.preventDefault();

    // Checked on Submit rather than as you type, which is when the legacy page
    // checked. What counts as required is RESIDENT_FIELDS, above.
    const missing = validateFields(RESIDENT_FIELDS, form);
    if (Object.keys(missing).length) {
      setFieldErrors(missing);
      setFormError(null);
      // The dialog scrolls, so the first field at fault is brought into view —
      // pressing Submit from the bottom would otherwise mark a box above it.
      focusFirstInvalid(RESIDENT_FIELDS, missing);
      return;
    }

    setBusy(true);
    setFieldErrors({});
    setFormError(null);
    try {
      if (form.__id) {
        // Editing an existing resident's own details. The house and its charges
        // are edited in the grid, as they were in the legacy GridView.
        await village.updateOwner(form.__id, {
          name: form.name,
          houseId: Number(form.houseId),
          address: form.address,
          mobile: form.mobile,
          altMobile: form.altMobile,
          idProofPath: form.idProofPath,
        });
      } else {
        /*
         * Adding creates the house first and then hangs the owner off it —
         * btnSubmitHouse_Click did exactly this:
         *
         *     int houseID = bL_House.InsertHouse(house);
         *     house.House_Id = houseID;
         *     bL_House.InsertOwner(house);
         *
         * so one dialog collects both, and asking for a house id that has to
         * exist already (as this form used to) had no counterpart in the
         * legacy page.
         */
        const { house_id: houseId } = await village.createHouse({
          houseNo: Number(form.houseNo || 0),
          houseType: Number(form.houseType) || 1,
          area: Number(form.area || 0),
          propertyTax: Number(form.propertyTax || 0),
          tapCount: Number(form.tapCount || 0),
          waterCharges: Number(form.waterCharges || 0),
          wasteCharges: Number(form.wasteCharges || 0),
        });

        if (!houseId) throw new Error('The house was saved but no id came back');

        await village.createOwner({
          name: form.name,
          houseId: Number(houseId),
          address: form.address,
          mobile: form.mobile,
          altMobile: form.altMobile,
          idProofPath: form.idProofPath,
        });
      }
      const wasEdit = Boolean(form.__id);
      setForm(null);
      await load();
      toast.success(`Resident ${wasEdit ? 'updated' : 'added'} successfully.`, { title: 'Saved' });
    } catch (err) {
      // A save that fails leaves the dialog open with what was typed, so the
      // message belongs in it rather than on the page behind.
      setFormError(err);
      toast.error('Your changes were not saved. Please check the form and try again.');
    } finally {
      setBusy(false);
    }
  };

  /** Open a row for editing, seeded with what it currently holds. */
  const startEdit = (row) => {
    setError(null);
    setEditing({
      houseId: row.house_id,
      /*
       * house_no rides along unchanged: sp_house's Update branch writes
       * `house_no = @house_no`, so omitting it would blank the column. Its
       * UPDATE deliberately leaves house_type alone, and the grid returns that
       * column as the type's *name* ("Kaccha house") rather than its id, so it
       * is not sent at all — the API defaults it and the SP ignores it.
       */
      houseNo: row.house_no ?? 0,
      houseTypeId: row.house_type_id ?? null,
      ...Object.fromEntries(HOUSE_EDIT_FIELDS.map((f) => [f.field, row[f.key] ?? 0])),
    });
  };

  /**
   * GridViewBills_RowUpdating — save the one row being edited.
   *
   * The legacy handler read exactly these five boxes off the row and left every
   * other column alone.
   */
  const saveRow = async () => {
    setBusy(true);
    setError(null);
    try {
      await village.updateHouse(editing.houseId, {
        houseNo: Number(editing.houseNo),
        /*
         * The API requires houseType because sp_house's INSERT branch writes
         * it; its UPDATE branch does not touch the column, so the value only
         * has to satisfy validation here. The row's real id is sent when the
         * grid supplies it (see SQL/FIX_sp_house_grid_type_id.sql) and 1 stands
         * in until that script has been run.
         */
        houseType: Number(editing.houseTypeId) || 1,
        ...Object.fromEntries(HOUSE_EDIT_FIELDS.map((f) => [f.field, Number(editing[f.field] || 0)])),
      });
      setEditing(null);
      await load();
      toast.success('House charges updated successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The row could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  /** The charge columns: plain text normally, an input while the row is open. */
  const editableColumn = ({ key, field, label, step }) => ({
    key,
    label,
    align: 'right',
    render: (value, row) =>
      editing?.houseId === row.house_id ? (
        <input
          className="field-input w-24 text-right"
          type="number"
          min="0"
          step={step}
          aria-label={label}
          value={editing[field] ?? ''}
          onChange={(e) => {
            const v = e.target.value;
            setEditing((p) => ({ ...p, [field]: v }));
          }}
        />
      ) : (
        money(value)
      ),
  });

  return (
    <section>
      {/* "Village Resident Details", as the legacy page headed itself. */}
      <PageHeader title="Village Resident Details" subtitle={`${rows.length} resident(s)`}>
        <button
          type="button"
          className="btn-primary"
          onClick={() => {
            // Cleared here rather than in an effect: an effect keyed on the
            // dialog would also fire on the render that setFormError causes,
            // wiping the message the moment Submit produced it.
            setFormError(null);
            setFieldErrors({});
            // The fields addHouseModal opened with, in its own order.
            setForm({
              name: '',
              address: '',
              mobile: '',
              houseNo: '',
              area: '',
              propertyTax: '',
              tapCount: '',
              waterCharges: '',
              wasteCharges: '',
              houseType: '',
              altMobile: '',
              idProofPath: '',
            });
          }}
        >
          Add
        </button>
      </PageHeader>

      {/* Screen only: on paper these three boxes repeat figures the table
          already carries and push the records down the page. */}
      <div className="mb-4 grid gap-3 sm:grid-cols-3 print:hidden">
        <StatCard label="Residents" value={rows.length} />
        <StatCard
          label="Property tax due"
          value={money(rows.reduce((s, r) => s + Number(r.gharpatti_charges || 0), 0))}
        />
        <StatCard
          label="Water charges"
          value={money(rows.reduce((s, r) => s + Number(r.water_charges || 0), 0))}
        />
      </div>

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          /* Column order follows v_resident.aspx's GridView: owner, address,
             phone and house no. read-only, then the five editable charge
             columns, then the total. */
          columns={[
            { key: 'name', label: 'Owner Name' },
            { key: 'address', label: 'Address' },
            { key: 'pre_mob', label: 'Phone' },
            { key: 'house_no', label: 'House No.' },
            ...HOUSE_EDIT_FIELDS.map(editableColumn),
            {
              key: '__total',
              label: 'Total Amount (Rs.)',
              align: 'right',
              render: (_v, row) => (
                <span className="font-semibold">{money(rowTotal(row))}</span>
              ),
              // The exports read row[key], and this column is computed rather
              // than stored — without this the CSV and PDF print it blank.
              exportValue: (row) => money(rowTotal(row)),
            },
          ]}
          rows={rows}
          idKey="house_id"
          loading={loading}
          /* v_resident.aspx carried a "Search here" box above its grid. */
          searchable
          searchPlaceholder="Search here"
          exportName="village-residents"
          exportTitle="Village Resident Details"
          emptyTitle="No residents recorded"
          /*
            The legacy Actions column swapped Edit for an Update / Cancel pair
            while its row was open (CommandName="Edit" / "Update" / "Cancel"),
            and that is what these do. "Details" opens the owner's own fields,
            which the legacy grid did not edit inline either.
          */
          actions={(row) =>
            editing?.houseId === row.house_id ? (
              <>
                <button type="button" className="btn-primary" onClick={saveRow} disabled={busy}>
                  {busy ? 'Saving…' : 'Update'}
                </button>
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => setEditing(null)}
                  disabled={busy}
                >
                  Cancel
                </button>
              </>
            ) : (
              <>
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => startEdit(row)}
                  disabled={Boolean(editing)}
                >
                  Edit
                </button>
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => {
                    setFormError(null);
                    setFieldErrors({});
                    setForm({
                      __id: row.village_owner_id,
                      name: row.name ?? '',
                      houseId: row.house_id ?? '',
                      address: row.address ?? '',
                      mobile: row.pre_mob ?? '',
                      altMobile: '',
                      idProofPath: '',
                    });
                  }}
                >
                  Details
                </button>
                <button
                  type="button"
                  className="btn-danger"
                  onClick={() =>
                    setConfirming({
                      title: 'Delete resident',
                      message: `Delete ${row.name}?`,
                      run: () => village.removeOwner(row.village_owner_id),
                    })
                  }
                >
                  Delete
                </button>
              </>
            )
          }
        />
      </div>

      <Modal
        open={Boolean(form)}
        title={form?.__id ? 'Resident Details' : 'Add House Details'}
        onClose={() => setForm(null)}
        footer={
          <>
            {/* addHouseModal's footer was Submit then Close. */}
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Close
            </button>
            <button type="submit" form="vres-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : form?.__id ? 'Save' : 'Submit'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="vres-form" onSubmit={save} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            {/*
              addHouseModal's own order: Owner Name, Address, Phone, then House
              No. beside House SqFt, then the three charge boxes, then Waste
              Collection.
            */}

            {/* A failed save reports at the top; the required-field messages
                sit against their own boxes below. */}
            {formError ? (
              <div className="sm:col-span-2">
                <ErrorNotice error={formError} />
              </div>
            ) : null}

            <TextField
              label="Owner Name"
              name="name"
              required
              className="sm:col-span-2"
              error={fieldErrors.name}
              value={form.name}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, name: value }));
                // The complaint goes as soon as it is answered.
                setFieldErrors((p) => ({ ...p, name: undefined }));
              }}
            />
            <TextField
              label="Address"
              name="address"
              className="sm:col-span-2"
              value={form.address}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, address: value }));
              }}
            />
            <TextField
              label="Phone"
              name="mobile"
              required
              error={fieldErrors.mobile}
              value={form.mobile}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, mobile: value }));
                setFieldErrors((p) => ({ ...p, mobile: undefined }));
              }}
            />
            <TextField
              label="Alternate phone"
              name="altMobile"
              value={form.altMobile}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, altMobile: value }));
              }}
            />

            {/*
              The house and its charges are only collected when adding: the
              legacy modal created both records at once, and an existing
              resident's charges are edited in the grid instead.
            */}
            {!form.__id
              ? [
                  ['houseNo', 'House No.', true],
                  ['area', 'House SqFt', false],
                  ['propertyTax', 'SqFt Charges (₹)', false],
                  ['tapCount', 'No. of Taps', false],
                  ['waterCharges', 'Tap Charges (₹)', false],
                  ['wasteCharges', 'Waste Collection (₹)', false],
                ].map(([key, label, required]) => (
                  <TextField
                    key={key}
                    label={label}
                    name={key}
                    type="number"
                    min="0"
                    required={required}
                    error={fieldErrors[key]}
                    value={form[key]}
                    onChange={(e) => {
                      const { value } = e.target;
                      setForm((p) => ({ ...p, [key]: value }));
                      setFieldErrors((p) => ({ ...p, [key]: undefined }));
                    }}
                  />
                ))
              : null}

            <FileUploadField
              label="ID proof"
              category="owner-documents"
              className="sm:col-span-2"
              currentPath={form.idProofPath}
              onUploaded={(f) => f && setForm((p) => ({ ...p, idProofPath: f.path }))}
            />
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
            toast.success('Resident deleted successfully.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The resident could not be deleted. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

/**
 * Payment modes offered by v_tax_payment.aspx's ddlPaymentMethod. The values
 * are the pay_mode ids the SP stores, not display order.
 */
const PAY_METHODS = [
  { value: 1, label: 'Cash' },
  { value: 4, label: 'UPI' },
  { value: 2, label: 'Cheque' },
];

const EMPTY_PAYMENT = { payMode: 1, transactionRef: '', chequeNo: '', chequeDate: '', remark: '' };

/*
 * What a payment must carry, by method. Cash needs nothing beyond the receipt;
 * the other two are only traceable if their identifying details are there — a
 * cheque with no number cannot be matched to a bank statement.
 *
 * Keyed by Village_payment_type’s own codes, as PAY_METHODS is.
 */
const PAYMENT_FIELDS_BY_MODE = {
  4: [{ name: 'transactionRef', label: 'Transaction reference', required: true }],
  2: [
    { name: 'chequeNo', label: 'Cheque no.', required: true },
    { name: 'chequeDate', label: 'Cheque date', required: true },
  ],
};

/** Village_payment_type's codes, for the pay dialog's heading. */
const CHARGE_TYPE_NAMES = { 1: 'Property Tax', 2: 'Water Charges', 3: 'Waste Charges' };

/**
 * A paid receipt, as a document rather than a list of labelled values.
 *
 * The legacy modal (#receiptModal) printed Receipt No, Date, Owner Name, House
 * Number, Payment Method, Transaction Reference, Cheque No, Cheque Date and the
 * amount, and closed with "Thank you for your payment!". Those are all kept —
 * what changes is that this reads like something you would hand over: the
 * village's name at the top, the amount as the one figure that leads, and a
 * PAID stamp.
 *
 * This is the screen view. Print Receipt and Download PDF both go through
 * buildReceiptPdf() instead, so the printed and downloaded documents are the
 * same file rather than two layouts kept in step by hand.
 */
function TaxReceipt({ receipt: r, villageName, bills = [] }) {
  const rows = [
    ['Owner Name', r.name],
    ['House Number', r.house_no],
    ['Address', r.address],
    ['Contact', r.pre_mob],
    /* The bills are itemised below when there is more than one, so repeating
       the charge names here would say it twice. */
    ...(bills.length > 1 ? [] : [['Bill Type', r.payment_type_name]]),
    ['Payment Method', r.pay_mode],
    /* Transation_ref is on house_tax_receipt but Grid_paid_charges does not
       select it, so it only appears when the row came from the single-receipt
       endpoint. Blank rows are dropped rather than printed as a dash. */
    ['Transaction Reference', r.Transation_ref],
    ['Cheque No.', r.chqno],
    ['Cheque Date', r.chqdate ? day(r.chqdate) : ''],
  ].filter(([, v]) => v !== null && v !== undefined && String(v).trim() !== '');

  return (
    <div className="print-receipt">
      {/* Header — who issued it, and its number and date. */}
      <div
        className="relative overflow-hidden rounded-xl px-6 py-5 text-white"
        style={{ background: 'linear-gradient(120deg, #1e3a8a 0%, #2563eb 60%, #4f7df3 100%)' }}
      >
        <div
          className="pointer-events-none absolute inset-0"
          aria-hidden="true"
          style={{
            backgroundImage:
              'radial-gradient(420px circle at 6% 0%, rgba(147,197,253,0.35), transparent 62%)',
          }}
        />
        <div className="relative flex flex-wrap items-start justify-between gap-3">
          <div>
            <p
              className="text-[11px] font-semibold uppercase tracking-[0.14em]"
              style={{ color: 'rgba(255,255,255,0.75)' }}
            >
              Gram Panchayat
            </p>
            <p className="mt-0.5 text-xl font-bold">{villageName || 'Village'}</p>
            <p className="mt-1 text-xs" style={{ color: 'rgba(255,255,255,0.7)' }}>
              Tax Payment Receipt
            </p>
          </div>
          <div className="text-right">
            <p className="text-[11px]" style={{ color: 'rgba(255,255,255,0.7)' }}>
              Receipt No.
            </p>
            <p className="text-lg font-bold">{r.receipt_no || '—'}</p>
            <p className="mt-1 text-xs" style={{ color: 'rgba(255,255,255,0.7)' }}>
              {day(r.pay_date)}
            </p>
          </div>
        </div>
      </div>

      {/* The amount, which is what the receipt is for. */}
      <div
        className="mt-4 flex flex-wrap items-center justify-between gap-3 rounded-xl px-6 py-4"
        style={{ background: '#f0fdf4', border: '1px solid #bbf7d0' }}
      >
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-wide" style={{ color: '#15803d' }}>
            Amount Paid
          </p>
          <p className="mt-0.5 text-3xl font-bold" style={{ color: '#166534' }}>
            ₹{money(r.Amount_paid)}
          </p>
        </div>
        {/* The stamp a paper receipt would carry. */}
        <span
          className="rounded-lg px-4 py-2 text-sm font-bold uppercase tracking-widest"
          style={{ color: '#16a34a', border: '2px solid #16a34a', transform: 'rotate(-4deg)' }}
        >
          Paid
        </span>
      </div>

      {/*
        What the payment settled. A payment can cover several bills — June and
        July together, say — and a receipt that names only a total does not say
        what it was for. Shown whenever the breakdown is known, so a single
        bill still states its period.
      */}
      {bills.length ? (
        <div className="mt-4 overflow-hidden rounded-xl" style={{ border: '1px solid var(--line)' }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: '#f8fafc' }}>
                <th className="px-4 py-2 text-left font-semibold" style={{ color: '#718096' }}>
                  Period
                </th>
                <th className="px-4 py-2 text-left font-semibold" style={{ color: '#718096' }}>
                  Charge
                </th>
                <th className="px-4 py-2 text-right font-semibold" style={{ color: '#718096' }}>
                  Amount
                </th>
              </tr>
            </thead>
            <tbody>
              {bills.map((b) => (
                <tr key={b.house_receipt_id} className="border-t" style={{ borderColor: 'var(--line)' }}>
                  {/* A yearly charge has no month, so it reads as the year. */}
                  <td className="px-4 py-2">{[b.Month, b.year].filter(Boolean).join(' ') || '—'}</td>
                  <td className="px-4 py-2">{b.payment_type_name}</td>
                  <td className="px-4 py-2 text-right font-semibold">₹{money(b.Amount_paid)}</td>
                </tr>
              ))}
            </tbody>
            {bills.length > 1 ? (
              <tfoot>
                <tr className="border-t" style={{ borderColor: 'var(--line)', background: '#f8fafc' }}>
                  <td className="px-4 py-2 font-semibold" colSpan={2}>
                    Total
                  </td>
                  <td className="px-4 py-2 text-right font-bold">
                    ₹{money(bills.reduce((s, b) => s + Number(b.Amount_paid || 0), 0))}
                  </td>
                </tr>
              </tfoot>
            ) : null}
          </table>
        </div>
      ) : null}

      {/* Details, one per line, so the eye runs down a single column. */}
      <dl className="mt-4 divide-y" style={{ borderColor: 'var(--line)' }}>
        {rows.map(([label, value]) => (
          <div key={label} className="flex justify-between gap-6 py-2.5">
            <dt className="text-sm" style={{ color: '#718096' }}>
              {label}
            </dt>
            <dd className="text-right text-sm font-semibold" style={{ color: 'var(--ink)' }}>
              {value}
            </dd>
          </div>
        ))}
      </dl>

      <p className="mt-5 text-center text-sm font-medium" style={{ color: '#718096' }}>
        Thank you for your payment!
      </p>
      <p className="mt-1 text-center text-[11px]" style={{ color: '#a0aec0' }}>
        This is a computer-generated receipt and needs no signature.
      </p>
    </div>
  );
}

/**
 * One pending amount in the grid, as a link that opens the pay dialog for that
 * house and that charge — the legacy grid's ViewWater / ViewProperty /
 * ViewWaste commands.
 *
 * `type` is the payment_type id: 1 Property Tax, 2 Water Charges, 3 Waste
 * Charges, matching Village_payment_type.
 */
function PendingAmount({ value, row, type, onPay }) {
  const amount = Number(value || 0);
  // The legacy link printed ₹{0:N2}; a zero is not a link, since there is
  // nothing to pay.
  if (!amount) return <span className="text-slate-400">₹{money(0)}</span>;

  return (
    <button
      type="button"
      className="font-semibold underline-offset-2 hover:underline"
      style={{ color: 'var(--accent-strong)' }}
      disabled={!PAYMENTS_ENABLED}
      title={
        PAYMENTS_ENABLED
          ? 'Pay this charge'
          : 'Payments are disabled until the flow has been run against a test database (VITE_ENABLE_VILLAGE_PAYMENTS)'
      }
      onClick={() => onPay(row, type)}
    >
      ₹{money(amount)}
    </button>
  );
}

/** The "Total Pending" column on v_tax_payment.aspx — the three dues added up. */
const pendingTotal = (r) =>
  Number(r?.pending_property_tax || 0) +
  Number(r?.pending_water_charges || 0) +
  Number(r?.pending_waste_charges || 0) +
  // Charges a village added itself. Without this the row total omitted them,
  // so a house owing one showed less than it owes.
  Number(r?.pending_other_charges || 0);

/**
 * Taking money is guarded the same way bill generation and receipt entry are:
 * the API is built and validated, but the button stays disabled until the flow
 * has been exercised against a test database.
 * Set VITE_ENABLE_VILLAGE_PAYMENTS=true to enable it.
 */
const PAYMENTS_ENABLED = import.meta.env.VITE_ENABLE_VILLAGE_PAYMENTS === 'true';

/**
 * Village payments — replaces v_payments.aspx, v_tax_payment.aspx and
 * house_tax_receipt.aspx. Pending charges by type, plus the paid receipts log.
 */
export function VillagePaymentsPage() {
  const [tab, setTab] = useState('pending');
  /*
   * Houses ticked in the pending grid's Select column, for the Send SMS
   * reminder below it. Paying does not use these — that is done by clicking an
   * amount, as gvPending's LinkButtons did.
   */
  const user = useOptionalUser();
  const villageName = user?.village_name || '';
  const toast = useToast();
  const [smsSelected, setSmsSelected] = useState([]);
  const [smsPreview, setSmsPreview] = useState(false);
  const [pending, setPending] = useState([]);
  const [receipts, setReceipts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [viewing, setViewing] = useState(null);
  /*
   * The bills the payment settled. A payment can cover several — June and July
   * together share one receipt number — and a receipt that names only a total
   * does not say what was paid for.
   */
  const [viewingBills, setViewingBills] = useState([]);
  const [receiptPdfBusy, setReceiptPdfBusy] = useState(false);

  // Pay modal: which house, its unpaid bills, and which are ticked.
  const [paying, setPaying] = useState(null); // { house, bills, selected:Set }
  const [payForm, setPayForm] = useState({ ...EMPTY_PAYMENT });
  const [payBusy, setPayBusy] = useState(false);
  // name -> message, for the payment boxes the last submit found empty.
  const [payFieldErrors, setPayFieldErrors] = useState({});
  const [payError, setPayError] = useState(null);

  /**
   * The open receipt as a PDF, laid out like the one on screen.
   *
   * tableToPdf draws a title, a subtitle, a tinted criteria box and a table —
   * which maps onto a receipt: the village in the heading, the amount and
   * receipt number in the box that leads, and the details as rows. Reusing it
   * keeps this file free of a second PDF implementation.
   */
  /*
   * Open a receipt, and fetch the bills behind it. The grid row carries the
   * payment's total; the bills say which periods and charges it covered, which
   * is what someone checks a receipt against.
   */
  const openReceipt = async (row) => {
    setViewing(row);
    setViewingBills([]);
    try {
      const data = await village.houseTaxReceipt(row.house_receipt_id);
      setViewingBills(data.bills ?? []);
    } catch {
      // The receipt still shows its header and total without the breakdown.
    }
  };

  // Cleared on close, so the next receipt opened cannot show the last one's
  // bills while its own are still being fetched.
  const closeReceipt = () => {
    setViewing(null);
    setViewingBills([]);
  };

  const buildReceiptPdf = async ({ print = false } = {}) => {
    if (!viewing) return;
    setReceiptPdfBusy(true);
    try {
      const { tableToPdf } = await import('@/lib/pdf');

      const rows = [
        ['Owner Name', viewing.name],
        ['House Number', viewing.house_no],
        ['Address', viewing.address],
        ['Contact', viewing.pre_mob],
        // Itemised below when the payment covered more than one bill.
        ...(viewingBills.length > 1 ? [] : [['Bill Type', viewing.payment_type_name]]),
        ['Payment Method', viewing.pay_mode],
        ['Transaction Reference', viewing.Transation_ref],
        ['Cheque No.', viewing.chqno],
        ['Cheque Date', viewing.chqdate ? day(viewing.chqdate) : ''],
      ]
        .filter(([, v]) => v !== null && v !== undefined && String(v).trim() !== '')
        .map(([field, value]) => ({ field, value: String(value) }));

      /*
       * The bills the payment settled, listed under the details so the printed
       * receipt says what was paid for and not just the total. The same table
       * takes both, so each bill is a Detail/Value pair: the period and charge
       * on the left, its amount on the right.
       */
      if (viewingBills.length) {
        rows.push({ field: '', value: '' });
        rows.push({ field: 'Bills settled', value: '' });
        for (const b of viewingBills) {
          const period = [b.Month, b.year].filter(Boolean).join(' ');
          rows.push({
            field: `   ${period} — ${b.payment_type_name ?? ''}`.trimEnd(),
            value: `Rs. ${money(b.Amount_paid)}`,
          });
        }
      }

      await tableToPdf({
        columns: [
          { key: 'field', label: 'Detail' },
          { key: 'value', label: 'Value' },
        ],
        rows,
        title: 'Tax Payment Receipt',
        subtitle: villageName,
        /*
         * The box under the title, which is what the green panel is on screen.
         * "Rs." rather than ₹ throughout: jsPDF's built-in Helvetica has no
         * rupee glyph and prints it as a blank or a stray quote.
         */
        filters: [
          { label: 'Receipt No.', value: viewing.receipt_no ?? '' },
          { label: 'Receipt Date', value: day(viewing.pay_date) },
          { label: 'Amount Paid', value: `Rs. ${money(viewing.Amount_paid)}` },
          { label: 'Status', value: 'PAID' },
        ],
        filename: `receipt-${viewing.receipt_no || viewing.house_receipt_id}`,
        orientation: 'portrait',
        // The green the on-screen receipt uses for a settled payment.
        accent: [22, 163, 74],
        print,
      });
    } catch (err) {
      window.alert(`Could not create the PDF: ${err.message}`);
    } finally {
      setReceiptPdfBusy(false);
    }
  };

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [p, r] = await Promise.all([
        village.houseTaxPending().catch(() => ({ items: [] })),
        village.houseTaxReceipts().catch(() => ({ items: [] })),
      ]);
      setPending(p.items ?? []);
      /*
       * Newest payment first. Grid_paid_charges returns rows in whatever order
       * the join produces, so the most recent receipt could land anywhere in
       * the list — and a payments log is read from the latest backwards.
       * house_receipt_id breaks ties within a day, since it rises with entry.
       */
      setReceipts(
        [...(r.items ?? [])].sort(
          (a, b) =>
            new Date(b.pay_date ?? 0) - new Date(a.pay_date ?? 0) ||
            Number(b.house_receipt_id ?? 0) - Number(a.house_receipt_id ?? 0),
        ),
      );
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  /**
   * Open the pay dialog for one house and one charge type — the legacy
   * PopulateModal(house_id, taxType).
   */
  const openPay = async (house, type) => {
    setPayError(null);
    setPayForm({ ...EMPTY_PAYMENT });
    setPayFieldErrors({});
    setPaying({ house, type, bills: [], selected: new Set(), loading: true });
    try {
      const d = await village.houseTaxBills(house.house_id, Number(type));
      const bills = (d.items ?? []).filter((b) => Number(b.payment_status) !== 1);
      setPaying({
        house,
        type,
        bills,
        // Every unpaid bill starts ticked, so the dialog opens showing the
        // whole amount the grid cell just reported. Untick to pay part of it.
        selected: new Set(bills.map((b) => Number(b.house_receipt_id))),
        loading: false,
      });
    } catch (err) {
      setPayError(err);
      setPaying({ house, type, bills: [], selected: new Set(), loading: false });
    }
  };

  const toggleBill = (id) =>
    setPaying((p) => {
      const next = new Set(p.selected);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return { ...p, selected: next };
    });

  const toggleAll = () =>
    setPaying((p) => ({
      ...p,
      selected:
        p.selected.size === p.bills.length
          ? new Set()
          : new Set(p.bills.map((b) => Number(b.house_receipt_id))),
    }));

  const selectedTotal = paying
    ? paying.bills
        .filter((b) => paying.selected.has(Number(b.house_receipt_id)))
        .reduce((s, b) => s + Number(b.pending_amount || 0), 0)
    : 0;

  const clearPayFieldError = (key) =>
    setPayFieldErrors((p) => (p[key] ? { ...p, [key]: undefined } : p));

  const submitPayment = async (e) => {
    e.preventDefault();

    /*
     * The boxes the legacy modal starred, for the method that is showing —
     * marked against the box at fault rather than named in one sentence, the
     * same as every other form in the app.
     */
    const payFields = PAYMENT_FIELDS_BY_MODE[Number(payForm.payMode)] ?? [];
    const missing = validateFields(payFields, payForm);
    setPayFieldErrors(missing);
    if (Object.keys(missing).length) {
      setPayError(null);
      focusFirstInvalid(payFields, missing);
      return;
    }

    setPayBusy(true);
    setPayError(null);
    try {
      await village.payHouseTax({
        receiptIds: [...paying.selected],
        payMode: Number(payForm.payMode),
        transactionRef: payForm.transactionRef,
        chequeNo: payForm.chequeNo,
        chequeDate: payForm.chequeDate,
        remark: payForm.remark,
      });
      const count = paying.selected.size;
      setPaying(null);
      await load();
      // Money changing hands is the one outcome an operator most needs
      // confirmed, so it names how many bills the receipt covered.
      toast.success(
        count === 1 ? 'Payment recorded for 1 bill.' : `Payment recorded for ${count} bills.`,
        { title: 'Payment saved' },
      );
    } catch (err) {
      setPayError(err);
      toast.error(err?.message ?? 'The payment could not be recorded. Please try again.');
    } finally {
      setPayBusy(false);
    }
  };

  const totals = useMemo(
    () => ({
      property: pending.reduce((s, r) => s + Number(r.pending_property_tax || 0), 0),
      water: pending.reduce((s, r) => s + Number(r.pending_water_charges || 0), 0),
      waste: pending.reduce((s, r) => s + Number(r.pending_waste_charges || 0), 0),
      // Charges the village added itself, which have no card of their own.
      other: pending.reduce((s, r) => s + Number(r.pending_other_charges || 0), 0),
      collected: receipts.reduce((s, r) => s + Number(r.Amount_paid || 0), 0),
    }),
    [pending, receipts],
  );

  return (
    <section>
      {/* "Tax Payments", as the legacy page headed itself. The grid below
          carries its own Print in the export toolbar, beside Excel and PDF, so
          a second one up here was the same action offered twice. */}
      <PageHeader title="Tax Payments" subtitle="Pending charges and collected receipts" />

      {/* Screen only, as on the residents page. */}
      <div className="mb-4 grid gap-3 sm:grid-cols-4 print:hidden">
        <StatCard label="Property tax due" value={money(totals.property)} tone="negative" />
        <StatCard label="Water charges due" value={money(totals.water)} tone="negative" />
        {/*
          Waste and anything the village added itself share a card: the strip
          is four wide, and a fifth would wrap. The grid below still lists
          other charges in their own column.
        */}
        <StatCard
          label={totals.other > 0 ? 'Waste & other due' : 'Waste charges due'}
          value={money(totals.waste + totals.other)}
          tone="negative"
        />
        <StatCard label="Collected" value={money(totals.collected)} tone="positive" />
      </div>

      <Tabs
        tabs={[
          /* The legacy page's own two tabs. */
          { id: 'pending', label: 'Pending Bills', count: pending.length },
          { id: 'receipts', label: 'Paid Bills', count: receipts.length },
        ]}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      <ErrorNotice error={error} onRetry={load} />

      {tab === 'pending' ? (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              /* gvPending's own columns: Name, House No, Water Tax, Property
                 Tax, Waste Tax. */
              { key: 'owner_name', label: 'Name' },
              { key: 'house_no', label: 'House No' },
              /*
                Each amount is its own button, which is how the legacy grid
                worked: the Water, Property and Waste cells carried
                CommandName="ViewWater" / "ViewProperty" / "ViewWaste" with the
                house_id, and clicking one opened the modal listing that house's
                unpaid bills of that type. A single charge-type selector for the
                whole page made you set it before clicking a figure, which
                nothing on screen told you to do.

                A zero is not a button — there is nothing to pay.
              */
              {
                key: 'pending_water_charges',
                label: 'Water Tax',
                align: 'right',
                render: (v, r) => <PendingAmount value={v} row={r} type={2} onPay={openPay} />,
                exportValue: (r) => money(r.pending_water_charges),
              },
              {
                key: 'pending_property_tax',
                label: 'Property Tax',
                align: 'right',
                render: (v, r) => <PendingAmount value={v} row={r} type={1} onPay={openPay} />,
                exportValue: (r) => money(r.pending_property_tax),
              },
              {
                key: 'pending_waste_charges',
                label: 'Waste Tax',
                align: 'right',
                render: (v, r) => <PendingAmount value={v} row={r} type={3} onPay={openPay} />,
                exportValue: (r) => money(r.pending_waste_charges),
              },
              {
                /*
                 * Charges the village added itself, summed. They have no
                 * column of their own because there can be any number of
                 * them; without this they were left out of the grid entirely
                 * and a house owing one appeared to owe nothing for it.
                 *
                 * Not payable from here: the pay dialog settles one charge
                 * type at a time and this column can stand for several.
                 */
                key: 'pending_other_charges',
                label: 'Other Charges',
                align: 'right',
                render: (v) => money(v),
                exportValue: (r) => money(r.pending_other_charges),
              },
              {
                /*
                 * "Total Pending" is in v_tax_payment.aspx's markup but
                 * commented out, alongside the Pay All button it sat beside.
                 * It is kept because the three amounts beside it are the whole
                 * point of the row and their sum is what anyone reads first;
                 * the key is its own rather than house_id, which made the
                 * exports print the id where the total belongs.
                 */
                key: '__pending_total',
                label: 'Total Pending',
                align: 'right',
                render: (_v, r) => <span className="font-semibold">₹{money(pendingTotal(r))}</span>,
                exportValue: (r) => money(pendingTotal(r)),
              },
            ]}
            rows={pending}
            idKey="house_id"
            loading={loading}
            searchable
            searchPlaceholder="Search here"
            exportName="village-pending-charges"
            exportTitle="Pending Charges"
            emptyTitle="No pending charges"
            /*
              No per-row action button: gvPending has no Action column. Paying
              is done by clicking one of the three amounts, and the Select
              checkbox below picks houses for the Send SMS reminder.
            */
            selectable
            selectionAtEnd
            selectedIds={smsSelected}
            onSelectionChange={setSmsSelected}
          />

          {/*
            btnSendSMS, under the grid. validateSelection() refused an empty
            selection, so the button stays disabled until something is ticked.

            btnSendSMS_Click gathered the ticked rows — owner, mobile and the
            three amounts — and then stopped at a "Process the data here..."
            comment: nothing was ever sent, and there is no SMS endpoint behind
            it. Rather than pretend, this reports what it would send and leaves
            the sending to be built.
          */}
          <div className="flex items-center justify-between gap-3 border-t px-4 py-3 print:hidden"
            style={{ borderColor: 'var(--line)' }}
          >
            <span className="text-sm" style={{ color: '#718096' }}>
              {smsSelected.length
                ? `${smsSelected.length} house(s) selected`
                : 'Select houses to remind'}
            </span>
            <button
              type="button"
              className="btn-primary"
              disabled={!smsSelected.length}
              onClick={() => setSmsPreview(true)}
            >
              Send SMS
            </button>
          </div>
        </div>
      ) : (
        <div className="card overflow-hidden">
          <DataGrid
            columns={[
              /*
               * gvPaid's own columns and order: Owner Name, House Number, Bill
               * Type, Total Tax, Payment Date, Payment Method. The receipt
               * number is not among them — it is on the receipt itself, which
               * the Action button opens.
               */
              { key: 'name', label: 'Owner Name' },
              { key: 'house_no', label: 'House Number' },
              { key: 'payment_type_name', label: 'Bill Type' },
              {
                key: 'Amount_paid',
                label: 'Total Tax',
                align: 'right',
                render: (v) => `₹${money(v)}`,
                exportValue: (r) => money(r.Amount_paid),
              },
              { key: 'pay_date', label: 'Payment Date', render: day, exportValue: (r) => day(r.pay_date) },
              // Grid_paid_charges resolves pay_mode to its name ("Cash",
              // "UPI"), so this column needs no lookup of its own.
              { key: 'pay_mode', label: 'Payment Method' },
            ]}
            rows={receipts}
            idKey="house_receipt_id"
            loading={loading}
            searchable
            searchPlaceholder="Search here"
            exportName="village-receipts"
            exportTitle="Tax Payment Receipts"
            emptyTitle="No receipts recorded"
            /* gvPaid's Action column held a single "Receipt" button. */
            actions={(row) => (
              <button type="button" className="btn-secondary" onClick={() => openReceipt(row)}>
                Receipt
              </button>
            )}
          />
        </div>
      )}

      <Modal
        open={Boolean(viewing)}
        title={`Receipt ${viewing?.receipt_no ?? ''}`}
        onClose={() => closeReceipt()}
        /* The legacy footer was Close then Print Receipt; the PDF is added
           because a receipt is usually wanted as a file to send on. */
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => closeReceipt()}>
              Close
            </button>
            <button
              type="button"
              className="btn-secondary"
              disabled={receiptPdfBusy}
              onClick={() => buildReceiptPdf()}
            >
              {receiptPdfBusy ? 'Preparing…' : 'Download PDF'}
            </button>
            {/* Prints the same document the download produces, rather than the
                dialog's own screen layout. */}
            <button
              type="button"
              className="btn-primary"
              disabled={receiptPdfBusy}
              onClick={() => buildReceiptPdf({ print: true })}
            >
              Print Receipt
            </button>
          </>
        }
      >
        {viewing ? (
          <TaxReceipt receipt={viewing} villageName={villageName} bills={viewingBills} />
        ) : null}
      </Modal>

      {/*
        What Send SMS would go out with. btnSendSMS_Click built exactly this
        list — owner, mobile and the three pending amounts — and then did
        nothing with it, so this shows the list rather than claiming to have
        sent anything there is no endpoint for.
      */}
      <Modal
        open={smsPreview}
        title="Send SMS reminder"
        onClose={() => setSmsPreview(false)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setSmsPreview(false)}>
            Close
          </button>
        }
      >
        <p className="mb-3 text-sm" style={{ color: '#718096' }}>
          Reminders are not sent yet — no SMS gateway is wired up. These are the
          houses and numbers a reminder would go to.
        </p>
        <div className="overflow-hidden rounded border" style={{ borderColor: 'var(--line)' }}>
          <table className="min-w-full">
            <thead>
              <tr>
                <th className="table-head">Name</th>
                <th className="table-head">Contact</th>
                <th className="table-head text-right">Total Pending</th>
              </tr>
            </thead>
            <tbody>
              {pending
                .filter((r) => smsSelected.includes(r.house_id))
                .map((r) => (
                  <tr key={r.house_id}>
                    <td className="table-cell">{r.owner_name}</td>
                    <td className="table-cell">{r.pre_mob || '—'}</td>
                    <td className="table-cell text-right">₹{money(pendingTotal(r))}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </Modal>

      {/* Pay modal — v_tax_payment.aspx's #taxModal. */}
      <Modal
        open={Boolean(paying)}
        /* lblModalTitle carried the owner and which charge is being settled. */
        title={`${CHARGE_TYPE_NAMES[paying?.type] ?? 'Charges'} — ${
          paying?.house?.owner_name ?? ''
        } (house ${paying?.house?.house_no ?? ''})`}
        onClose={() => setPaying(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setPaying(null)}>
              Cancel
            </button>
            <button
              type="submit"
              form="village-pay-form"
              className="btn-primary"
              disabled={payBusy || !paying?.selected?.size}
            >
              {payBusy ? 'Processing…' : `Process Payment (${money(selectedTotal)})`}
            </button>
          </>
        }
      >
        {paying?.loading ? (
          <Spinner label="Loading pending bills…" />
        ) : paying ? (
          <form id="village-pay-form" onSubmit={submitPayment} className="space-y-4" noValidate>
            <FormErrorSummary count={countErrors(payFieldErrors)} />
            {paying.bills.length === 0 ? (
              <EmptyState title="No unpaid bills of this type for this house" />
            ) : (
              <div className="overflow-hidden rounded border" style={{ borderColor: '#e3e6f0' }}>
                <table className="min-w-full">
                  <thead>
                    <tr>
                      <th className="table-head w-10">
                        <input
                          type="checkbox"
                          aria-label="Select all bills"
                          checked={paying.selected.size === paying.bills.length && paying.bills.length > 0}
                          onChange={toggleAll}
                        />
                      </th>
                      <th className="table-head">Period</th>
                      <th className="table-head">Type</th>
                      <th className="table-head text-right">Pending</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paying.bills.map((b) => {
                      const id = Number(b.house_receipt_id);
                      return (
                        <tr key={id}>
                          <td className="table-cell">
                            <input
                              type="checkbox"
                              aria-label={`Select bill ${b.receipt_no}`}
                              checked={paying.selected.has(id)}
                              onChange={() => toggleBill(id)}
                            />
                          </td>
                          {/*
                            A yearly charge has no month — the view returns an
                            empty Month for it — so it reads as the year alone
                            rather than a stray leading space.
                          */}
                          <td className="table-cell">
                            {[b.Month, b.year].filter(Boolean).join(' ')}
                          </td>
                          <td className="table-cell">{b.payment_type_name}</td>
                          <td className="table-cell text-right">{money(b.pending_amount)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            {/* .pay-total-section — the running total of what is ticked. */}
            <div
              className="flex items-center justify-between rounded-lg px-4 py-3"
              style={{ background: '#f7f9fd', border: '1px solid var(--line)' }}
            >
              <span className="text-sm font-semibold" style={{ color: '#4a5568' }}>
                Total Amount:
              </span>
              <span className="text-xl font-bold" style={{ color: 'var(--ink)' }}>
                ₹{money(selectedTotal)}
              </span>
            </div>

            <p className="text-xs" style={{ color: '#6b7280' }}>
              Each selected bill is settled in full — the stored procedure does not
              support part payment.
            </p>

            <div className="grid gap-3 sm:grid-cols-2">
              <SelectField
                label="Payment Method"
                name="payMode"
                required
                placeholder=""
                options={PAY_METHODS}
                value={String(payForm.payMode)}
                onChange={(e) => {
                  setPayForm((p) => ({
                    ...p,
                    payMode: Number(e.target.value),
                    // Switching method drops what the previous one asked for, so
                    // a cheque number cannot be posted with a UPI payment.
                    transactionRef: '',
                    chequeNo: '',
                    chequeDate: '',
                  }));
                  // ...and its complaints go with those inputs, rather than
                  // hanging over boxes that are no longer shown.
                  setPayFieldErrors({});
                }}
              />

              {/*
                toggleTransactionRef() in v_tax_payment.aspx: Cash asks for
                nothing, UPI (4) shows Transaction Reference alone, and Cheque
                (2) shows Cheque No. and Cheque Date alone. Reference was
                previously shown for cheques too, which the legacy never did.
              */}
              {Number(payForm.payMode) === 4 ? (
                <TextField
                  label="Transaction Reference"
                  name="transactionRef"
                  required
                  error={payFieldErrors.transactionRef}
                  maxLength={50}
                  placeholder="Enter transaction/reference number"
                  value={payForm.transactionRef}
                  onChange={(e) => {
                    const { value } = e.target;
                    setPayForm((p) => ({ ...p, transactionRef: value }));
                    clearPayFieldError('transactionRef');
                  }}
                />
              ) : null}

              {Number(payForm.payMode) === 2 ? (
                <>
                  <TextField
                    label="Cheque No."
                    name="chequeNo"
                    required
                    error={payFieldErrors.chequeNo}
                    maxLength={50}
                    placeholder="Enter Cheque number"
                    value={payForm.chequeNo}
                    onChange={(e) => {
                      const { value } = e.target;
                      setPayForm((p) => ({ ...p, chequeNo: value }));
                      clearPayFieldError('chequeNo');
                    }}
                  />
                  <TextField
                    label="Cheque Date"
                    name="chequeDate"
                    type="date"
                    required
                    error={payFieldErrors.chequeDate}
                    value={payForm.chequeDate}
                    onChange={(e) => {
                      const { value } = e.target;
                      setPayForm((p) => ({ ...p, chequeDate: value }));
                      clearPayFieldError('chequeDate');
                    }}
                  />
                </>
              ) : null}

              <TextField
                label="Remarks"
                name="remark"
                className="sm:col-span-2"
                maxLength={500}
                placeholder="Add any additional notes (optional)"
                value={payForm.remark}
                onChange={(e) => setPayForm((p) => ({ ...p, remark: e.target.value }))}
              />
            </div>

            <ErrorNotice error={payError} />
          </form>
        ) : null}
      </Modal>
    </section>
  );
}

/**
 * House tax and water tax registers. Both read through application-level
 * fallbacks because `house_owner.house_no` does not exist — see
 * docs/MIGRATION-MAP.md §7.1. Village bill generation stays disabled until
 * that defect is resolved.
 */
export function VillageTaxPage({ kind = 'house' }) {
  const isWater = kind === 'water';
  const [rows, setRows] = useState([]);
  const [source, setSource] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = isWater ? await village.waterTax() : await village.houseTax();
      setRows(data.items ?? []);
      setSource(data.source ?? '');
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [isWater]);

  useEffect(() => {
    load();
  }, [load]);

  const columns = isWater
    ? [
        { key: 'house_no', label: 'House no.' },
        { key: 'owner_name', label: 'Owner' },
        { key: 'connection_type', label: 'Connection' },
        { key: 'water_connection_size', label: 'Size' },
        { key: 'water_tax_amount', label: 'Amount', align: 'right', render: money },
        { key: 'due', label: 'Due', align: 'right', render: money },
      ]
    : [
        { key: 'house_no', label: 'House no.' },
        { key: 'owner_name', label: 'Owner' },
        { key: 'house_tax_bill_no', label: 'Bill no.' },
        { key: 'from_date', label: 'From', render: day },
        { key: 'to_date', label: 'To', render: day },
        { key: 'house_tax_amount', label: 'Amount', align: 'right', render: money },
        { key: 'due', label: 'Due', align: 'right', render: money },
      ];

  const totalDue = rows.reduce((s, r) => s + Number(r.due || 0), 0);

  return (
    <section>
      <PageHeader
        title={isWater ? 'Water tax' : 'House tax'}
        subtitle={`${rows.length} record(s) · ${money(totalDue)} outstanding`}
      >
        <button type="button" className="btn-secondary" onClick={() => window.print()}>
          Print
        </button>
      </PageHeader>

      <ErrorNotice error={error} onRetry={load} />

      {/* Surfaced rather than hidden: the screen is reading around a known
          database defect, and generation is unavailable because of it. */}
      <div className="mb-4 rounded-md border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
        <p className="font-medium">Bill generation unavailable</p>
        <p className="mt-1">
          {isWater ? 'sp_water_tax' : 'sp_house_tax'} and its view both join{' '}
          <code>house_owner.house_no</code>, a column that does not exist. This register reads the
          underlying table directly instead. Generating village bills additionally needs
          <code> house_owner.house_type</code>, which is also absent — see the pending SQL items.
        </p>
      </div>

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={rows}
          idKey={isWater ? 'water_tax_id' : 'house_tax_id'}
          loading={loading}
          searchable
          searchPlaceholder="Search here"
          exportName={isWater ? 'water-tax' : 'house-tax'}
          exportTitle={isWater ? 'Water Tax' : 'Property Tax'}
          emptyTitle={`No ${isWater ? 'water tax' : 'house tax'} records`}
          emptyHint="Generated bills will appear here once generation is available."
        />
      </div>

      {source ? <p className="mt-2 text-xs text-slate-400">Source: {source}</p> : null}
    </section>
  );
}
