import { useCallback, useEffect, useState } from 'react';
import * as M from '@/api/modules';
import { api } from '@/api/client';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  FormErrorSummary,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import {
  FileUploadField,
  PageHeader,
  SelectField,
  TextField,
} from '@/components/FormControls.jsx';
import {
  openableUrl,
  unopenableReason,
  needsAuth,
  fetchProtectedUrl,
  revokeBlobUrl,
} from '@/lib/storedFile';
import { useToast } from '@/components/Toast.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

/**
 * Useful contacts — replaces contact_master.aspx.
 *
 * That page is not a grid: it lays the contacts out as cards, four to a row,
 * each showing organisation, phone, email, address and remark against an icon.
 * The look is reproduced here — gradient card, coloured accent bar that grows
 * on hover, lift on hover — because it is what the screen is recognised by.
 *
 * Colours are the legacy stylesheet's: #667eea → #764ba2 accent, #6c757d for
 * the type line, #1a1a1a for the name.
 */

const EMPTY = {
  name: '',
  typeId: '',
  orgName: '',
  contactNo: '',
  email: '',
  address: '',
  address2: '',
  remark: '',
  // contact_master.aspx had a FileUpload writing to id_path. The API accepted
  // it all along; the form did not carry it, so every save cleared whatever
  // document was stored — and 10 contacts here already have one.
  idPath: '',
};

/** The five detail rows a card shows, in the legacy order, with its icon. */
const DETAILS = [
  ['org_name', 'building'],
  ['contact_no', 'phone'],
  ['email', 'envelope'],
  ['contact_address', 'home'],
  ['remark', 'comment'],
];

const ICONS = {
  building: 'M4 21V4h10v17M14 21V9h6v12M7 8h2M7 12h2M7 16h2',
  phone: 'M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2 4.2 2 2 0 0 1 4 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.4-1.1a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2Z',
  envelope: 'M4 4h16v16H4zM4 7l8 6 8-6',
  home: 'M3 10.5 12 3l9 7.5M5.5 9.5V20h13V9.5',
  comment: 'M21 11.5a8.4 8.4 0 0 1-9 8.5 8.5 8.5 0 0 1-3.8-.9L3 21l1.9-5.2A8.5 8.5 0 0 1 12 3a8.4 8.4 0 0 1 9 8.5Z',
};

function DetailIcon({ name }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width="16"
      height="16"
      fill="none"
      stroke="#667eea"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="mt-0.5 shrink-0"
      aria-hidden="true"
    >
      <path d={ICONS[name]} />
    </svg>
  );
}

function ContactCard({ contact, onEdit, onDelete, onViewFile }) {
  const rows = DETAILS.filter(([key]) => String(contact[key] ?? '').trim());

  return (
    <li
      className="group relative flex flex-col overflow-hidden rounded-xl border p-6 transition-all duration-300 hover:-translate-y-2"
      style={{
        background: 'linear-gradient(145deg, #ffffff, #f8f9fa)',
        borderColor: '#e9ecef',
      }}
    >
      {/* The accent bar that scales in on hover. */}
      <span
        className="absolute inset-x-0 top-0 h-1 origin-left scale-x-0 transition-transform duration-300 group-hover:scale-x-100"
        style={{ background: 'linear-gradient(90deg, #667eea, #764ba2)' }}
        aria-hidden="true"
      />

      <header className="mb-4">
        <h3 className="text-xl font-bold" style={{ color: '#1a1a1a' }}>
          {contact.p_name || '—'}
        </h3>
        <p className="text-sm font-medium" style={{ color: '#6c757d' }}>
          {contact.p_type_name || 'Contact'}
        </p>
      </header>

      <div className="flex-1 space-y-3">
        {rows.length === 0 ? (
          <p className="text-sm" style={{ color: '#6c757d' }}>
            No further details recorded.
          </p>
        ) : (
          rows.map(([key, icon]) => (
            <div key={key} className="flex items-start gap-3 text-sm">
              <DetailIcon name={icon} />
              <span className="min-w-0 break-words" style={{ color: '#1a1a1a' }}>
                {contact[key]}
              </span>
            </div>
          ))
        )}
      </div>

      <div className="mt-5 flex justify-end gap-2">
        {/* contact_master.aspx's per-card file link. Several rows hold a path
            on the old server's disk, which openableUrl refuses rather than
            producing a dead link. */}
        {String(contact.id_path ?? '').trim() ? (
          <button
            type="button"
            className="btn-secondary px-2 text-xs"
            onClick={() => onViewFile(contact)}
          >
            View ID
          </button>
        ) : null}
        <button type="button" className="btn-secondary px-2 text-xs" onClick={() => onEdit(contact)}>
          Edit
        </button>
        <button type="button" className="btn-danger px-2 text-xs" onClick={() => onDelete(contact)}>
          Delete
        </button>
      </div>
    </li>
  );
}

/*
 * What Submit insists on, in the shape validateFields expects. Only the
 * name is required: usefull_contact takes every other column as optional, and
 * the legacy form starred nothing else either.
 *
 * Contact no and email are listed without `required` so that they are optional
 * but still format-checked — a directory whose numbers cannot be dialled is
 * worth less than one with gaps in it.
 */
const CONTACT_FIELDS = [
  { name: 'name', label: 'Name', required: true },
  { name: 'contactNo', label: 'Contact no', phone: true, digits: true, maxLength: 10 },
  { name: 'email', label: 'Email', type: 'email' },
];

export default function ContactsPage() {
  const [rows, setRows] = useState([]);
  const [types, setTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState(null);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const [deleting, setDeleting] = useState(false);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const toast = useToast();
  const [viewingFile, setViewingFile] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await M.contacts.list(search ? { search } : undefined);
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    load();
  }, [load]);

  // 24 a page, not the 25 the tables use: the grid runs four to a row, and 25
  // would leave a single card stranded on the last line.
  const paging = usePaging(rows.length, 24);
  const pageRows = rows.slice(paging.first, paging.first + paging.size);

  // Types do not depend on the search term, so they load once.
  useEffect(() => {
    M.lookups
      .contactTypes()
      .then((d) => setTypes(d.items ?? d ?? []))
      .catch(() => {});
  }, []);

  const openCreate = () => {
    setFormError(null);
    setEditing({ id: null, form: { ...EMPTY } });
  };

  const openEdit = (r) => {
    setFormError(null);
    setEditing({
      id: r.usefull_contact_id,
      form: {
        name: r.p_name ?? '',
        typeId: r.p_type ? String(r.p_type) : '',
        orgName: r.org_name ?? '',
        contactNo: r.contact_no ?? '',
        email: r.email ?? '',
        address: r.contact_address ?? '',
        address2: r.address2 ?? '',
        remark: r.remark ?? '',
        idPath: r.id_path ?? '',
      },
    });
  };

  const setField = (key) => (e) => {
    const { value } = e.target;
    const field = CONTACT_FIELDS.find((f) => f.name === key);
    // A `digits` box takes 0-9 only, trimmed to maxLength, as the shared form
    // engines do — these inputs are hand-rolled and had no filter.
    const next = field?.digits
      ? String(value).replace(/\D/g, '').slice(0, field.maxLength)
      : value;
    setEditing((p) => ({ ...p, form: { ...p.form, [key]: next } }));
    // The complaint goes as soon as it is being answered.
    setFieldErrors((p) => (p[key] ? { ...p, [key]: undefined } : p));
  };

  const save = async (e) => {
    e.preventDefault();

    // The form carries noValidate, so nothing enforced the red asterisk on Name
    // — an empty contact saved as a blank row. Same pass as every other screen.
    const missing = validateFields(CONTACT_FIELDS, editing.form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setFormError(null);
      focusFirstInvalid(CONTACT_FIELDS, missing);
      return;
    }

    setSaving(true);
    setFormError(null);
    try {
      const body = { ...editing.form, typeId: Number(editing.form.typeId) || 0 };
      const wasEdit = Boolean(editing.id);
      if (wasEdit) await M.contacts.update(editing.id, body);
      else await M.contacts.create(body);
      setEditing(null);
      await load();
      toast.success(`Contact ${wasEdit ? 'updated' : 'added'} successfully.`, { title: 'Saved' });
    } catch (err) {
      setFormError(err);
      toast.error('Your changes were not saved. Please check the form and try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <section>
      <PageHeader title="Assistant Contact" subtitle={`${rows.length} contact(s)`}>
        <input
          className="field-input w-56"
          placeholder="Search contacts…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search contacts"
        />
        <button type="button" className="btn-primary" onClick={openCreate}>
          Add
        </button>
      </PageHeader>

      <ErrorNotice error={error} onRetry={load} />

      {loading ? (
        <Spinner />
      ) : rows.length === 0 ? (
        <EmptyState
          title="No contacts found"
          hint={search ? 'Try a different search term.' : 'Add the first contact to get started.'}
        />
      ) : (
        // Four to a row on a wide screen, two on a tablet, one on a phone —
        // the legacy breakpoints.
        <>
        <ul className="grid gap-6 sm:grid-cols-2 xl:grid-cols-4">
          {pageRows.map((c) => (
            <ContactCard
              key={c.usefull_contact_id}
              contact={c}
              onEdit={openEdit}
              onDelete={setConfirming}
              onViewFile={setViewingFile}
            />
          ))}
        </ul>
        {/* The cards are not in a card container of their own, so the pager
            carries the border the table pages get from theirs. */}
        <Pager
          page={paging.page}
          pageCount={paging.pageCount}
          first={paging.first}
          last={paging.last}
          total={rows.length}
          onPage={paging.setPage}
        />
        </>
      )}

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Assistant Contact' : 'New Assistant Contact'}
        onClose={() => setEditing(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setEditing(null)}>
              Close
            </button>
            <button type="submit" form="contact-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="contact-form" onSubmit={save} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            {/* Order and placeholders follow contact_master.aspx's modal. */}
            <TextField
              label="Name"
              name="name"
              required
              placeholder="Enter person's name"
              error={fieldErrors.name}
              value={editing.form.name}
              onChange={setField('name')}
            />
            <SelectField
              label="Type"
              name="typeId"
              placeholder="Select type"
              options={types}
              valueKey="p_type_id"
              labelKey="p_type_name"
              value={editing.form.typeId}
              onChange={setField('typeId')}
            />
            <TextField
              label="Organisation"
              name="orgName"
              placeholder="Enter organization name"
              value={editing.form.orgName}
              onChange={setField('orgName')}
            />
            <TextField
              label="Contact number"
              name="contactNo"
              error={fieldErrors.contactNo}
              placeholder="Enter mobile number"
              inputMode="numeric"
              maxLength={10}
              value={editing.form.contactNo}
              onChange={setField('contactNo')}
            />
            <TextField
              label="Email"
              name="email"
              type="email"
              error={fieldErrors.email}
              placeholder="Enter email address"
              value={editing.form.email}
              onChange={setField('email')}
            />
            <TextField
              label="Remark"
              name="remark"
              placeholder="Enter remark"
              value={editing.form.remark}
              onChange={setField('remark')}
            />
            <TextField
              label="Address line 1"
              name="address"
              placeholder="Enter address line 1"
              value={editing.form.address}
              onChange={setField('address')}
            />
            <TextField
              label="Address line 2"
              name="address2"
              placeholder="Enter address line 2"
              value={editing.form.address2}
              onChange={setField('address2')}
            />
            <FileUploadField
              label="ID document"
              category="society-documents"
              className="sm:col-span-2"
              currentPath={editing.form.idPath}
              onUploaded={(f) =>
                f && setEditing((p) => ({ ...p, form: { ...p.form, idPath: f.path } }))
              }
            />
            <div className="sm:col-span-2">
              <ErrorNotice error={formError} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete contact"
        message={`Delete ${confirming?.p_name}?`}
        // Without this the confirm button stayed live during the request, so
        // an impatient second click sent the delete twice.
        busy={deleting}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setDeleting(true);
          try {
            await M.contacts.remove(confirming.usefull_contact_id);
            await load();
            toast.success('Contact deleted successfully.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The contact could not be deleted. Please try again.');
          } finally {
            setDeleting(false);
            setConfirming(null);
          }
        }}
      />

      <ContactFileModal contact={viewingFile} onClose={() => setViewingFile(null)} />
    </section>
  );
}

/**
 * Views the document stored against a contact.
 *
 * Files served by this API sit behind the bearer token, which an <iframe>
 * cannot send, so the file is fetched through the authenticated client and
 * shown as a blob. Several rows hold a path on the *old server's disk*
 * (`D:\VengurlaTech\…`) rather than an uploaded file; those cannot be reached
 * over HTTP at all, so the modal explains that instead of failing silently.
 */
function ContactFileModal({ contact, onClose }) {
  const reason = contact ? unopenableReason(contact.id_path) : null;
  // Not fetched when there is a reason against it — a legacy path resolves to
  // a URL nothing serves, which showed a 404 page inside the viewer.
  const target = contact && !reason ? openableUrl(contact.id_path) : null;

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
      open={Boolean(contact)}
      title={`ID document — ${contact?.p_name ?? ''}`}
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
          title={`ID document for ${contact?.p_name ?? ''}`}
          src={src}
          className="h-[60vh] w-full rounded border"
          style={{ borderColor: '#e3e6f0' }}
        />
      ) : null}
      {!target ? (
        <p className="text-sm" style={{ color: '#6c757d' }}>
          {reason}
        </p>
      ) : null}
    </Modal>
  );
}
