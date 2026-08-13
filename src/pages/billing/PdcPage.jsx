import { useEffect, useState } from 'react';
import { pdc } from '@/api/onboarding';
import { residents } from '@/api/masters';
import useCrudResource from '../masters/useCrudResource';
import DateRangeReport, { money, day } from '../DateRangeReport.jsx';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner, FormErrorSummary } from '@/components/ui.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

const EMPTY = { ownerId: '', wingId: '', chequeNo: '', amount: '', chequeDate: '' };

/* What Submit insists on, in the shape validateFields expects. */
const PDC_FIELDS = [
  { name: 'ownerId', label: 'Owner', type: 'select', required: true },
  { name: 'chequeNo', label: 'Cheque number', required: true },
  { name: 'amount', label: 'Amount', required: true },
  { name: 'chequeDate', label: 'Cheque date', required: true },
];

/** What a cheque's status reads as, from the three flags. */
const statusText = (r) =>
  r.che_dep ? 'Deposited' : r.che_ret ? 'Returned' : r.che_can ? 'Bounced' : 'Pending';

// ExportToolbar reads values off the row, so dates and amounts are formatted
// here rather than relying on the cell markup.
const EXPORT_COLUMNS = [
  { key: 'chqno', label: 'Cheque no.' },
  { key: 'name', label: 'Resident' },
  { key: 'Unit', label: 'Unit' },
  { key: 'che_date', label: 'Cheque date', exportValue: (r) => day(r.che_date) },
  { key: 'che_amount', label: 'Amount', exportValue: (r) => money(r.che_amount) },
  { key: 'status', label: 'Status', exportValue: statusText },
];

/** Post-dated cheques on file. Replaces pdc_reminder_search.aspx. */
export function PdcPage() {
  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(pdc);
  const [editing, setEditing] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [confirming, setConfirming] = useState(null);
  const [search, setSearch] = useState('');
  const [ownerList, setOwnerList] = useState([]);

  // The legacy modal picked the owner from a list and filled the building and
  // wing from it; this page asked for a bare owner_id instead.
  useEffect(() => {
    let cancelled = false;
    residents
      .list()
      .then((d) => !cancelled && setOwnerList(d.items ?? []))
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  // The owner's contact block, fetched when one is picked. Read-only, exactly
  // as the legacy form left these boxes once it filled them.
  const [ownerDetails, setOwnerDetails] = useState(null);
  // Cheques already on file for that owner — GridView2 in the legacy modal.
  const [ownerCheques, setOwnerCheques] = useState([]);
  const chosenOwnerId = editing?.form.ownerId;

  useEffect(() => {
    if (!chosenOwnerId) {
      setOwnerCheques([]);
      return undefined;
    }
    let cancelled = false;
    pdc
      .forOwner(chosenOwnerId)
      .then((d) => !cancelled && setOwnerCheques(d.items ?? []))
      .catch(() => !cancelled && setOwnerCheques([]));
    return () => {
      cancelled = true;
    };
  }, [chosenOwnerId]);

  useEffect(() => {
    if (!chosenOwnerId) {
      setOwnerDetails(null);
      return undefined;
    }
    let cancelled = false;
    pdc
      .ownerDetails(chosenOwnerId)
      .then((d) => {
        if (cancelled) return;
        setOwnerDetails(d.owner ?? null);
        // wing_id travels with the owner, as it did on the legacy page —
        // asking for it separately invited a mismatch.
        if (d.owner?.wing_id != null) {
          setEditing((prev) =>
            prev ? { ...prev, form: { ...prev.form, wingId: d.owner.wing_id } } : prev,
          );
        }
      })
      .catch(() => !cancelled && setOwnerDetails(null));
    return () => {
      cancelled = true;
    };
  }, [chosenOwnerId]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
    setEditing((prev) => ({ ...prev, form: { ...prev.form, [key]: value } }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    // The form carries noValidate, so nothing enforced the asterisks — a
    // cheque with no number or date went straight to the API.
    const missing = validateFields(PDC_FIELDS, editing.form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(PDC_FIELDS, missing);
      return;
    }
    const body = {
      ...editing.form,
      ownerId: Number(editing.form.ownerId),
      wingId: editing.form.wingId ? Number(editing.form.wingId) : 0,
    };
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
    } catch {
      // Shown in the modal.
    }
  };

  const flag = (v, label) =>
    v ? <span className="rounded bg-slate-100 px-2 py-0.5 text-xs">{label}</span> : null;

  // pdc_reminder_search.aspx filtered the rendered table on keyup rather than
  // querying, so the same filtering happens here over the loaded rows.
  const term = search.trim().toLowerCase();
  const visible = term
    ? items.filter((r) =>
        [r.chqno, r.name, r.Unit, r.build_name].some((v) =>
          String(v ?? '').toLowerCase().includes(term),
        ),
      )
    : items;

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Post-dated cheques</h1>
          <p className="text-sm text-slate-500">
            {visible.length === items.length
              ? `${items.length} cheque(s) on file`
              : `${visible.length} of ${items.length} cheque(s)`}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <input
            className="field-input w-56"
            placeholder="Search cheques…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            aria-label="Search cheques"
          />
          <button
            type="button"
            className="btn-primary"
            onClick={() => setEditing({ id: null, form: { ...EMPTY } })}
          >
            Add cheque
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : visible.length === 0 ? (
          <EmptyState
            title={items.length ? 'No cheques match that search' : 'No cheques recorded'}
          />
        ) : (
          <>
            {/* The Export/PDF/Print set every legacy grid page carried; this
                screen builds its own table, so the toolbar is added here. */}
            <ExportToolbar
              columns={EXPORT_COLUMNS}
              rows={visible}
              exportName="post-dated-cheques"
              exportTitle="Post-dated cheques"
            />
            <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Cheque no.</th>
                  <th className="table-head">Resident</th>
                  <th className="table-head">Unit</th>
                  <th className="table-head">Cheque date</th>
                  <th className="table-head text-right">Amount</th>
                  <th className="table-head">Status</th>
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {visible.map((row) => (
                  <tr key={row.pdc_rem_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800">{row.chqno}</td>
                    <td className="table-cell">{row.name}</td>
                    <td className="table-cell">{row.Unit}</td>
                    <td className="table-cell">{day(row.che_date)}</td>
                    <td className="table-cell text-right">{money(row.che_amount)}</td>
                    <td className="table-cell space-x-1">
                      {flag(row.che_dep, 'Deposited')}
                      {flag(row.che_ret, 'Returned')}
                      {/* "Bounced" is what both legacy grids call che_can. */}
                      {flag(row.che_can, 'Bounced')}
                      {!row.che_dep && !row.che_ret && !row.che_can ? (
                        <span className="text-xs text-slate-500">Pending</span>
                      ) : null}
                    </td>
                    <td className="table-cell text-right">
                      <button
                        type="button"
                        className="btn-secondary"
                        onClick={() =>
                          setEditing({
                            id: row.pdc_rem_id,
                            form: {
                              ownerId: row.owner_id ?? '',
                              // Blank here meant every edit wrote wing_id back
                              // as 0, detaching the cheque from its wing.
                              wingId: row.wing_id ?? '',
                              chequeNo: row.chqno ?? '',
                              amount: row.che_amount ?? '',
                              chequeDate: row.che_date ? String(row.che_date).slice(0, 10) : '',
                              // Carried so a plain edit does not clear them —
                              // pdcParams defaults each to 0 when absent.
                              deposited: Boolean(row.che_dep),
                              returned: Boolean(row.che_ret),
                              cancelled: Boolean(row.che_can),
                            },
                          })
                        }
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        className="btn-danger ml-2"
                        onClick={() => setConfirming(row)}
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            </div>
          </>
        )}
      </div>

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Edit cheque' : 'Add cheque'}
        onClose={() => {
          setEditing(null);
          setError(null);
        }}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setEditing(null)} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="pdc-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="pdc-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <Field label="Owner" required name="ownerId" error={fieldErrors.ownerId}>
              <select
                className="field-input"
                value={editing.form.ownerId}
                onChange={setField('ownerId')}
                required
              >
                <option value="">Select…</option>
                {ownerList.map((o) => (
                  <option key={o.owner_id} value={o.owner_id}>
                    {o.name}
                    {o.Unit ? ` — ${o.Unit}` : ''}
                  </option>
                ))}
              </select>
            </Field>
            {/* Building-wing, mobile, address and email come from the owner
                and are left read-only — the legacy page disabled every one of
                these boxes after filling them, so the cheque cannot claim
                contact details the resident record disagrees with. */}
            <Field label="Building — wing" hint="From the selected owner.">
              <input
                className="field-input"
                value={
                  ownerDetails
                    ? [ownerDetails.build_name, ownerDetails.w_name].filter(Boolean).join(' — ')
                    : ''
                }
                readOnly
              />
            </Field>
            <Field label="Mobile no.">
              <input className="field-input" value={ownerDetails?.pre_mob ?? ''} readOnly />
            </Field>
            <Field label="Alternate mobile no.">
              <input className="field-input" value={ownerDetails?.alter_mob ?? ''} readOnly />
            </Field>
            <Field label="E-mail ID">
              <input className="field-input" value={ownerDetails?.email ?? ''} readOnly />
            </Field>
            <div className="sm:col-span-2">
              <Field label="Present address">
              <input className="field-input" value={ownerDetails?.pre_addr1 ?? ''} readOnly />
            </Field>
            </div>
            <div className="sm:col-span-2">
              <Field label="Present address 2">
              <input className="field-input" value={ownerDetails?.pre_add2 ?? ''} readOnly />
            </Field>
            </div>
            <Field label="Cheque number" required name="chequeNo" error={fieldErrors.chequeNo}>
              <input className="field-input" value={editing.form.chequeNo} onChange={setField('chequeNo')} required />
            </Field>
            <Field label="Amount" required name="amount" error={fieldErrors.amount}>
              <input className="field-input" type="number" step="0.01" value={editing.form.amount} onChange={setField('amount')} required />
            </Field>
            <Field label="Cheque date" required name="chequeDate" error={fieldErrors.chequeDate}>
              <input className="field-input" type="date" value={editing.form.chequeDate} onChange={setField('chequeDate')} required />
            </Field>
            {/* GridView2 in the legacy modal: the cheques already on file for
                this owner, so a duplicate is visible before one more is
                added. Read-only there and here — the flags are changed from
                the clearing screen, which also raises the receipt. */}
            {ownerCheques.length ? (
              <div className="sm:col-span-2">
                <h3 className="mb-2 text-sm font-semibold text-slate-800">
                  Cheques already on file
                </h3>
                <div className="overflow-x-auto rounded border border-slate-200">
                  <table className="min-w-full">
                    <thead>
                      <tr>
                        <th className="table-head">Cheque no.</th>
                        <th className="table-head">Cheque date</th>
                        <th className="table-head text-right">Amount</th>
                        <th className="table-head">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {ownerCheques.map((c) => (
                        <tr key={c.pdc_rem_id}>
                          <td className="table-cell font-medium text-slate-800">{c.chqno}</td>
                          <td className="table-cell">{day(c.che_date)}</td>
                          <td className="table-cell text-right">{money(c.che_amount)}</td>
                          <td className="table-cell space-x-1">
                            {flag(c.che_dep, 'Deposited')}
                            {flag(c.che_ret, 'Returned')}
                            {flag(c.che_can, 'Bounced')}
                            {!c.che_dep && !c.che_ret && !c.che_can ? (
                              <span className="text-xs text-slate-500">Pending</span>
                            ) : null}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ) : null}

            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete cheque"
        message={
          confirming
            ? `Delete cheque ${confirming.chqno} for ${money(confirming.che_amount)}?`
            : ''
        }
        confirmLabel="Delete"
        busy={saving}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          try {
            await remove(confirming.pdc_rem_id);
          } catch {
            // Reported by the page's error notice.
          } finally {
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

/**
 * The three outcomes a cheque can reach, as pdc_clearing.aspx recorded them.
 *
 * Exactly one applies at a time — the legacy checkboxes cleared the other two
 * when one was ticked — so they are radio buttons here rather than boxes that
 * can all be on at once.
 */
const CHEQUE_STATES = [
  { key: 'deposited', label: 'Deposited', field: 'che_dep' },
  { key: 'returned', label: 'Returned', field: 'che_ret' },
  { key: 'cancelled', label: 'Bounced', field: 'che_can' },
];

const stateOf = (row) =>
  CHEQUE_STATES.find((s) => Number(row[s.field]) === 1)?.key ?? '';

// The clearing grid names the resident differently from the reminder grid.
const CLEARING_EXPORT_COLUMNS = [
  { key: 'chqno', label: 'Cheque no.' },
  { key: 'owner_name', label: 'Resident' },
  { key: 'che_date', label: 'Cheque date', exportValue: (r) => day(r.che_date) },
  { key: 'che_amount', label: 'Amount', exportValue: (r) => money(r.che_amount) },
  { key: 'status', label: 'Status', exportValue: statusText },
];

/** Cheques falling due in a window. Replaces pdc_clearing.aspx. */
export function PdcClearingPage() {
  const [busyId, setBusyId] = useState(null);
  const [confirmDeposit, setConfirmDeposit] = useState(null);
  const [clearError, setClearError] = useState(null);
  const toast = useToast();

  /** Records the outcome. Depositing raises a receipt, so it is confirmed. */
  const applyState = async (row, key, reload) => {
    setBusyId(row.pdc_rem_id);
    setClearError(null);
    try {
      await pdc.clear(row.pdc_rem_id, {
        deposited: key === 'deposited',
        returned: key === 'returned',
        cancelled: key === 'cancelled',
        // The API refuses a deposit without this, because of the receipt.
        confirm: key === 'deposited',
      });
      await reload();
      // Depositing raises a receipt, so saying so matters more here than on an
      // ordinary save — the operator needs to know the money side happened.
      toast.success(
        key === 'deposited'
          ? `Cheque ${row.cheque_no} marked deposited. A receipt has been raised.`
          : `Cheque ${row.cheque_no} marked ${key}.`,
        { title: 'Updated' },
      );
    } catch (err) {
      setClearError(err);
      toast.error(err?.message ?? 'The cheque could not be updated. Please try again.');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <DateRangeReport
      title="Cheque clearing"
      subtitle="Cheques dated within the selected period"
      load={pdc.clearing}
      render={(d, { reload }) =>
        d.items.length === 0 ? (
          <EmptyState title="No cheques due in this period" />
        ) : (
          <div className="card overflow-hidden">
            <div className="px-4 pt-4 print:hidden">
              <ErrorNotice error={clearError} />
            </div>
            <ExportToolbar
              columns={CLEARING_EXPORT_COLUMNS}
              rows={d.items}
              exportName="cheque-clearing"
              exportTitle="Cheque clearing"
            />
            <div className="overflow-x-auto">
              <table className="min-w-full">
                <thead>
                  <tr>
                    <th className="table-head">Cheque no.</th>
                    <th className="table-head">Resident</th>
                    <th className="table-head">Cheque date</th>
                    <th className="table-head text-right">Amount</th>
                    {CHEQUE_STATES.map((s) => (
                      <th key={s.key} className="table-head text-center">
                        {s.label}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {d.items.map((r) => {
                    const current = stateOf(r);
                    return (
                      <tr key={r.pdc_rem_id}>
                        <td className="table-cell font-medium text-slate-800">{r.chqno}</td>
                        <td className="table-cell">{r.owner_name}</td>
                        <td className="table-cell">{day(r.che_date)}</td>
                        <td className="table-cell text-right">{money(r.che_amount)}</td>
                        {CHEQUE_STATES.map((s) => (
                          <td key={s.key} className="table-cell text-center">
                            <input
                              type="radio"
                              className="h-4 w-4"
                              // One group per cheque, so picking an outcome
                              // clears the other two — what the legacy
                              // CheckedChanged handlers did by hand.
                              name={`state-${r.pdc_rem_id}`}
                              checked={current === s.key}
                              disabled={busyId === r.pdc_rem_id}
                              aria-label={`${s.label} — cheque ${r.chqno}`}
                              onChange={() => {
                                if (s.key === 'deposited') setConfirmDeposit({ row: r, reload });
                                else applyState(r, s.key, reload);
                              }}
                            />
                          </td>
                        ))}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <ConfirmDialog
              open={Boolean(confirmDeposit)}
              title="Mark cheque deposited"
              // Depositing runs sp_receipt, which writes a real receipt and
              // moves the resident's dues — worth saying before it happens.
              message={
                confirmDeposit
                  ? `Marking cheque ${confirmDeposit.row.chqno} deposited raises a receipt for ${money(
                      confirmDeposit.row.che_amount,
                    )} against ${confirmDeposit.row.owner_name}. Continue?`
                  : ''
              }
              confirmLabel="Mark deposited"
              busy={busyId != null}
              onCancel={() => setConfirmDeposit(null)}
              onConfirm={async () => {
                const { row, reload: r } = confirmDeposit;
                setConfirmDeposit(null);
                await applyState(row, 'deposited', r);
              }}
            />
          </div>
        )
      }
    />
  );
}
