import { useCallback, useEffect, useMemo, useState } from 'react';
import { village } from '@/api/modules';
import DataGrid from '@/components/DataGrid.jsx';
import { ConfirmDialog, ErrorNotice, FormErrorSummary, Modal } from '@/components/ui.jsx';
import { PageHeader, SelectField, Tabs, TextAreaField, TextField } from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/*
 * The three headings v_announcement.aspx filed announcements under, and the
 * labels its tabs carried. `value` is what notice_master.category stores —
 * ddlCategory's own values.
 */
const CATEGORIES = [
  { value: 'General', label: 'General Announcements' },
  { value: 'Meeting', label: 'Meeting Updates' },
  { value: 'WorkBudget', label: 'Work & Budget Information' },
];

/** ddlCategory itself, which offered the bare names rather than the tab labels. */
const CATEGORY_OPTIONS = [
  { value: 'General', label: 'General' },
  { value: 'Meeting', label: 'Meeting' },
  { value: 'WorkBudget', label: 'WorkBudget' },
];

const EMPTY = { category: 'General', title: '', description: '', validTo: '' };

/*
 * What Submit insists on, in the shape validateFields expects. Only the
 * title: the API takes the description as optional and the legacy modal did
 * not star it either.
 */
const REQUIRED_FIELDS = [{ name: 'title', label: 'Title', required: true }];

/**
 * Village announcements — replaces v_announcement.aspx.
 *
 * Its shape is kept: a search box beside "Add Announcement", three tabs, and a
 * grid of Title / Description / Date / Category under each.
 *
 * The legacy page stored nothing. Each tab was filled by a method that built a
 * DataTable in code — its own comment reads "Method to get General
 * Announcements dummy data" — and anything added went into a
 * `static List<Announcement>`, lost on every app restart and shared by every
 * village at once.
 *
 * These are rows in village_announcement, the village's own table, scoped to
 * the signed-in village. See SQL/ADD_village_announcement.sql.
 */
export default function VillageAnnouncementsPage() {
  const [tab, setTab] = useState('General');
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [form, setForm] = useState(null);

  const [formError, setFormError] = useState(null);
  // Which fields Submit found empty, as { fieldName: message }.
  const [fieldErrors, setFieldErrors] = useState({});
  const [busy, setBusy] = useState(false);
  const [confirming, setConfirming] = useState(null);
  const toast = useToast();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const d = await village.announcements();
      setRows(d.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  // A row with no category is a General announcement — see the note above.
  const byTab = useMemo(
    () => rows.filter((r) => (r.category || 'General') === tab),
    [rows, tab],
  );

  const counts = useMemo(
    () =>
      Object.fromEntries(
        CATEGORIES.map((c) => [
          c.value,
          rows.filter((r) => (r.category || 'General') === c.value).length,
        ]),
      ),
    [rows],
  );

  const save = async (event) => {
    event.preventDefault();

    /*
     * Checked on Submit and reported against the box at fault, using the same
     * pass every other screen runs — the wording, the summary and the jump to
     * the first empty field all come from formValidation so this dialog does
     * not behave differently from the rest of the app.
     *
     * Description is not demanded: POST /village/announcements accepts it as
     * optional, and the legacy modal did not star it either.
     */
    const missing = validateFields(REQUIRED_FIELDS, form);
    if (Object.keys(missing).length) {
      setFieldErrors(missing);
      setFormError(null);
      focusFirstInvalid(REQUIRED_FIELDS, missing);
      return;
    }

    setBusy(true);
    setFieldErrors({});
    setFormError(null);
    try {
      const body = {
        category: form.category,
        title: form.title,
        description: form.description,
        validTo: form.validTo || undefined,
      };
      const wasEdit = Boolean(form.__id);
      if (wasEdit) await village.updateAnnouncement(form.__id, body);
      else await village.createAnnouncement(body);
      setForm(null);
      await load();
      toast.success(`Announcement ${wasEdit ? 'updated' : 'published'} successfully.`, {
        title: 'Saved',
      });
    } catch (err) {
      setFormError(err);
      toast.error('Your changes were not saved. Please check the form and try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <section>
      <PageHeader title="Announcements" subtitle={`${rows.length} announcement(s)`}>
        <button
          type="button"
          className="btn-primary"
          onClick={() => {
            setFormError(null);
            setFieldErrors({});
            // New announcements open on whichever tab is showing.
            setForm({ ...EMPTY, category: tab });
          }}
        >
          Add Announcement
        </button>
      </PageHeader>

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <Tabs
        tabs={CATEGORIES.map((c) => ({ id: c.value, label: c.label, count: counts[c.value] }))}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      <div className="card overflow-hidden">
        <DataGrid
          /* The legacy grid's columns, less the ID it showed. */
          columns={[
            { key: 'title', label: 'Title' },
            { key: 'description', label: 'Description' },
            { key: 'date', label: 'Date', render: day, exportValue: (r) => day(r.date) },
            {
              key: 'category',
              label: 'Category',
              render: (v) => v || 'General',
              exportValue: (r) => r.category || 'General',
            },
          ]}
          rows={byTab}
          idKey="announcement_id"
          loading={loading}
          searchable
          searchPlaceholder="Search here"
          exportName="village-announcements"
          exportTitle="Announcements"
          emptyTitle="No announcements here yet"
          actions={(row) => (
            <>
              <button
                type="button"
                className="btn-secondary"
                onClick={() => {
                  setFormError(null);
                  setFieldErrors({});
                  setForm({
                    __id: row.announcement_id,
                    category: row.category || 'General',
                    title: row.title ?? '',
                    description: row.description ?? '',
                    validTo: row.valid_to ? String(row.valid_to).slice(0, 10) : '',
                  });
                }}
              >
                Edit
              </button>
              <button
                type="button"
                className="btn-danger"
                onClick={() =>
                  setConfirming({
                    title: 'Delete announcement',
                    message: `Delete “${row.title}”?`,
                    run: () => village.removeAnnouncement(row.announcement_id),
                  })
                }
              >
                Delete
              </button>
            </>
          )}
        />
      </div>

      {/* addAnnouncementModal — Category, Title, Description, Date. */}
      <Modal
        open={Boolean(form)}
        title={form?.__id ? 'Edit Announcement' : 'Add New Announcement'}
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Close
            </button>
            <button type="submit" form="v-ann-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save Announcement'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="v-ann-form" onSubmit={save} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            {formError ? (
              <div className="sm:col-span-2">
                <ErrorNotice error={formError} />
              </div>
            ) : null}

            <SelectField
              label="Category"
              name="category"
              required
              placeholder=""
              className="sm:col-span-2"
              options={CATEGORY_OPTIONS}
              value={form.category}
              onChange={(e) => setForm((p) => ({ ...p, category: e.target.value }))}
            />
            {/* data-field is what a failed submit scrolls to and flashes. */}
            <div className="rounded-md sm:col-span-2" data-field="title">
              <TextField
                label="Title"
                name="title"
                required
                placeholder="Enter announcement title"
                error={fieldErrors.title}
                value={form.title}
                onChange={(e) => {
                  const { value } = e.target;
                  setForm((p) => ({ ...p, title: value }));
                  // The complaint goes as soon as it is answered.
                  setFieldErrors((p) => ({ ...p, title: undefined }));
                }}
              />
            </div>
            <TextAreaField
              label="Description"
              name="description"
              rows={4}
              className="sm:col-span-2"
              placeholder="Enter description"
              error={fieldErrors.description}
              value={form.description}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, description: value }));
                setFieldErrors((p) => ({ ...p, description: undefined }));
              }}
            />
            {/*
              The legacy box was labelled "Date" but its value was ignored: the
              SP stamps `date` with getdate() on insert. valid_to is the date a
              notice actually carries, so that is what is asked for.

              No Recipients picker: addAnnouncementModal had none, and a village
              announcement goes to the village.
            */}
            <TextField
              label="Valid until"
              name="validTo"
              type="date"
              className="sm:col-span-2"
              value={form.validTo}
              onChange={(e) => setForm((p) => ({ ...p, validTo: e.target.value }))}
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
            toast.success('Announcement deleted successfully.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'The announcement could not be deleted. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
