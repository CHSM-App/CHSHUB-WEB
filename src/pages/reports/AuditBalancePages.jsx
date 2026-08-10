import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { reports } from '@/api/modules';
import { api } from '@/api/client';
import DataGrid from '@/components/DataGrid.jsx';
import { ConfirmDialog, EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import {
  PageHeader,
  SelectField,
  StatCard,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// Audit.aspx printed dd/MM/yyyy under the signature block.
const auditDate = () => new Date().toLocaleDateString('en-GB');

// LoadAuditPeriod() hardcoded this string; there is no stored period to read,
// so it is carried over as-is rather than invented from the current date.
const AUDIT_PERIOD = 'दि.०१-०४-२०२४ ते दि. ३१-०३-२०२५ अखेरचे';

/**
 * The society's address as the legacy page built it — the parts joined with
 * ", ", empty ones dropped (LoadSocietyInfo in Audit.aspx.cs).
 */
const fullAddress = (info) =>
  [
    info?.off_address1,
    info?.off_address2,
    info?.city,
    info?.division,
    info?.district,
    info?.state,
    info?.pincode,
  ]
    .map((p) => (p == null ? '' : String(p).trim()))
    .filter(Boolean)
    .join(', ');

/**
 * The formal audit report — the legacy page's "📄 View Audit Form" modal
 * (लेखापरिक्षण अहवाल), rendered for screen, print and PDF alike.
 *
 * Sections with no questions are left out, matching rptHeaders_ItemDataBound,
 * which set e.Item.Visible = false when a header had no rows.
 */
function AuditFormReport({ sections, info, period, innerRef }) {
  const visible = sections.filter((s) => s.questions.length > 0);

  return (
    <div ref={innerRef} className="bg-white p-6 text-[13px] leading-relaxed text-slate-900">
      <header className="border-b border-slate-200 pb-3 text-center">
        <h2 className="text-lg font-bold">वैयक्तिक लेखापरिक्षण अहवाल</h2>
        <p className="mt-1 font-medium">{info?.name ?? ''}</p>
        <p>{fullAddress(info)}</p>
        <p>{info?.contact_no1 ?? ''}</p>
        <p className="mt-2">लेखापरिक्षण कालावधी</p>
        <p>{period}</p>
        <p className="mt-1 font-semibold">लेखापरिक्षण वर्ग: &lsquo;ब&rsquo;</p>
      </header>

      <div className="my-4 rounded border border-slate-200 bg-slate-50 p-4">
        <p className="font-semibold text-slate-700">सोसायटी माहिती:</p>
        <div className="mt-2 grid gap-x-8 gap-y-1 sm:grid-cols-2">
          <p>
            <span className="font-medium text-slate-700">नाव:</span> {info?.name ?? '—'}
          </p>
          <p>
            <span className="font-medium text-slate-700">दूरध्वनी:</span> {info?.contact_no1 ?? '—'}
          </p>
          <p>
            <span className="font-medium text-slate-700">पत्ता:</span> {fullAddress(info) || '—'}
          </p>
          <p>
            <span className="font-medium text-slate-700">जिल्हा:</span> {info?.district ?? '—'}
          </p>
        </div>
      </div>

      {visible.map((section) => (
        <div key={section.audt_header_id} className="break-inside-avoid">
          <div className="mt-4 rounded border border-slate-300 bg-slate-100 px-3 py-2 font-bold text-slate-800">
            {section.audt_header_desc}
          </div>
          <div className="ml-3">
            {section.questions.map((q, i) => (
              <div
                key={q.audt_ques_id}
                className="flex break-inside-avoid flex-col gap-2 border-b border-dashed border-slate-200 py-3 last:border-b-0 sm:flex-row sm:gap-5"
              >
                <p className="flex-1">
                  <strong>{i + 1})</strong> {q.question_desc}
                </p>
                <p className="rounded border-l-4 border-slate-500 bg-slate-50 px-3 py-2 sm:w-[28%]">
                  {q.answer_desc || '—'}
                </p>
              </div>
            ))}
          </div>
        </div>
      ))}

      <footer className="mt-8 break-inside-avoid border-t border-slate-200 pt-4">
        <div className="flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
          <p>
            <strong>दिनांक:</strong> {auditDate()}
          </p>
          <div className="sm:text-right">
            <p className="font-semibold">लेखापरिक्षकांची सही</p>
            <div className="mt-10 w-56 border-b border-slate-900 sm:ml-auto" />
          </div>
        </div>
      </footer>
    </div>
  );
}

/**
 * Audit questionnaire — replaces Audit.aspx.
 *
 * Questions are grouped under headers; both are editable, and the whole sheet
 * prints for the auditor.
 */
export function AuditPage() {
  const [headers, setHeaders] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [societyInfo, setSocietyInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [headerForm, setHeaderForm] = useState(null);
  const [questionForm, setQuestionForm] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const [viewingForm, setViewingForm] = useState(false);
  const [pdfBusy, setPdfBusy] = useState(false);
  const [openSections, setOpenSections] = useState([]);
  const formRef = useRef(null);

  // Section order while dragging. Null until the first drop, so the sheet
  // follows the server's SequenceOrder until the auditor actually reorders it —
  // and the Save button stays hidden, as btnSaveSequence did.
  const [dragOrder, setDragOrder] = useState(null);
  const dragFrom = useRef(null);

  const toggleSection = (id) =>
    setOpenSections((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]));

  /** Move the dragged section to the position it was dropped on. */
  const dropOn = (toIndex, current) => {
    const from = dragFrom.current;
    dragFrom.current = null;
    if (from == null || from === toIndex) return;
    const next = current.map((s) => s.audt_header_id);
    const [moved] = next.splice(from, 1);
    next.splice(toIndex, 0, moved);
    setDragOrder(next);
  };

  const saveSequence = async () => {
    setBusy(true);
    setError(null);
    try {
      await reports.auditHeaderSequence(
        dragOrder.map((headerId, i) => ({ headerId, sequence: i + 1 })),
      );
      setDragOrder(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [h, q, info] = await Promise.all([
        reports.auditHeaders().catch(() => ({ items: [] })),
        reports.auditQuestions().catch(() => ({ items: [] })),
        reports.societyInfo().catch(() => ({ info: null })),
      ]);
      setHeaders(h.items ?? []);
      setQuestions(q.items ?? []);
      setSocietyInfo(info.info ?? null);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  // The legacy modal edited a section title together with all of its
  // subpoints — one Save wrote the header, then every question under it
  // (btnSaveAudit_Click). Editing a title and its questions separately was a
  // migration artefact, not how the page worked.
  const openHeaderEditor = (section) =>
    setHeaderForm({
      headerId: section?.audt_header_id ?? 0,
      description: section?.audt_header_desc ?? '',
      subpoints: (section?.questions ?? []).map((q) => ({
        key: `q${q.audt_ques_id}`,
        questionId: q.audt_ques_id,
        question: q.question_desc ?? '',
        answer: q.answer_desc ?? '',
      })),
    });

  const setSubpoint = (key, field, value) =>
    setHeaderForm((p) => ({
      ...p,
      subpoints: p.subpoints.map((s) => (s.key === key ? { ...s, [field]: value } : s)),
    }));

  const addSubpoint = () =>
    setHeaderForm((p) => ({
      ...p,
      // A client-side row has no id yet; the save posts questionId 0 for it,
      // which is what the legacy "+ उप मुद्दा जोडा" template did.
      subpoints: [...p.subpoints, { key: `new${p.subpoints.length}${Date.now()}`, questionId: 0, question: '', answer: '' }],
    }));

  const removeSubpoint = (key) =>
    setHeaderForm((p) => ({ ...p, subpoints: p.subpoints.filter((s) => s.key !== key) }));

  const saveHeader = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const saved = await api.post('/reports/audit/headers', {
        headerId: headerForm.headerId || 0,
        description: headerForm.description,
        statusId: 1,
      });
      // On insert the SP hands back the new id; the subpoints below need it to
      // attach to the section that was just created.
      const headerId = headerForm.headerId || saved?.audt_header_id;

      if (headerId) {
        for (const s of headerForm.subpoints) {
          // Blank rows are skipped, as in the legacy save loop.
          if (!s.question.trim() && !s.answer.trim()) continue;
          await api.post('/reports/audit/questions', {
            questionId: s.questionId || 0,
            question: s.question,
            answer: s.answer,
            headerId: Number(headerId),
            statusId: 1,
          });
        }
      }

      setHeaderForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const saveQuestion = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post('/reports/audit/questions', {
        questionId: questionForm.questionId || 0,
        question: questionForm.question,
        answer: questionForm.answer,
        headerId: Number(questionForm.headerId),
        statusId: 1,
      });
      setQuestionForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const grouped = useMemo(() => {
    const sections = headers.map((h) => ({
      ...h,
      questions: questions.filter((q) => Number(q.audt_header_id) === Number(h.audt_header_id)),
    }));
    // An unsaved drag reorders the sheet in place; the server's order stands
    // until Save Sequence is pressed.
    if (!dragOrder) return sections;
    const byId = new Map(sections.map((s) => [s.audt_header_id, s]));
    return dragOrder.map((id) => byId.get(id)).filter(Boolean);
  }, [headers, questions, dragOrder]);

  const shownQuestions = grouped.reduce((n, s) => n + s.questions.length, 0);

  // The legacy modal's "Download PDF", which captured #auditFormContent with
  // html2canvas. elementToPdf does the same, sliced across A4 pages.
  const downloadPdf = async () => {
    setPdfBusy(true);
    try {
      const { elementToPdf } = await import('@/lib/pdf');
      await elementToPdf(formRef.current, 'audit-report');
    } catch (err) {
      setError(err);
    } finally {
      setPdfBusy(false);
    }
  };

  if (loading) return <Spinner label="Loading audit sheet…" />;

  return (
    <section>
      <PageHeader
        title="Audit questionnaire"
        // Counted off the sections rather than the raw question list, so the
        // figure matches what is on screen. A question whose header belongs to
        // another society is not shown, and must not be counted either.
        subtitle={`${headers.length} section(s) · ${shownQuestions} question(s)`}
      >
        {/* The legacy page's "📄 View Audit Form" — the formal report the
            auditor signs, as opposed to the editable sheet behind it. Print
            and Download PDF live inside that dialog, which is what an auditor
            actually puts on paper, so the toolbar carries no Print of its own. */}
        <button type="button" className="btn-secondary" onClick={() => setViewingForm(true)}>
          📄 View audit form
        </button>
        {/* btnAddNew_Click opened the modal empty with one blank subpoint row. */}
        <button
          type="button"
          className="btn-secondary"
          onClick={() =>
            setHeaderForm({
              headerId: 0,
              description: '',
              subpoints: [{ key: 'new0', questionId: 0, question: '', answer: '' }],
            })
          }
        >
          + Add new
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() =>
            setQuestionForm({
              questionId: 0,
              question: '',
              answer: '',
              headerId: headers[0]?.audt_header_id ?? '',
            })
          }
        >
          Add question
        </button>
      </PageHeader>

      {societyInfo ? (
        <div className="card mb-4 p-5">
          <h2 className="text-sm font-semibold text-slate-800">{societyInfo.name}</h2>
          <p className="mt-1 text-sm text-slate-600">
            {[societyInfo.off_address1, societyInfo.off_address2, societyInfo.city, societyInfo.pincode]
              .filter(Boolean)
              .join(', ')}
          </p>
          <p className="text-sm text-slate-600">
            {[societyInfo.contact_no1, societyInfo.email].filter(Boolean).join(' · ')}
          </p>
        </div>
      ) : null}

      <ErrorNotice error={error} onRetry={load} />

      {grouped.length === 0 ? (
        <EmptyState title="No audit questions configured" hint="Add a section, then questions under it." />
      ) : (
        <div className="space-y-5">
          {/* Collapsible sections, as on the legacy page: the .qa-header bar
              toggles its .qa-body, which starts closed (display:none). */}
          {grouped.map((section, index) => {
            const open = openSections.includes(section.audt_header_id);
            return (
              <div
                key={section.audt_header_id}
                // Dropping onto a section moves the dragged one into its place,
                // the same rearrangement jquery-ui's sortable performed.
                onDragOver={(e) => e.preventDefault()}
                onDrop={() => dropOn(index, grouped)}
                className="overflow-hidden rounded-lg border border-slate-200 transition hover:border-[#012970] hover:shadow-md print:border-slate-300 print:shadow-none"
              >
                <div className="flex items-center justify-between gap-3 bg-gradient-to-r from-[#012970] to-[#024298] px-5 py-3 text-white">
                  {/* Only the handle starts a drag, so selecting the title
                      text still works — as with the legacy .drag-handle. */}
                  <span
                    draggable
                    onDragStart={() => {
                      dragFrom.current = index;
                    }}
                    aria-hidden="true"
                    title="Drag to reorder"
                    className="cursor-grab select-none rounded bg-white/90 px-2 py-0.5 text-lg leading-none text-[#012970] active:cursor-grabbing print:hidden"
                  >
                    ⇅
                  </span>
                  <button
                    type="button"
                    onClick={() => toggleSection(section.audt_header_id)}
                    aria-expanded={open}
                    className="flex flex-1 items-center gap-3 text-left text-sm font-semibold"
                  >
                    <span aria-hidden="true" className="text-xs">
                      {open ? '▾' : '▸'}
                    </span>
                    {section.audt_header_desc}
                    <span className="text-xs font-normal text-white/70">
                      ({section.questions.length})
                    </span>
                  </button>
                  <button
                    type="button"
                    className="shrink-0 rounded bg-white px-3 py-1 text-xs font-medium text-[#012970] hover:bg-slate-100 print:hidden"
                    onClick={() => openHeaderEditor(section)}
                  >
                    ✏️ Edit
                  </button>
                </div>

                {/* Printing shows every section — the collapsed state is a
                    screen affordance, not a filter on the document. */}
                <div className={open ? 'block' : 'hidden print:block'}>
                  {section.questions.length === 0 ? (
                    <p className="px-6 py-4 text-sm text-slate-500">No questions in this section.</p>
                  ) : (
                    <ol className="px-6 py-2">
                      {section.questions.map((q, i) => (
                        <li
                          key={q.audt_ques_id}
                          className="flex flex-col gap-4 border-b border-slate-100 py-3 last:border-b-0 sm:flex-row sm:items-start"
                        >
                          <p className="flex-1 pr-5 text-sm leading-relaxed text-slate-700">
                            <strong>{i + 1})</strong> {q.question_desc}
                          </p>
                          <p className="rounded border-l-[3px] border-[#012970] bg-slate-50 px-4 py-2 text-sm text-slate-700 sm:w-[300px] sm:shrink-0">
                            {q.answer_desc || '—'}
                          </p>
                          <div className="whitespace-nowrap print:hidden">
                            <button
                              type="button"
                              className="btn-secondary mr-2"
                              onClick={() =>
                                setQuestionForm({
                                  questionId: q.audt_ques_id,
                                  question: q.question_desc ?? '',
                                  answer: q.answer_desc ?? '',
                                  headerId: q.audt_header_id ?? '',
                                })
                              }
                            >
                              Edit
                            </button>
                            <button
                              type="button"
                              className="btn-danger"
                              onClick={() =>
                                setConfirming({
                                  title: 'Delete question',
                                  message: 'Remove this question from the audit sheet?',
                                  run: () => api.delete(`/reports/audit/questions/${q.audt_ques_id}`),
                                })
                              }
                            >
                              Delete
                            </button>
                          </div>
                        </li>
                      ))}
                    </ol>
                  )}
                </div>
              </div>
            );
          })}

          {/* Hidden until a drag actually changes the order, exactly as
              btnSaveSequence was (display:none until the sortable fired). */}
          {dragOrder ? (
            <div className="flex items-center justify-end gap-3 print:hidden">
              <p className="text-sm text-slate-500">Section order changed.</p>
              <button type="button" className="btn-secondary" onClick={() => setDragOrder(null)} disabled={busy}>
                Reset
              </button>
              <button type="button" className="btn-primary" onClick={saveSequence} disabled={busy}>
                {busy ? 'Saving…' : 'Save sequence'}
              </button>
            </div>
          ) : null}

        </div>
      )}

      <Modal
        open={Boolean(headerForm)}
        title={headerForm?.headerId ? 'Edit audit header' : 'Add audit header'}
        maxWidth="max-w-3xl"
        onClose={() => setHeaderForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setHeaderForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="header-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {headerForm ? (
          <form id="header-form" onSubmit={saveHeader} noValidate>
            <TextField
              label="मुख्य मुद्दा (section title)"
              name="description"
              required
              value={headerForm.description}
              onChange={(e) => {
                const { value } = e.target;
                setHeaderForm((p) => ({ ...p, description: value }));
              }}
            />

            {/* The legacy modal's subpoint cards: each a numbered question and
                answer pair with its own Delete, plus "+ उप मुद्दा जोडा". */}
            <div className="mt-4 space-y-3">
              {headerForm.subpoints.map((s, i) => (
                <div key={s.key} className="rounded-lg border border-slate-200 p-4">
                  <div className="mb-2 flex items-center justify-between">
                    <strong className="text-sm text-slate-700">{i + 1})</strong>
                    <button
                      type="button"
                      className="btn-danger text-xs"
                      onClick={() => removeSubpoint(s.key)}
                    >
                      Delete
                    </button>
                  </div>
                  <TextAreaField
                    label="प्रश्न (question)"
                    name={`question-${s.key}`}
                    rows={2}
                    value={s.question}
                    onChange={(e) => setSubpoint(s.key, 'question', e.target.value)}
                  />
                  <div className="mt-3">
                    <TextField
                      label="उत्तर (answer)"
                      name={`answer-${s.key}`}
                      value={s.answer}
                      onChange={(e) => setSubpoint(s.key, 'answer', e.target.value)}
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-3 text-right">
              <button type="button" className="btn-secondary" onClick={addSubpoint}>
                + उप मुद्दा जोडा
              </button>
            </div>

            <div className="mt-3">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <Modal
        open={Boolean(questionForm)}
        title={questionForm?.questionId ? 'Edit question' : 'Add question'}
        onClose={() => setQuestionForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setQuestionForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="question-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {questionForm ? (
          <form id="question-form" onSubmit={saveQuestion} className="space-y-4" noValidate>
            <SelectField
              label="Section"
              name="headerId"
              required
              options={headers}
              valueKey="audt_header_id"
              labelKey="audt_header_desc"
              value={questionForm.headerId}
              onChange={(e) => {
                const { value } = e.target;
                setQuestionForm((p) => ({ ...p, headerId: value }));
              }}
            />
            <TextAreaField
              label="Question"
              name="question"
              required
              rows={2}
              value={questionForm.question}
              onChange={(e) => {
                const { value } = e.target;
                setQuestionForm((p) => ({ ...p, question: value }));
              }}
            />
            <TextAreaField
              label="Answer"
              name="answer"
              rows={3}
              value={questionForm.answer}
              onChange={(e) => {
                const { value } = e.target;
                setQuestionForm((p) => ({ ...p, answer: value }));
              }}
            />
            <ErrorNotice error={error} />
          </form>
        ) : null}
      </Modal>

      <Modal
        open={viewingForm}
        title="लेखापरिक्षण अहवाल"
        maxWidth="max-w-5xl"
        onClose={() => setViewingForm(false)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => window.print()}>
              Print
            </button>
            <button type="button" className="btn-primary" onClick={downloadPdf} disabled={pdfBusy}>
              {pdfBusy ? 'Preparing…' : 'Download PDF'}
            </button>
          </>
        }
      >
        {/* A failed export would otherwise report itself only on the page
            behind the dialog, where it cannot be seen. */}
        <div className="print:hidden">
          <ErrorNotice error={error} />
        </div>
        <AuditFormReport
          innerRef={formRef}
          sections={grouped}
          info={societyInfo}
          period={AUDIT_PERIOD}
        />
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
          } catch (err) {
            setError(err);
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

/**
 * Balance sheet — replaces BalanceSheet.aspx.
 * Heads with editable sub-points, totals, and printing.
 */
export function BalanceSheetEditorPage() {
  const [heads, setHeads] = useState([]);
  const [subPoints, setSubPoints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [headForm, setHeadForm] = useState(null);
  const [subForm, setSubForm] = useState(null);
  const [confirming, setConfirming] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get('/reports/balance-sheet');
      setHeads(data.heads ?? []);
      setSubPoints(data.subPoints ?? []);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const grouped = useMemo(
    () =>
      heads.map((h) => ({
        ...h,
        subs: subPoints.filter((s) => Number(s.bal_head_id) === Number(h.bal_head_id)),
      })),
    [heads, subPoints],
  );

  const grandTotal = heads.reduce((s, h) => s + Number(h.amount || 0), 0);

  const saveHead = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post('/reports/balance-sheet/heads', {
        headId: headForm.headId || 0,
        description: headForm.description,
        amount: Number(headForm.amount || 0),
        seqOrder: Number(headForm.seqOrder || 0),
        statusId: 1,
      });
      setHeadForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const saveSub = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post('/reports/balance-sheet/sub-points', {
        subId: subForm.subId || 0,
        headId: Number(subForm.headId),
        description: subForm.description,
        amount: Number(subForm.amount || 0),
        statusId: 1,
      });
      setSubForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  if (loading) return <Spinner label="Loading balance sheet…" />;

  return (
    <section>
      <PageHeader title="Balance sheet" subtitle={`${heads.length} head(s) · total ${money(grandTotal)}`}>
        <button type="button" className="btn-secondary" onClick={() => window.print()}>
          Print
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() => setHeadForm({ headId: 0, description: '', amount: '', seqOrder: heads.length + 1 })}
        >
          Add head
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Heads" value={heads.length} />
        <StatCard label="Sub-points" value={subPoints.length} />
        <StatCard label="Total" value={money(grandTotal)} />
      </div>

      <ErrorNotice error={error} onRetry={load} />

      {grouped.length === 0 ? (
        <EmptyState title="No balance-sheet heads configured" hint="Add a head to begin." />
      ) : (
        <div className="space-y-4">
          {grouped.map((head) => (
            <div key={head.bal_head_id} className="card overflow-hidden">
              <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-200 px-4 py-3">
                <div>
                  <h2 className="text-sm font-semibold text-slate-800">{head.bal_header_desc}</h2>
                  <p className="text-xs text-slate-500">{money(head.amount)}</p>
                </div>
                <div className="print:hidden">
                  <button
                    type="button"
                    className="btn-secondary mr-2 text-xs"
                    onClick={() =>
                      setHeadForm({
                        headId: head.bal_head_id,
                        description: head.bal_header_desc,
                        amount: head.amount ?? '',
                        seqOrder: head.Seq_order ?? 0,
                      })
                    }
                  >
                    Edit head
                  </button>
                  <button
                    type="button"
                    className="btn-secondary text-xs"
                    onClick={() =>
                      setSubForm({ subId: 0, headId: head.bal_head_id, description: '', amount: '' })
                    }
                  >
                    Add sub-point
                  </button>
                </div>
              </div>

              {head.subs.length === 0 ? (
                <p className="px-4 py-4 text-sm text-slate-500">No sub-points under this head.</p>
              ) : (
                <table className="min-w-full">
                  <tbody>
                    {head.subs.map((s) => (
                      <tr key={s.bal_sub_id} className="border-t border-slate-100">
                        <td className="table-cell pl-8">{s.bal_sub_desc}</td>
                        <td className="table-cell text-right">{money(s.amount)}</td>
                        <td className="table-cell whitespace-nowrap text-right print:hidden">
                          <button
                            type="button"
                            className="btn-secondary mr-2"
                            onClick={() =>
                              setSubForm({
                                subId: s.bal_sub_id,
                                headId: s.bal_head_id,
                                description: s.bal_sub_desc ?? '',
                                amount: s.amount ?? '',
                              })
                            }
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            className="btn-danger"
                            onClick={() =>
                              setConfirming({
                                title: 'Delete sub-point',
                                message: `Remove "${s.bal_sub_desc}"?`,
                                run: () => api.delete(`/reports/balance-sheet/sub-points/${s.bal_sub_id}`),
                              })
                            }
                          >
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          ))}
        </div>
      )}

      <Modal
        open={Boolean(headForm)}
        title={headForm?.headId ? 'Edit head' : 'Add head'}
        onClose={() => setHeadForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setHeadForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="head-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {headForm ? (
          <form id="head-form" onSubmit={saveHead} className="grid gap-4 sm:grid-cols-2" noValidate>
            <TextField
              label="Head description"
              name="description"
              required
              className="sm:col-span-2"
              value={headForm.description}
              onChange={(e) => {
                const { value } = e.target;
                setHeadForm((p) => ({ ...p, description: value }));
              }}
            />
            <TextField
              label="Amount"
              name="amount"
              type="number"
              step="0.01"
              value={headForm.amount}
              onChange={(e) => {
                const { value } = e.target;
                setHeadForm((p) => ({ ...p, amount: value }));
              }}
            />
            <TextField
              label="Display order"
              name="seqOrder"
              type="number"
              value={headForm.seqOrder}
              onChange={(e) => {
                const { value } = e.target;
                setHeadForm((p) => ({ ...p, seqOrder: value }));
              }}
            />
            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <Modal
        open={Boolean(subForm)}
        title={subForm?.subId ? 'Edit sub-point' : 'Add sub-point'}
        onClose={() => setSubForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setSubForm(null)} disabled={busy}>
              Cancel
            </button>
            <button type="submit" form="sub-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {subForm ? (
          <form id="sub-form" onSubmit={saveSub} className="grid gap-4 sm:grid-cols-2" noValidate>
            <SelectField
              label="Under head"
              name="headId"
              required
              className="sm:col-span-2"
              options={heads}
              valueKey="bal_head_id"
              labelKey="bal_header_desc"
              value={subForm.headId}
              onChange={(e) => {
                const { value } = e.target;
                setSubForm((p) => ({ ...p, headId: value }));
              }}
            />
            <TextField
              label="Description"
              name="description"
              required
              value={subForm.description}
              onChange={(e) => {
                const { value } = e.target;
                setSubForm((p) => ({ ...p, description: value }));
              }}
            />
            <TextField
              label="Amount"
              name="amount"
              type="number"
              step="0.01"
              value={subForm.amount}
              onChange={(e) => {
                const { value } = e.target;
                setSubForm((p) => ({ ...p, amount: value }));
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
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await confirming.run();
            await load();
          } catch (err) {
            setError(err);
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
