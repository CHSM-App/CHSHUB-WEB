import { useEffect, useMemo, useState } from 'react';
import { flats } from '@/api/masters';
import useCrudResource from './useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner, FormErrorSummary } from '@/components/ui.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';
import useSortedRows from '@/components/useSortedRows.js';
import { SortableHead, SortControl } from '@/components/SortableHead.jsx';

/*
 * Flat numbers are text but read as numbers — the comparison is numeric-aware,
 * so A-9 lands before A-101 rather than after it. The two measures sort as
 * numbers so a blank sq. ft. doesn't order between two figures.
 */
const COLUMNS = [
  { key: 'flat_no', label: 'Flat no.' },
  { key: 'build_wing', label: 'Building / wing' },
  { key: 'flat_type', label: 'Type' },
  { key: 'bed', label: 'Bedrooms', sortValue: (r) => (r.bed == null || r.bed === '' ? null : Number(r.bed)) },
  { key: 'sq_ft', label: 'Sq. ft.', sortValue: (r) => (r.sq_ft == null || r.sq_ft === '' ? null : Number(r.sq_ft)) },
];

const EMPTY = {
  wingId: '',
  flatNo: '',
  flatTypeId: '',
  bedroomId: '',
  usageId: '',
  sqFt: '',
  terraceSqFt: '',
  intercomNo: '',
};

const toForm = (row) => ({
  wingId: row.wing_id ?? '',
  flatNo: row.flat_no ?? '',
  flatTypeId: row.flat_type_id ?? '',
  bedroomId: row.bed_id ?? '',
  usageId: row.usage_id ?? '',
  sqFt: row.sq_ft ?? '',
  terraceSqFt: row.terrace_sq_ft ?? '',
  intercomNo: row.intercom_no ?? '',
});

/* What Submit insists on, in the shape validateFields expects. */
const FLAT_FIELDS = [
  { name: 'wingId', label: 'Wing', type: 'select', required: true },
  { name: 'flatNo', label: 'Flat number', required: true },
  { name: 'bedroomId', label: 'Bedrooms', type: 'select', required: true },
  { name: 'usageId', label: 'Usage', type: 'select', required: true },
];

export default function FlatsPage() {
  const [wingFilter, setWingFilter] = useState('');
  const params = useMemo(() => ({ wingId: wingFilter || undefined }), [wingFilter]);

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(flats, { params });

  const { sorted, sort, toggleSort } = useSortedRows(items, COLUMNS);

  const [lookups, setLookups] = useState({ wings: [], flatTypes: [], usages: [], bedrooms: [] });
  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  useEffect(() => {
    let cancelled = false;
    flats
      .lookups()
      .then((data) => {
        if (!cancelled) setLookups(data);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  const openCreate = () => setEditing({ id: null, form: { ...EMPTY, wingId: wingFilter || '' } });
  const openEdit = (row) => setEditing({ id: row.flat_id, form: toForm(row) });

  const closeForm = () => {
    setEditing(null);
    setError(null);
  };

  // Read e.target.value eagerly — see ResidentsPage for the full explanation.
  const setField = (key) => (e) => {
    const { value } = e.target;
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
    setEditing((prev) => ({ ...prev, form: { ...prev.form, [key]: value } }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    // The form carries noValidate, so nothing enforced the asterisks — an
    // empty save wrote a blank row. Same pass as every other screen.
    const missing = validateFields(FLAT_FIELDS, editing.form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(FLAT_FIELDS, missing);
      return;
    }
    const f = editing.form;
    const body = {
      wingId: Number(f.wingId),
      flatNo: f.flatNo,
      flatTypeId: Number(f.flatTypeId),
      bedroomId: Number(f.bedroomId),
      usageId: Number(f.usageId),
      sqFt: f.sqFt,
      terraceSqFt: f.terraceSqFt,
      intercomNo: f.intercomNo,
    };
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
    } catch {
      // Rendered in the modal.
    }
  };

  const onDelete = async () => {
    try {
      await remove(confirming.flat_id);
    } finally {
      setConfirming(null);
    }
  };

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Flats</h1>
          <p className="text-sm text-slate-500">{items.length} record(s)</p>
        </div>
        <div className="flex gap-2">
          <select
            className="field-input w-56"
            value={wingFilter}
            onChange={(e) => setWingFilter(e.target.value)}
            aria-label="Filter by wing"
          >
            <option value="">All wings</option>
            {lookups.wings.map((w) => (
              <option key={w.wing_id} value={w.wing_id}>
                {w.name}
              </option>
            ))}
          </select>
          <button type="button" className="btn-primary" onClick={openCreate}>
            Add flat
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState title="No flats found" hint="Flats belong to a wing — add one to get started." />
        ) : (
          <>
          <SortControl columns={COLUMNS} sort={sort} onSort={toggleSort} className="px-4 pb-2 pt-3" />
          <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {COLUMNS.map((c) => (
                    <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
                  ))}
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {sorted.map((row) => (
                  <tr key={row.flat_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800" data-label="Flat no.">{row.flat_no}</td>
                    <td className="table-cell" data-label="Building / wing">{row.build_wing}</td>
                    <td className="table-cell" data-label="Type">{row.flat_type}</td>
                    <td className="table-cell" data-label="Bedrooms">{row.bed}</td>
                    <td className="table-cell" data-label="Sq. ft.">{row.sq_ft || '—'}</td>
                    <td className="table-cell whitespace-nowrap text-right" data-actions="">
                      <button type="button" className="btn-secondary mr-2" onClick={() => openEdit(row)}>
                        Edit
                      </button>
                      <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
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
        title={editing?.id ? 'Edit flat' : 'Add flat'}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="flat-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="flat-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <Field label="Wing" required name="wingId" error={fieldErrors.wingId}>
              <select className="field-input" value={editing.form.wingId} onChange={setField('wingId')} required>
                <option value="">Select a wing…</option>
                {lookups.wings.map((w) => (
                  <option key={w.wing_id} value={w.wing_id}>
                    {w.name}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Flat number" required name="flatNo" error={fieldErrors.flatNo}>
              <input className="field-input" value={editing.form.flatNo} onChange={setField('flatNo')} required />
            </Field>

            <Field
              label="Flat type"
              required
              // The update path in sp_flat_master never writes flat_type_id, so
              // the API rejects a change. Disable rather than let it fail on save.
              hint={editing.id ? 'Flat type cannot be changed after creation' : undefined}
            >
              <select
                className="field-input"
                value={editing.form.flatTypeId}
                onChange={setField('flatTypeId')}
                disabled={Boolean(editing.id)}
                required
              >
                <option value="">Select…</option>
                {lookups.flatTypes.map((t) => (
                  <option key={t.flat_type_id} value={t.flat_type_id}>
                    {t.flat_type}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Bedrooms" required name="bedroomId" error={fieldErrors.bedroomId}>
              <select
                className="field-input"
                value={editing.form.bedroomId}
                onChange={setField('bedroomId')}
                required
              >
                <option value="">Select…</option>
                {lookups.bedrooms.map((b) => (
                  <option key={b.bed_id} value={b.bed_id}>
                    {b.bed}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Usage" required name="usageId" error={fieldErrors.usageId}>
              <select className="field-input" value={editing.form.usageId} onChange={setField('usageId')} required>
                <option value="">Select…</option>
                {lookups.usages.map((u) => (
                  <option key={u.usage_id} value={u.usage_id}>
                    {u.usage}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Carpet area (sq. ft.)">
              <input className="field-input" value={editing.form.sqFt} onChange={setField('sqFt')} />
            </Field>
            <Field label="Terrace area (sq. ft.)">
              <input className="field-input" value={editing.form.terraceSqFt} onChange={setField('terraceSqFt')} />
            </Field>
            <Field label="Intercom number">
              <input className="field-input" value={editing.form.intercomNo} onChange={setField('intercomNo')} />
            </Field>

            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete flat"
        message={`Delete flat "${confirming?.flat_no}"? Any assigned owner must be removed first.`}
        onConfirm={onDelete}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
    </section>
  );
}
