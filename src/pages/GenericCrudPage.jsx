import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import useCrudResource from './masters/useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';
import { FileUploadField } from '@/components/FormControls.jsx';

/**
 * One implementation behind most list/edit screens.
 *
 * The legacy app repeats the same page shape — searchable grid, modal form,
 * soft delete — across dozens of masters. Rather than clone that markup, each
 * screen is described declaratively:
 *
 *   columns : [{ key, label, format? }]
 *   fields  : [{ name, label, type?, required?, options?, hint?, span? }]
 *   toForm  : (row) => form values          (defaults to identity-by-field-name)
 *   idKey   : primary-key column
 *
 * Screens with genuinely bespoke behaviour (bills, receipts, helpdesk) keep
 * their own components.
 */
export default function GenericCrudPage({
  title,
  subtitle,
  headerActions,
  children,
  resource,
  idKey = 'id',
  columns,
  fields = [],
  toForm,
  toBody,
  searchable = true,
  canCreate = true,
  canEdit = true,
  canDelete = true,
  deleteLabel = 'Delete',
  deleteMessage,
  emptyHint,
  lookups: lookupLoaders,
}) {
  const [search, setSearch] = useState('');
  const deferred = useDeferredValue(search);
  const params = useMemo(
    () => (searchable && deferred ? { search: deferred } : undefined),
    [searchable, deferred],
  );

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(resource, { params });

  const [lookups, setLookups] = useState({});
  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);

  // Dropdown data, loaded once. Each entry is name -> () => Promise<rows>.
  useEffect(() => {
    if (!lookupLoaders) return undefined;
    let cancelled = false;
    Promise.all(
      Object.entries(lookupLoaders).map(([key, load]) =>
        load()
          .then((data) => [key, data.items ?? data])
          .catch(() => [key, []]),
      ),
    ).then((pairs) => {
      if (!cancelled) setLookups(Object.fromEntries(pairs));
    });
    return () => {
      cancelled = true;
    };
  }, [lookupLoaders]);

  const blank = useMemo(
    () => Object.fromEntries(fields.map((f) => [f.name, f.type === 'checkbox' ? false : ''])),
    [fields],
  );

  const rowToForm = (row) =>
    toForm ? toForm(row) : Object.fromEntries(fields.map((f) => [f.name, row[f.name] ?? '']));

  const openCreate = () => setEditing({ id: null, form: { ...blank } });
  const openEdit = (row) => setEditing({ id: row[idKey], form: rowToForm(row) });

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
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    const body = toBody ? toBody(editing.form) : editing.form;
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
    } catch {
      // Rendered inside the modal.
    }
  };

  const onDelete = async () => {
    try {
      await remove(confirming[idKey]);
    } finally {
      setConfirming(null);
    }
  };

  const renderCell = (col, row) => {
    const raw = row[col.key];
    if (col.format) return col.format(raw, row);
    if (raw === null || raw === undefined || raw === '') return '—';
    return String(raw);
  };

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">{title}</h1>
          <p className="text-sm text-slate-500">{subtitle ?? `${items.length} record(s)`}</p>
        </div>
        <div className="flex gap-2">
          {searchable ? (
            <input
              className="field-input w-56"
              placeholder="Search…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              aria-label={`Search ${title}`}
            />
          ) : null}
          {canCreate && fields.length ? (
            <button type="button" className="btn-primary" onClick={openCreate}>
              Add
            </button>
          ) : null}
          {/* Screens whose legacy page carried an extra toolbar button — e.g.
              park_place_search.aspx's "import data" — pass it in here. */}
          {headerActions}
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
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
                  {(canEdit && fields.length) || canDelete ? (
                    <th className="table-head sr-only">Actions</th>
                  ) : null}
                </tr>
              </thead>
              <tbody>
                {items.map((row, i) => (
                  <tr key={row[idKey] ?? i} className="hover:bg-slate-50">
                    {columns.map((c, ci) => (
                      <td
                        key={c.key}
                        className={ci === 0 ? 'table-cell font-medium text-slate-800' : 'table-cell'}
                      >
                        {renderCell(c, row)}
                      </td>
                    ))}
                    {(canEdit && fields.length) || canDelete ? (
                      <td className="table-cell whitespace-nowrap text-right">
                        {canEdit && fields.length ? (
                          <button type="button" className="btn-secondary mr-2" onClick={() => openEdit(row)}>
                            Edit
                          </button>
                        ) : null}
                        {canDelete ? (
                          <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
                            {deleteLabel}
                          </button>
                        ) : null}
                      </td>
                    ) : null}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal
        open={Boolean(editing)}
        title={`${editing?.id ? 'Edit' : 'Add'} — ${title}`}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="generic-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="generic-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            {fields.map((f) => {
              const span = f.span === 2 ? 'sm:col-span-2' : '';
              if (f.type === 'checkbox') {
                return (
                  <label key={f.name} className={`flex items-center gap-2 ${span}`}>
                    <input
                      type="checkbox"
                      className="h-4 w-4 rounded border-slate-300"
                      checked={Boolean(editing.form[f.name])}
                      onChange={setField(f.name)}
                    />
                    <span className="text-sm text-slate-700">{f.label}</span>
                  </label>
                );
              }
              // Uploads render their own label and current-file state, so they
              // sit outside the <Field> wrapper.
              if (f.type === 'file') {
                return (
                  <FileUploadField
                    key={f.name}
                    label={f.label}
                    category={f.category}
                    className={span}
                    currentPath={editing.form[f.name]}
                    onUploaded={(uploaded) =>
                      uploaded &&
                      setEditing((p) => ({ ...p, form: { ...p.form, [f.name]: uploaded.path } }))
                    }
                  />
                );
              }
              return (
                <div key={f.name} className={span}>
                  <Field label={f.label} required={f.required} hint={f.hint}>
                    {f.type === 'select' ? (
                      <select
                        className="field-input"
                        value={editing.form[f.name] ?? ''}
                        onChange={setField(f.name)}
                        required={f.required}
                      >
                        <option value="">Select…</option>
                        {(f.options ?? lookups[f.lookup] ?? []).map((o) => (
                          <option key={o[f.optionValue ?? 'id']} value={o[f.optionValue ?? 'id']}>
                            {o[f.optionLabel ?? 'name']}
                          </option>
                        ))}
                      </select>
                    ) : f.type === 'textarea' ? (
                      <textarea
                        className="field-input min-h-[6rem]"
                        value={editing.form[f.name] ?? ''}
                        onChange={setField(f.name)}
                        required={f.required}
                      />
                    ) : (
                      <input
                        className="field-input"
                        type={f.type ?? 'text'}
                        step={f.type === 'number' ? f.step ?? 'any' : undefined}
                        value={editing.form[f.name] ?? ''}
                        onChange={setField(f.name)}
                        required={f.required}
                      />
                    )}
                  </Field>
                </div>
              );
            })}
            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={`${deleteLabel} record`}
        message={
          deleteMessage
            ? deleteMessage(confirming)
            : `${deleteLabel} this record? This cannot be undone from the app.`
        }
        confirmLabel={deleteLabel}
        onConfirm={onDelete}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
      {/* Extra dialogs a screen needs alongside the standard CRUD ones. */}
      {children}
    </section>
  );
}
