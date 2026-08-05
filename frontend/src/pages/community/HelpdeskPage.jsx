import { useCallback, useEffect, useMemo, useState } from 'react';
import { community } from '@/api/modules';
import DataGrid from '@/components/DataGrid.jsx';
import { EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import { PageHeader, SelectField, StatCard, Tabs, TextAreaField } from '@/components/FormControls.jsx';

const day = (v) => (v ? new Date(v).toLocaleString() : '—');

const URGENCY = { 1: 'Low', 2: 'Medium', 3: 'High' };

/** Status ids come from HelpdeskStatus; 4 is the resolved state. */
const statusTone = (id) =>
  Number(id) === 4
    ? 'bg-green-50 text-green-700'
    : Number(id) === 1
      ? 'bg-amber-50 text-amber-700'
      : 'bg-slate-100 text-slate-600';

/**
 * Helpdesk — full parity with Society2024/support_ticket.aspx.
 *
 * Ticket list with status filtering, a detail view carrying the full comment
 * thread, attached images, and the status transition control.
 */
export default function HelpdeskPage() {
  const [rows, setRows] = useState([]);
  const [statuses, setStatuses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [tab, setTab] = useState('open');

  const [detail, setDetail] = useState(null);
  const [comment, setComment] = useState('');
  const [newStatus, setNewStatus] = useState('');

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

  const openTicket = async (row) => {
    setDetail({ loading: true, ticket: row });
    setComment('');
    setNewStatus(String(row.status ?? ''));
    try {
      const data = await community.helpdeskTicket(row.helpdesk_id);
      setDetail({ loading: false, ...data });
      setNewStatus(String(data.ticket?.status ?? row.status ?? ''));
    } catch (err) {
      setError(err);
      setDetail(null);
    }
  };

  const addComment = async (event) => {
    event.preventDefault();
    if (!comment.trim()) return;
    setBusy(true);
    try {
      await community.addHelpdeskComment(detail.ticket.helpdesk_id, {
        comment,
        flatId: detail.ticket.flat_id,
        type: 'Admin',
      });
      setComment('');
      await openTicket(detail.ticket);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const changeStatus = async () => {
    setBusy(true);
    try {
      await community.setHelpdeskStatus(detail.ticket.helpdesk_id, Number(newStatus));
      await openTicket(detail.ticket);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const visible = useMemo(() => {
    if (tab === 'open') return rows.filter((r) => Number(r.status) !== 4);
    if (tab === 'resolved') return rows.filter((r) => Number(r.status) === 4);
    return rows;
  }, [rows, tab]);

  const statusName = (id) =>
    statuses.find((s) => Number(s.id) === Number(id))?.status ?? `Status ${id}`;

  const columns = [
    { key: 'helpdesk_id', label: 'Ticket' },
    { key: 'query', label: 'Query' },
    { key: 'p_type_name', label: 'Category' },
    { key: 'name', label: 'Raised by' },
    { key: 'flat_no', label: 'Flat' },
    {
      key: 'urgency',
      label: 'Urgency',
      render: (v) => URGENCY[Number(v)] ?? '—',
    },
    {
      key: 'status',
      label: 'Status',
      render: (v) => (
        <span className={`rounded px-2 py-0.5 text-xs font-medium ${statusTone(v)}`}>
          {statusName(v)}
        </span>
      ),
    },
    { key: 'date', label: 'Raised' },
  ];

  return (
    <section>
      <PageHeader title="Helpdesk" subtitle={`${visible.length} ticket(s)`} />

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Open" value={rows.filter((r) => Number(r.status) !== 4).length} tone="warning" />
        <StatCard label="Resolved" value={rows.filter((r) => Number(r.status) === 4).length} tone="positive" />
        <StatCard label="Total" value={rows.length} />
      </div>

      <Tabs
        tabs={[
          { id: 'open', label: 'Open', count: rows.filter((r) => Number(r.status) !== 4).length },
          { id: 'resolved', label: 'Resolved', count: rows.filter((r) => Number(r.status) === 4).length },
          { id: 'all', label: 'All', count: rows.length },
        ]}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      {!detail ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={columns}
          rows={visible}
          idKey="helpdesk_id"
          loading={loading}
          exportName="helpdesk-tickets"
          emptyTitle="No tickets"
          actions={(row) => (
            <button type="button" className="btn-secondary" onClick={() => openTicket(row)}>
              Open
            </button>
          )}
        />
      </div>

      <Modal
        open={Boolean(detail)}
        title={`Ticket #${detail?.ticket?.helpdesk_id ?? ''}`}
        onClose={() => setDetail(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
            Close
          </button>
        }
      >
        {detail?.loading ? (
          <Spinner />
        ) : detail ? (
          <div className="space-y-5">
            <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm sm:grid-cols-3">
              {[
                ['Raised by', detail.ticket?.name],
                ['Unit', detail.ticket?.Unit ?? detail.ticket?.flat_no],
                ['Category', detail.ticket?.categoryName ?? detail.ticket?.p_type_name],
                ['Raised', detail.ticket?.date],
                ['Service date', detail.ticket?.req_service_date],
                ['Building', detail.ticket?.build_name],
              ].map(([label, value]) => (
                <div key={label}>
                  <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
                  <dd className="mt-0.5 text-slate-800">{value ?? '—'}</dd>
                </div>
              ))}
            </dl>

            <div>
              <h3 className="mb-1 text-sm font-semibold text-slate-800">Query</h3>
              <p className="rounded-md bg-slate-50 p-3 text-sm text-slate-700">
                {detail.ticket?.query}
              </p>
            </div>

            {/* Attachments arrive as a comma-separated list of file names. */}
            {detail.ticket?.image ? (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Attachments</h3>
                <ul className="flex flex-wrap gap-2">
                  {String(detail.ticket.image)
                    .split(',')
                    .filter(Boolean)
                    .map((img) => (
                      <li key={img} className="rounded bg-slate-100 px-2 py-1 text-xs text-slate-600">
                        {img}
                      </li>
                    ))}
                </ul>
              </div>
            ) : null}

            <div className="flex flex-wrap items-end gap-3 border-t border-slate-200 pt-4">
              <SelectField
                label="Status"
                name="status"
                className="w-56"
                options={statuses}
                valueKey="id"
                labelKey="status"
                placeholder="Select status…"
                value={newStatus}
                onChange={(e) => setNewStatus(e.target.value)}
              />
              <button
                type="button"
                className="btn-primary"
                disabled={busy || !newStatus || String(newStatus) === String(detail.ticket?.status)}
                onClick={changeStatus}
              >
                Update status
              </button>
            </div>

            <div>
              <h3 className="mb-2 text-sm font-semibold text-slate-800">
                Comments ({detail.comments?.length ?? 0})
              </h3>
              {detail.comments?.length ? (
                <ul className="space-y-2">
                  {detail.comments.map((c) => (
                    <li key={c.comment_id} className="rounded-md border border-slate-200 p-3">
                      <div className="flex flex-wrap items-baseline justify-between gap-2">
                        <span className="text-sm font-medium text-slate-800">{c.name}</span>
                        <span className="text-xs text-slate-500">{day(c.dateTime)}</span>
                      </div>
                      <p className="mt-1 text-sm text-slate-700">{c.description}</p>
                    </li>
                  ))}
                </ul>
              ) : (
                <EmptyState title="No comments yet" />
              )}

              <form onSubmit={addComment} className="mt-3 space-y-2">
                <TextAreaField
                  label="Add a comment"
                  name="comment"
                  rows={3}
                  value={comment}
                  onChange={(e) => setComment(e.target.value)}
                />
                <button type="submit" className="btn-primary" disabled={busy || !comment.trim()}>
                  {busy ? 'Posting…' : 'Post comment'}
                </button>
              </form>
            </div>

            <ErrorNotice error={error} />
          </div>
        ) : null}
      </Modal>
    </section>
  );
}
