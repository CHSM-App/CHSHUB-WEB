import { useCallback, useEffect, useMemo, useState } from 'react';
import { community } from '@/api/modules';
import { api } from '@/api/client';
import DataGrid from '@/components/DataGrid.jsx';
import { EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import { PageHeader, StatCard, Tabs, TextAreaField } from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  fetchProtectedUrl,
  needsAuth,
  openableUrl,
  revokeBlobUrl,
  unopenableReason,
} from '@/lib/storedFile';

/**
 * Comment timestamps arrive pre-formatted, so they are shown as they come.
 *
 * GetComments returns `CONVERT(varchar, dateTime, 100)` — style 100 is
 * "Aug 12 2026  9:40AM", with two spaces before the time and no space before
 * the meridiem. `new Date()` cannot parse that: it yields Invalid Date, which
 * is what rendered where the time should have been. Anything else (a real ISO
 * timestamp, should the SP ever stop converting) is formatted normally.
 */
/**
 * A date with no time of day.
 *
 * req_service_date is the day the resident asked to be visited — there is no
 * meaningful time on it, and the column is stored as smalldatetime, so a raw
 * value drags "00:00:00" along behind the date. Values the SP has already
 * formatted ("12 Aug 2026") are passed through untouched.
 */
function dateOnly(value) {
  if (!value) return '—';
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? String(value) : parsed.toLocaleDateString();
}

function commentTime(value) {
  if (!value) return '';
  const s = String(value);
  const parsed = new Date(s);
  return Number.isNaN(parsed.getTime()) ? s : parsed.toLocaleString();
}

/**
 * HelpdeskRequest.urgency is a flag, not a scale.
 *
 * support_ticket.aspx renders it as `urgency == "0" ? "Minor" : "Urgent"`, and
 * the column is written by the mobile app's raise-complaint form. It was mapped
 * here as 1/2/3 = Low/Medium/High, which left every Minor ticket showing "—"
 * (0 was not in the map) and labelled the Urgent ones "Low" — the inverse of
 * what they are.
 */
const urgencyLabel = (v) => (Number(v) === 0 ? 'Minor' : 'Urgent');

/** Status ids come from HelpdeskStatus; 4 is the resolved state. */
const statusTone = (id) =>
  Number(id) === 4
    ? 'bg-green-50 text-green-700'
    : Number(id) === 1
      ? 'bg-amber-50 text-amber-700'
      : 'bg-slate-100 text-slate-600';

/**
 * One attached image, fetched through the authenticated client.
 *
 * /api/web/uploads/file/... needs the bearer token, which <img src> cannot
 * send, so the bytes come back through axios as a blob. Legacy rows hold a path
 * on the old server instead of an upload; those cannot be served here at all,
 * so the tile says so rather than showing a broken image.
 */
function TicketImage({ path }) {
  const reason = unopenableReason(path);
  const target = reason ? null : openableUrl(path);

  const [src, setSrc] = useState(null);
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
    setError(null);

    fetchProtectedUrl(target, api.raw)
      .then((blobUrl) => {
        created = blobUrl;
        if (cancelled) revokeBlobUrl(blobUrl);
        else setSrc(blobUrl);
      })
      .catch((err) => !cancelled && setError(err));

    return () => {
      cancelled = true;
      revokeBlobUrl(created);
    };
  }, [target]);

  if (reason || error) {
    return (
      <div className="rounded border border-slate-200 bg-slate-50 p-3 text-xs text-slate-500">
        {reason ?? 'This image could not be loaded.'}
      </div>
    );
  }
  if (!src) return <Spinner />;

  return (
    // Opens full size in a tab, which is what the legacy carousel's max-height
    // 500px preview could not do.
    <a href={src} target="_blank" rel="noreferrer" className="block">
      <img
        src={src}
        alt="Helpdesk attachment"
        className="max-h-[420px] w-full rounded border border-slate-200 object-contain"
      />
    </a>
  );
}

/**
 * Helpdesk — support_ticket.aspx.
 *
 * The legacy grid carried its three controls on the row itself: a status
 * dropdown that saved on change, a Comments button opening the chat thread, and
 * a View Image button opening the attachments. Both modals are reached from the
 * row, so an operator working a list of tickets never loses their place.
 */
export default function HelpdeskPage() {
  const [rows, setRows] = useState([]);
  const [statuses, setStatuses] = useState([]);
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [tab, setTab] = useState('open');

  // Which ticket each modal is showing. Separate, because they are separate
  // buttons on the row — opening images must not discard a half-typed reply.
  const [comments, setComments] = useState(null);
  const [images, setImages] = useState(null);
  const [reply, setReply] = useState('');
  // The row whose status select is mid-save, so only that one disables.
  const [savingStatus, setSavingStatus] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await community.helpdesk();
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    community
      .helpdeskStatuses()
      .then((d) => setStatuses(d.items ?? []))
      .catch(() => {});
  }, [load]);

  const openComments = async (row) => {
    setComments({ loading: true, ticket: row });
    setReply('');
    try {
      const data = await community.helpdeskTicket(row.helpdesk_id);
      setComments({ loading: false, ticket: { ...row, ...data.ticket }, comments: data.comments });
    } catch (err) {
      setError(err);
      setComments(null);
    }
  };

  const openImages = async (row) => {
    setImages({ loading: true, ticket: row });
    try {
      const data = await community.helpdeskTicket(row.helpdesk_id);
      setImages({ loading: false, ticket: { ...row, ...data.ticket } });
    } catch (err) {
      setError(err);
      setImages(null);
    }
  };

  const postReply = async (event) => {
    event.preventDefault();
    if (!reply.trim()) return;
    setBusy(true);
    try {
      await community.addHelpdeskComment(comments.ticket.helpdesk_id, {
        comment: reply,
        flatId: comments.ticket.flat_id,
        type: 'Admin',
      });
      setReply('');
      await openComments(comments.ticket);
      toast.success('Your reply has been posted to the ticket.', { title: 'Reply sent' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The reply could not be posted. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  /*
   * Saves as soon as the select changes, as ddlStatus_SelectedIndexChanged did.
   * The row is updated in place rather than reloading the list: a reload
   * reorders and repages the grid, moving the row the operator is working on.
   */
  const changeStatus = async (row, value) => {
    const status = Number(value);
    if (!status || status === Number(row.status)) return;
    setSavingStatus(row.helpdesk_id);
    setError(null);
    try {
      await community.setHelpdeskStatus(row.helpdesk_id, status);
      setRows((prev) =>
        prev.map((r) => (r.helpdesk_id === row.helpdesk_id ? { ...r, status } : r)),
      );
      // The row updates in place and the dropdown keeps its new value whether
      // or not the write landed, so without this a failed save looks identical
      // to a successful one.
      // The statuses are loaded from the API, so name the one just picked
      // rather than hard-coding a list that could drift from it.
      const label = statuses.find((s) => Number(s.id) === status)?.status;
      toast.success(
        label
          ? `Ticket #${row.helpdesk_id} set to ${label}.`
          : `Ticket #${row.helpdesk_id} updated.`,
        { title: 'Status updated' },
      );
    } catch (err) {
      setError(err);
      // Put the dropdown back, so it does not claim a status the API refused.
      setRows((prev) =>
        prev.map((r) => (r.helpdesk_id === row.helpdesk_id ? { ...r, status: row.status } : r)),
      );
      toast.error(err?.message ?? 'The ticket status could not be changed. Please try again.');
    } finally {
      setSavingStatus(null);
    }
  };

  const openCount = rows.filter((r) => Number(r.status) !== 4).length;
  const resolvedCount = rows.filter((r) => Number(r.status) === 4).length;

  const visible = useMemo(() => {
    if (tab === 'open') return rows.filter((r) => Number(r.status) !== 4);
    if (tab === 'resolved') return rows.filter((r) => Number(r.status) === 4);
    return rows;
  }, [rows, tab]);

  const statusName = (id) =>
    statuses.find((s) => Number(s.id) === Number(id))?.status ?? `Status ${id}`;

  const columns = [
    { key: 'helpdesk_id', label: 'Ticket' },
    /*
     * Building Name and Unit, the two columns support_ticket.aspx put first.
     *
     * Both need SQL/FIX_helpdesk_tickets_building_unit.sql applied: GetTickets
     * dropped them in its UserDataCombined CTE, so until that runs they arrive
     * undefined. Unit falls back to flat_no, which the CTE has always carried,
     * so the column still says something on an unmigrated database.
     */
    { key: 'build_name', label: 'Building Name' },
    { key: 'Unit', label: 'Unit', render: (v, row) => v || row.flat_no || '—' },
    { key: 'p_type_name', label: 'Type' },
    { key: 'query', label: 'Query' },
    { key: 'name', label: 'Raised by' },
    {
      key: 'req_service_date',
      label: 'Service date',
      // Unlike `date`, this one is not CONVERTed by the SP, so it arrives as a
      // full timestamp and showed a meaningless 00:00:00 next to the date.
      render: dateOnly,
      sortValue: (r) => r.req_service_date ?? '',
    },
    {
      key: 'urgency',
      label: 'Urgency',
      render: (v) => (
        <span
          className={`rounded px-2 py-0.5 text-xs font-medium ${
            Number(v) === 0 ? 'bg-slate-100 text-slate-600' : 'bg-red-50 text-red-700'
          }`}
        >
          {urgencyLabel(v)}
        </span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      // Sorts and exports by the name shown, not the id behind it.
      sortValue: (r) => statusName(r.status),
      render: (v, row) => (
        <select
          className="field-input py-1 text-sm print:hidden"
          value={String(v ?? '')}
          disabled={savingStatus === row.helpdesk_id}
          aria-label={`Status for ticket ${row.helpdesk_id}`}
          onChange={(e) => changeStatus(row, e.target.value)}
        >
          <option value="">Select Status</option>
          {statuses.map((s) => (
            <option key={s.id} value={s.id}>
              {s.status}
            </option>
          ))}
        </select>
      ),
    },
    /*
     * Comments and images are columns rather than row actions, as they were on
     * the legacy grid. Left in the actions slot both buttons sat side by side
     * and stretched that column wide enough to squeeze the query text; under
     * their own headings each button sits below its label instead.
     */
    {
      key: 'comments',
      label: 'Comments',
      sortable: false,
      render: (_v, row) => (
        <button
          type="button"
          className="btn-secondary print:hidden"
          onClick={() => openComments(row)}
        >
          View
        </button>
      ),
    },
    {
      key: 'image',
      label: 'Image',
      sortable: false,
      render: (_v, row) => (
        <button
          type="button"
          className="btn-secondary print:hidden"
          onClick={() => openImages(row)}
        >
          View
        </button>
      ),
    },
  ];

  return (
    <section>
      <PageHeader title="Helpdesk" subtitle={`${visible.length} ticket(s)`} />

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Open" value={openCount} tone="warning" />
        <StatCard label="Resolved" value={resolvedCount} tone="positive" />
        <StatCard label="Total" value={rows.length} />
      </div>

      <Tabs
        tabs={[
          { id: 'open', label: 'Open', count: openCount },
          { id: 'resolved', label: 'Resolved', count: resolvedCount },
          { id: 'all', label: 'All', count: rows.length },
        ]}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      <ErrorNotice error={error} onRetry={load} />

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={visible}
          idKey="helpdesk_id"
          loading={loading}
          searchable
          searchPlaceholder="Search here"
          exportName="helpdesk-tickets"
          emptyTitle="No tickets"
          emphasiseRow={(r) => Number(r.urgency) !== 0}
        />
      </div>

      {/* ------------------------------------------------------- comments */}
      <Modal
        open={Boolean(comments)}
        title={`Helpdesk Comments — #${comments?.ticket?.helpdesk_id ?? ''}`}
        onClose={() => setComments(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setComments(null)}>
            Close
          </button>
        }
      >
        {comments?.loading ? <Spinner /> : null}
        {comments && !comments.loading ? (
          <div className="space-y-4">
            <p className="text-sm text-slate-600">
              <span className="font-medium text-slate-800">{comments.ticket?.name}</span>
              {comments.ticket?.Unit || comments.ticket?.flat_no
                ? ` — ${comments.ticket.Unit ?? comments.ticket.flat_no}`
                : ''}
            </p>
            <p className="rounded-md bg-slate-50 p-3 text-sm text-slate-700">
              {comments.ticket?.query}
            </p>

            {/*
              The legacy thread put residents left and staff right, keyed off
              `type` — anything that is not owner/member is the office replying.
            */}
            {comments.comments?.length ? (
              <ul className="max-h-[320px] space-y-3 overflow-y-auto rounded border border-slate-200 bg-slate-50 p-3">
                {comments.comments.map((c) => {
                  const t = String(c.type ?? '').toLowerCase();
                  const fromResident = t === 'owner' || t === 'member';
                  return (
                    <li
                      key={c.comment_id}
                      className={`max-w-[75%] ${fromResident ? '' : 'ml-auto'}`}
                    >
                      <div className="surface overflow-hidden rounded-2xl">
                        <div
                          className={`px-3 py-1.5 text-xs font-semibold ${
                            fromResident ? 'bg-slate-200 text-slate-800' : 'bg-[#fbe3e3] text-[#7d1a1a]'
                          }`}
                        >
                          {c.name}
                        </div>
                        <p className="whitespace-pre-wrap px-3 py-2 text-sm text-slate-700">
                          {c.description}
                        </p>
                        <p className="px-3 pb-2 text-xs text-slate-400">
                          {commentTime(c.dateTime)}
                        </p>
                      </div>
                    </li>
                  );
                })}
              </ul>
            ) : (
              <EmptyState title="No comments available." />
            )}

            <form onSubmit={postReply} className="space-y-2 border-t border-slate-200 pt-3">
              <TextAreaField
                label="Write a reply"
                name="reply"
                rows={3}
                maxLength={500}
                placeholder="Type your reply here..."
                value={reply}
                onChange={(e) => setReply(e.target.value)}
              />
              <button type="submit" className="btn-primary" disabled={busy || !reply.trim()}>
                {busy ? 'Sending…' : 'Send'}
              </button>
            </form>
          </div>
        ) : null}
      </Modal>

      {/* --------------------------------------------------------- images */}
      <Modal
        open={Boolean(images)}
        title={`Helpdesk Images — #${images?.ticket?.helpdesk_id ?? ''}`}
        onClose={() => setImages(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setImages(null)}>
            Close
          </button>
        }
      >
        {images?.loading ? <Spinner /> : null}
        {images && !images.loading ? <TicketImages value={images.ticket?.image} /> : null}
      </Modal>
    </section>
  );
}

/**
 * The attachments for one ticket.
 *
 * GetRequestById returns them STRING_AGG'd into one comma-separated column, so
 * the list is split back out here. Stacked rather than put in a carousel: the
 * legacy one hid every image after the first behind arrows, and these are
 * usually two or three photos of the same fault.
 */
function TicketImages({ value }) {
  const paths = String(value ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  if (!paths.length) return <EmptyState title="No images found." />;

  return (
    <div className="space-y-3">
      {paths.map((p) => (
        <TicketImage key={p} path={p} />
      ))}
    </div>
  );
}
