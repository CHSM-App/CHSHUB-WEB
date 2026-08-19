import { useMemo, useState } from 'react';
import { charges } from '@/api/settings';
import useCrudResource from '../masters/useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner, FormErrorSummary } from '@/components/ui.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';
import useSortedRows from '@/components/useSortedRows.js';
import { SortableHead, SortControl } from '@/components/SortableHead.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';

const EMPTY = { name: '', amount: '', chargesType: '1', active: true };

const TYPE_LABEL = { 1: 'Regular', 0: 'Add-on' };

/** charges_type comes back as a bit — normalise to 0/1. */
const typeOf = (row) => (row.charges_type === true || Number(row.charges_type) === 1 ? 1 : 0);

const toForm = (row) => ({
  name: row.NatureOfCharge ?? '',
  amount: row.amount ?? '',
  chargesType: String(typeOf(row)),
  active: row.status === true || Number(row.status) === 1,
});

/**
 * Maintenance charge heads. Each charge's amount is divided across the
 * society's flats when a bill is generated.
 */
/* What Submit insists on, in the shape validateFields expects. */
const CHARGE_FIELDS = [
  { name: 'name', label: 'Nature of charge', required: true },
  { name: 'amount', label: 'Amount', required: true },
  { name: 'chargesType', label: 'Charge type', type: 'select', required: true },
];

/*
 * Three of these cells don't show their raw field, so each says what it orders
 * by: type is a bit rendered as a word, status a bit rendered as a pill, and
 * amount arrives as a string that would otherwise sort 100 before 20.
 */
const COLUMNS = [
  { key: 'NatureOfCharge', label: 'Nature of charge' },
  { key: 'charges_type', label: 'Type', sortValue: (r) => TYPE_LABEL[typeOf(r)] },
  { key: 'amount', label: 'Amount', sortValue: (r) => Number(r.amount ?? 0) },
  {
    key: 'status',
    label: 'Status',
    sortValue: (r) => (r.status === true || Number(r.status) === 1 ? 'Active' : 'Inactive'),
  },
  {
    /*
     * The cell prints `Date` as it arrives rather than formatting it, so it may
     * be a real timestamp or a string the server already rendered. Parsing is
     * tried first and the raw value kept when it isn't a date, which at least
     * groups equal dates together instead of ordering by NaN.
     */
    key: 'Date',
    label: 'Created',
    sortValue: (r) => {
      if (!r.Date) return null;
      const t = new Date(r.Date).getTime();
      return Number.isNaN(t) ? String(r.Date) : t;
    },
  },
];

export default function ChargesPage() {
  const [typeFilter, setTypeFilter] = useState('');
  const params = useMemo(
    () => (typeFilter === '' ? undefined : { chargesType: typeFilter }),
    [typeFilter],
  );

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(charges, { params });

  const { sorted, sort, toggleSort } = useSortedRows(items, COLUMNS);

  // 25 to a page, as every other list — this table used to render every row.
  const paging = usePaging(sorted.length, 25);
  const visible = sorted.slice(paging.first, paging.first + paging.size);

  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  const openCreate = () => setEditing({ id: null, form: { ...EMPTY } });
  const openEdit = (row) => setEditing({ id: row.charge_id, form: toForm(row) });

  const closeForm = () => {
    setEditing(null);
    setError(null);
  };

  const setField = (key) => (e) => {
    const { value, type, checked } = e.target;
    setEditing((prev) => ({
      ...prev,
      form: { ...prev.form, [key]: type === 'checkbox' ? checked : value },
    }));
    // The complaint goes as soon as it is being answered.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    // The form carries noValidate, so nothing enforced the asterisks — an
    // empty save wrote a blank row. Same pass as every other screen.
    const missing = validateFields(CHARGE_FIELDS, editing.form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(CHARGE_FIELDS, missing);
      return;
    }
    try {
      if (editing.id) await update(editing.id, editing.form);
      else await create(editing.form);
      setEditing(null);
    } catch {
      // Shown in the modal.
    }
  };

  const onDeactivate = async () => {
    try {
      await remove(confirming.charge_id);
    } finally {
      setConfirming(null);
    }
  };

  /**
   * Put a spent charge back into the next run.
   *
   * An add-on is charged once — sp_new_maintenance switches its head off after
   * generating — so a levy that recurs, or one raised against the wrong month,
   * otherwise needed the edit form opened just to tick a box. Same PUT the form
   * sends, with the head's own values carried over so nothing else moves.
   */
  const onReactivate = async (row) => {
    try {
      await update(row.charge_id, { ...toForm(row), active: true });
    } catch {
      // Shown by the page-level notice.
    }
  };

  const total = items
    .filter((r) => r.status === true || Number(r.status) === 1)
    .reduce((sum, r) => sum + Number(r.amount || 0), 0);

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Maintenance charges</h1>
          <p className="text-sm text-slate-500">
            {items.length} head(s) · active total {total.toFixed(2)}
          </p>
        </div>
        <div className="flex gap-2">
          <select
            className="field-input w-44"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            aria-label="Filter by charge type"
          >
            <option value="">All types</option>
            <option value="1">Regular</option>
            <option value="0">Add-on</option>
          </select>
          <button type="button" className="btn-primary" onClick={openCreate}>
            Add charge
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState title="No charges configured" hint="Add a charge head to include it in bills." />
        ) : (
          <>
          <SortControl columns={COLUMNS} sort={sort} onSort={toggleSort} className="px-4 pb-2 pt-3" />
          <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {/* Row number, as every other list carries. */}
                  <th className="table-head w-px whitespace-nowrap">No.</th>
                  {COLUMNS.map((c) => (
                    <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
                  ))}
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {visible.map((row, i) => {
                  const isActive = row.status === true || Number(row.status) === 1;
                  return (
                    <tr key={row.charge_id} className="hover:bg-slate-50">
                      {/* Counts from the row's place in the whole list, so page
                          2 carries on rather than restarting at 1. */}
                      <td className="table-cell w-px whitespace-nowrap text-slate-500" data-label="No.">
                        {paging.first + i + 1}
                      </td>
                      <td className="table-cell font-medium text-slate-800" data-label="Nature of charge">{row.NatureOfCharge}</td>
                      <td className="table-cell" data-label="Type">{TYPE_LABEL[typeOf(row)]}</td>
                      <td className="table-cell" data-label="Amount">{Number(row.amount ?? 0).toFixed(2)}</td>
                      <td className="table-cell" data-label="Status">
                        <span
                          className={
                            isActive
                              ? 'rounded bg-green-50 px-2 py-0.5 text-xs font-medium text-green-700'
                              : 'rounded bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-500'
                          }
                        >
                          {isActive ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="table-cell" data-label="Created">{row.Date || '—'}</td>
                      <td className="table-cell whitespace-nowrap text-right" data-actions="">
                        <button type="button" className="btn-secondary mr-2" onClick={() => openEdit(row)}>
                          Edit
                        </button>
                        {isActive ? (
                          <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
                            Deactivate
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="btn-secondary"
                            disabled={saving}
                            onClick={() => onReactivate(row)}
                          >
                            Include in next bill
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <Pager
            page={paging.page}
            pageCount={paging.pageCount}
            first={paging.first}
            last={paging.last}
            total={sorted.length}
            onPage={paging.setPage}
          />
          </>
        )}
      </div>

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Edit charge' : 'Add charge'}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="charge-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="charge-form" onSubmit={onSubmit} className="grid gap-4" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <Field label="Nature of charge" required name="name" error={fieldErrors.name}>
              <input className="field-input" value={editing.form.name} onChange={setField('name')} required />
            </Field>
            <Field label="Amount" required name="amount" error={fieldErrors.amount} hint="Divided across all flats at bill generation">
              <input
                className="field-input"
                type="number"
                step="0.01"
                min="0"
                value={editing.form.amount}
                onChange={setField('amount')}
                required
              />
            </Field>
            <Field label="Charge type" required name="chargesType" error={fieldErrors.chargesType}>
              <select className="field-input" value={editing.form.chargesType} onChange={setField('chargesType')}>
                <option value="1">Regular — included in the monthly bill</option>
                <option value="0">Add-on — used for ad-hoc bills</option>
              </select>
            </Field>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-slate-300"
                checked={editing.form.active}
                onChange={setField('active')}
              />
              <span className="text-sm text-slate-700">Active — include in the next bill run</span>
            </label>
            <ErrorNotice error={error} />
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Deactivate charge"
        message={`Deactivate "${confirming?.NatureOfCharge}"? It will be excluded from future bills. Existing bills are unaffected.`}
        confirmLabel="Deactivate"
        onConfirm={onDeactivate}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
    </section>
  );
}
