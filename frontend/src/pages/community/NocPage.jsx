import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { community } from '@/api/modules';
import { useAuth } from '@/auth/AuthContext.jsx';
import DataGrid from '@/components/DataGrid.jsx';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import {
  PageHeader,
  SelectField,
  StatCard,
  Tabs,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';

/**
 * NOC — what members have asked for, and what the society issued.
 *
 * Requests and certificates are two stages of one thing, and the page follows
 * that order. A member raises a request; the committee approves it, which is
 * what creates the certificate; the secretary prints and signs it and gives
 * out a day to collect it. Only then does a row appear under Certificates.
 *
 * They are separate tabs because they answer different questions — "what needs
 * an answer today" against "what have we issued" — but a request carries its
 * own certificate once it has one, so the secretary never has to cross from
 * one tab to the other to see what a request produced.
 */

/* ------------------------------------------------------------------ types */

/**
 * The kinds of NOC, and the wording each one turns on.
 *
 * The clause is offered as a starting point the secretary can rewrite. It is
 * sent to the server on every save rather than derived there: a certificate is
 * a legal statement fixed when it was signed, so rewording the society's
 * standard clause later must not change what an already-issued certificate
 * reads.
 */
const NOC_TYPES = [
  {
    code: 'NoDues',
    label: 'No dues',
    clause:
      'to the issue of this certificate, all maintenance charges and other dues ' +
      'payable in respect of the said flat having been paid in full as on the ' +
      'date of this certificate.',
  },
  {
    code: 'SaleTransfer',
    label: 'Sale / transfer',
    clause:
      'to the sale and transfer of the said flat by the member, and holds no ' +
      'claim, charge or lien over the said flat other than its dues, if any.',
  },
  {
    code: 'Renovation',
    label: 'Renovation',
    clause:
      'to the internal repairs and renovation work proposed by the member in the ' +
      'said flat, subject to no damage being caused to the structure of the ' +
      'building.',
  },
  {
    code: 'Mortgage',
    label: 'Mortgage / loan',
    clause:
      'to the member mortgaging the said flat to a bank or financial institution ' +
      'for the purpose of availing a loan.',
  },
  {
    code: 'General',
    label: 'General',
    clause: 'to the requested purpose mentioned below in respect of the said flat.',
  },
  { code: 'Other', label: 'Other', clause: '' },
];

const typeLabel = (code) => NOC_TYPES.find((t) => t.code === code)?.label ?? code ?? '—';
const typeClause = (code) => NOC_TYPES.find((t) => t.code === code)?.clause ?? '';

/**
 * Where a request has got to.
 *
 * Codes are vendor_bills': 1 Pending, 2 Approved, 4 Rejected, with 5 Ready and
 * 6 Collected for the two steps that happen on paper. 3 is skipped — it means
 * Paid there and nothing here.
 */
const STATUS = {
  1: { label: 'Pending', tone: 'bg-amber-50 text-amber-700' },
  2: { label: 'Approved', tone: 'bg-blue-50 text-blue-700' },
  4: { label: 'Rejected', tone: 'bg-red-50 text-red-700' },
  5: { label: 'Ready to collect', tone: 'bg-green-50 text-green-700' },
  6: { label: 'Collected', tone: 'bg-slate-100 text-slate-600' },
};

const statusOf = (code) => STATUS[Number(code)] ?? STATUS[1];

const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/** Today as yyyy-MM-dd, for the collection date input's floor. */
const todayIso = () => new Date().toISOString().slice(0, 10);

/**
 * Which officers sign this society's certificates, from Settings → Account.
 *
 * A context rather than a prop: the certificate sheet is rendered in two
 * places — the certificates list and the request that produced it — and
 * threading one society-wide setting through both would have every component
 * between them carrying it.
 *
 * The default is both officers under their usual names, which is what the
 * sheet printed before this was configurable.
 */
const DEFAULT_SIGNATORIES = {
  mode: 'Both',
  secretary: 'Secretary',
  chairman: 'Chairman',
};

const SignatoriesContext = createContext(DEFAULT_SIGNATORIES);

/* ------------------------------------------------------------------- page */

export default function NocPage() {
  const [tab, setTab] = useState('requests');
  const [search, setSearch] = useState('');
  const [requests, setRequests] = useState([]);
  const [certificates, setCertificates] = useState([]);
  const [signatories, setSignatories] = useState(null);
  const [adding, setAdding] = useState(false);
  // The certificate open in the preview — opened from the list, or handed
  // straight over by the form that has just issued it.
  const [viewing, setViewing] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Searched server-side by both procedures — on member, flat and serial, the
  // three things somebody asking about a NOC actually knows.
  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = search.trim() ? { search: search.trim() } : undefined;
      const [reqs, certs] = await Promise.all([
        community.nocRequests(params),
        community.nocCertificates(params),
      ]);
      setRequests(reqs.items ?? []);
      setCertificates(certs.items ?? []);
      // Rides along with the certificate list rather than a call of its own.
      if (certs.signatories) setSignatories(certs.signatories);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    load();
  }, [load]);

  /*
   * The requests still on somebody's desk.
   *
   * A collected request is finished: the letter is signed and in the member's
   * hands, and the record of it is the certificate. Leaving it under Requests
   * would grow that tab forever with rows nobody has to do anything about,
   * and the secretary would scroll past every NOC the society has ever issued
   * to reach the two waiting for an answer.
   */
  const openRequests = useMemo(
    () => requests.filter((r) => Number(r.status) !== 6),
    [requests],
  );

  const counts = useMemo(() => {
    const by = (code) => requests.filter((r) => Number(r.status) === code).length;
    return {
      pending: by(1),
      approved: by(2),
      ready: by(5),
      issued: certificates.length,
    };
  }, [requests, certificates]);

  if (error) return <ErrorNotice error={error} onRetry={load} />;

  return (
    // Until the setting has loaded the context's own default stands, which is
    // what the sheet printed before it was configurable.
    <SignatoriesContext.Provider value={signatories ?? DEFAULT_SIGNATORIES}>
    <section className="space-y-4">
      <PageHeader
        title="NOC"
        subtitle="Requests from members, and the certificates they produced"
      >
        <input
          type="search"
          className="field-input w-56"
          placeholder="Search member, flat or serial…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search NOC"
        />
        {/* Issuing without a request behind it is the exception — the member
            who asked at the desk — so the button says what it makes rather
            than a bare "Add". */}
        <button type="button" className="btn-primary" onClick={() => setAdding(true)}>
          Add NOC
        </button>
      </PageHeader>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard label="Awaiting a decision" value={counts.pending} tone="warning" />
        <StatCard label="Approved, to be signed" value={counts.approved} />
        <StatCard label="Ready to collect" value={counts.ready} tone="positive" />
        <StatCard label="Certificates issued" value={counts.issued} />
      </div>

      <Tabs
        active={tab}
        onChange={setTab}
        tabs={[
          { id: 'requests', label: 'Requests', count: openRequests.length },
          {
            id: 'certificates',
            label: 'Certificates',
            count: certificates.length,
          },
        ]}
      />

      {loading ? (
        <Spinner />
      ) : tab === 'requests' ? (
        <RequestsTab rows={openRequests} onChanged={load} onIssue={setAdding} />
      ) : (
        <CertificatesTab rows={certificates} onChanged={load} onOpen={setViewing} />
      )}

      {adding && (
        <CertificateFormModal
          fromRequest={adding === true ? null : adding}
          onClose={() => setAdding(false)}
          onSaved={(issued) => {
            setAdding(false);
            setTab('certificates');
            load();
            // Straight into the letter with its number on it: printing what
            // was just issued is the next thing the secretary does, and
            // finding the row in the list to open it is a step with no
            // purpose.
            setViewing(issued);
          }}
        />
      )}

      {viewing && (
        <Modal
          open
          title={viewing.serial_no || 'Certificate'}
          onClose={() => setViewing(null)}
          maxWidth="max-w-3xl"
        >
          <Certificate detail={viewing} />
        </Modal>
      )}
    </section>
    </SignatoriesContext.Provider>
  );
}

/* --------------------------------------------------------------- requests */

function RequestsTab({ rows, onChanged, onIssue }) {
  const [open, setOpen] = useState(null);
  const [confirmDelete, setConfirmDelete] = useState(null);
  const toast = useToast();

  const remove = async () => {
    try {
      await community.removeNocRequest(confirmDelete.request_id);
      toast.success('Request deleted.');
      setConfirmDelete(null);
      onChanged();
    } catch (err) {
      toast.error(err?.message ?? 'Could not delete the request');
    }
  };

  // DataGrid calls render as (value, row) — the cell's own value first, the
  // whole record second.
  const columns = [
    {
      key: 'member_name',
      label: 'Member',
      render: (v, r) => (
        <div>
          <div className="font-medium text-slate-800">{v || '—'}</div>
          <div className="text-xs text-slate-500">
            {[r.building_name, r.flat_no].filter(Boolean).join(' · ') || '—'}
          </div>
        </div>
      ),
    },
    {
      key: 'noc_type',
      label: 'Type',
      render: (v, r) => (v === 'Other' && r.custom_title ? r.custom_title : typeLabel(v)),
    },
    { key: 'purpose', label: 'Purpose', render: (v) => v || '—' },
    { key: 'requested_on', label: 'Requested', render: day },
    {
      key: 'status',
      label: 'Status',
      render: (v, r) => {
        const s = statusOf(v);
        return (
          <div className="space-y-1">
            <span
              className={`inline-block rounded px-2 py-0.5 text-xs font-medium ${s.tone}`}
            >
              {s.label}
            </span>
            {/* How far the approvals have got, while it is still waiting. */}
            {Number(r.status) === 1 && Number(r.approver_count) > 0 && (
              <div className="text-xs text-slate-500">
                {r.approved_count} of {r.approver_count} approved
              </div>
            )}

            {/* Who settled it. Any one officer can, so "approved" alone does
                not say which of them did — and an approved row no longer opens
                a drawer where that could be read. */}
            {r.decided_by && Number(r.status) !== 1 && (
              <div className="text-xs text-slate-500">
                {Number(r.status) === 4 ? 'Rejected' : 'Approved'} by {r.decided_by}
                {r.decided_on ? ` · ${day(r.decided_on)}` : ''}
              </div>
            )}

            {Number(r.status) === 5 && r.collection_date && (
              <div className="text-xs text-slate-500">{day(r.collection_date)}</div>
            )}
          </div>
        );
      },
    },
    { key: 'serial_no', label: 'Certificate', render: (v) => v || '—' },
  ];

  return (
    <>
      <DataGrid
        columns={columns}
        rows={rows}
        idKey="request_id"
        emptyTitle="No NOC requests"
        emptyHint="Requests members raise from their app appear here."
        actions={(r) => (
          <>
            {/* An approved request with no certificate yet needs exactly one
                thing: writing it. The button says so and opens the form,
                rather than opening a drawer whose only content is the same
                button again. */}
            {Number(r.status) === 2 && !r.noc_id ? (
              <button type="button" className="btn-primary" onClick={() => onIssue(r)}>
                NOC
              </button>
            ) : (
              <button
                type="button"
                className="btn-secondary"
                onClick={() => setOpen(r)}
              >
                Open
              </button>
            )}
            <button
              type="button"
              className="btn-danger"
              onClick={() => setConfirmDelete(r)}
            >
              Delete
            </button>
          </>
        )}
      />

      {open && (
        <RequestDrawer
          request={open}
          onClose={() => setOpen(null)}
          onIssue={(r) => {
            setOpen(null);
            onIssue(r);
          }}
          onChanged={() => {
            setOpen(null);
            onChanged();
          }}
        />
      )}

      {confirmDelete && (
        <ConfirmDialog
          open
          title="Delete this request?"
          message={`${confirmDelete.member_name ?? 'This member'}'s ${typeLabel(
            confirmDelete.noc_type,
          )} request will be removed.`}
          confirmLabel="Delete"
          onConfirm={remove}
          onCancel={() => setConfirmDelete(null)}
        />
      )}
    </>
  );
}

/**
 * One request, and whatever it needs next.
 *
 * What is on offer follows the status rather than being shown all at once: a
 * pending request needs wording and approvers, an approved one needs a
 * collection date, a ready one needs marking as handed over. Showing every
 * control at every stage would mean most of them being disabled most of the
 * time.
 */
function RequestDrawer({ request, onClose, onChanged, onIssue }) {
  const { user } = useAuth();
  const toast = useToast();

  const [detail, setDetail] = useState(null);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setError(null);
    try {
      setDetail(await community.nocRequest(request.request_id));
    } catch (err) {
      setError(err);
    }
  }, [request.request_id]);

  useEffect(() => {
    load();
  }, [load]);

  const status = Number(detail?.status ?? request.status);

  /**
   * Run one action, then close the drawer and reload the list behind it.
   *
   * Every action here settles what the drawer was open for, and what comes
   * next is a button on the row: an approved request grows a NOC button, a
   * ready one is marked collected. Keeping the drawer open would leave the
   * secretary looking at a request that no longer needs them.
   */
  const act = async (fn, message) => {
    setBusy(true);
    try {
      await fn();
      toast.success(message);
      onChanged();
    } catch (err) {
      toast.error(err?.message ?? 'That did not go through');
      setBusy(false);
    }
  };

  return (
    <Modal
      title={`${request.member_name ?? 'Member'} — ${
        request.noc_type === 'Other' && request.custom_title
          ? request.custom_title
          : typeLabel(request.noc_type)
      }`}
      onClose={onClose}
      open
      maxWidth="max-w-3xl"
    >
      {error ? (
        <ErrorNotice error={error} onRetry={load} />
      ) : !detail ? (
        <Spinner />
      ) : (
        <div className="space-y-5">
          <Summary detail={detail} />

          {status === 1 && (
            <PendingSection
              detail={detail}
              userId={user?.user_id}
              busy={busy}
              act={act}
            />
          )}

          {/* Approved, in two steps: write the certificate, then give the
              member a day to collect the signed copy. The collection date is
              no use before the letter exists — there is nothing to print. */}
          {status === 2 &&
            (detail.noc_id ? (
              <ReadySection detail={detail} busy={busy} act={act} />
            ) : (
              <IssueSection detail={detail} onIssue={onIssue} />
            ))}

          {status === 5 && <CollectSection detail={detail} busy={busy} act={act} />}

          {status === 4 && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
              <div className="font-medium">Rejected</div>
              {detail.reject_reason && <div className="mt-1">{detail.reject_reason}</div>}
            </div>
          )}

          {status === 6 && (
            <div className="rounded-lg bg-slate-50 p-3 text-sm text-slate-700">
              Collected on {day(detail.collected_on)}
              {detail.collected_by ? ` by ${detail.collected_by}` : ''}.
            </div>
          )}

          {/* The certificate this request produced, shown on the request
              itself rather than on a list of its own: the secretary reaches it
              by opening the request they were already looking at, and never
              has to match a serial against a name to find it. */}
          {detail.serial_no && <Certificate detail={detail} />}

          {(detail.approvals ?? []).length > 0 && (
            <ApprovalList approvals={detail.approvals} />
          )}
        </div>
      )}
    </Modal>
  );
}

/**
 * The certificate as the letter reads, with the three things done to it.
 *
 * The same document the Secretary app shows, and the same one `elementToPdf`
 * captures: a letterhead, the reference line, the recital, the operative "no
 * objection" sentence, the particulars as a table, and the two signature
 * blocks. What is on screen is what comes out of the printer, so the secretary
 * is never surprised by the page they hand over.
 */
function Certificate({ detail, actions = true }) {
  const sheetRef = useRef(null);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const { user } = useAuth();
  const signatories = useContext(SignatoriesContext);

  /*
   * The lines the sheet leaves for ink, from the society's own setting.
   *
   * How many officers sign is each society's rule, so this is configured in
   * Settings rather than fixed here. A line for an officer who does not sign
   * leaves a blank the member is asked about at the bank; one missing for an
   * officer who does means reprinting the letter.
   */
  const signatureRoles =
    signatories.mode === 'Secretary'
      ? [signatories.secretary]
      : signatories.mode === 'Chairman'
        ? [signatories.chairman]
        : [signatories.secretary, signatories.chairman];

  const society = user?.society_name || 'The society';
  const title =
    detail.noc_type === 'Other' && detail.custom_title
      ? detail.custom_title
      : typeLabel(detail.noc_type);

  const member = detail.member_name || '____________';
  const flat = detail.flat_no || '______';
  const filename = `noc-${detail.serial_no || member}`.replace(/[^\w-]+/g, '-');

  const exportSheet = async (print) => {
    setBusy(true);
    try {
      const { elementToPdf } = await import('@/lib/pdf');
      await elementToPdf(sheetRef.current, filename, { print });
    } catch (err) {
      toast.error(err?.message ?? 'Could not produce the PDF');
    } finally {
      setBusy(false);
    }
  };

  /*
   * Share hands the PDF to the device's own share sheet where there is one —
   * a phone or a tablet. On a desktop browser there is none, and the Web Share
   * API either is missing or refuses a file, so the same PDF is downloaded
   * instead: the secretary still ends up with a file to attach to an email,
   * which is what sharing meant here anyway.
   */
  const share = async () => {
    setBusy(true);
    try {
      const { elementToPdfBlob } = await import('@/lib/pdf');
      const blob = await elementToPdfBlob(sheetRef.current);
      const file = new File([blob], `${filename}.pdf`, {
        type: 'application/pdf',
      });

      if (navigator.canShare?.({ files: [file] })) {
        await navigator.share({
          files: [file],
          title: detail.serial_no || 'NOC',
        });
        return;
      }

      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${filename}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
      toast.success('Downloaded — attach it to an email or message to share.');
    } catch (err) {
      // The user dismissing the share sheet rejects with AbortError; that is
      // a choice, not a failure worth a red toast.
      if (err?.name !== 'AbortError') {
        toast.error(err?.message ?? 'Could not share the certificate');
      }
    } finally {
      setBusy(false);
    }
  };

  const particulars = [
    ['Member name', member],
    ['Flat no.', flat],
    ...(detail.building_name ? [['Building / wing', detail.building_name]] : []),
    ...(detail.purpose ? [['Purpose', detail.purpose]] : []),
    ['Date of issue', day(detail.issued_on)],
    // No end date means the certificate does not lapse — a real and common
    // choice, not a missing value.
    ['Valid till', detail.valid_till ? day(detail.valid_till) : 'Does not lapse'],
  ];

  return (
    <div className="space-y-3">
      {/* Off in the form's preview: there is nothing to print or share until
          the certificate has been issued and given its number. */}
      {actions && (
        <div className="flex flex-wrap justify-end gap-2 print:hidden">
          <button
            type="button"
            className="btn-secondary"
            disabled={busy}
            onClick={() => exportSheet(true)}
          >
            Print
          </button>
          <button
            type="button"
            className="btn-secondary"
            disabled={busy}
            onClick={() => exportSheet(false)}
          >
            Download PDF
          </button>
          <button type="button" className="btn-secondary" disabled={busy} onClick={share}>
            Share
          </button>
        </div>
      )}

      {/* The captured sheet. White ground and fixed ink colours: html2canvas
          photographs whatever is on screen, so a themed background would end
          up on the printed page. */}
      <div
        ref={sheetRef}
        className="bg-white p-2 text-slate-900"
        style={{ colorScheme: 'light' }}
      >
        {/* The double rule is what makes the block read as a certificate
            rather than as a panel — the printed sheet carries the same. */}
        <div className="border-[1.2px] border-amber-600 p-[3px]">
          <div className="border border-amber-600/45 p-6">
            <header className="text-center">
              <h2 className="text-lg font-bold uppercase tracking-wide">{society}</h2>
              <p className="mt-1 text-xs text-slate-500">
                Registered Co-operative Housing Society
              </p>
              <div className="mx-auto mt-3 h-px w-24 bg-amber-600" />
              <h3 className="mt-3 text-base font-semibold uppercase tracking-wide">
                {title} — No Objection Certificate
              </h3>
            </header>

            <div className="mt-6 flex items-start justify-between text-xs">
              <div>
                <div className="text-slate-500">Certificate No.</div>
                <div className="font-medium text-slate-800">
                  {detail.serial_no || '—'}
                </div>
              </div>
              <div className="text-right">
                <div className="text-slate-500">Date of Issue</div>
                <div className="font-medium text-slate-800">{day(detail.issued_on)}</div>
              </div>
            </div>

            <div className="mt-6 space-y-3 text-sm leading-relaxed">
              <p>
                This is to certify that {member}, residing in Flat No. {flat}
                {detail.building_name ? `, ${detail.building_name}` : ''}, {society}, is a
                registered member/resident of our society.
              </p>
              <p>
                The society has <strong>no objection</strong>{' '}
                {detail.clause || typeClause(detail.noc_type)}
              </p>
              {detail.remarks && <p className="text-slate-700">{detail.remarks}</p>}
            </div>

            <div className="mt-6 border-t border-slate-200 pt-4">
              <dl className="grid gap-2 text-xs sm:grid-cols-2">
                {particulars.map(([label, value]) => (
                  <div key={label}>
                    <dt className="text-slate-500">{label}</dt>
                    <dd className="text-slate-800">{value}</dd>
                  </div>
                ))}
              </dl>
            </div>

            {/* A line for each officer, both blank for ink — nothing here is a
                digital signature. Two rather than one because societies
                commonly have both sign and a bank may look for both; how many
                are actually required is the society's own rule, so one signing
                officer just leaves the other line empty. */}
            <div className="mt-8 flex items-end justify-between gap-4">
              <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-full border-[1.2px] border-amber-600 text-center text-[7px] font-bold leading-tight text-amber-700">
                SOCIETY
                <br />
                SEAL
              </div>
              {signatureRoles.map((role) => (
                <div key={role} className="text-center">
                  <div className="h-8" />
                  <div className="w-28 border-t border-slate-400" />
                  <div className="mt-1 text-xs font-semibold">{role}</div>
                  <div className="text-[10px] text-slate-500">{society}</div>
                </div>
              ))}
            </div>

            {/* States what this sheet is, not what makes it valid. How many
                signatures a society's certificate needs is set by its own
                bye-laws and by whoever is being asked to act on it — a line
                claiming both are required would have a society that signs with
                one officer declaring its own certificates invalid. */}
            <p className="mt-6 border-t border-slate-200 pt-2 text-center text-[10px] text-slate-500">
              Issued by the society. Please sign and affix the society seal before
              handing this certificate over.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

function Summary({ detail }) {
  const s = statusOf(detail.status);
  const rows = [
    ['Flat', [detail.building_name, detail.flat_no].filter(Boolean).join(' · ') || '—'],
    ['Purpose', detail.purpose || '—'],
    ['Requested on', day(detail.requested_on)],
  ];

  return (
    <div className="rounded-lg border border-slate-200 p-4">
      <div className="mb-3 flex items-center justify-between">
        <span className="text-sm font-medium text-slate-700">Request</span>
        <span className={`rounded px-2 py-0.5 text-xs font-medium ${s.tone}`}>
          {s.label}
        </span>
      </div>
      <dl className="grid gap-2 text-sm sm:grid-cols-2">
        {rows.map(([label, value]) => (
          <div key={label}>
            <dt className="text-xs text-slate-500">{label}</dt>
            <dd className="text-slate-800">{value}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

/**
 * A pending request: approve it or refuse it.
 *
 * Nothing is chosen here first. The request already went to every office the
 * society has — admin, secretary, chairman — the moment the member raised it,
 * because it goes to the same offices every time and asking the committee to
 * "send" it to themselves settled nothing.
 *
 * The wording is not settled here either. It belongs on the certificate, and
 * that is written from the issue form once the request is approved — which is
 * also where the issue date, the wing and whether it lapses are set, none of
 * which the request carries.
 */
function PendingSection({ detail, userId, busy, act }) {
  const [rejecting, setRejecting] = useState(false);
  const [rejectReason, setRejectReason] = useState('');

  const approvals = detail.approvals ?? [];

  // The approval this signed-in officer was asked for, if it is unanswered.
  // The server only accepts a decision from the officer it was asked of, so
  // there is nothing to gain by showing anyone else's as actionable.
  const mine = approvals.find(
    (a) => String(a.user_id) === String(userId) && Number(a.approval_status) === 1,
  );

  // Signed in as somebody the request did not go to — a treasurer or an
  // ordinary committee member — or as an officer who has already answered.
  if (!mine) {
    return (
      <p className="rounded-lg bg-slate-50 p-3 text-sm text-slate-600">
        {approvals.length
          ? 'Waiting on the officers listed below.'
          : 'This request has not reached any officer yet. Reopen it in a moment.'}
      </p>
    );
  }

  return (
    <section className="space-y-3 rounded-lg border border-slate-200 bg-slate-50 p-4">
      <h3 className="text-sm font-medium text-slate-700">Your decision</h3>

      {rejecting ? (
        <>
          <TextAreaField
            name="reason"
            label="Reason"
            required
            rows={2}
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            hint="The member is shown this."
          />
          <div className="flex gap-2">
            <button
              type="button"
              disabled={busy || !rejectReason.trim()}
              onClick={() =>
                act(
                  () =>
                    community.decideNocRequest(detail.request_id, mine.approval_id, {
                      decision: 'reject',
                      remarks: rejectReason.trim(),
                    }),
                  'Rejected.',
                )
              }
              className="rounded-lg bg-red-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
            >
              Confirm rejection
            </button>
            <button
              type="button"
              onClick={() => setRejecting(false)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-700 hover:bg-white"
            >
              Cancel
            </button>
          </div>
        </>
      ) : (
        <div className="flex gap-2">
          <button
            type="button"
            disabled={busy}
            onClick={() =>
              act(
                () =>
                  community.decideNocRequest(detail.request_id, mine.approval_id, {
                    decision: 'approve',
                  }),
                'Approved. Use the NOC button to write the certificate.',
              )
            }
            className="rounded-lg bg-green-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50"
          >
            Approve
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={() => setRejecting(true)}
            className="rounded-lg border border-red-300 px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-50 disabled:opacity-50"
          >
            Reject
          </button>
        </div>
      )}
    </section>
  );
}

/**
 * Approved, with no certificate written yet.
 *
 * The letter carries more than the request does — the member's name as it
 * should read, the wing, an issue date, whether it lapses — and a certificate
 * is fixed the moment it is issued. So the secretary writes it on the form,
 * which opens filled in from the request rather than blank.
 */
function IssueSection({ detail, onIssue }) {
  return (
    <section className="space-y-3 rounded-lg border border-blue-200 bg-blue-50/40 p-4">
      <h3 className="text-sm font-medium text-slate-700">Issue the certificate</h3>
      <p className="text-xs text-slate-600">
        Approved. Write the certificate and it will be given its number — the
        form opens with what {detail.member_name || 'the member'} asked for
        already filled in.
      </p>
      <button
        type="button"
        onClick={() => onIssue(detail)}
        className="rounded-lg bg-slate-900 px-3 py-1.5 text-sm font-medium text-white hover:bg-slate-800"
      >
        Issue certificate
      </button>
    </section>
  );
}

/** Certificate written: print it, get it signed, then tell the member when to come. */
function ReadySection({ detail, busy, act }) {
  const [date, setDate] = useState(todayIso());
  const [time, setTime] = useState('');
  const [note, setNote] = useState('');

  return (
    <section className="space-y-3 rounded-lg border border-blue-200 bg-blue-50/40 p-4">
      <h3 className="text-sm font-medium text-slate-700">Ready for collection</h3>
      {/* "Get it signed", not "have the chairman and secretary sign it":
          which officers sign is the society's own rule, and the sheet leaves
          a line for each rather than requiring both. */}
      <p className="text-xs text-slate-600">
        Print the certificate{detail.serial_no ? ` (${detail.serial_no})` : ''}, get it
        signed and sealed, then give the member a day to collect it. They are told as
        soon as you save this.
      </p>

      <TextField
        name="collectionDate"
        label="Collection date"
        type="date"
        required
        min={todayIso()}
        value={date}
        onChange={(e) => setDate(e.target.value)}
      />
      <TextField
        name="officeHours"
        label="Office hours"
        value={time}
        onChange={(e) => setTime(e.target.value)}
        placeholder="10 AM – 1 PM"
      />
      <TextField
        name="anythingToBring"
        label="Anything to bring"
        value={note}
        onChange={(e) => setNote(e.target.value)}
        placeholder="Carry your Aadhaar card"
      />

      <button
        type="button"
        disabled={busy || !date}
        onClick={() =>
          act(
            () =>
              community.setNocReady(detail.request_id, {
                collectionDate: date,
                collectionTime: time || undefined,
                collectionNote: note || undefined,
              }),
            'The member has been told when to collect it.',
          )
        }
        className="rounded-lg bg-slate-900 px-3 py-1.5 text-sm font-medium text-white hover:bg-slate-800 disabled:opacity-50"
      >
        Notify the member
      </button>
    </section>
  );
}

/** Ready: record who took it away, or move the appointment. */
function CollectSection({ detail, busy, act }) {
  const [collectedBy, setCollectedBy] = useState('');
  const [date, setDate] = useState(
    (detail.collection_date ?? '').slice(0, 10) || todayIso(),
  );
  const [time, setTime] = useState(detail.collection_time ?? '');
  const [note, setNote] = useState(detail.collection_note ?? '');
  const [rescheduling, setRescheduling] = useState(false);

  return (
    <section className="space-y-3 rounded-lg border border-green-200 bg-green-50/40 p-4">
      <h3 className="text-sm font-medium text-slate-700">Waiting to be collected</h3>
      <p className="text-xs text-slate-600">
        {day(detail.collection_date)}
        {detail.collection_time ? `, ${detail.collection_time}` : ''}
        {detail.collection_note ? ` — ${detail.collection_note}` : ''}
      </p>

      {rescheduling ? (
        <>
          <TextField
            name="collectionDate"
            label="Collection date"
            type="date"
            min={todayIso()}
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />
          <TextField
            name="officeHours"
            label="Office hours"
            value={time}
            onChange={(e) => setTime(e.target.value)}
            placeholder="10 AM – 1 PM"
          />
          <TextField
            name="anythingToBring"
            label="Anything to bring"
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
          <div className="flex gap-2">
            <button
              type="button"
              disabled={busy || !date}
              onClick={() =>
                act(
                  () =>
                    community.setNocReady(detail.request_id, {
                      collectionDate: date,
                      collectionTime: time || undefined,
                      collectionNote: note || undefined,
                    }),
                  'The member has been told the new date.',
                )
              }
              className="rounded-lg bg-slate-900 px-3 py-1.5 text-sm font-medium text-white hover:bg-slate-800 disabled:opacity-50"
            >
              Save new date
            </button>
            <button
              type="button"
              onClick={() => setRescheduling(false)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-700 hover:bg-white"
            >
              Cancel
            </button>
          </div>
        </>
      ) : (
        <>
          <TextField
            name="collectedBy"
            label="Collected by"
            value={collectedBy}
            onChange={(e) => setCollectedBy(e.target.value)}
            placeholder={detail.member_name ?? 'The member'}
            hint="Leave blank if the member collected it themselves."
          />
          <div className="flex gap-2">
            <button
              type="button"
              disabled={busy}
              onClick={() =>
                act(
                  () =>
                    community.setNocCollected(detail.request_id, {
                      collectedBy: collectedBy.trim() || undefined,
                    }),
                  'Marked as collected.',
                )
              }
              className="rounded-lg bg-green-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50"
            >
              Mark as collected
            </button>
            <button
              type="button"
              onClick={() => setRescheduling(true)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-700 hover:bg-white"
            >
              Change the date
            </button>
          </div>
        </>
      )}
    </section>
  );
}

/** Who was asked to decide, and what they said. */
function ApprovalList({ approvals }) {
  const label = (code) =>
    Number(code) === 2 ? 'Approved' : Number(code) === 4 ? 'Rejected' : 'Waiting';
  const tone = (code) =>
    Number(code) === 2
      ? 'text-green-700'
      : Number(code) === 4
        ? 'text-red-700'
        : 'text-slate-500';

  /*
   * Answered officers first.
   *
   * Any one of them settles the request, so the useful line is "who decided
   * this" — and under a list of seven accounts held by three people, the
   * officer who actually answered was as likely to be at the bottom as the
   * top.
   */
  const ordered = [...approvals].sort(
    (a, b) =>
      (Number(a.approval_status) === 1 ? 1 : 0) -
      (Number(b.approval_status) === 1 ? 1 : 0),
  );

  return (
    <section className="rounded-lg border border-slate-200 p-4">
      <h3 className="mb-2 text-sm font-medium text-slate-700">Approvals</h3>
      <ul className="space-y-2">
        {ordered.map((a) => (
          <li key={a.approval_id} className="text-sm">
            <div className="flex items-center justify-between gap-3">
              <span className="min-w-0 text-slate-800">
                {a.name}
                {/* The office, so a name the reader does not recognise still
                    says why this person was asked. */}
                {a.role && <span className="ml-1.5 text-xs text-slate-500">{a.role}</span>}
              </span>
              <span
                className={`shrink-0 text-xs font-medium ${tone(a.approval_status)}`}
              >
                {label(a.approval_status)}
                {a.approval_date ? ` · ${day(a.approval_date)}` : ''}
              </span>
            </div>
            {a.remarks && (
              <div className="mt-0.5 text-xs text-slate-600">{a.remarks}</div>
            )}
          </li>
        ))}
      </ul>
    </section>
  );
}

/* ----------------------------------------------------------- certificates */

/**
 * What the society has issued.
 *
 * A row appears here the moment a request is approved, because that is what
 * creates the certificate. The request itself stays under Requests until it
 * has been collected — the secretary still has to print it, sign it and hand
 * it over, and those are the steps that tab is for.
 */
function CertificatesTab({ rows, onChanged, onOpen }) {
  const [confirmDelete, setConfirmDelete] = useState(null);
  const toast = useToast();

  const remove = async () => {
    try {
      await community.removeNocCertificate(confirmDelete.noc_id);
      toast.success('Certificate deleted.');
      setConfirmDelete(null);
      onChanged();
    } catch (err) {
      toast.error(err?.message ?? 'Could not delete the certificate');
    }
  };

  const columns = [
    { key: 'serial_no', label: 'Serial', render: (v) => v || '—' },
    {
      key: 'member_name',
      label: 'Member',
      render: (v, r) => (
        <div>
          <div className="font-medium text-slate-800">{v || '—'}</div>
          <div className="text-xs text-slate-500">
            {[r.building_name, r.flat_no].filter(Boolean).join(' · ') || '—'}
          </div>
        </div>
      ),
    },
    {
      key: 'noc_type',
      label: 'Type',
      render: (v, r) => (v === 'Other' && r.custom_title ? r.custom_title : typeLabel(v)),
    },
    { key: 'purpose', label: 'Purpose', render: (v) => v || '—' },
    { key: 'issued_on', label: 'Issued', render: day },
    {
      key: 'valid_till',
      label: 'Valid till',
      // A certificate with no end date does not lapse — a real and common
      // choice, not a missing value.
      render: (v) => (v ? day(v) : 'Does not lapse'),
    },
  ];

  return (
    <>
      <DataGrid
        columns={columns}
        rows={rows}
        idKey="noc_id"
        emptyTitle="No certificates issued"
        emptyHint="A certificate is created when a request is fully approved, or you can add one from the button above."
        actions={(r) => (
          <>
            <button type="button" className="btn-secondary" onClick={() => onOpen(r)}>
              Open
            </button>
            <button
              type="button"
              className="btn-danger"
              onClick={() => setConfirmDelete(r)}
            >
              Delete
            </button>
          </>
        )}
      />

      {confirmDelete && (
        <ConfirmDialog
          open
          title="Delete this certificate?"
          message={`${confirmDelete.serial_no} for ${
            confirmDelete.member_name ?? 'this member'
          } will no longer be listed. Any copy already given out stays valid on paper.`}
          confirmLabel="Delete"
          onConfirm={remove}
          onCancel={() => setConfirmDelete(null)}
        />
      )}
    </>
  );
}

/**
 * Issue a certificate directly, without a request behind it.
 *
 * The ordinary route is a member raising a request and the committee approving
 * it, which writes the certificate on its own. This covers the member who
 * asked at the desk: the secretary types what the request would have carried
 * and the certificate is issued at once, with no approval step.
 */
function CertificateFormModal({ onClose, onSaved, fromRequest = null }) {
  const toast = useToast();

  /*
   * Opened from an approved request, the form starts as what the member asked
   * for: the type they chose, their name and flat, the purpose in their own
   * words, and the standard clause for that type. All of it stays editable —
   * the certificate is the society's statement, not a copy of the request, and
   * the wording is what the officers put their name to.
   *
   * Opened from "Add NOC" there is no request behind it and the form is blank
   * but for today's date.
   */
  const startType = fromRequest?.noc_type || 'NoDues';

  const [nocType, setNocType] = useState(startType);
  const [customTitle, setCustomTitle] = useState(fromRequest?.custom_title ?? '');
  const [clause, setClause] = useState(
    fromRequest?.clause || typeClause(startType),
  );
  const [memberName, setMemberName] = useState(fromRequest?.member_name ?? '');
  const [flatNo, setFlatNo] = useState(fromRequest?.flat_no ?? '');
  const [buildingName, setBuildingName] = useState(
    fromRequest?.building_name ?? '',
  );
  const [purpose, setPurpose] = useState(fromRequest?.purpose ?? '');
  const [remarks, setRemarks] = useState(fromRequest?.remarks ?? '');
  const [issuedOn, setIssuedOn] = useState(todayIso());
  const [validTill, setValidTill] = useState(
    (fromRequest?.valid_till ?? '').slice(0, 10),
  );
  const [members, setMembers] = useState([]);
  // Which resident the picker is showing; empty once a field is typed over.
  const [memberId, setMemberId] = useState('');
  const [busy, setBusy] = useState(false);

  /*
   * Picking a member fills the three fields below rather than replacing them.
   * A NOC names a member and a flat, and a mistyped flat number produces a
   * certificate the society cannot stand behind — but the fields stay editable
   * for the resident whose record is out of date or who is not on the list at
   * all. The picker failing leaves the form usable, just typed.
   */
  useEffect(() => {
    community
      .nocMembers()
      .then((d) => {
        const items = d.items ?? [];
        setMembers(items);

        /*
         * Opened from a request: find the resident it came from and fill the
         * picker and the wing from their record.
         *
         * The request carries a flat_id, a name and a flat number, but not the
         * building — the member's app never asked for one. The picker holds
         * it, so matching the request to a row there completes the form the
         * same way choosing that resident by hand would.
         *
         * Matched on flat_id first, which is the request's own key. Falling
         * back to the name is for requests raised at the desk with no flat
         * behind them.
         */
        if (!fromRequest) return;

        const match =
          items.find(
            (m) =>
              fromRequest.flat_id != null &&
              String(m.flat_id) === String(fromRequest.flat_id),
          ) ??
          items.find(
            (m) =>
              fromRequest.member_name &&
              m.name?.trim().toLowerCase() ===
                fromRequest.member_name.trim().toLowerCase(),
          );

        if (!match) return;

        setMemberId(match.id);
        // The request's own name and flat stand — they are what the member
        // asked under. Only the building, which the request never had, is
        // taken from the record.
        if (match.building_name) setBuildingName(match.building_name);
      })
      .catch(() => setMembers([]));
  }, [fromRequest]);

  const pickMember = (id) => {
    // Back to the placeholder: the secretary has cleared the picker, and the
    // fields below are theirs to fill in by hand.
    if (!id) {
      setMemberId('');
      return;
    }

    const m = members.find((x) => x.id === id);
    if (!m) return;

    setMemberId(id);
    setMemberName(m.name ?? '');
    setFlatNo(m.flat_no ?? '');
    setBuildingName(m.building_name ?? '');
  };

  /*
   * Typing over one of the filled fields drops the selection.
   *
   * The picker names a resident on record; once the certificate says something
   * that record does not, leaving that name selected would claim the two still
   * agree. The typed value stands — this only clears what the picker shows.
   */
  const editedByHand = (set) => (e) => {
    setMemberId('');
    set(e.target.value);
  };

  /* Switching type swaps in that type's standard wording, unless the
     secretary has already written something of their own. */
  const changeType = (code) => {
    if (!clause || clause === typeClause(nocType)) setClause(typeClause(code));
    setNocType(code);
  };

  const canSave =
    memberName.trim() &&
    flatNo.trim() &&
    clause.trim() &&
    (nocType !== 'Other' || customTitle.trim());

  /*
   * The form as a certificate, for the preview.
   *
   * Keyed the way a saved row is, so the preview and the issued certificate
   * are rendered by the same component and cannot drift apart. The serial says
   * it is pending because the server allocates it on save — the form cannot
   * know it in advance.
   */
  const previewDetail = {
    serial_no: 'To be allocated',
    noc_type: nocType,
    custom_title: customTitle,
    clause: clause || typeClause(nocType),
    member_name: memberName,
    flat_no: flatNo,
    building_name: buildingName,
    purpose,
    remarks,
    issued_on: issuedOn,
    valid_till: validTill,
  };

  const save = async () => {
    setBusy(true);
    try {
      const reply = await community.createNocCertificate({
        nocType,
        customTitle: nocType === 'Other' ? customTitle.trim() : undefined,
        clause: clause.trim(),
        memberName: memberName.trim(),
        flatNo: flatNo.trim(),
        buildingName: buildingName.trim() || undefined,
        purpose: purpose.trim() || undefined,
        remarks: remarks.trim() || undefined,
        issuedOn: issuedOn || undefined,
        validTill: validTill || undefined,
        // Ties the certificate back to the request it came from, so the
        // member's screen can read its serial and the secretary's list stops
        // offering to issue one that already exists. Absent when the
        // certificate was raised from "Add NOC" with no request behind it.
        requestId: fromRequest?.request_id,
      });
      toast.success(
        reply?.serial_no ? `Issued as ${reply.serial_no}.` : 'Certificate issued.',
      );
      /*
       * Hand back the certificate as it was issued, so the page can open it
       * for printing straight away.
       *
       * Built from what was typed plus the id and serial the server allocated,
       * rather than refetching: the row is in the list the caller reloads, but
       * finding it there would mean waiting on that round trip before the
       * secretary can print the letter they have just issued — which is the
       * next thing they do.
       */
      onSaved({
        ...previewDetail,
        noc_id: reply?.noc_id ?? null,
        serial_no: reply?.serial_no ?? null,
      });
    } catch (err) {
      toast.error(err?.message ?? 'Could not issue the certificate');
      setBusy(false);
    }
  };

  return (
    <Modal
      open
      title="Add NOC certificate"
      description="Issued straight away, with no approval step — for a member who asked at the desk."
      onClose={onClose}
      maxWidth="max-w-2xl"
      footer={
        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={busy || !canSave}
            onClick={save}
            className="rounded-lg bg-slate-900 px-3 py-2 text-sm font-medium text-white hover:bg-slate-800 disabled:opacity-50"
          >
            Issue certificate
          </button>
        </div>
      }
    >
      <div className="space-y-4">
        <SelectField
          name="nocType"
          label="Type"
          value={nocType}
          onChange={(e) => changeType(e.target.value)}
          options={NOC_TYPES.map((t) => ({ value: t.code, label: t.label }))}
        />

        {nocType === 'Other' && (
          <TextField
            name="title"
            label="Title"
            required
            value={customTitle}
            onChange={(e) => setCustomTitle(e.target.value)}
            placeholder="e.g. NOC for gas connection"
          />
        )}

        {members.length > 0 && (
          <SelectField
            name="nocMember"
            label="Pick a member"
            hint="Fills in the name, flat and building below."
            placeholder="Choose a resident…"
            // Holds the selection, so the picker keeps showing whoever was
            // chosen. Editing a field below clears it back to the placeholder:
            // the certificate then no longer says what that record says, and a
            // name still sitting in the picker would claim it does.
            value={memberId}
            onChange={(e) => pickMember(e.target.value)}
            options={members.map((m) => ({
              value: m.id,
              label: [m.name, m.flat_no, m.building_name].filter(Boolean).join(' · '),
            }))}
          />
        )}

        <div className="grid gap-4 sm:grid-cols-2">
          <TextField
            name="member"
            label="Member"
            required
            value={memberName}
            onChange={editedByHand(setMemberName)}
          />
          <TextField
            name="flat"
            label="Flat"
            required
            value={flatNo}
            onChange={editedByHand(setFlatNo)}
          />
        </div>

        <TextField
          name="buildingOrWing"
          label="Building or wing"
          value={buildingName}
          onChange={editedByHand(setBuildingName)}
          hint="Leave blank if the society has none."
        />

        <TextAreaField
          name="theSocietyHasNoObjection"
          label="The society has no objection …"
          required
          rows={4}
          value={clause}
          onChange={(e) => setClause(e.target.value)}
          hint="This is what the certificate will read."
        />

        <TextField
          name="purpose"
          label="Purpose"
          value={purpose}
          onChange={(e) => setPurpose(e.target.value)}
          placeholder="e.g. For a home loan from State Bank of India"
        />

        <TextAreaField
          name="remarks"
          label="Remarks"
          rows={2}
          value={remarks}
          onChange={(e) => setRemarks(e.target.value)}
          hint="Printed as a further paragraph on the letter. Optional."
        />

        <div className="grid gap-4 sm:grid-cols-2">
          <TextField
            name="issuedOn"
            label="Issued on"
            type="date"
            value={issuedOn}
            onChange={(e) => setIssuedOn(e.target.value)}
          />
          <TextField
            name="validTill"
            label="Valid till"
            type="date"
            value={validTill}
            onChange={(e) => setValidTill(e.target.value)}
            hint="Leave blank if it does not lapse."
          />
        </div>

        {/*
          The letter as it will read, updating as the form is filled in — the
          same preview the Secretary app shows under its form. The wording is
          the point of this screen and it is easier to check as a letter than
          as a textarea.

          Collapsible because it is tall: on a laptop it pushes the fields off
          the modal, and a secretary issuing a routine no-dues certificate has
          nothing to check.
        */}
        <details open className="rounded-lg border border-slate-200">
          <summary className="cursor-pointer select-none px-4 py-2 text-sm font-medium text-slate-700">
            Preview
          </summary>
          <div className="border-t border-slate-200 p-3">
            <Certificate detail={previewDetail} actions={false} />
          </div>
        </details>
      </div>
    </Modal>
  );
}
