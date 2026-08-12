import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import useCrudResource from './masters/useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';
import { FileUploadField } from '@/components/FormControls.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import RichTextField from '@/components/RichTextField.jsx';

/**
 * One implementation behind most list/edit screens.
 *
 * The legacy app repeats the same page shape — searchable grid, modal form,
 * soft delete — across dozens of masters. Rather than clone that markup, each
 * screen is described declaratively:
 *
 *   columns : [{ key, label, format?, exportValue?, printHidden? }]
 *             format is (value, row, index); printHidden drops the column from
 *             the printed sheet, for one whose cell is only a control.
 *   fields  : [{ name, label, type?, required?, options?, hint?, span?, showIf?,
 *               placeholder?, maxLength?, digits? }]
 *             maxLength stops the input at the column's width; digits admits
 *             0-9 only, as the legacy onkeypress filters did.
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
  filterRow,
  canCreate = true,
  canEdit = true,
  canDelete = true,
  deleteLabel = 'Delete',
  deleteMessage,
  emptyHint,
  lookups: lookupLoaders,
  formActions,
}) {
  const [search, setSearch] = useState('');
  const deferred = useDeferredValue(search);
  // `filterRow` screens narrow the loaded rows in the browser — their endpoint
  // has no search parameter, so sending one would only refetch the same list on
  // every keystroke. Same convention as MasterScreen.
  const params = useMemo(
    () => (searchable && !filterRow && deferred ? { search: deferred } : undefined),
    [searchable, filterRow, deferred],
  );

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(resource, { params });

  const rows = useMemo(() => {
    const term = deferred.trim().toLowerCase();
    if (!filterRow || !term) return items;
    return items.filter((r) => filterRow(r, term));
  }, [items, deferred, filterRow]);

  const [lookups, setLookups] = useState({});
  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

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

  const openCreate = () => {
    setFieldErrors({});
    setEditing({ id: null, form: { ...blank } });
  };
  const openEdit = (row) => {
    setFieldErrors({});
    setEditing({ id: row[idKey], form: rowToForm(row) });
  };

  const closeForm = () => {
    setEditing(null);
    setFieldErrors({});
    setError(null);
  };

  const setField = (key, field) => (e) => {
    const { value, type, checked } = e.target;
    let next = type === 'checkbox' ? checked : value;
    /*
     * A `digits` field takes 0-9 only, trimmed to maxLength. The legacy pages
     * did this with an onkeypress that swallowed other characters; doing it on
     * the value catches a paste as well, which that filter never saw.
     */
    if (field?.digits && type !== 'checkbox') {
      next = String(next).replace(/\D/g, '');
      if (field.maxLength) next = next.slice(0, field.maxLength);
    }
    setEditing((prev) => ({
      ...prev,
      form: { ...prev.form, [key]: next },
    }));
    // Clear the field's complaint as soon as it is being answered, rather than
    // leaving it up until the next submit.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    /*
     * The form carries `noValidate`, so the browser never enforces the
     * `required` inputs — a red asterisk was the only sign a field was
     * mandatory, and submitting with one blank saved it empty. Check them
     * here and name the offending field, the way the legacy pages' own
     * "Please Enter Name" feedback did.
     *
     * Only fields actually on screen count: a `showIf` field that is hidden
     * is not rendered, so its value cannot be supplied.
     */
    const missing = {};
    for (const f of fields) {
      if (!f.required) continue;
      if (f.showIf && !f.showIf(editing.form)) continue;
      const v = editing.form[f.name];
      if (v === null || v === undefined || String(v).trim() === '') {
        missing[f.name] = `${f.label} is required`;
      }
    }
    setFieldErrors(missing);
    if (Object.keys(missing).length) return;

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

  // `index` is passed through for the legacy grids' serial-number column, which
  // numbered rows off the grid position rather than any data field.
  const renderCell = (col, row, index) => {
    const raw = row[col.key];
    if (col.format) return col.format(raw, row, index);
    if (raw === null || raw === undefined || raw === '') return '—';
    return String(raw);
  };

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        {/* On paper the title is the sheet's own heading, so it centres over
            the table; on screen it stays left, beside the controls. */}
        <div className="print:w-full print:text-center">
          <h1 className="text-lg font-semibold text-slate-800">{title}</h1>
          {/* A screen affordance — how much the search narrowed the list. The
              printed sheet carries the records themselves. */}
          <p className="text-sm text-slate-500 print:hidden">
            {subtitle ??
              (rows.length === items.length
                ? `${items.length} record(s)`
                : `${rows.length} of ${items.length} record(s)`)}
          </p>
        </div>
        {/* Controls, not content: the printed sheet keeps the heading and the
            table but not the box used to narrow them. */}
        <div className="flex gap-2 print:hidden">
          {searchable || filterRow ? (
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
        ) : rows.length === 0 ? (
          <EmptyState title={`No ${title.toLowerCase()} found`} hint={emptyHint} />
        ) : (
          <>
            {/* The legacy pages' Print / export buttons. DataGrid has carried
                these all along; the screens rendered here had no equivalent.
                Outside the scroll box so it stays put on a narrow screen. */}
            <ExportToolbar
              columns={columns}
              rows={rows}
              exportName={title.toLowerCase().replace(/\s+/g, '-')}
              exportTitle={title}
            />
            <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  {columns.map((c) => (
                    <th
                      key={c.key}
                      className={`table-head${c.printHidden ? ' print:hidden' : ''}`}
                    >
                      {c.label}
                    </th>
                  ))}
                  {/* The Edit/Delete column: its buttons are already dropped in
                      print, which left an empty column ruled to the page edge. */}
                  {(canEdit && fields.length) || canDelete ? (
                    <th className="table-head sr-only print:hidden">Actions</th>
                  ) : null}
                </tr>
              </thead>
              <tbody>
                {rows.map((row, i) => (
                  <tr key={row[idKey] ?? i} className="hover:bg-slate-50">
                    {columns.map((c, ci) => (
                      <td
                        key={c.key}
                        className={`${ci === 0 ? 'table-cell font-medium text-slate-800' : 'table-cell'}${
                          c.printHidden ? ' print:hidden' : ''
                        }`}
                      >
                        {renderCell(c, row, i)}
                      </td>
                    ))}
                    {(canEdit && fields.length) || canDelete ? (
                      <td className="table-cell whitespace-nowrap text-right print:hidden">
                        {/* gap-2 rather than a margin on the first button, so the
                            spacing matches DataGrid's action column. */}
                        <div className="flex items-center justify-end gap-2">
                          {canEdit && fields.length ? (
                            <button type="button" className="btn-secondary" onClick={() => openEdit(row)}>
                              Edit
                            </button>
                          ) : null}
                          {canDelete ? (
                            <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
                              {deleteLabel}
                            </button>
                          ) : null}
                        </div>
                      </td>
                    ) : null}
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
        title={`${editing?.id ? 'Edit' : 'Add'} — ${title}`}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            {/* Screens whose legacy modal carried a Print button next to Save.
                Given the loaded lookups too, so an action can resolve an id
                field back to the name the user picked. */}
            {formActions?.(editing?.form, { close: closeForm, lookups })}
            <button type="submit" form="generic-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="generic-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            {fields.map((f) => {
              // `showIf` mirrors the legacy pages' conditional panels — the ones
              // that swapped inputs in and out as a dropdown changed. A hidden
              // field is not rendered, so its `required` cannot block the save.
              if (f.showIf && !f.showIf(editing.form)) return null;
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
              // Renders its own label and toolbar, so it sits outside <Field>
              // like the upload control does.
              if (f.type === 'richtext') {
                return (
                  <RichTextField
                    key={f.name}
                    label={f.label}
                    required={f.required}
                    hint={f.hint}
                    maxLength={f.maxLength}
                    className={span}
                    value={editing.form[f.name] ?? ''}
                    onChange={(html) =>
                      setEditing((p) => ({ ...p, form: { ...p.form, [f.name]: html } }))
                    }
                  />
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
                  <Field label={f.label} required={f.required} hint={f.hint} error={fieldErrors[f.name]}>
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
                        placeholder={f.placeholder}
                        value={editing.form[f.name] ?? ''}
                        onChange={setField(f.name)}
                        required={f.required}
                      />
                    ) : (
                      <input
                        className="field-input"
                        type={f.type ?? 'text'}
                        step={f.type === 'number' ? f.step ?? 'any' : undefined}
                        placeholder={f.placeholder}
                        value={editing.form[f.name] ?? ''}
                        onChange={setField(f.name, f)}
                        required={f.required}
                        // The legacy pages' MaxLength — the field stops taking
                        // characters at the limit rather than letting the user
                        // type past it and refusing the whole save afterwards.
                        maxLength={f.maxLength}
                        // `digits` fields carried an onkeypress that admitted
                        // 0-9 only. A number input would bring a spinner and
                        // accept "e"/"-", so it stays a text input with a
                        // numeric keypad on mobile.
                        inputMode={f.digits ? 'numeric' : undefined}
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
          // The dialog stays mounted while closed, when `confirming` is null —
          // so a screen whose deleteMessage reads fields off the row threw on
          // every render until one was picked.
          confirming && deleteMessage
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
