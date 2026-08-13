import { useEffect, useMemo, useState } from 'react';
import { buildings as buildingsApi, wings } from '@/api/masters';
import useCrudResource from './useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner, FormErrorSummary } from '@/components/ui.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

/* What Submit insists on, in the shape validateFields expects. */
const WING_FIELDS = [
  { name: 'buildingId', label: 'Building', type: 'select', required: true },
  { name: 'name', label: 'Wing name', required: true },
];

export default function WingsPage() {
  const [buildingFilter, setBuildingFilter] = useState('');
  const params = useMemo(
    () => ({ buildingId: buildingFilter || undefined }),
    [buildingFilter],
  );

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(wings, { params });

  const [buildingOptions, setBuildingOptions] = useState([]);
  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  // Buildings populate both the filter and the form's parent selector.
  useEffect(() => {
    let cancelled = false;
    buildingsApi
      .list()
      .then((data) => {
        if (!cancelled) setBuildingOptions(data?.items ?? []);
      })
      .catch(() => {
        if (!cancelled) setBuildingOptions([]);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const openCreate = () =>
    setEditing({ id: null, form: { name: '', buildingId: buildingFilter || '' } });

  const openEdit = (row) =>
    setEditing({ id: row.wing_id, form: { name: row.w_name ?? '', buildingId: row.build_id ?? '' } });

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
    const missing = validateFields(WING_FIELDS, editing.form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(WING_FIELDS, missing);
      return;
    }
    const body = { name: editing.form.name, buildingId: Number(editing.form.buildingId) };
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
    } catch {
      // Shown inside the modal.
    }
  };

  const onDelete = async () => {
    try {
      await remove(confirming.wing_id);
    } finally {
      setConfirming(null);
    }
  };

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Wings</h1>
          <p className="text-sm text-slate-500">{items.length} record(s)</p>
        </div>
        <div className="flex gap-2">
          <select
            className="field-input w-56"
            value={buildingFilter}
            onChange={(e) => setBuildingFilter(e.target.value)}
            aria-label="Filter by building"
          >
            <option value="">All buildings</option>
            {buildingOptions.map((b) => (
              <option key={b.build_id} value={b.build_id}>
                {b.name}
              </option>
            ))}
          </select>
          <button type="button" className="btn-primary" onClick={openCreate}>
            Add wing
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState title="No wings found" hint="Wings belong to a building — add one to get started." />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Wing</th>
                  <th className="table-head">Building</th>
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((row) => (
                  <tr key={row.wing_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800">{row.w_name}</td>
                    <td className="table-cell">{row.name}</td>
                    <td className="table-cell whitespace-nowrap text-right">
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
        )}
      </div>

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Edit wing' : 'Add wing'}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="wing-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="wing-form" onSubmit={onSubmit} className="grid gap-4" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <Field label="Building" required name="buildingId" error={fieldErrors.buildingId}>
              <select
                className="field-input"
                value={editing.form.buildingId}
                onChange={setField('buildingId')}
                required
              >
                <option value="">Select a building…</option>
                {buildingOptions.map((b) => (
                  <option key={b.build_id} value={b.build_id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Wing name" required name="name" error={fieldErrors.name}>
              <input className="field-input" value={editing.form.name} onChange={setField('name')} required />
            </Field>
            <ErrorNotice error={error} />
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete wing"
        message={`Delete wing "${confirming?.w_name}"? Its flats must be removed first.`}
        onConfirm={onDelete}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
    </section>
  );
}
