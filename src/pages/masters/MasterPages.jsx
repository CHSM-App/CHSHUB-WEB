import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import * as M from '@/api/modules';
import { flats } from '@/api/masters';
import { api } from '@/api/client';
import DataGrid from '@/components/DataGrid.jsx';
import {
  openableUrl,
  unopenableReason,
  needsAuth,
  fetchProtectedUrl,
  revokeBlobUrl,
} from '@/lib/storedFile';
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
  singularise,
} from '@/components/formValidation.js';
import {
  CheckboxField,
  FileUploadField,
  PageHeader,
  SelectField,
  StatCard,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');
const toDateInput = (v) => (v ? String(v).slice(0, 10) : '');

/**
 * A yyyy-mm-dd date shifted forward by whole months, as SQL Server's DATEADD
 * does it — 31 Jan + 1 month is 28 Feb, not 3 March. `Date.setMonth` overflows
 * into the next month instead, so the day is clamped to the target month's
 * length. Kept in step with the grid's DATEADD(MONTH, ...) column.
 */
function addMonths(date, months) {
  const s = String(date ?? '').slice(0, 10);
  const n = Number(months);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s) || !Number.isFinite(n)) return '';

  const [y, m, d] = s.split('-').map(Number);
  const target = new Date(Date.UTC(y, m - 1 + n, 1));
  const lastDay = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(d, lastDay));
  return target.toISOString().slice(0, 10);
}

/**
 * Shared scaffold for the master screens: search, grid, modal form, delete.
 *
 * Unlike the earlier GenericCrudPage this uses DataGrid (sorting, paging, CSV
 * export) and renders fields through the FormControls set, so every screen gets
 * the same production behaviour without being written out per page.
 */
/**
 * The default delete prompt: quotes the row's first column, which is the
 * identifying one on every screen, so the user can see what they are about to
 * destroy without cancelling to go and re-read it.
 */
function describeDeletion(row, columns, deleteLabel) {
  const identifier = row?.[columns?.[0]?.key];
  const consequence = 'This cannot be undone from the app.';
  if (identifier === null || identifier === undefined || String(identifier).trim() === '') {
    return `${deleteLabel} this record? ${consequence}`;
  }
  return `${deleteLabel} “${String(identifier).trim()}”? ${consequence}`;
}

function MasterScreen({
  title,
  resource,
  idKey,
  columns,
  fields,
  toForm,
  toBody,
  lookupLoaders,
  stats,
  searchable = true,
  canCreate = true,
  canDelete = true,
  deleteLabel = 'Delete',
  deleteMessage,
  validate,
  emptyHint,
  extraActions,
  headerActions,
  filterRow,
}) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [search, setSearch] = useState('');
  const [lookups, setLookups] = useState({});
  const [form, setForm] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const toast = useToast();
  // "Buildings" is the screen; "Building" is what a toast just saved.
  const recordLabel = singularise(title);

  // `filterRow` screens narrow the loaded rows in the browser, so the term is
  // not a query parameter. It is also kept out of the dependencies below:
  // leaving it in rebuilt `load` on every keystroke, and the effect that calls
  // it refetched the whole list each time — for a search the server never sees.
  const queryTerm = filterRow ? '' : search;

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await resource.list(queryTerm ? { search: queryTerm } : undefined);
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [resource, queryTerm]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    if (!lookupLoaders) return;
    Promise.all(
      Object.entries(lookupLoaders).map(([k, fn]) =>
        fn()
          .then((d) => [k, d.items ?? d])
          .catch(() => [k, []]),
      ),
    ).then((pairs) => setLookups(Object.fromEntries(pairs)));
  }, [lookupLoaders]);

  const blank = useMemo(
    () => Object.fromEntries(fields.map((f) => [f.name, f.default ?? ''])),
    [fields],
  );

  const visibleRows = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!filterRow || !term) return rows;
    return rows.filter((r) => filterRow(r, term));
  }, [rows, search, filterRow]);

  const setField = (key, field) => (e) => {
    const { value, type, checked } = e.target;
    let next = type === 'checkbox' ? checked : value;
    /*
     * A `digits` field takes 0-9 only, trimmed to maxLength — the same filter
     * GenericCrudPage applies. Doing it on the value catches a paste as well,
     * which the legacy onkeypress never saw.
     */
    if (field?.digits && type !== 'checkbox') {
      next = String(next).replace(/\D/g, '');
      if (field.maxLength) next = next.slice(0, field.maxLength);
    }
    setForm((prev) => ({ ...prev, [key]: next }));
    // Clear the field's complaint as soon as it is being answered, rather than
    // leaving it up until the next submit.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  // Opening and closing both reset the complaints, so a dialog dismissed with
  // errors up does not reopen still showing them.
  const openForm = (values) => {
    setFieldErrors({});
    setError(null);
    setForm(values);
  };
  const closeForm = () => {
    setFieldErrors({});
    setError(null);
    setForm(null);
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    /*
     * The same required-field pass GenericCrudPage runs, so both families of
     * screen reject an empty form the same way. This used to be a single
     * banner from `validate`, which named one problem at a time and left the
     * offending input looking untouched.
     *
     * `validate` still runs, for the cross-field rules a per-field check
     * cannot express ("a rented flat needs a tenant"); it keeps the banner.
     */
    const missing = validateFields(fields, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(fields, missing);
      return;
    }

    const message = validate?.(form);
    if (message) {
      setError(new Error(message));
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const body = toBody ? toBody(form) : form;
      const wasEdit = Boolean(form.__id);
      if (wasEdit) await resource.update(form.__id, body);
      else await resource.create(body);
      closeForm();
      await load();
      // These screens call the resource directly rather than going through
      // useCrudResource, so the confirmation is raised here — same wording as
      // every other list screen.
      toast.success(`${recordLabel} ${wasEdit ? 'updated' : 'added'} successfully.`, {
        title: 'Saved',
      });
    } catch (err) {
      setError(err);
      toast.error('Your changes were not saved. Please check the form and try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <section>
      <PageHeader
        title={title}
        subtitle={
          visibleRows.length === rows.length
            ? `${rows.length} record(s)`
            : `${visibleRows.length} of ${rows.length} record(s)`
        }
      >
        {searchable ? (
          <input
            className="field-input w-56"
            placeholder={`Search ${title.toLowerCase()}…`}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            aria-label={`Search ${title}`}
          />
        ) : null}
        {/* Screens whose legacy page carried an extra toolbar button. */}
        {headerActions}
        {canCreate ? (
          <button type="button" className="btn-primary" onClick={() => openForm({ ...blank })}>
            Add
          </button>
        ) : null}
      </PageHeader>

      {stats ? <div className="mb-4 grid gap-3 sm:grid-cols-3">{stats(rows)}</div> : null}

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={visibleRows}
          idKey={idKey}
          loading={loading}
          exportName={title.toLowerCase().replace(/\s+/g, '-')}
          emptyTitle={`No ${title.toLowerCase()} found`}
          emptyHint={emptyHint}
          actions={(row) => (
            <>
              {extraActions?.(row, { reload: load })}
              {/* Compact, so screens with extra actions still fit one line. */}
              <button
                type="button"
                className="btn-secondary px-2 text-xs"
                onClick={() => openForm({ ...toForm(row), __id: row[idKey] })}
              >
                Edit
              </button>
              {canDelete ? (
                <button
                  type="button"
                  className="btn-danger px-2 text-xs"
                  onClick={() =>
                    setConfirming({
                      title: `${deleteLabel} record`,
                      // Names the row being destroyed rather than asking about
                      // "this record" — see the same fallback in
                      // GenericCrudPage for why the first column identifies it.
                      message: deleteMessage?.(row) ?? describeDeletion(row, columns, deleteLabel),
                      run: () => resource.remove(row[idKey]),
                    })
                  }
                >
                  {deleteLabel}
                </button>
              ) : null}
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(form)}
        title={`${form?.__id ? 'Edit' : 'Add'} — ${title}`}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="master-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="master-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            {fields.map((f) => {
              // Values computed from other fields, recalculated as they change
              // — the legacy pages did this with an AutoPostBack per input.
              const derived = f.derive ? f.derive(form) : undefined;
              const span = f.span === 2 ? 'sm:col-span-2' : '';
              const common = {
                key: f.name,
                label: f.label,
                name: f.name,
                required: f.required,
                hint: f.hint,
                // The controls already render the message and set aria-invalid
                // — they were simply never given anything to show.
                error: fieldErrors[f.name],
                className: span,
                value: derived !== undefined ? derived : (form[f.name] ?? ''),
                onChange: setField(f.name, f),
              };
              if (f.type === 'select') {
                return (
                  <SelectField
                    {...common}
                    options={f.options ?? lookups[f.lookup] ?? []}
                    valueKey={f.optionValue ?? 'value'}
                    labelKey={f.optionLabel ?? 'label'}
                  />
                );
              }
              if (f.type === 'textarea') return <TextAreaField {...common} rows={f.rows ?? 3} />;
              if (f.type === 'checkbox') {
                return (
                  <CheckboxField
                    key={f.name}
                    label={f.label}
                    name={f.name}
                    className={span}
                    checked={Boolean(form[f.name])}
                    onChange={setField(f.name, f)}
                  />
                );
              }
              if (f.type === 'file') {
                return (
                  <FileUploadField
                    key={f.name}
                    label={f.label}
                    category={f.category}
                    className={span}
                    currentPath={form[f.name]}
                    onUploaded={(uploaded) =>
                      uploaded && setForm((p) => ({ ...p, [f.name]: uploaded.path }))
                    }
                  />
                );
              }
              return (
                <TextField
                  {...common}
                  type={f.type ?? 'text'}
                  step={f.step}
                  readOnly={f.readOnly}
                  // The field stops taking characters at the limit rather than
                  // letting the user type past it and refusing the whole save
                  // afterwards. A numeric keypad on mobile for digits fields;
                  // not type="number", which brings a spinner and accepts "e".
                  maxLength={f.maxLength}
                  inputMode={f.digits ? 'numeric' : undefined}
                />
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
        title={confirming?.title}
        message={confirming?.message}
        confirmLabel={deleteLabel}
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
            // This screen calls the resource directly rather than going through
            // useCrudResource, so the confirmation is raised here.
            toast.success(`${recordLabel} deleted successfully.`, { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The record could not be deleted. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

/* --------------------------------------------------------------- flats */

export function FlatsMasterPage() {
  const [lookups, setLookups] = useState({ wings: [], flatTypes: [], usages: [], bedrooms: [] });

  useEffect(() => {
    flats
      .lookups()
      .then(setLookups)
      .catch(() => {});
  }, []);

  return (
    <MasterScreen
      title="Flats"
      resource={flats}
      idKey="flat_id"
      columns={[
        { key: 'flat_no', label: 'Flat no.' },
        { key: 'build_wing', label: 'Building / wing' },
        { key: 'flat_type', label: 'Type' },
        { key: 'bed', label: 'Bedrooms' },
        { key: 'usage', label: 'Usage' },
        { key: 'sq_ft', label: 'Carpet (sq ft)', align: 'right' },
        { key: 'terrace_sq_ft', label: 'Terrace', align: 'right' },
        { key: 'intercom_no', label: 'Intercom' },
      ]}
      fields={[
        {
          name: 'wingId',
          label: 'Wing',
          type: 'select',
          required: true,
          options: lookups.wings,
          optionValue: 'wing_id',
          optionLabel: 'name',
        },
        { name: 'flatNo', label: 'Flat number', required: true },
        {
          name: 'flatTypeId',
          label: 'Flat type',
          type: 'select',
          required: true,
          options: lookups.flatTypes,
          optionValue: 'flat_type_id',
          optionLabel: 'flat_type',
          hint: 'Cannot be changed after creation',
        },
        {
          name: 'bedroomId',
          label: 'Bedrooms',
          type: 'select',
          required: true,
          options: lookups.bedrooms,
          optionValue: 'bed_id',
          optionLabel: 'bed',
        },
        {
          name: 'usageId',
          label: 'Usage',
          type: 'select',
          required: true,
          options: lookups.usages,
          optionValue: 'usage_id',
          optionLabel: 'usage',
        },
        { name: 'sqFt', label: 'Carpet area (sq ft)' },
        { name: 'terraceSqFt', label: 'Terrace area (sq ft)' },
        { name: 'intercomNo', label: 'Intercom number' },
      ]}
      toForm={(r) => ({
        wingId: r.wing_id ?? '',
        flatNo: r.flat_no ?? '',
        flatTypeId: r.flat_type_id ?? '',
        bedroomId: r.bed_id ?? '',
        usageId: r.usage_id ?? '',
        sqFt: r.sq_ft ?? '',
        terraceSqFt: r.terrace_sq_ft ?? '',
        intercomNo: r.intercom_no ?? '',
      })}
      toBody={(f) => ({
        wingId: Number(f.wingId),
        flatNo: f.flatNo,
        flatTypeId: Number(f.flatTypeId),
        bedroomId: Number(f.bedroomId),
        usageId: Number(f.usageId),
        sqFt: f.sqFt,
        terraceSqFt: f.terraceSqFt,
        intercomNo: f.intercomNo,
      })}
      validate={(f) => {
        if (!f.wingId) return 'Select a wing';
        if (!String(f.flatNo).trim()) return 'Flat number is required';
        if (!f.flatTypeId || !f.bedroomId || !f.usageId) return 'Type, bedrooms and usage are required';
        return null;
      }}
      deleteMessage={(r) => `Delete flat ${r.flat_no}? Any assigned owner must be removed first.`}
      stats={(rows) => (
        <>
          <StatCard label="Flats" value={rows.length} />
          <StatCard label="Occupied" value={rows.filter((r) => Number(r.flat_status) === 1).length} />
          <StatCard label="Rented" value={rows.filter((r) => r.is_rented).length} />
        </>
      )}
    />
  );
}

/* --------------------------------------------------------------- staff */

export function StaffMasterPage() {
  const [attendanceFor, setAttendanceFor] = useState(null);
  const [viewingFile, setViewingFile] = useState(null);
  return (
    <>
    <MasterScreen
      title="Staff"
      resource={M.staff}
      idKey="staff_id"
      columns={[
        // Joined is dropped from the grid to leave room for the four row
        // actions on one line; the date is still on the edit form.
        { key: 'name', label: 'Name' },
        { key: 'role', label: 'Role' },
        { key: 'contact_no', label: 'Contact' },
        { key: 'email', label: 'Email' },
        { key: 'address', label: 'Address' },
        { key: 'salary', label: 'Salary', align: 'right', render: money },
      ]}
      fields={[
        { name: 'name', label: 'Staff name', required: true },
        {
          name: 'roleId',
          label: 'Role',
          type: 'select',
          lookup: 'roles',
          optionValue: 'role_id',
          optionLabel: 'role',
        },
        { name: 'contactNo', label: 'Contact number', phone: true, digits: true, maxLength: 10 },
        { name: 'email', label: 'Email', type: 'email' },
        { name: 'address', label: 'Address', span: 2 },
        { name: 'dateOfJoin', label: 'Date of joining', type: 'date' },
        { name: 'salary', label: 'Salary', type: 'number', step: '0.01' },
        { name: 'imagePath', label: 'Photo', type: 'file', category: 'staff' },
        { name: 'idProofPath', label: 'ID proof', type: 'file', category: 'staff' },
      ]}
      lookupLoaders={{ roles: M.lookups.staffRoles }}
      toForm={(r) => ({
        name: r.name ?? '',
        roleId: r.role_id ?? '',
        contactNo: r.contact_no ?? '',
        email: r.email ?? '',
        address: r.address ?? '',
        dateOfJoin: toDateInput(r.date_of_join),
        salary: r.salary ?? '',
        imagePath: r.image ?? '',
        idProofPath: r.id_path ?? '',
      })}
      validate={(f) => (String(f.name).trim() ? null : 'Staff name is required')}
      deleteMessage={(r) => `Delete ${r.name}?`}
      // Staff_Master.aspx's grid had an Attendance column opening that member's
      // punch log. The endpoint existed but nothing reached it.
      // Compact so all four actions sit on one line. The full wording stays in
      // each button's title for anyone unsure what the short label means.
      extraActions={(row) => (
        <>
          {/* Staff_Master.aspx's per-row "View ID" link, which opened id_path
              in a modal. */}
          <button
            type="button"
            className="btn-secondary px-2 text-xs"
            title={`View ID proof for ${row.name}`}
            onClick={() => setViewingFile({ path: row.id_path, name: row.name, label: 'ID proof' })}
          >
            View ID
          </button>
          <button
            type="button"
            className="btn-secondary px-2 text-xs"
            title={`Attendance for ${row.name}`}
            onClick={() => setAttendanceFor(row)}
          >
            Attendance
          </button>
        </>
      )}
      stats={(rows) => (
        <>
          <StatCard label="Staff" value={rows.length} />
          <StatCard
            label="Monthly salary"
            value={money(rows.reduce((s, r) => s + Number(r.salary || 0), 0))}
          />
          <StatCard label="Roles" value={new Set(rows.map((r) => r.role)).size} />
        </>
      )}
    />
    <StaffAttendanceModal staff={attendanceFor} onClose={() => setAttendanceFor(null)} />
    <StoredFileModal file={viewingFile} onClose={() => setViewingFile(null)} />
    </>
  );
}

/**
 * Views a file recorded against a record — Staff_Master.aspx's "View ID",
 * which previewed the document in an iframe and showed a message when the
 * path was empty.
 *
 * Some rows hold a path on the *old server's disk* (`D:\...`) rather than an
 * uploaded file. Those cannot be fetched over HTTP, so the modal explains that
 * instead of showing a broken frame.
 */
export function StoredFileModal({ file, onClose }) {
  const reason = file ? unopenableReason(file.path) : null;
  // A path with a reason against it is not fetched at all. A legacy
  // /Documents/... path resolves to a URL nothing serves, so loading it put a
  // 404 page inside the viewer; the explanation below says where the file
  // actually is instead.
  const target = file && !reason ? openableUrl(file.path) : null;

  // Files served by this API sit behind the bearer token, which an <iframe>
  // cannot send — pointing it straight at the URL returns 401. Fetch through
  // the authenticated client and show the blob instead.
  const [src, setSrc] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!target) {
      setSrc(null);
      return undefined;
    }
    if (!needsAuth(target)) {
      setSrc(target);
      return undefined;
    }

    let cancelled = false;
    let created = null;
    setLoading(true);
    setError(null);

    fetchProtectedUrl(target, api.raw)
      .then((blobUrl) => {
        created = blobUrl;
        if (cancelled) revokeBlobUrl(blobUrl);
        else setSrc(blobUrl);
      })
      .catch((err) => !cancelled && setError(err))
      .finally(() => !cancelled && setLoading(false));

    return () => {
      cancelled = true;
      revokeBlobUrl(created);
    };
  }, [target]);

  return (
    <Modal
      open={Boolean(file)}
      title={`${file?.label ?? 'File'} — ${file?.name ?? ''}`}
      onClose={onClose}
      footer={
        <>
          {src ? (
            <a className="btn-secondary" href={src} target="_blank" rel="noreferrer">
              Open in new tab
            </a>
          ) : null}
          <button type="button" className="btn-secondary" onClick={onClose}>
            Close
          </button>
        </>
      }
    >
      {loading ? <Spinner label="Loading file…" /> : null}
      <ErrorNotice error={error} />
      {src ? (
        <iframe
          title={`${file?.label ?? 'File'} for ${file?.name ?? ''}`}
          src={src}
          className="h-[60vh] w-full rounded border"
          style={{ borderColor: '#e3e6f0' }}
        />
      ) : null}
      {!target ? (
        <p className="text-sm" style={{ color: '#6b7280' }}>
          {reason}
        </p>
      ) : null}
    </Modal>
  );
}

/** Punch log for one staff member — sp_staff_master/GetAttendace. */
function StaffAttendanceModal({ staff, onClose }) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!staff) return undefined;
    let cancelled = false;
    setLoading(true);
    setError(null);
    M.lookups
      .staffAttendance(staff.staff_id)
      .then((d) => !cancelled && setRows(d.items ?? []))
      .catch((err) => !cancelled && setError(err))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [staff]);

  // in_time/out_time come back as full timestamps on a 1970 date; only the
  // clock part is meaningful.
  const clock = (v) => (v ? new Date(v).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—');

  return (
    <Modal
      open={Boolean(staff)}
      title={`Attendance — ${staff?.name ?? ''}`}
      onClose={onClose}
      footer={
        <button type="button" className="btn-secondary" onClick={onClose}>
          Close
        </button>
      }
    >
      <ErrorNotice error={error} />
      <DataGrid
        columns={[
          { key: 'in_date', label: 'In date', render: day },
          { key: 'in_time', label: 'In time', render: clock },
          { key: 'out_date', label: 'Out date', render: day },
          { key: 'out_time', label: 'Out time', render: clock },
          { key: 'working_hours', label: 'Hours', align: 'right' },
        ]}
        rows={rows}
        idKey="attendance_id"
        loading={loading}
        exportName={`attendance-${staff?.name ?? ''}`}
        emptyTitle="No attendance recorded"
        responsiveCards={false}
      />
    </Modal>
  );
}

/* ----------------------------------------------------------- inventory */

const inventoryResource = {
  list: () => api.get('/masters/inventory'),
  create: (body) => api.post('/masters/inventory', body),
  update: (id, body) => api.post('/masters/inventory', { ...body, itemId: id }),
  remove: (id) => api.delete(`/masters/inventory/${id}`),
};

/**
 * The condition codes InventoryMaster.aspx's grid dropdown wrote.
 *
 * These had drifted: this page previously offered Good/Needs repair/Damaged/
 * Written off as 0-3, so a row saved here as "Good" (0) reads as the legacy
 * page's "Select" — i.e. unset — and every other value named a different
 * condition than the one stored. The legacy list is authoritative because the
 * data was written against it.
 */
const CONDITIONS = [
  { value: '0', label: 'Select' },
  { value: '1', label: 'New' },
  { value: '2', label: 'Good' },
  { value: '3', label: 'Needs repair' },
  { value: '4', label: 'Disposed' },
];

/**
 * The same list for the edit form, without the legacy "Select" entry.
 *
 * Code 0 means no condition recorded, which is what SelectField's own
 * placeholder option already stands for — offering both put "Select" in the
 * dropdown twice. The grid's plain <select> has no placeholder of its own, so
 * it keeps the full list and can still show a stored 0.
 */
const CONDITION_CHOICES = CONDITIONS.filter((c) => c.value !== '0');

const CONDITION_LABEL = Object.fromEntries(CONDITIONS.map((c) => [c.value, c.label]));

/**
 * The grid's condition dropdown, which saves as soon as it changes.
 *
 * InventoryMaster.aspx put this in every row with AutoPostBack, so marking an
 * item as needing repair took one click rather than opening the edit form.
 *
 * The edited value is held by the page rather than this component: DataGrid
 * renders a table and a stacked-card list from the same rows, so each item has
 * two of these on screen and per-cell state would leave the hidden one showing
 * a stale value once the breakpoint changed.
 *
 * The grid is not reloaded after a save — the request writes this one column,
 * so the selection already shows what is stored. A failure puts the previous
 * value back rather than leaving the box showing something the database does
 * not hold.
 */
function ConditionCell({ row, value, onSaved }) {
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState(false);
  // What the row itself holds, which is what the override is recorded against.
  const stored = String(row.condition_status ?? '0');

  const change = async (next) => {
    const previous = value;
    onSaved(row.item_id, next, stored);
    setBusy(true);
    setFailed(false);
    try {
      await api.put(`/masters/inventory/${row.item_id}/condition`, {
        conditionStatus: Number(next),
      });
    } catch {
      onSaved(row.item_id, previous, stored);
      setFailed(true);
    } finally {
      setBusy(false);
    }
  };

  return (
    <span className="inline-flex items-center gap-1">
      <select
        className="field-input px-2 py-1 text-xs"
        value={value}
        disabled={busy}
        aria-label={`Condition for ${row.item_name ?? 'item'}`}
        onChange={(e) => change(e.target.value)}
      >
        {CONDITIONS.map((c) => (
          <option key={c.value} value={c.value}>
            {c.label}
          </option>
        ))}
      </select>
      {failed ? (
        <span className="text-xs text-red-600" role="alert">
          Not saved
        </span>
      ) : null}
    </span>
  );
}

export function InventoryMasterPage() {
  // Conditions changed in the grid since the row was loaded, by item_id.
  // Shared by the table and card renderings of the same row — see
  // ConditionCell.
  //
  // Each entry records the row value it was applied over. Saving the edit form
  // reloads the grid, and a reloaded row already carries whatever was stored;
  // once the row no longer shows the old value the override has been overtaken
  // and is dropped, so it cannot mask a later change made elsewhere.
  const [conditions, setConditions] = useState({});
  const setCondition = useCallback(
    (itemId, value, wasValue) =>
      setConditions((p) => ({ ...p, [itemId]: { value, over: wasValue } })),
    [],
  );
  const conditionOf = useCallback(
    (row) => {
      const stored = String(row.condition_status ?? '0');
      const edit = conditions[row.item_id];
      return edit && edit.over === stored ? edit.value : stored;
    },
    [conditions],
  );

  return (
    <MasterScreen
      title="Inventory"
      resource={inventoryResource}
      idKey="item_id"
      // InventoryMaster.aspx's search box filtered the rendered table on
      // keyup rather than querying — there is no search operation on this
      // endpoint — so the same filtering happens here over the loaded rows.
      filterRow={(r, term) =>
        [r.item_name, r.vendor_name, r.unit, r.remarks, CONDITION_LABEL[conditionOf(r)]]
          .some((v) => String(v ?? '').toLowerCase().includes(term))
      }
      // Stock enters through a vendor bill, as it does in the legacy app —
      // InventoryMaster.aspx's "Add New Item" button is commented out and its
      // grid only lists items billed against an approved vendor bill. Adding
      // one here would save a row the grid then refuses to show.
      canCreate={false}
      headerActions={
        <Link to="/accounts/vendor-bills" className="btn-primary">
          Vendor Bills
        </Link>
      }
      emptyHint="Items appear here once they are received against an approved vendor bill."
      // Column order follows InventoryMaster.aspx's grid: item, vendor, date,
      // quantity, warranty, total — then Condition last, immediately before
      // the row actions, which is where the legacy dropdown sat. Unit and
      // purchase cost have no legacy column; they follow the ones that do.
      columns={[
        { key: 'item_name', label: 'Item' },
        { key: 'vendor_name', label: 'Vendor' },
        { key: 'purchase_date', label: 'Date', render: day },
        { key: 'quantity', label: 'Quantity', align: 'right' },
        {
          key: 'warranty_last_date',
          label: 'Warranty',
          render: (v) => {
            if (!v) return '—';
            const expired = new Date(v) < new Date();
            return (
              <span className={expired ? 'text-red-700' : 'text-slate-700'}>
                {day(v)}
                {expired ? ' (expired)' : ''}
              </span>
            );
          },
        },
        { key: 'total_amount', label: 'Total amount', align: 'right', render: money },
        { key: 'unit', label: 'Unit' },
        { key: 'purchase_cost', label: 'Cost', align: 'right', render: money },
        // Editable in place, as the legacy grid had it — last data column,
        // directly before Edit/Delete.
        {
          key: 'condition_status',
          label: 'Condition',
          render: (_v, row) => (
            <ConditionCell row={row} value={conditionOf(row)} onSaved={setCondition} />
          ),
          exportValue: (row) => CONDITION_LABEL[conditionOf(row)] ?? '',
        },
      ]}
      // Order follows InventoryMaster.aspx: item > date > cost > quantity >
      // warranty months > remark. (The legacy warranty-last-date box was
      // derived in the page from purchase date + months — there is no column
      // for it, so it stays a computed grid column rather than an input.)
      // Unit, tax, total and condition have no legacy counterpart and follow after.
      fields={[
        { name: 'name', label: 'Item name', required: true },
        // The vendor comes from the bill the item was received against, so it
        // is shown but not editable — changing it here would say the stock
        // arrived from someone other than the bill records.
        {
          name: 'vendorName',
          label: 'Vendor name',
          readOnly: true,
          hint: 'From the vendor bill this item was received against.',
        },
        { name: 'purchaseDate', label: 'Purchase date', type: 'date' },
        { name: 'purchaseCost', label: 'Purchase cost', type: 'number', step: '0.01' },
        { name: 'quantity', label: 'Quantity', type: 'number' },
        { name: 'warrantyMonths', label: 'Warranty (months)', type: 'number' },
        // InventoryMaster.aspx showed this as a read-only box recomputed from
        // purchase date + months. There is no column for it — the grid derives
        // it with DATEADD — so it stays derived here too.
        {
          name: 'warrantyLastDate',
          label: 'Warranty last date',
          readOnly: true,
          hint: 'Purchase date plus the warranty months.',
          derive: (f) => addMonths(f.purchaseDate, f.warrantyMonths),
        },
        { name: 'unit', label: 'Unit' },
        { name: 'tax', label: 'Tax', type: 'number', step: '0.01' },
        { name: 'totalAmount', label: 'Total amount', type: 'number', step: '0.01' },
        { name: 'conditionStatus', label: 'Condition', type: 'select', options: CONDITION_CHOICES },
        { name: 'remarks', label: 'Remarks', type: 'textarea', span: 2 },
      ]}
      toForm={(r) => ({
        name: r.item_name ?? '',
        quantity: r.quantity ?? '',
        unit: r.unit ?? '',
        purchaseCost: r.purchase_cost ?? '',
        tax: r.tax ?? '',
        totalAmount: r.total_amount ?? '',
        purchaseDate: toDateInput(r.purchase_date),
        warrantyMonths: r.warranty ?? '',
        // A condition changed in the grid is saved but the row still carries
        // the value it was loaded with, so the override has to win here too.
        // Reading r.condition_status alone showed the form the old value —
        // and saving the form then wrote that stale value straight back.
        conditionStatus: conditionOf(r),
        remarks: r.remarks ?? '',
        // Shown read-only; carried so the save does not blank them. vendorId
        // and vendorBillId were missing entirely, so editing an item detached
        // it from its vendor and bill — both went back as 0.
        vendorName: r.vendor_name ?? '',
        vendorId: r.vendor_id ?? '',
        vendorBillId: r.vendor_bill_id ?? '',
      })}
      validate={(f) => (String(f.name).trim() ? null : 'Item name is required')}
      stats={(rows) => (
        <>
          <StatCard label="Items" value={rows.length} />
          <StatCard label="Total value" value={money(rows.reduce((s, r) => s + Number(r.total_amount || 0), 0))} />
          <StatCard
            label="Warranty expired"
            value={rows.filter((r) => r.warranty_last_date && new Date(r.warranty_last_date) < new Date()).length}
            tone="warning"
          />
        </>
      )}
    />
  );
}

/* ---------------------------------------------------------- facilities */

/**
 * How a facility is booked — the Day / Hour / Slot radio group on
 * Facility_master.aspx. The code-behind stores 1, 2 or 3 in `facilities.slot`
 * (`radiobtn1 ? 1 : radiobtn3 ? 2 : 3`, Facility_master.aspx.cs:63).
 */
const BOOKING_BASIS = [
  { value: '1', label: 'Day' },
  { value: '2', label: 'Hour' },
  { value: '3', label: 'Slot' },
];

export function FacilitiesMasterPage() {
  return (
    <MasterScreen
      title="Facilities"
      resource={M.facilities}
      idKey="facility_id"
      columns={[
        { key: 'name', label: 'Facility' },
        { key: 'description', label: 'Description' },
        { key: 'cost', label: 'Cost', align: 'right', render: money },
        { key: 'capacity', label: 'Capacity', align: 'right' },
        {
          key: 'slot',
          label: 'Booked by',
          render: (v) => BOOKING_BASIS.find((b) => Number(b.value) === Number(v))?.label ?? '—',
        },
        {
          key: 'isActive',
          label: 'Bookable',
          render: (v) => (
            <span
              className={`rounded px-2 py-0.5 text-xs font-medium ${
                v ? 'bg-green-50 text-green-700' : 'bg-slate-100 text-slate-500'
              }`}
            >
              {v ? 'Yes' : 'No'}
            </span>
          ),
        },
      ]}
      fields={[
        { name: 'name', label: 'Facility name', required: true },
        { name: 'cost', label: 'Cost per booking', type: 'number', step: '0.01' },
        { name: 'capacity', label: 'Capacity', type: 'number' },
        // Facility_master.aspx offered this as a Day / Hour / Slot radio group.
        // It was migrated as a free "Number of slots" box, which is wrong: the
        // column is a 1/2/3 code for how the facility is booked, and every row
        // in the database holds 1 or 2.
        {
          name: 'slots',
          label: 'Booked by',
          type: 'select',
          options: BOOKING_BASIS,
          default: '1',
        },
        { name: 'description', label: 'Description', type: 'textarea', span: 2 },
        {
          name: 'isActive',
          label: 'Available for booking',
          type: 'select',
          options: [
            { value: 'true', label: 'Yes' },
            { value: 'false', label: 'No' },
          ],
          default: 'true',
        },
      ]}
      toForm={(r) => ({
        name: r.name ?? '',
        cost: r.cost ?? '',
        capacity: r.capacity ?? '',
        slots: r.slot ? String(r.slot) : '1',
        description: r.description ?? '',
        isActive: r.isActive ? 'true' : 'false',
      })}
      toBody={(f) => ({ ...f, slots: Number(f.slots) || 1, isActive: f.isActive === 'true' })}
      validate={(f) => (String(f.name).trim() ? null : 'Facility name is required')}
      deleteMessage={(r) => `Delete ${r.name}? Its booking slots will also be removed.`}
    />
  );
}

/* ------------------------------------------------------------- helpers */

/**
 * The five services servent_search.aspx tracked, each a checkbox plus a rate.
 * `flag`/`charge` are the DB columns; `body` is the API field name.
 */
const HELPER_SERVICES = [
  { body: 'meal', flag: 'meal', charge: 'meal_charge', label: 'Preparing meal' },
  { body: 'clothWash', flag: 'cloth_wash', charge: 'cloth_wash_charge', label: 'Cloth washing' },
  { body: 'utensilWash', flag: 'b_wash', charge: 'b_wash_charge', label: 'Utensil washing' },
  { body: 'floorWash', flag: 'f_wash', charge: 'f_wash_charge', label: 'Floor washing' },
  { body: 'babySitting', flag: 'baby_set', charge: 'b_set_charge', label: 'Baby sitting' },
];

export function HelpersMasterPage() {
  return (
    <MasterScreen
      title="Helpers"
      resource={M.helpers}
      idKey="servent_id"
      columns={[
        { key: 's_name', label: 'Name' },
        { key: 'mobile_no1', label: 'Mobile' },
        { key: 'mobile_no2', label: 'Alternate' },
        { key: 's_address_1', label: 'Address' },
        {
          key: 'services',
          label: 'Services',
          // Five separate flag columns read better as one summary cell.
          render: (_v, r) =>
            HELPER_SERVICES.filter((s) => Number(r?.[s.flag]) === 1)
              .map((s) => s.label)
              .join(', ') || '—',
        },
        {
          key: 'total_charge',
          label: 'Charges',
          render: (_v, r) => {
            const total = HELPER_SERVICES.reduce(
              (sum, s) => (Number(r?.[s.flag]) === 1 ? sum + Number(r?.[s.charge] || 0) : sum),
              0,
            );
            return total ? total.toFixed(2) : '—';
          },
        },
        { key: 'remark', label: 'Remark' },
      ]}
      fields={[
        { name: 'name', label: 'Helper name', required: true },
        { name: 'mobile1', label: 'Mobile number', phone: true, digits: true, maxLength: 10 },
        { name: 'mobile2', label: 'Alternate mobile', phone: true, digits: true, maxLength: 10 },
        { name: 'address1', label: 'Address line 1' },
        { name: 'address2', label: 'Address line 2' },
        // Each service is a checkbox plus the charge it attracts, as in
        // servent_search.aspx.
        ...HELPER_SERVICES.flatMap((s) => [
          { name: s.body, label: s.label, type: 'checkbox' },
          {
            name: `${s.body}Charge`,
            label: `${s.label} charge`,
            type: 'number',
            step: '0.01',
          },
        ]),
        { name: 'remark', label: 'Remark', type: 'textarea', span: 2 },
      ]}
      toForm={(r) => ({
        name: r.s_name ?? '',
        mobile1: r.mobile_no1 ?? '',
        mobile2: r.mobile_no2 ?? '',
        address1: r.s_address_1 ?? '',
        address2: r.s_address_2 ?? '',
        remark: r.remark ?? '',
        ...Object.fromEntries(
          HELPER_SERVICES.flatMap((s) => [
            [s.body, Number(r[s.flag]) === 1],
            [`${s.body}Charge`, r[s.charge] ?? ''],
          ]),
        ),
      })}
      validate={(f) => (String(f.name).trim() ? null : 'Helper name is required')}
      deleteMessage={(r) => `Delete ${r.s_name}?`}
    />
  );
}

/* -------------------------------------------------- parking allotment */

/**
 * Parking allotment — allots a place to a vehicle and releases it again.
 * Replaces parking_allotment_search.aspx, whose grid joined vehicles, parking
 * places and owners.
 */
/* What Assign insists on — a place cannot be allotted without a flat. */
const ALLOT_FIELDS = [{ name: 'flatId', label: 'Owner', type: 'select', required: true }];

export function ParkingAllotmentPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [confirming, setConfirming] = useState(null);
  const [form, setForm] = useState(null);
  const toast = useToast();
  const [places, setPlaces] = useState([]);
  const [owners, setOwners] = useState([]);
  const [vehicles, setVehicles] = useState([]);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await M.lookups.parkingAllotment(search || undefined);
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [search]);

  // parking_allotment_search.aspx picked the resident by name and the place
  // from those still free — nobody typed a flat id.
  useEffect(() => {
    load();
  }, [load]);

  // Owners do not depend on the search term, so this must not sit in the effect
  // above — `load` changes on every keystroke and would refetch them each time.
  useEffect(() => {
    M.lookups
      .parkingAllotmentLookups()
      .then((d) => {
        setOwners(d.owners ?? []);
        setPlaces(d.places ?? []);
      })
      .catch(() => {});
  }, []);

  /*
   * The form cascades the way the legacy page did: resident → vehicle → place.
   *
   * Picking the resident narrows the vehicles to that flat's unassigned ones.
   * AssignPlace only *updates* an existing vehicle row, so choosing one is the
   * difference between the allotment saving and silently doing nothing.
   */
  useEffect(() => {
    const flatId = form?.flatId;
    if (!flatId) {
      setVehicles([]);
      return undefined;
    }
    let cancelled = false;
    M.lookups
      .parkingAllotmentLookups(flatId)
      .then((d) => !cancelled && setVehicles(d.vehicles ?? []))
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [form?.flatId]);

  // Then the vehicle decides which places are offered: bike bays and car bays
  // are separate lists, so this cannot be loaded before the vehicle is known.
  // On Edit the vehicle already has a place, so fill_vehicle omits it — fall
  // back to the type carried in from the grid row.
  const selectedVehicle = vehicles.find((v) => v.vehicle_no === form?.vehicleNo);
  const vehicleType = selectedVehicle?.vehicle_type ?? form?.keepVehicleType;

  useEffect(() => {
    if (vehicleType == null) {
      setPlaces([]);
      return undefined;
    }
    let cancelled = false;
    M.lookups
      .parkingAllotmentLookups(form?.flatId, Number(vehicleType))
      .then((d) => !cancelled && setPlaces(d.places ?? []))
      .catch(() => {});
    return () => {
      cancelled = true;
    };
    // form.flatId is already settled by the effect above.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [vehicleType]);

  const assign = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post('/masters/parking-allotment/assign', {
        placeId: Number(form.placeId),
        vehicleNo: form.vehicleNo,
        flatId: Number(form.flatId),
      });
      setForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  return (
    <section>
      <PageHeader title="Parking allotment" subtitle={`${rows.length} allotted`}>
        {/* Same header shape as the other list screens: search then action. */}
        <input
          className="field-input w-56"
          placeholder="Search parking allotment…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search parking allotment"
        />
        <button
          type="button"
          className="btn-primary"
          onClick={() => setForm({ placeId: '', vehicleNo: '', flatId: '' })}
        >
          Allot parking
        </button>
      </PageHeader>

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={[
            { key: 'parking_no', label: 'Parking' },
            // The flat's owner — the allotment belongs to them, not to a tenant.
            { key: 'name', label: 'Owner' },
            { key: 'vehicle_no', label: 'Vehicle' },
            { key: 'model_name', label: 'Model' },
            { key: 'park_for', label: 'Type' },
            { key: 'pre_mob', label: 'Contact' },
          ]}
          rows={rows}
          idKey="vehicle_id"
          loading={loading}
          exportName="parking-allotment"
          emptyTitle="No parking allotted"
          actions={(row) => (
            <>
              {/*
                Re-allot: the same form, pre-filled. AssignPlace overwrites
                park_place_id on the vehicle, so moving a vehicle to a
                different place is the same call as the first assignment.
              */}
              <button
                type="button"
                className="btn-secondary px-2 text-xs"
                title={`Change the place allotted to ${row.vehicle_no}`}
                onClick={() =>
                  setForm({
                    flatId: String(row.flat_id ?? ''),
                    vehicleNo: row.vehicle_no ?? '',
                    placeId: row.place_id ? String(row.place_id) : '',
                    // fill_vehicle and fill_place both list only what is free,
                    // so this vehicle and its current place are absent from
                    // them — carry both so the form opens on its own values.
                    keepVehicle: { vehicle_no: row.vehicle_no },
                    keepVehicleType: row.vehicle_type,
                    keepPlace: row.place_id
                      ? { place_id: row.place_id, parking_no: row.parking_no }
                      : null,
                  })
                }
              >
                Edit
              </button>
              <button
                type="button"
                className="btn-danger px-2 text-xs"
                onClick={() =>
                  setConfirming({
                    title: 'Release parking',
                    message: `Release the parking place allotted to ${row.vehicle_no}?`,
                    run: () => api.delete(`/masters/parking-allotment/${row.vehicle_id}`),
                  })
                }
              >
                Release
              </button>
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(form)}
        title="Allot parking"
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="allot-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Allot'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="allot-form" onSubmit={assign} className="grid gap-4 sm:grid-cols-2" noValidate>
            {/*
              Resident → vehicle → place, in that order, as on
              parking_allotment_search.aspx. Each step decides what the next
              one may offer, so the later fields stay disabled until the
              earlier choice is made.

              Resident was a raw "Flat ID" number box, which meant knowing an
              internal id; fill_owner lists them by name with the flat behind.
            */}
            <SelectField
              label="Owner"
              name="flatId"
              required
              placeholder="Select owner…"
              // Parking belongs to the flat, and the flat belongs to its owner,
              // so the owner is the name shown — tenants are not listed.
              hint="Parking is allotted to the flat, so it covers everyone living there"
              options={owners}
              valueKey="flat_id"
              labelKey="name"
              value={form.flatId}
              onChange={(e) => {
                const { value } = e.target;
                // Choices made for the previous resident no longer apply.
                setForm((p) => ({ ...p, flatId: value, vehicleNo: '', placeId: '' }));
              }}
            />

            {/*
              A dropdown, not a text box: AssignPlace matches on vehicle_no and
              flat_id, so a number that is not already registered against the
              flat updates nothing — the allotment looks saved but is not.
            */}
            <SelectField
              label="Vehicle"
              name="vehicleNo"
              required
              disabled={!form.flatId}
              placeholder={form.flatId ? 'Select vehicle…' : 'Choose a resident first'}
              hint={
                form.flatId && vehicles.length === 0
                  ? 'This resident has no vehicle without a place. Register one first.'
                  : undefined
              }
              // When re-allotting, the vehicle already has a place, so
              // fill_vehicle leaves it out — add it back or the form would
              // open with its own vehicle unselectable.
              options={
                form.keepVehicle &&
                !vehicles.some((v) => v.vehicle_no === form.keepVehicle.vehicle_no)
                  ? [form.keepVehicle, ...vehicles]
                  : vehicles
              }
              valueKey="vehicle_no"
              labelKey="vehicle_no"
              value={form.vehicleNo}
              onChange={(e) => {
                const { value } = e.target;
                // Bike and car bays are different lists, so a place chosen for
                // the previous vehicle may not be valid for this one.
                // Switching vehicle invalidates the place *and* the kept one
                // carried in from Edit, since bike and car bays differ.
                setForm((p) => ({
                  ...p,
                  vehicleNo: value,
                  placeId: '',
                  keepPlace: null,
                  keepVehicleType: undefined,
                }));
              }}
            />

            {/* Places are filtered to the chosen vehicle's type. */}
            <SelectField
              label="Parking place"
              name="placeId"
              required
              disabled={!form.vehicleNo}
              placeholder={form.vehicleNo ? 'Select place…' : 'Choose a vehicle first'}
              hint={
                form.vehicleNo && places.length === 0
                  ? 'No free place for this vehicle type.'
                  : undefined
              }
              // fill_place lists only free places, so a vehicle's own place is
              // missing when re-allotting — add it back or the dropdown opens
              // blank on the value it already holds.
              options={
                form.keepPlace &&
                !places.some((p) => Number(p.place_id) === Number(form.keepPlace.place_id))
                  ? [form.keepPlace, ...places]
                  : places
              }
              valueKey="place_id"
              labelKey="parking_no"
              value={form.placeId}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, placeId: value }));
              }}
            />
            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        confirmLabel="Release"
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
            toast.success('Parking place released successfully.', { title: 'Released' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The parking place could not be released. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

/* ------------------------------------------------------ committee list */

const EMPTY_MEMBER = {
  ownerId: '',
  name: '',
  userTypeId: '',
  username: '',
  password: '',
  email: '',
  contactNo: '',
};

/*
 * What Submit insists on, in the shape validateFields expects.
 *
 * E-mail ID and Username carry a red asterisk on the form but were not listed,
 * so nothing enforced either — a member saved with both blank, and the e-mail
 * took any text at all. The password is required only when adding: editing
 * leaves it blank to keep the current one, which is why it is not here.
 */
const MEMBER_FIELDS = [
  { name: 'ownerId', label: 'Name', type: 'select', required: true },
  { name: 'userTypeId', label: 'Designation', type: 'select', required: true },
  { name: 'contactNo', label: 'Contact no', required: true, phone: true, digits: true, maxLength: 10 },
  { name: 'email', label: 'E-mail ID', required: true, type: 'email' },
  { name: 'username', label: 'Username', required: true },
];

export function CommitteeMembersPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const [reloadKey, setReloadKey] = useState(0);
  // society_member_search.aspx could add, edit and delete members; this screen
  // was read-only.
  const [editing, setEditing] = useState(null); // { id, form }
  const [memberTypes, setMemberTypes] = useState([]);
  const [ownerOptions, setOwnerOptions] = useState([]);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const [deleting, setDeleting] = useState(false);
  // name -> message, for the fields the last submit found empty.
  const [memberErrors, setMemberErrors] = useState({});
  const toast = useToast();

  useEffect(() => {
    setLoading(true);
    M.lookups
      .members(search ? { search } : undefined)
      .then((d) => setRows(d.items ?? []))
      .catch(setError)
      .finally(() => setLoading(false));
  }, [search, reloadKey]);

  useEffect(() => {
    api
      .get('/masters/member-lookups')
      .then((d) => {
        setMemberTypes(d.types ?? []);
        setOwnerOptions(d.owners ?? []);
      })
      .catch(() => {});
  }, []);

  /**
   * Picking a resident fills in their contact, email and username — exactly
   * what CategoryRepeater_ItemCommand1 did on the legacy page.
   */
  const pickOwner = (e) => {
    const ownerId = e.target.value;
    setMemberErrors((p) => (p.ownerId ? { ...p, ownerId: undefined } : p));
    const o = ownerOptions.find((x) => String(x.owner_id) === String(ownerId));
    setEditing((p) => ({
      ...p,
      form: {
        ...p.form,
        ownerId,
        ...(o
          ? {
              name: o.name ?? '',
              contactNo: o.contact_no ?? '',
              email: o.email ?? '',
              username: o.email ?? '',
            }
          : {}),
      },
    }));
  };

  const reload = () => setReloadKey((k) => k + 1);

  const openCreate = () => {
    setFormError(null);
    setEditing({ id: null, form: { ...EMPTY_MEMBER } });
  };

  const toMemberForm = (r) => ({
    ownerId: r.owner_id ? String(r.owner_id) : '',
    name: r.name ?? '',
    userTypeId: r.user_type_id ? String(r.user_type_id) : '',
    username: r.username ?? '',
    password: '', // blank means "leave the existing password alone"
    email: r.email ?? '',
    contactNo: r.contact_no ?? '',
  });

  /**
   * Loads the member through `Select` rather than reusing the grid row: the
   * list branch (`Grid_Show`) does not return `owner_id`, so opening the form
   * from the row alone left the Name picker blank and would have unlinked the
   * resident on save.
   */
  const openEdit = async (row) => {
    setFormError(null);
    setEditing({ id: row.user_id, form: toMemberForm(row), loading: true });
    try {
      const d = await api.get(`/masters/members/${row.user_id}`);
      setEditing({ id: row.user_id, form: toMemberForm(d.member ?? row) });
    } catch (err) {
      // The row alone cannot fill the resident picker, and saving from here
      // would send ownerId 0 and unlink the member. Mark the form so the
      // submit handler leaves ownerId untouched.
      setEditing({ id: row.user_id, form: toMemberForm(row), ownerUnknown: true });
      setFormError(err);
    }
  };

  const setField = (key) => (e) => {
    const { value } = e.target;
    const field = MEMBER_FIELDS.find((f) => f.name === key);
    // A `digits` field takes 0-9 only, trimmed to maxLength, as the shared form
    // engines do — these inputs are hand-rolled and had no filter.
    const next = field?.digits
      ? String(value).replace(/\D/g, '').slice(0, field.maxLength)
      : value;
    setEditing((p) => ({ ...p, form: { ...p.form, [key]: next } }));
    // The complaint goes as soon as it is being answered.
    setMemberErrors((p) => (p[key] ? { ...p, [key]: undefined } : p));
  };

  const saveMember = async (e) => {
    e.preventDefault();

    /*
     * A new member needs a password; an existing one keeps theirs when the box
     * is left blank, so it is only insisted on while adding.
     */
    const fields = editing.id
      ? MEMBER_FIELDS
      : [...MEMBER_FIELDS, { name: 'password', label: 'Password', required: true }];
    const missing = validateFields(fields, editing.form);
    setMemberErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(fields, missing);
      return;
    }
    setSaving(true);
    setFormError(null);
    try {
      // `name` is not an input — pickOwner copies it from the chosen resident.
      const body = {
        ...editing.form,
        userTypeId: Number(editing.form.userTypeId),
      };
      // Only send ownerId when we actually know it. Omitting it makes the API
      // keep whatever is stored, rather than clearing the link.
      if (editing.form.ownerId) body.ownerId = Number(editing.form.ownerId);
      else if (!editing.ownerUnknown && !editing.id) body.ownerId = 0;
      const wasEdit = Boolean(editing.id);
      if (wasEdit) await api.put(`/masters/members/${editing.id}`, body);
      else await api.post('/masters/members', body);
      setEditing(null);
      reload();
      toast.success(`Committee member ${wasEdit ? 'updated' : 'added'} successfully.`, {
        title: 'Saved',
      });
    } catch (err) {
      setFormError(err);
      // The detail renders inside the form, which stays open; this covers the
      // case where that notice has scrolled out of view.
      toast.error('Your changes were not saved. Please check the form and try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <section>
      {/* Same header shape as every other list screen: title on the left,
          search and Add on the right. */}
      <PageHeader title="Committee Member List" subtitle={`${rows.length} member(s)`}>
        <input
          className="field-input w-56"
          placeholder="Search…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search members"
        />
        <button type="button" className="btn-primary" onClick={openCreate}>
          Add
        </button>
      </PageHeader>

      <ErrorNotice error={error} />

      <div className="card overflow-hidden">
        <DataGrid
          // The legacy grid shows No, Name and Designation only — its User Id
          // column is Visible="false". The row number comes off the record
          // itself rather than the render index, which restarts on each page.
          columns={[
            {
              key: '__no',
              label: 'No',
              sortable: false,
              render: (_v, r) => rows.findIndex((x) => x.user_id === r.user_id) + 1,
            },
            { key: 'name', label: 'Name' },
            { key: 'UserTypeName', label: 'Designation' },
          ]}
          rows={rows}
          idKey="user_id"
          loading={loading}
          exportName="committee-members"
          emptyTitle="No Record Found"
          actions={(row) => (
            <>
              <button type="button" className="btn-secondary" onClick={() => openEdit(row)}>
                Edit
              </button>
              <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
                Delete
              </button>
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Edit committee member' : 'Add committee member'}
        onClose={() => setEditing(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setEditing(null)}>
              Close
            </button>
            <button type="submit" form="member-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="member-form" onSubmit={saveMember} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(memberErrors)} />
            {/*
              Labels and placeholders follow society_member_search.aspx. "Name"
              there is a picker over the resident list, not a text box — the
              rest of the form fills from whoever is chosen.
            */}
            <SelectField
              label="Name"
              name="ownerId"
              error={memberErrors.ownerId}
              required
              placeholder="Select Name"
              options={ownerOptions}
              valueKey="owner_id"
              labelKey="name"
              value={editing.form.ownerId}
              onChange={pickOwner}
            />
            <SelectField
              label="Designation"
              name="userTypeId"
              error={memberErrors.userTypeId}
              required
              placeholder="Select Designation"
              options={memberTypes}
              valueKey="UserTypeId"
              labelKey="UserTypeName"
              value={editing.form.userTypeId}
              onChange={setField('userTypeId')}
            />
            <TextField
              label="Contact No."
              name="contactNo"
              error={memberErrors.contactNo}
              required
              placeholder="Enter contact No."
              inputMode="numeric"
              maxLength={10}
              value={editing.form.contactNo}
              onChange={setField('contactNo')}
            />
            <TextField
              label="E-mail ID"
              name="email"
              type="email"
              error={memberErrors.email}
              required
              placeholder="Enter Email"
              value={editing.form.email}
              onChange={setField('email')}
            />
            <TextField
              label="Username"
              name="username"
              error={memberErrors.username}
              required
              placeholder="Enter Username"
              value={editing.form.username}
              onChange={setField('username')}
            />
            <TextField
              label="Password"
              name="password"
              type="password"
              error={memberErrors.password}
              required={!editing.id}
              placeholder="Enter Password"
              // Not in the legacy page, which always rewrote the password —
              // blanking it there locked the member out. See the PUT endpoint.
              hint={editing.id ? 'Leave blank to keep the current password' : undefined}
              value={editing.form.password}
              onChange={setField('password')}
            />
            <div className="sm:col-span-2">
              <ErrorNotice error={formError} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete committee member"
        message={`Delete ${confirming?.name}? Their login will stop working.`}
        // Without this the confirm button stayed live while the delete was in
        // flight, and an impatient second click sent the request twice.
        busy={deleting}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setDeleting(true);
          try {
            await api.delete(`/masters/members/${confirming.user_id}`);
            reload();
            toast.success(`${confirming.name} removed from the committee.`, { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The member could not be removed. Please try again.');
          } finally {
            setDeleting(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
