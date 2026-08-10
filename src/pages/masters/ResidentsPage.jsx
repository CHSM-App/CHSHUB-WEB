import { useCallback, useDeferredValue, useEffect, useMemo, useState } from 'react';
import { residents } from '@/api/masters';
import { api } from '@/api/client';
import useCrudResource from './useCrudResource';
import OwnerDetailPanel from './OwnerDetailPanel.jsx';
import DataGrid from '@/components/DataGrid.jsx';
import { FileUploadField } from '@/components/FormControls.jsx';
import {
  openableUrl,
  unopenableReason,
  needsAuth,
  fetchProtectedUrl,
  revokeBlobUrl,
} from '@/lib/storedFile';
import { ConfirmDialog, ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';

/**
 * The three files rental_search.aspx's "View Docs" opened, as
 * `[label, column]`. Rows carry the stored path; an empty column means the
 * document was never uploaded.
 */
const DOC_FIELDS = [
  ['ID proof', 'id_proof'],
  ['Rent agreement', 'agreement_path'],
  ['Police verification', 'police_verification_path'],
];

const docsFor = (row) =>
  DOC_FIELDS.filter(([, key]) => String(row?.[key] ?? '').trim()).map(([label, key]) => ({
    label,
    path: String(row[key]).trim(),
  }));

/**
 * One document row in the View Docs list.
 *
 * Files served by this API sit behind the bearer token, which a plain `<a
 * href>` cannot send — the link would download a 401 body. Fetching through
 * the authenticated client and handing over a blob URL avoids that. Absolute
 * URLs and legacy web paths are linked directly; a path on the old server's
 * disk cannot be reached at all and says so.
 */
function StoredFileRow({ label, path }) {
  const target = openableUrl(path);
  const [href, setHref] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!target || !needsAuth(target)) {
      setHref(target);
      return undefined;
    }
    let cancelled = false;
    let created = null;
    setBusy(true);
    fetchProtectedUrl(target, api.raw)
      .then((blobUrl) => {
        created = blobUrl;
        if (cancelled) revokeBlobUrl(blobUrl);
        else setHref(blobUrl);
      })
      .catch((err) => !cancelled && setError(err))
      .finally(() => !cancelled && setBusy(false));
    return () => {
      cancelled = true;
      revokeBlobUrl(created);
    };
  }, [target]);

  const problem = error ? 'Could not load this file.' : unopenableReason(path);

  return (
    <li className="flex items-start justify-between gap-3">
      <div className="min-w-0">
        <span className="text-sm text-slate-700">{label}</span>
        {problem ? (
          <p className="mt-0.5 text-xs" style={{ color: '#6b7280' }}>
            {problem}
          </p>
        ) : null}
      </div>
      {href ? (
        <a className="btn-secondary shrink-0" href={href} target="_blank" rel="noreferrer">
          Open
        </a>
      ) : busy ? (
        <span className="shrink-0 text-xs" style={{ color: '#6b7280' }}>
          Loading…
        </span>
      ) : null}
    </li>
  );
}

const EMPTY = {
  name: '',
  mobile: '',
  altMobile: '',
  email: '',
  flatId: '',
  wingId: '',
  marriedId: '',
  dob: '',
  occupation: '',
  monthlyIncome: '',
  officeAddress1: '',
  officeAddress2: '',
  officeTel: '',
  docId: '',
  possessionDate: '',
  agreementDate: '',
  agreementFrom: '',
  agreementTo: '',
  policeVerificationDate: '',
  // Stored file paths. The API always accepted these; the form did not carry
  // them, so every save wrote them back empty.
  idProofPath: '',
  photoPath: '',
  agreementPath: '',
  policeVerificationPath: '',
};

/** ISO timestamps from SQL Server -> yyyy-mm-dd for <input type="date">. */
const toDateInput = (v) => (v ? String(v).slice(0, 10) : '');


const toForm = (row) => ({
  name: row.name ?? '',
  mobile: row.pre_mob ?? '',
  altMobile: row.alter_mob ?? '',
  email: row.email ?? '',
  flatId: row.flat_id ?? '',
  wingId: row.wing_id ?? '',
  marriedId: row.married_id ?? '',
  dob: toDateInput(row.dob),
  occupation: row.job_title ?? '',
  monthlyIncome: row.monthly_income ?? '',
  officeAddress1: row.off_addr1 ?? '',
  officeAddress2: row.off_addr2 ?? '',
  officeTel: row.off_tel ?? '',
  docId: row.doc_id ?? '',
  possessionDate: toDateInput(row.poss_date),
  agreementDate: toDateInput(row.aggrement_date),
  agreementFrom: toDateInput(row.aggrement_period_from),
  agreementTo: toDateInput(row.aggrement_period_to),
  policeVerificationDate: toDateInput(row.police_verification_date),
  idProofPath: row.id_proof ?? '',
  photoPath: row.photo_name ?? '',
  agreementPath: row.agreement_path ?? '',
  policeVerificationPath: row.police_verification_path ?? '',
});

/**
 * Owners and tenants are the same record type (owner_master.type), so one page
 * serves both. `type` is fixed by the route: 'Owner' or 'Rent'.
 */
export default function ResidentsPage({ type = 'Owner' }) {
  const isTenant = type === 'Rent';
  const noun = isTenant ? 'tenant' : 'owner';

  const [search, setSearch] = useState('');
  const deferredSearch = useDeferredValue(search);
  const params = useMemo(
    () => ({ type, search: deferredSearch || undefined }),
    [type, deferredSearch],
  );

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(residents, { params });

  const [lookups, setLookups] = useState({ wings: [], docs: [], marital: [], availableFlats: [] });
  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const [familyFor, setFamilyFor] = useState(null);
  const [docsRow, setDocsFor] = useState(null);

  const loadLookups = useCallback(() => {
    let cancelled = false;
    residents
      .lookups(type)
      .then((data) => {
        if (!cancelled) setLookups(data);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [type]);

  useEffect(() => loadLookups(), [loadLookups]);

  // Reset transient UI when switching between the owners and tenants routes.
  useEffect(() => {
    setSearch('');
    setEditing(null);
    setConfirming(null);
    setFamilyFor(null);
  }, [type]);

  const openCreate = () => setEditing({ id: null, form: { ...EMPTY } });
  const openEdit = (row) => setEditing({ id: row.owner_id, form: toForm(row) });

  const closeForm = () => {
    setEditing(null);
    setError(null);
  };

  // Read e.target.value eagerly: the state updater runs after the event has
  // been recycled, so reading it inside the callback yields a stale value and
  // only the first keystroke survives.
  const setField = (key) => (e) => {
    const { value } = e.target;
    setEditing((prev) => ({ ...prev, form: { ...prev.form, [key]: value } }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    const f = editing.form;
    const body = {
      ...f,
      type,
      flatId: Number(f.flatId),
      wingId: Number(f.wingId),
      marriedId: f.marriedId ? Number(f.marriedId) : undefined,
      docId: f.docId ? Number(f.docId) : undefined,
    };
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
      // Allocating a flat changes which flats remain available.
      loadLookups();
    } catch {
      // Surfaced in the modal.
    }
  };

  const onDelete = async () => {
    try {
      await remove(confirming.owner_id);
      loadLookups();
    } finally {
      setConfirming(null);
    }
  };

  // When editing, the resident's own flat is no longer "available", so add it
  // back or the select would show a blank value.
  const flatOptions = useMemo(() => {
    const opts = [...(lookups.availableFlats ?? [])];
    if (editing?.id) {
      const current = items.find((r) => Number(r.owner_id) === Number(editing.id));
      if (current && !opts.some((o) => Number(o.flat_id) === Number(current.flat_id))) {
        opts.unshift({ flat_id: current.flat_id, flat_type: `${current.Unit} (current)` });
      }
    }
    return opts;
  }, [lookups.availableFlats, editing, items]);

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold capitalize text-slate-800">{noun}s</h1>
          <p className="text-sm text-slate-500">{items.length} record(s)</p>
        </div>
        <div className="flex gap-2">
          <input
            className="field-input w-56"
            placeholder={`Search ${noun}s…`}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            aria-label={`Search ${noun}s`}
          />
          <button type="button" className="btn-primary" onClick={openCreate}>
            Add {noun}
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      {/*
        DataGrid rather than a hand-rolled table: it carries the three export
        actions the legacy page had — "Export to Excel", "Download PDF" and
        Print — which this screen was missing entirely. Sq.ft and Type are
        legacy grid columns the API already returned but nothing displayed.
      */}
      <div className="card mt-3 overflow-hidden">
        <DataGrid
          // Column set follows each legacy grid: rental_search.aspx carries
          // Sq.ft, owner_search.aspx does not.
          columns={[
            { key: 'name', label: 'Name' },
            { key: 'build_name', label: 'Building' },
            { key: 'Unit', label: 'Unit' },
            ...(isTenant ? [{ key: 'sq_ft', label: 'Sq.ft', align: 'right' }] : []),
            { key: 'flat_type', label: 'Type' },
            { key: 'pre_mob', label: 'Mobile' },
            { key: 'email', label: 'Email' },
          ]}
          rows={items}
          idKey="owner_id"
          loading={loading}
          exportName={`${noun}s`}
          exportTitle={`${noun.charAt(0).toUpperCase()}${noun.slice(1)} details`}
          emptyTitle={`No ${noun}s found`}
          emptyHint={search ? 'Try a different search term.' : `Add the first ${noun} to get started.`}
          /*
           * Four actions on an eight-column grid do not fit as full-width
           * buttons, so they are compact and shortened — "Docs" rather than
           * "View Docs". Each carries a title and aria-label with the full
           * wording, so the meaning is not lost.
           */
          actions={(row) => (
            <>
              <button
                type="button"
                className="btn-secondary px-2 text-xs"
                title={`Details for ${row.name}`}
                onClick={() => setFamilyFor(row)}
              >
                Details
              </button>
              {/* rental_search.aspx's "View Docs" — ID proof, agreement and
                  police verification, which nothing in the app exposed. */}
              {docsFor(row).length ? (
                <button
                  type="button"
                  className="btn-secondary px-2 text-xs"
                  title={`View documents for ${row.name}`}
                  aria-label={`View documents for ${row.name}`}
                  onClick={() => setDocsFor(row)}
                >
                  Docs
                </button>
              ) : null}
              <button
                type="button"
                className="btn-secondary px-2 text-xs"
                title={`Edit ${row.name}`}
                onClick={() => openEdit(row)}
              >
                Edit
              </button>
              <button
                type="button"
                className="btn-danger px-2 text-xs"
                title={`Delete ${row.name}`}
                onClick={() => setConfirming(row)}
              >
                Delete
              </button>
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(editing)}
        title={`${editing?.id ? 'Edit' : 'Add'} ${noun}`}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="resident-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="resident-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <Field label="Full name" required>
              <input className="field-input" value={editing.form.name} onChange={setField('name')} required />
            </Field>
            <Field label="Mobile" required>
              <input className="field-input" value={editing.form.mobile} onChange={setField('mobile')} required />
            </Field>
            <Field label="Alternate mobile">
              <input className="field-input" value={editing.form.altMobile} onChange={setField('altMobile')} />
            </Field>
            <Field label="Email">
              <input className="field-input" type="email" value={editing.form.email} onChange={setField('email')} />
            </Field>

            <Field label="Wing" required>
              <select className="field-input" value={editing.form.wingId} onChange={setField('wingId')} required>
                <option value="">Select a wing…</option>
                {lookups.wings.map((w) => (
                  <option key={w.wing_id} value={w.wing_id}>
                    {w.name}
                  </option>
                ))}
              </select>
            </Field>
            <Field
              label="Flat"
              required
              hint={isTenant ? 'Only flats available to rent are listed' : 'Only unallocated flats are listed'}
            >
              <select className="field-input" value={editing.form.flatId} onChange={setField('flatId')} required>
                <option value="">Select a flat…</option>
                {flatOptions.map((f) => (
                  <option key={f.flat_id} value={f.flat_id}>
                    {f.flat_type}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Marital status">
              <select
                className="field-input"
                value={editing.form.marriedId}
                onChange={setField('marriedId')}
              >
                <option value="">Select…</option>
                {lookups.marital.map((m) => (
                  <option key={m.married_id} value={m.married_id}>
                    {m.married_name}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Date of birth">
              <input className="field-input" type="date" value={editing.form.dob} onChange={setField('dob')} />
            </Field>

            <Field label="Occupation">
              <input className="field-input" value={editing.form.occupation} onChange={setField('occupation')} />
            </Field>
            <Field label="Monthly income">
              <input
                className="field-input"
                value={editing.form.monthlyIncome}
                onChange={setField('monthlyIncome')}
              />
            </Field>

            <Field label="Office address line 1">
              <input
                className="field-input"
                value={editing.form.officeAddress1}
                onChange={setField('officeAddress1')}
              />
            </Field>
            <Field label="Office address line 2">
              <input
                className="field-input"
                value={editing.form.officeAddress2}
                onChange={setField('officeAddress2')}
              />
            </Field>
            <Field label="Office telephone">
              <input className="field-input" value={editing.form.officeTel} onChange={setField('officeTel')} />
            </Field>
            <Field label="ID document type">
              <select className="field-input" value={editing.form.docId} onChange={setField('docId')}>
                <option value="">Select…</option>
                {lookups.docs.map((d) => (
                  <option key={d.doc_id} value={d.doc_id}>
                    {d.doc_name}
                  </option>
                ))}
              </select>
            </Field>

            {/*
              The form asked which ID document this was but gave no way to
              attach it. The API and the upload categories both existed, so
              every save was writing these paths back as empty.
            */}
            <FileUploadField
              label="ID proof"
              category="owner-documents"
              currentPath={editing.form.idProofPath}
              onUploaded={(f) =>
                f && setEditing((p) => ({ ...p, form: { ...p.form, idProofPath: f.path } }))
              }
            />
            <FileUploadField
              label="Photo"
              category="owner-photos"
              currentPath={editing.form.photoPath}
              onUploaded={(f) =>
                f && setEditing((p) => ({ ...p, form: { ...p.form, photoPath: f.path } }))
              }
            />

            {isTenant ? (
              <>
                <Field label="Agreement date">
                  <input
                    className="field-input"
                    type="date"
                    value={editing.form.agreementDate}
                    onChange={setField('agreementDate')}
                  />
                </Field>
                <Field label="Police verification date">
                  <input
                    className="field-input"
                    type="date"
                    value={editing.form.policeVerificationDate}
                    onChange={setField('policeVerificationDate')}
                  />
                </Field>
                <Field label="Agreement from">
                  <input
                    className="field-input"
                    type="date"
                    value={editing.form.agreementFrom}
                    onChange={setField('agreementFrom')}
                  />
                </Field>
                <Field label="Agreement to">
                  <input
                    className="field-input"
                    type="date"
                    value={editing.form.agreementTo}
                    onChange={setField('agreementTo')}
                  />
                </Field>
                {/* The two files rental_search.aspx's "View Docs" opened
                    alongside the ID proof. */}
                <FileUploadField
                  label="Rent agreement"
                  category="agreements"
                  currentPath={editing.form.agreementPath}
                  onUploaded={(f) =>
                    f && setEditing((p) => ({ ...p, form: { ...p.form, agreementPath: f.path } }))
                  }
                />
                <FileUploadField
                  label="Police verification"
                  category="police-verification"
                  currentPath={editing.form.policeVerificationPath}
                  onUploaded={(f) =>
                    f &&
                    setEditing((p) => ({
                      ...p,
                      form: { ...p.form, policeVerificationPath: f.path },
                    }))
                  }
                />
              </>
            ) : (
              <Field label="Possession date">
                <input
                  className="field-input"
                  type="date"
                  value={editing.form.possessionDate}
                  onChange={setField('possessionDate')}
                />
              </Field>
            )}

            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <OwnerDetailPanel resident={familyFor} onClose={() => setFamilyFor(null)} />

      <Modal
        open={Boolean(docsRow)}
        title={`Documents — ${docsRow?.name ?? ''}`}
        onClose={() => setDocsFor(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setDocsFor(null)}>
            Close
          </button>
        }
      >
        <ul className="space-y-2">
          {docsFor(docsRow).map((d) => (
            <StoredFileRow key={d.label} label={d.label} path={d.path} />
          ))}
        </ul>
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={`Delete ${noun}`}
        message={`Delete "${confirming?.name}"? Their flat will be released and family members deactivated.`}
        onConfirm={onDelete}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
    </section>
  );
}
