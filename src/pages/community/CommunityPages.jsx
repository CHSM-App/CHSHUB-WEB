import { useCallback, useEffect, useMemo, useState } from 'react';
import * as M from '@/api/modules';
import { api } from '@/api/client';
import DataGrid from '@/components/DataGrid.jsx';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  FormErrorSummary,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import {
  CheckboxField,
  FileUploadField,
  PageHeader,
  SelectField,
  StatCard,
  Tabs,
  TextAreaField,
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
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/* ------------------------------------------------------ facility booking */

/** Fields follow facility_booking.aspx's form, in its order. */
const EMPTY_BOOKING = {
  facilityId: '',
  bookDate: '',
  ownerId: '',
  flatNo: '',
  flatId: '',
  name: '',
  address: '',
  contact: '',
  fromDate: '',
  toDate: '',
  fromTime: '',
  toTime: '',
  amount: '',
  note: '',
  societyIn: false,
};

/*
 * What each form insists on, in the shape validateFields expects. These
 * mirror the red asterisks already on the inputs, which nothing enforced —
 * every one of these forms carries noValidate, so an empty submit went
 * straight to the API.
 */
const BOOKING_FIELDS = [
  { name: 'facilityId', label: 'Facility', type: 'select', required: true },
  { name: 'bookDate', label: 'Date', required: true },
  { name: 'name', label: 'Name', required: true },
  { name: 'contact', label: 'Contact no', required: true, phone: true, digits: true, maxLength: 10 },
  { name: 'address', label: 'Address', required: true },
  { name: 'fromDate', label: 'From date', required: true },
  { name: 'fromTime', label: 'From time', required: true },
  { name: 'toTime', label: 'To time', required: true },
];

const POLL_FIELDS = [{ name: 'topic', label: 'Topic', required: true }];

const DOCUMENT_FIELDS = [{ name: 'docName', label: 'Document name', required: true }];

const VISITOR_FIELDS = [
  { name: 'v_name', label: 'Visitor name', required: true },
  { name: 'type', label: 'Type', type: 'select', required: true },
  // Optional, but format-checked once filled — the form renders a contact box
  // that no rule covered, so a gate entry saved with "abc" as the number.
  { name: 'contactNo', label: 'Contact number', phone: true, digits: true, maxLength: 10 },
];

/**
 * Facility bookings — replaces facility_booking.aspx.
 *
 * The committee can book on a resident's behalf, as the legacy page allowed;
 * residents also book from the mobile app. Availability is shown per facility.
 */
export function FacilityBookingsPage() {
  const [rows, setRows] = useState([]);
  const [facilities, setFacilities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [search, setSearch] = useState('');
  const [confirming, setConfirming] = useState(null);
  const [form, setForm] = useState(null);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState(null);
  const [lookups, setLookups] = useState({ facilities: [], residents: [] });
  // Per-day cost of the chosen facility; the total is derived from it.
  const [facilityCost, setFacilityCost] = useState(null);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  /*
   * Clear a complaint as soon as its field is answered. These forms update
   * through inline arrows rather than one shared setField, so watching the
   * form is simpler than threading a clear through a dozen handlers — and it
   * behaves the same as the setField-based screens.
   */
  useEffect(() => {
    if (!form) return;
    setFieldErrors((prev) => {
      let changed = false;
      const next = { ...prev };
      for (const k of Object.keys(prev)) {
        if (prev[k] && String(form[k] ?? '').trim() !== '') {
          next[k] = undefined;
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [form]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await M.community.facilityBookings(search ? { search } : undefined);
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

  // Lookups do not depend on the search term, so they load once rather than on
  // every keystroke.
  useEffect(() => {
    M.facilities
      .list()
      .then((d) => setFacilities(d.items ?? []))
      .catch(() => {});
    M.community
      .facilityBookingLookups()
      .then(setLookups)
      .catch(() => {});
  }, []);

  /** Picking a resident fills their contact and address, as the legacy page did. */
  const pickResident = (e) => {
    const ownerId = e.target.value;
    const r = lookups.residents.find((x) => String(x.owner_id) === String(ownerId));
    setForm((p) => ({
      ...p,
      ownerId,
      ...(r
        ? {
            flatId: r.flat_id ?? '',
            // fill_owner carries no flat_no, so the id doubles as the label.
            flatNo: String(r.flat_id ?? ''),
            name: r.name ?? '',
            contact: r.contact ?? '',
            address: r.address ?? '',
          }
        : {}),
    }));
  };

  /** Choosing a facility pulls its per-day charge, as the legacy page did. */
  const pickFacility = async (e) => {
    const facilityId = e.target.value;
    setForm((p) => ({ ...p, facilityId }));
    if (!facilityId) {
      setFacilityCost(null);
      return;
    }
    try {
      const d = await M.community.facilityCharge(facilityId);
      setFacilityCost(d.charge ? Number(d.charge.cost) : null);
    } catch {
      setFacilityCost(null);
    }
  };

  /*
   * Charges, exactly as facility_booking.aspx computes them
   * (facility_booking.aspx.cs:505-535):
   *
   *   cost 0                -> "Free"
   *   otherwise             -> cost x days + 18% GST, days inclusive of both
   *                            ends, and "Invalid date range" if To precedes From.
   *
   * The legacy box was a read-only multi-line field showing the working, with
   * the figure after "=" being what got saved. Same here: the breakdown is
   * shown and the total is what the form submits.
   */
  const charge = useMemo(() => {
    if (facilityCost == null) return null;
    if (facilityCost === 0) return { free: true, total: 0, text: 'Free' };

    // Before any date is chosen, price it as a single day so the charge shows
    // as soon as the facility is picked, rather than staying blank.
    const from = form?.fromDate ? new Date(form.fromDate) : null;
    const to = form?.toDate ? new Date(form.toDate) : from;
    const days = from ? Math.floor((to - from) / 86400000) + 1 : 1;
    if (days < 1) return { invalid: true, text: 'Invalid date range' };

    const base = facilityCost * days;
    const gst = (base * 18) / 100;
    return {
      total: base + gst,
      text: `${base} + 18% GST (${gst}) = ${base + gst}`,
      days,
    };
  }, [facilityCost, form?.fromDate, form?.toDate]);

  const saveBooking = async (e) => {
    e.preventDefault();

    const missing = validateFields(BOOKING_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setFormError(null);
      focusFirstInvalid(BOOKING_FIELDS, missing);
      return;
    }

    setSaving(true);
    setFormError(null);
    try {
      // Save the computed total, not the breakdown text.
      await M.community.createFacilityBooking({ ...form, amount: charge?.total ?? 0 });
      setForm(null);
      await load();
      toast.success('Facility booked successfully.', { title: 'Saved' });
    } catch (err) {
      setFormError(err);
      toast.error('The booking could not be saved. Please check the form and try again.');
    } finally {
      setSaving(false);
    }
  };

  const revenue = rows.reduce((s, r) => s + Number(r.amount || 0), 0);

  return (
    <section>
      <PageHeader title="Facility bookings" subtitle={`${rows.length} booking(s)`}>
        <input
          className="field-input w-56"
          placeholder="Search bookings…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search bookings"
        />
        <button
          type="button"
          className="btn-primary"
          onClick={() => {
            // A fresh dialog must not inherit the last one's complaints.
            setFieldErrors({});
            setForm({ ...EMPTY_BOOKING });
          }}
        >
          Add
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Bookings" value={rows.length} />
        <StatCard label="Revenue" value={money(revenue)} tone="positive" />
        <StatCard label="Facilities" value={facilities.length} />
      </div>

      <ErrorNotice error={error} onRetry={load} />

      <div className="card overflow-hidden">
        <DataGrid
          columns={[
            // Columns as facility_booking.aspx's grid has them:
            // Name · Building · Unit · Phone · Facility · Date · Time · Charges.
            { key: 'name', label: 'Name' },
            { key: 'build_name', label: 'Building' },
            { key: 'Unit', label: 'Unit' },
            { key: 'pre_mob', label: 'Phone' },
            { key: 'facility_name', label: 'Facility' },
            { key: 'to_date', label: 'Date', render: day },
            {
              key: 'from_time',
              label: 'Time',
              render: (v, r) => (v ? `${v} – ${r.to_time ?? ''}` : '—'),
            },
            { key: 'amount', label: 'Charges', align: 'right', render: money },
          ]}
          rows={rows}
          idKey="facility_book_id"
          loading={loading}
          exportName="facility-bookings"
          emptyTitle="No bookings"
          actions={(row) => (
            <button
              type="button"
              className="btn-danger"
              onClick={() =>
                setConfirming({
                  title: 'Cancel booking',
                  message: `Cancel the ${row.facility_name} booking for ${row.name}?`,
                  run: () => M.community.cancelBooking(row.facility_book_id),
                  done: 'Booking cancelled.',
                })
              }
            >
              Cancel
            </button>
          )}
        />
      </div>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        confirmLabel="Cancel booking"
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
            toast.success(confirming.done ?? 'Done.', { title: 'Updated' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'That could not be completed. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />

      {/* Add — facility_booking.aspx's booking form. */}
      <Modal
        open={Boolean(form)}
        title="Book a facility"
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)}>
              Cancel
            </button>
            <button
              type="submit"
              form="booking-form"
              className="btn-primary"
              disabled={
                saving ||
                !form?.facilityId ||
                !form?.name?.trim() ||
                !form?.fromDate ||
                // Legacy showed "Invalid date range" and refused to price it.
                Boolean(charge?.invalid)
              }
            >
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="booking-form" onSubmit={saveBooking} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            {/*
              Field order and labels follow facility_booking.aspx:
              Facilities · Date · Name · Flat no · Name · Address · Contact No ·
              From Date · To Date · From Time · To Time · Charges ·
              Note to Admin · In Society.
            */}
            <SelectField
              label="Facilities"
              name="facilityId"
              error={fieldErrors.facilityId}
              required
              placeholder="Select"
              options={lookups.facilities}
              valueKey="facility_id"
              labelKey="name"
              value={form.facilityId}
              onChange={pickFacility}
            />
            <TextField
              label="Date"
              name="bookDate"
              error={fieldErrors.bookDate}
              type="date"
              required
              value={form.bookDate}
              onChange={(e) => setForm((p) => ({ ...p, bookDate: e.target.value }))}
            />

            {/* The legacy "Name" picker over residents; the plain Name box
                below it is the booking name, which it pre-fills. */}
            <SelectField
              label="Resident"
              name="ownerId"
              placeholder="Select"
              hint="Fills in flat, name, address and contact"
              options={lookups.residents}
              valueKey="owner_id"
              labelKey="name"
              value={form.ownerId}
              onChange={pickResident}
            />
            {/*
              Read-only, as on the legacy page: txt_flat is filled from the
              chosen resident and the save uses the hidden flat_id behind it
              (facility_booking.aspx.cs:156, 243), never the typed text.
            */}
            <TextField
              label="Flat no"
              name="flatNo"
              readOnly
              placeholder="Select a resident"
              value={form.flatNo}
              onChange={() => {}}
            />

            <TextField
              label="Name"
              name="name"
              error={fieldErrors.name}
              required
              placeholder="Enter Name"
              value={form.name}
              onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
            />
            <TextField
              label="Contact No"
              name="contact"
              error={fieldErrors.contact}
              required
              placeholder="Enter Mobile no"
              inputMode="numeric"
              maxLength={10}
              value={form.contact}
              onChange={(e) =>
                setForm((p) => ({ ...p, contact: e.target.value.replace(/\D/g, '').slice(0, 10) }))
              }
            />
            <TextField
              label="Address"
              name="address"
              error={fieldErrors.address}
              required
              className="sm:col-span-2"
              placeholder="Enter Address"
              value={form.address}
              onChange={(e) => setForm((p) => ({ ...p, address: e.target.value }))}
            />

            <TextField
              label="From Date"
              name="fromDate"
              error={fieldErrors.fromDate}
              type="date"
              required
              value={form.fromDate}
              onChange={(e) => setForm((p) => ({ ...p, fromDate: e.target.value }))}
            />
            <TextField
              label="To Date"
              name="toDate"
              type="date"
              value={form.toDate}
              onChange={(e) => setForm((p) => ({ ...p, toDate: e.target.value }))}
            />
            <TextField
              label="From Time"
              name="fromTime"
              error={fieldErrors.fromTime}
              type="time"
              required
              value={form.fromTime}
              onChange={(e) => setForm((p) => ({ ...p, fromTime: e.target.value }))}
            />
            <TextField
              label="To Time"
              name="toTime"
              error={fieldErrors.toTime}
              type="time"
              required
              value={form.toTime}
              onChange={(e) => setForm((p) => ({ ...p, toTime: e.target.value }))}
            />

            {/* Read-only and computed, as on the legacy page: it shows the
                working and the total after "=" is what is saved. */}
            <TextField
              label="Charges"
              name="amount"
              readOnly
              hint={
                charge?.days > 1
                  ? `${charge.days} days at ${money(facilityCost)} per day, plus 18% GST`
                  : 'One day at the facility charge, plus 18% GST'
              }
              placeholder="Select a facility"
              value={charge?.text ?? ''}
              onChange={() => {}}
            />
            <TextField
              label="Note to Admin"
              name="note"
              placeholder="Enter Note"
              value={form.note}
              onChange={(e) => setForm((p) => ({ ...p, note: e.target.value }))}
            />

            <CheckboxField
              label="In Society"
              name="societyIn"
              className="sm:col-span-2"
              checked={form.societyIn}
              onChange={(e) => setForm((p) => ({ ...p, societyIn: e.target.checked }))}
            />

            <div className="sm:col-span-2">
              <ErrorNotice error={formError} />
            </div>
          </form>
        ) : null}
      </Modal>
    </section>
  );
}

/* ---------------------------------------------------------------- polls */

/** Audience groups offered by Vote.aspx's ddlAudience. */
// ddlAudience on Vote.aspx:482 — four options, in this order. The code-behind
// maps each to a notification recipients group (1→5 all, 2→4 committee,
// 3→1 owners, 4→2 tenants).
const POLL_AUDIENCES = [
  { value: '1', label: 'All Members' },
  { value: '2', label: 'Association Committee' },
  { value: '3', label: 'Owners Only' },
  { value: '4', label: 'Tenants Only' },
];

// Vote.aspx required at least two options, so the form starts with two blanks.
const EMPTY_POLL = {
  topic: '',
  description: '',
  expiryDate: '',
  audience: '1',
  allowMultipleVotes: false,
  oneVotePerUnit: false,
  options: ['', ''],
};

/**
 * One poll, as the .poll-card in Vote.aspx: title, question, its options with a
 * result bar each, then a footer with the vote total and the expiry date.
 *
 * Options load when the card mounts — the legacy page rendered them straight
 * into the card from the same query that listed the polls (SELECTALL pivots the
 * options into Option1..N columns), so they are visible without opening
 * anything.
 */
function PollCard({ poll, onShowVotes, onDelete }) {
  const [options, setOptions] = useState(null);
  const [voting, setVoting] = useState(false);
  const [voteError, setVoteError] = useState(null);
  const toast = useToast();

  const loadOptions = useCallback(async () => {
    try {
      const d = await M.community.pollVotes(poll.PollId);
      setOptions(d.items ?? []);
    } catch {
      setOptions([]);
    }
  }, [poll.PollId]);

  useEffect(() => {
    loadOptions();
  }, [loadOptions]);

  /*
   * Clicking an option casts a vote, exactly as the legacy card did. The rules
   * live in sp_PollVoting, so this does not try to pre-judge them — it sends
   * the click and re-reads the counts, and shows whatever the server says when
   * a vote is refused ("Someone from your flat has already voted…").
   */
  const castVote = async (optionId) => {
    if (voting) return;
    setVoting(true);
    setVoteError(null);
    try {
      await M.community.votePoll(poll.PollId, optionId);
      await loadOptions();
      toast.success('Your vote has been recorded.', { title: 'Voted' });
    } catch (err) {
      setVoteError(err);
      toast.error(err?.message ?? 'Your vote could not be recorded. Please try again.');
    } finally {
      setVoting(false);
    }
  };

  const total = (options ?? []).reduce((s, o) => s + Number(o.votes || 0), 0);

  return (
    // break-inside-avoid keeps a card from being split across two columns.
    <article
      className="card mb-4 p-4"
      style={{ breakInside: 'avoid', WebkitColumnBreakInside: 'avoid' }}
    >
      <div className="flex items-start justify-between gap-2">
        <h3 className="text-sm font-bold" style={{ color: '#012970' }}>
          {poll.Topic}
        </h3>
        {/* .delete-btn — the legacy card's ✕ in the corner. */}
        <button
          type="button"
          className="shrink-0 rounded px-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600"
          title="Delete Poll"
          aria-label={`Delete poll ${poll.Topic}`}
          onClick={onDelete}
        >
          ✕
        </button>
      </div>

      {poll.Description ? (
        <p className="mt-1 text-sm text-slate-600">{poll.Description}</p>
      ) : null}

      <div className="mt-3 space-y-2">
        {options === null ? (
          <p className="text-xs text-slate-400">Loading options…</p>
        ) : options.length === 0 ? (
          <p className="text-xs text-slate-400">No options on this poll.</p>
        ) : (
          options.map((o) => {
            const votes = Number(o.votes || 0);
            const pct = total ? Math.round((votes / total) * 100) : 0;
            return (
              <button
                key={o.OptionId}
                type="button"
                className="block w-full rounded-lg px-3 py-2 text-left transition-colors disabled:opacity-60"
                style={{
                  // isSelected marks the option this user voted for; the legacy
                  // card highlighted it the same way.
                  border: o.isSelected ? '1.5px solid #1d4ed8' : '1px solid #e2e8f0',
                  background: o.isSelected ? '#f4f7fe' : '#fff',
                  cursor: voting ? 'wait' : 'pointer',
                }}
                disabled={voting}
                aria-pressed={Boolean(o.isSelected)}
                onClick={() => castVote(o.OptionId)}
              >
                <div className="flex items-baseline justify-between gap-2 text-sm">
                  <span className="min-w-0 truncate text-slate-700">
                    {o.isSelected ? '✓ ' : ''}
                    {o.text}
                  </span>
                  <span className="shrink-0 text-xs font-semibold text-slate-500">{pct}%</span>
                </div>
                <div className="mt-1.5 h-1.5 overflow-hidden rounded-full" style={{ background: '#eef2f9' }}>
                  <div
                    className="h-full rounded-full transition-all duration-500"
                    style={{
                      width: `${pct}%`,
                      background: 'linear-gradient(90deg, #1d4ed8, #4f8cf7)',
                    }}
                  />
                </div>
              </button>
            );
          })
        )}
      </div>

      {/* Why a click did nothing — sp_PollVoting's refusal message verbatim. */}
      {voteError ? (
        <p className="mt-2 text-xs" style={{ color: '#b42318' }} role="status">
          {voteError.message}
        </p>
      ) : null}

      {/* .poll-footer — vote total on the left, expiry on the right. */}
      <div className="mt-3 flex items-center justify-between gap-2 border-t border-slate-100 pt-2.5">
        <button
          type="button"
          className="text-xs font-semibold hover:underline"
          style={{ color: '#1d4ed8' }}
          onClick={onShowVotes}
          title="Show Poll"
        >
          {total} vote{total === 1 ? '' : 's'}
        </button>
        <span className="text-xs text-slate-500">Expires: {day(poll.ExpiryDate)}</span>
      </div>
    </article>
  );
}

/** Polls with per-option vote counts. Replaces Vote.aspx. */
export function PollsPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [detail, setDetail] = useState(null);
  const [form, setForm] = useState(null);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  /*
   * Clear a complaint as soon as its field is answered. These forms update
   * through inline arrows rather than one shared setField, so watching the
   * form is simpler than threading a clear through a dozen handlers — and it
   * behaves the same as the setField-based screens.
   */
  useEffect(() => {
    if (!form) return;
    setFieldErrors((prev) => {
      let changed = false;
      const next = { ...prev };
      for (const k of Object.keys(prev)) {
        if (prev[k] && String(form[k] ?? '').trim() !== '') {
          next[k] = undefined;
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [form]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await M.community.polls();
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const openPoll = async (row) => {
    setDetail({ loading: true, poll: row });
    try {
      const data = await M.community.pollVotes(row.PollId);
      setDetail({ loading: false, poll: row, options: data.items ?? [] });
    } catch (err) {
      setError(err);
      setDetail(null);
    }
  };

  const totalVotes = detail?.options?.reduce((s, o) => s + Number(o.votes || 0), 0) ?? 0;

  const setOption = (i, value) =>
    setForm((p) => ({ ...p, options: p.options.map((o, idx) => (idx === i ? value : o)) }));

  const savePoll = async (e) => {
    e.preventDefault();

    const missing = validateFields(POLL_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setFormError(null);
      focusFirstInvalid(POLL_FIELDS, missing);
      return;
    }

    setSaving(true);
    setFormError(null);
    try {
      await M.community.createPoll({
        ...form,
        options: form.options.map((o) => o.trim()).filter(Boolean),
      });
      setForm(null);
      await load();
      toast.success('Poll created successfully.', { title: 'Saved' });
    } catch (err) {
      setFormError(err);
      toast.error('The poll could not be saved. Please check the form and try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <section>
      <PageHeader title="Polls" subtitle={`${rows.length} active poll(s)`}>
        <button type="button" className="btn-primary" onClick={() => setForm({ ...EMPTY_POLL })}>
          Start Poll
        </button>
      </PageHeader>

      <ErrorNotice error={error} onRetry={load} />

      {/*
        Vote.aspx laid polls out as cards in a masonry grid (#masonryContainer),
        each showing its options inline — not as a table. CSS columns reproduce
        that: cards keep their natural height and flow into the next column.
      */}
      {loading ? (
        <Spinner />
      ) : rows.length === 0 ? (
        <EmptyState title="No active polls" hint="Only polls that have not expired are listed." />
      ) : (
        <div style={{ columnWidth: 320, columnGap: '1rem' }}>
          {rows.map((row) => (
            <PollCard
              key={row.PollId}
              poll={row}
              onShowVotes={() => openPoll(row)}
              onDelete={() =>
                setConfirming({
                  title: 'Delete poll',
                  message: `Delete "${row.Topic}"? Votes cast on it are removed too.`,
                  run: () => M.community.removePoll(row.PollId),
                  done: 'Poll deleted.',
                })
              }
            />
          ))}
        </div>
      )}

      <Modal
        open={Boolean(detail)}
        title={detail?.poll?.Topic ?? 'Poll'}
        onClose={() => setDetail(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
            Close
          </button>
        }
      >
        {detail?.loading ? (
          <Spinner />
        ) : detail?.options?.length ? (
          <div className="space-y-3">
            <p className="text-sm text-slate-600">{detail.poll?.Description}</p>
            <p className="text-sm font-medium text-slate-800">{totalVotes} vote(s) cast</p>
            <ul className="space-y-2">
              {detail.options.map((o) => {
                const pct = totalVotes ? Math.round((Number(o.votes || 0) / totalVotes) * 100) : 0;
                return (
                  <li key={o.OptionId}>
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-700">{o.text}</span>
                      <span className="font-medium text-slate-800">
                        {o.votes} ({pct}%)
                      </span>
                    </div>
                    <div className="mt-1 h-2 rounded-full bg-slate-100">
                      <div className="h-2 rounded-full bg-blue-600" style={{ width: `${pct}%` }} />
                    </div>
                  </li>
                );
              })}
            </ul>
          </div>
        ) : (
          <EmptyState title="No votes recorded yet" />
        )}
      </Modal>

      {/* Start Poll — Vote.aspx's create form. */}
      <Modal
        open={Boolean(form)}
        title="Start a poll"
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)}>
              Cancel
            </button>
            <button
              type="submit"
              form="poll-form"
              className="btn-primary"
              disabled={
                saving ||
                !form?.topic.trim() ||
                !form?.expiryDate ||
                form?.options.filter((o) => o.trim()).length < 2
              }
            >
              {saving ? 'Starting…' : 'Start Poll'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="poll-form" onSubmit={savePoll} className="space-y-4" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <TextField
              label="Topic"
              name="topic"
              error={fieldErrors.topic}
              required
              value={form.topic}
              onChange={(e) => setForm((p) => ({ ...p, topic: e.target.value }))}
            />
            <TextAreaField
              label="Description"
              name="description"
              rows={3}
              value={form.description}
              onChange={(e) => setForm((p) => ({ ...p, description: e.target.value }))}
            />

            <div className="grid gap-3 sm:grid-cols-2">
              <TextField
                label="Expiry date"
                name="expiryDate"
                type="date"
                required
                min={new Date().toISOString().slice(0, 10)}
                value={form.expiryDate}
                onChange={(e) => setForm((p) => ({ ...p, expiryDate: e.target.value }))}
              />
              <SelectField
                label="Audience"
                name="audience"
                placeholder=""
                options={POLL_AUDIENCES}
                value={form.audience}
                onChange={(e) => setForm((p) => ({ ...p, audience: e.target.value }))}
              />
            </div>

            <div>
              <p className="field-label">Options</p>
              <p className="mb-2 text-xs" style={{ color: '#6b7280' }}>
                At least two. Commas are not allowed — options are stored as one
                comma-separated value.
              </p>
              <div className="space-y-2">
                {form.options.map((o, i) => (
                  <div key={i} className="flex gap-2">
                    <input
                      className="field-input"
                      aria-label={`Option ${i + 1}`}
                      placeholder={`Option ${i + 1}`}
                      value={o}
                      onChange={(e) => setOption(i, e.target.value)}
                    />
                    {form.options.length > 2 ? (
                      <button
                        type="button"
                        className="btn-secondary"
                        aria-label={`Remove option ${i + 1}`}
                        onClick={() =>
                          setForm((p) => ({ ...p, options: p.options.filter((_, idx) => idx !== i) }))
                        }
                      >
                        ✕
                      </button>
                    ) : null}
                  </div>
                ))}
              </div>
              <button
                type="button"
                className="btn-secondary mt-2 text-xs"
                onClick={() => setForm((p) => ({ ...p, options: [...p.options, ''] }))}
              >
                Add option
              </button>
            </div>

            <div className="space-y-2">
              <CheckboxField
                label="Allow multiple votes"
                name="allowMultipleVotes"
                checked={form.allowMultipleVotes}
                onChange={(e) => setForm((p) => ({ ...p, allowMultipleVotes: e.target.checked }))}
              />
              <CheckboxField
                label="One vote per unit"
                name="oneVotePerUnit"
                checked={form.oneVotePerUnit}
                onChange={(e) => setForm((p) => ({ ...p, oneVotePerUnit: e.target.checked }))}
              />
            </div>

            <ErrorNotice error={formError} />
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          try {
            await confirming.run();
            await load();
            toast.success(confirming.done ?? 'Done.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'That could not be completed. Please try again.');
          } finally {
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

/* ------------------------------------------------------------- messages */

/** Resident messages to the committee. Replaces Messages_master.aspx. */
export function MessagesPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [viewing, setViewing] = useState(null);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.get('/community/messages');
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const unread = rows.filter((r) => Number(r.view_status) === 0).length;

  /*
   * filterTable() in Messages_master.aspx matched the typed text against every
   * cell but the last (the actions column), so the same fields are searched
   * here. The legacy box doubled as a date picker writing yyyy-MM-dd, which is
   * just text that matches the date column — typing a date still works.
   */
  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter((r) =>
      [r.owner_name, r.message_sub, r.date, r.message]
        .some((v) => String(v ?? '').toLowerCase().includes(q)),
    );
  }, [rows, search]);

  return (
    <section>
      {/* "Messages" — the <h1> on Messages_master.aspx. */}
      <PageHeader
        title="Messages"
        subtitle={`${visible.length} of ${rows.length} message(s) · ${unread} unread`}
      >
        <input
          className="field-input w-64"
          type="search"
          placeholder="Search here"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search messages"
        />
      </PageHeader>

      <ErrorNotice error={error} onRetry={load} />

      <div className="card overflow-hidden">
        <DataGrid
          columns={[
            { key: 'message_sub', label: 'Subject' },
            { key: 'owner_name', label: 'From' },
            { key: 'date', label: 'Date', render: day },
            {
              key: 'view_status',
              label: 'Status',
              render: (v) =>
                Number(v) === 0 ? (
                  <span className="rounded bg-amber-50 px-2 py-0.5 text-xs font-medium text-amber-700">
                    Unread
                  </span>
                ) : (
                  <span className="text-xs text-slate-500">Read</span>
                ),
            },
          ]}
          rows={visible}
          idKey="r_id"
          loading={loading}
          exportName="resident-messages"
          emptyTitle="No Messages Found"
          actions={(row) => (
            <button
              type="button"
              className="btn-secondary"
              onClick={async () => {
                setViewing(row);
                // Opening marks it read, as the legacy grid did.
                if (Number(row.view_status) === 0) {
                  try {
                    await api.put(`/community/messages/${row.r_id}/read`);
                    await load();
                  } catch {
                    /* non-critical */
                  }
                }
              }}
            >
              Read
            </button>
          )}
        />
      </div>

      {/* "Message Details" with Sender / Date / Subject above the body — the
          #viewModal layout from Messages_master.aspx. */}
      <Modal
        open={Boolean(viewing)}
        title="Message Details"
        onClose={() => setViewing(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setViewing(null)}>
            Close
          </button>
        }
      >
        {viewing ? (
          <div className="space-y-3">
            <dl className="space-y-1.5 text-sm">
              <div className="flex gap-2">
                <dt className="font-semibold text-slate-700">Sender:</dt>
                <dd className="min-w-0 text-slate-800">{viewing.owner_name}</dd>
              </div>
              <div className="flex gap-2">
                <dt className="font-semibold text-slate-700">Date:</dt>
                <dd className="text-slate-800">{day(viewing.date)}</dd>
              </div>
              <div className="flex gap-2">
                <dt className="font-semibold text-slate-700">Subject:</dt>
                <dd className="min-w-0 text-slate-800">{viewing.message_sub}</dd>
              </div>
            </dl>

            <div>
              <p className="field-label">Message</p>
              {/* Read-only multiline box, as the legacy TextBox was. */}
              <p
                className="whitespace-pre-wrap rounded-md p-3 text-sm text-slate-700"
                style={{ background: '#f8f9fc', border: '1px solid #e2e8f0', minHeight: '7rem' }}
              >
                {viewing.message}
              </p>
            </div>
          </div>
        ) : null}
      </Modal>
    </section>
  );
}

/* ------------------------------------------------------------ documents */

/** Society documents with upload. Replaces upload_doc_search.aspx. */
export function DocumentsPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [search, setSearch] = useState('');
  const [form, setForm] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  /*
   * Clear a complaint as soon as its field is answered. These forms update
   * through inline arrows rather than one shared setField, so watching the
   * form is simpler than threading a clear through a dozen handlers — and it
   * behaves the same as the setField-based screens.
   */
  useEffect(() => {
    if (!form) return;
    setFieldErrors((prev) => {
      let changed = false;
      const next = { ...prev };
      for (const k of Object.keys(prev)) {
        if (prev[k] && String(form[k] ?? '').trim() !== '') {
          next[k] = undefined;
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [form]);
  const [viewing, setViewing] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await M.documents.list(search ? { search } : undefined);
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

  const save = async (event) => {
    event.preventDefault();

    const missing = validateFields(DOCUMENT_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(DOCUMENT_FIELDS, missing);
      return;
    }
    // The file is not a Field, so it keeps its own message rather than a
    // per-field complaint.
    if (!form.filePath) {
      setError(new Error('Upload a file first'));
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await api.post('/uploads/record/society-document', {
        docName: form.docName,
        tag: form.tag,
        description: form.description,
        filePath: form.filePath,
      });
      setForm(null);
      await load();
      toast.success('Document uploaded successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  return (
    <section>
      <PageHeader title="Society documents" subtitle={`${rows.length} document(s)`}>
        <input
          className="field-input w-56"
          placeholder="Search documents…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search documents"
        />
        <button
          type="button"
          className="btn-primary"
          onClick={() => setForm({ docName: '', tag: '', description: '', filePath: '' })}
        >
          Upload document
        </button>
      </PageHeader>

      {!form ? <ErrorNotice error={error} onRetry={load} /> : null}

      <div className="card overflow-hidden">
        <DataGrid
          columns={[
            { key: 'doc_name', label: 'Document' },
            { key: 'Tag', label: 'Tag' },
            { key: 'Description', label: 'Description' },
            { key: 'date', label: 'Uploaded', render: day },
          ]}
          rows={rows}
          idKey="file_id"
          loading={loading}
          exportName="society-documents"
          emptyTitle="No documents uploaded"
          actions={(row) => (
            <>
              {/* upload_doc_search.aspx linked the stored file from each row.
                  Rows whose path is on the old server's disk still get the
                  button — the modal explains why they cannot be opened. */}
              {String(row.file_save_path ?? '').trim() ? (
                <button type="button" className="btn-secondary" onClick={() => setViewing(row)}>
                  View
                </button>
              ) : null}
              <button
                type="button"
                className="btn-danger"
                onClick={() =>
                  setConfirming({
                    title: 'Delete document',
                    done: 'Document deleted.',
                    message: `Delete ${row.doc_name}?`,
                    run: () => M.documents.remove(row.file_id),
                  })
                }
              >
                Delete
              </button>
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(form)}
        title="Upload document"
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="doc-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="doc-form" onSubmit={save} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <TextField
              label="Document name"
              name="docName"
              error={fieldErrors.docName}
              required
              value={form.docName}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, docName: value }));
              }}
            />
            <TextField
              label="Tag"
              name="tag"
              value={form.tag}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, tag: value }));
              }}
            />
            <TextAreaField
              label="Description"
              name="description"
              rows={2}
              className="sm:col-span-2"
              value={form.description}
              onChange={(e) => {
                const { value } = e.target;
                setForm((p) => ({ ...p, description: value }));
              }}
            />
            <FileUploadField
              label="File"
              category="society-documents"
              className="sm:col-span-2"
              hint="JPEG, PNG or PDF, up to 10 MB"
              currentPath={form.filePath}
              onUploaded={(f) => f && setForm((p) => ({ ...p, filePath: f.path }))}
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
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
            toast.success(confirming.done ?? 'Done.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'That could not be completed. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />

      <DocumentFileModal doc={viewing} onClose={() => setViewing(null)} />
    </section>
  );
}

/**
 * Views the file stored against a society document.
 *
 * Files served by this API sit behind the bearer token, which an <iframe>
 * cannot send, so the file is fetched through the authenticated client and
 * shown as a blob. Older rows hold a path on the previous server's disk
 * (`D:\VengurlaTech\…`) rather than an uploaded file; those cannot be reached
 * over HTTP at all, so the modal explains that instead of failing silently.
 */
function DocumentFileModal({ doc, onClose }) {
  const reason = doc ? unopenableReason(doc.file_save_path) : null;
  // Not fetched when there is a reason against it — a legacy path resolves to
  // a URL nothing serves, which showed a 404 page inside the viewer.
  const target = doc && !reason ? openableUrl(doc.file_save_path) : null;

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
      open={Boolean(doc)}
      title={doc?.doc_name ? `Document — ${doc.doc_name}` : 'Document'}
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
          title={`Document ${doc?.doc_name ?? ''}`}
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

/* -------------------------------------------------------------- visitors */

/**
 * visitor_search.aspx swapped in a different panel per visitor type, but every
 * panel wrote the same three columns — company, location and vehicle_no. Only
 * the labels differed, so the type drives labels and which inputs are shown
 * rather than a separate form per type.
 */
const VISITOR_TYPES = {
  Guest: [
    { name: 'location', label: 'Address' },
    { name: 'purpose', label: 'Purpose of visit' },
  ],
  Cab: [
    { name: 'company', label: 'Cab company' },
    { name: 'vehicleNo', label: 'Vehicle number' },
    { name: 'location', label: 'Pickup / drop location' },
  ],
  Delivery: [
    { name: 'company', label: 'Delivery company' },
    { name: 'vehicleNo', label: 'Vehicle number' },
    { name: 'purpose', label: 'Package description' },
  ],
  Service: [
    { name: 'company', label: 'Service company' },
    { name: 'vehicleNo', label: 'Vehicle number' },
    { name: 'purpose', label: 'Nature of work' },
  ],
};

const EMPTY_VISITOR = {
  name: '',
  type: 'Guest',
  contactNo: '',
  flatId: '',
  buildId: '',
  company: '',
  vehicleNo: '',
  location: '',
  purpose: '',
  inDate: '',
  inTime: '',
};

/** Visitor log with in/out detail. Replaces visitor_search.aspx. */
export function VisitorsPage() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [detail, setDetail] = useState(null);
  const [tab, setTab] = useState('all');
  const [form, setForm] = useState(null); // null = closed; object = open
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  /*
   * Clear a complaint as soon as its field is answered. These forms update
   * through inline arrows rather than one shared setField, so watching the
   * form is simpler than threading a clear through a dozen handlers — and it
   * behaves the same as the setField-based screens.
   */
  useEffect(() => {
    if (!form) return;
    setFieldErrors((prev) => {
      let changed = false;
      const next = { ...prev };
      for (const k of Object.keys(prev)) {
        if (prev[k] && String(form[k] ?? '').trim() !== '') {
          next[k] = undefined;
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [form]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await M.community.visitors();
      setRows(data.items ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const visible = useMemo(() => {
    if (tab === 'inside') return rows.filter((r) => r.in_date && !r.out_date);
    if (tab === 'expected') return rows.filter((r) => !r.in_date);
    return rows;
  }, [rows, tab]);

  const openNew = () =>
    setForm({ ...EMPTY_VISITOR, inDate: new Date().toISOString().slice(0, 10) });

  const openEdit = (row) =>
    setForm({
      visitor_id: row.visitor_id,
      name: row.v_name ?? '',
      type: row.type ?? 'Guest',
      contactNo: row.contact_no ?? '',
      flatId: row.flat_id ?? '',
      buildId: row.build_id ?? '',
      company: row.company ?? '',
      vehicleNo: row.vehicle_no ?? '',
      location: row.location ?? '',
      purpose: row.purpose ?? '',
      inDate: row.in_date ?? '',
      inTime: row.in_time ?? '',
    });

  const save = async (e) => {
    e.preventDefault();

    const missing = validateFields(VISITOR_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setFormError(null);
      focusFirstInvalid(VISITOR_FIELDS, missing);
      return;
    }

    setSaving(true);
    setFormError(null);
    try {
      const wasEdit = Boolean(form.visitor_id);
      if (wasEdit) await M.community.updateVisitor(form.visitor_id, form);
      else await M.community.createVisitor(form);
      setForm(null);
      await load();
      toast.success(`Visitor ${wasEdit ? 'updated' : 'registered'} successfully.`, { title: 'Saved' });
    } catch (err) {
      setFormError(err);
      toast.error('The visitor could not be saved. Please check the form and try again.');
    } finally {
      setSaving(false);
    }
  };

  const runConfirmed = async () => {
    if (!confirming) return;
    try {
      await confirming.run();
      await load();
      toast.success(confirming.done ?? 'Done.', { title: 'Updated' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'That could not be completed. Please try again.');
    } finally {
      setConfirming(null);
    }
  };

  // Which extra inputs this type shows — see VISITOR_TYPES.
  const typeFields = form ? (VISITOR_TYPES[form.type] ?? VISITOR_TYPES.Guest) : [];

  return (
    <section>
      <PageHeader title="Visitors" subtitle={`${visible.length} visitor(s)`}>
        <button type="button" className="btn-primary" onClick={openNew}>
          Register visitor
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Total (30 days)" value={rows.length} />
        <StatCard
          label="Currently inside"
          value={rows.filter((r) => r.in_date && !r.out_date).length}
          tone="warning"
        />
        <StatCard label="Expected" value={rows.filter((r) => !r.in_date).length} />
      </div>

      <Tabs
        tabs={[
          { id: 'all', label: 'All', count: rows.length },
          { id: 'inside', label: 'Inside', count: rows.filter((r) => r.in_date && !r.out_date).length },
          { id: 'expected', label: 'Expected', count: rows.filter((r) => !r.in_date).length },
        ]}
        active={tab}
        onChange={setTab}
        className="mb-4"
      />

      <ErrorNotice error={error} onRetry={load} />

      <div className="card overflow-hidden">
        <DataGrid
          columns={[
            { key: 'v_name', label: 'Visitor' },
            { key: 'type', label: 'Type' },
            { key: 'unit', label: 'Unit' },
            { key: 'contact_no', label: 'Contact' },
            { key: 'in_date', label: 'In' },
            { key: 'in_time', label: 'Time in' },
            { key: 'out_time', label: 'Time out' },
            { key: 'purpose', label: 'Purpose' },
          ]}
          rows={visible}
          idKey="visitor_id"
          loading={loading}
          exportName="visitors"
          emptyTitle="No visitors"
          actions={(row) => (
            <>
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setDetail(row)}
              >
                View
              </button>
              <button
                type="button"
                className="btn-secondary"
                onClick={() => openEdit(row)}
              >
                Edit
              </button>
              {row.in_date && !row.out_date ? (
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() =>
                    setConfirming({
                      title: 'Check out visitor',
                      message: `Record ${row.v_name} leaving now?`,
                      run: () => M.community.checkoutVisitor(row.visitor_id),
                  done: 'Visitor checked out.',
                    })
                  }
                >
                  Check out
                </button>
              ) : null}
              <button
                type="button"
                className="btn-danger"
                onClick={() =>
                  setConfirming({
                    title: 'Delete visitor',
                    message: `Delete the record for ${row.v_name}?`,
                    run: () => M.community.removeVisitor(row.visitor_id),
                  done: 'Visitor deleted.',
                  })
                }
              >
                Delete
              </button>
            </>
          )}
        />
      </div>

      <Modal
        open={Boolean(detail)}
        title={detail?.v_name ?? 'Visitor'}
        onClose={() => setDetail(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
            Close
          </button>
        }
      >
        {detail ? (
          <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
            {[
              ['Visitor', detail.v_name],
              ['Type', detail.type],
              ['Company', detail.company],
              ['Unit', detail.unit],
              ['Resident', detail.UserName],
              ['Contact', detail.contact_no],
              ['Vehicle', detail.vehicle_no],
              ['Purpose', detail.purpose],
              ['In', `${detail.in_date ?? '—'} ${detail.in_time ?? ''}`],
              ['Out', `${detail.out_date ?? '—'} ${detail.out_time ?? ''}`],
              ['Approved by', detail.Approver_Name],
              ['Gate OTP', detail.gateOtp],
            ].map(([label, value]) => (
              <div key={label}>
                <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
                <dd className="mt-0.5 text-slate-800">{value || '—'}</dd>
              </div>
            ))}
          </dl>
        ) : null}
      </Modal>

      <Modal
        open={Boolean(form)}
        title={form?.visitor_id ? 'Edit visitor' : 'Register visitor'}
        onClose={() => setForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setForm(null)}>
              Cancel
            </button>
            <button
              type="submit"
              form="visitor-form"
              className="btn-primary"
              disabled={saving || !form?.name.trim()}
            >
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {form ? (
          <form id="visitor-form" className="grid gap-3 sm:grid-cols-2" onSubmit={save} noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <TextField
              label="Visitor name"
              name="v_name"
              error={fieldErrors.v_name}
              required
              value={form.name}
              onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
            />
            <SelectField
              label="Visitor type"
              name="type"
              error={fieldErrors.type}
              required
              placeholder=""
              options={Object.keys(VISITOR_TYPES).map((t) => ({ value: t, label: t }))}
              value={form.type}
              onChange={(e) => setForm((p) => ({ ...p, type: e.target.value }))}
            />

            <TextField
              label="Contact number"
              // Named for the form key, not the column: focusFirstInvalid and
              // the error lookup both go by the field name, and "contact_no"
              // matched neither.
              name="contactNo"
              error={fieldErrors.contactNo}
              inputMode="numeric"
              maxLength={10}
              value={form.contactNo}
              onChange={(e) =>
                setForm((p) => ({ ...p, contactNo: e.target.value.replace(/\D/g, '').slice(0, 10) }))
              }
            />
            <TextField
              label="Flat ID"
              name="flat_id"
              type="number"
              hint="Unit being visited"
              value={form.flatId}
              onChange={(e) => setForm((p) => ({ ...p, flatId: e.target.value }))}
            />

            {/* Inputs that depend on the visitor type. */}
            {typeFields.map((f) => (
              <TextField
                key={f.name}
                label={f.label}
                name={f.name}
                value={form[f.name] ?? ''}
                onChange={(e) => setForm((p) => ({ ...p, [f.name]: e.target.value }))}
              />
            ))}

            <TextField
              label="In date"
              name="in_date"
              type="date"
              value={form.inDate}
              onChange={(e) => setForm((p) => ({ ...p, inDate: e.target.value }))}
            />
            <TextField
              label="In time"
              name="in_time"
              type="time"
              value={form.inTime}
              onChange={(e) => setForm((p) => ({ ...p, inTime: e.target.value }))}
            />

            <div className="sm:col-span-2">
              <ErrorNotice error={formError} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        onCancel={() => setConfirming(null)}
        onConfirm={runConfirmed}
      />
    </section>
  );
}
