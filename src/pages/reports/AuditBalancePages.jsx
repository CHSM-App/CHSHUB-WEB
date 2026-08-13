import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { reports } from '@/api/modules';
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
  PageHeader,
  SelectField,
  StatCard,
  TextAreaField,
  TextField,
} from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// Audit.aspx printed dd/MM/yyyy under the signature block.
const auditDate = () => new Date().toLocaleDateString('en-GB');

/** Marathi digits, for the audit period the legacy page printed in Devanagari. */
const mrDigits = (n) => String(n).replace(/\d/g, (d) => '०१२३४५६७८९'[Number(d)]);

/**
 * The financial year being audited, as "दि.०१-०४-YYYY ते दि. ३१-०३-YYYY अखेरचे".
 *
 * LoadAuditPeriod() wrote 2024–25 as a literal, so every report printed that
 * range whatever year it was run in. There is no stored period to read, but the
 * Indian financial year runs 1 April to 31 March, which today's date does give:
 * before April the year under audit is the one that started last April.
 */
const auditPeriod = (now = new Date()) => {
  const startYear = now.getMonth() < 3 ? now.getFullYear() - 1 : now.getFullYear();
  return `दि.${mrDigits('01')}-${mrDigits('04')}-${mrDigits(startYear)} ते दि. ${mrDigits(
    '31',
  )}-${mrDigits('03')}-${mrDigits(startYear + 1)} अखेरचे`;
};

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
/*
 * What each form insists on, in the shape validateFields expects. These
 * mirror asterisks already on the inputs that nothing enforced — the forms
 * carry noValidate, so an empty submit posted a blank row.
 */
const HEADER_FIELDS = [{ name: 'description', label: 'Section title', required: true }];
const QUESTION_FIELDS = [
  { name: 'headerId', label: 'Section', type: 'select', required: true },
  { name: 'question', label: 'Question', required: true },
];
const BALANCE_HEAD_FIELDS = [{ name: 'description', label: 'Header title', required: true }];

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
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
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

    const missing = validateFields(HEADER_FIELDS, headerForm);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(HEADER_FIELDS, missing);
      return;
    }

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
      toast.success('Audit section saved successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error('The section could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  const saveQuestion = async (event) => {
    event.preventDefault();

    const missing = validateFields(QUESTION_FIELDS, questionForm);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(QUESTION_FIELDS, missing);
      return;
    }

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
      toast.success('Audit question saved successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error('The question could not be saved. Please try again.');
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
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <TextField
              label="मुख्य मुद्दा (section title)"
              name="description"
              required
              error={fieldErrors.description}
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
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <SelectField
              label="Section"
              name="headerId"
              required
              error={fieldErrors.headerId}
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
              error={fieldErrors.question}
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
          period={auditPeriod()}
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
            toast.success('Audit question deleted.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'That could not be deleted. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}

// BalanceSheet.aspx split the heads by comp_id: 2 down the Liabilities column,
// 1 down the Assets column. The ids are what the SP stores, so they stay.
const LIABILITY = 2;
const ASSET = 1;

const COLUMNS = [
  { compId: LIABILITY, title: 'Liabilities', type: 'liability' },
  { compId: ASSET, title: 'Assets', type: 'asset' },
];

/**
 * One head as the legacy page drew it: a title bar carrying the head's own
 * amount and an edit pencil, the sub-points indented beneath it, and a Total
 * row closing the block.
 *
 * The total is the head's own amount plus its sub-points — the sum
 * rptBalance_ItemDataBound computed into lblTotal, not the head amount alone.
 */
function HeadBlock({ head, index, onEdit, onDelete, onDragStart, onDrop }) {
  const total = Number(head.amount || 0) + head.subs.reduce((s, x) => s + Number(x.amount || 0), 0);

  return (
    <div
      // Dropping onto a head moves the dragged one into its place — the
      // rearrangement jquery-ui's connected sortables performed.
      onDragOver={(e) => e.preventDefault()}
      onDrop={() => onDrop(index)}
      className="border-b-2 border-[#012970] bg-[#f0f4f8] last:border-b-0"
    >
      <div className="flex items-center justify-between gap-2 border-b border-slate-200 bg-white px-5 py-3">
        <h3 className="flex flex-1 items-center gap-2.5 text-[15px] font-semibold text-[#012970]">
          {/* Only the handle starts a drag, so the title text stays
              selectable — as with the legacy .drag-handle. */}
          <span
            draggable
            onDragStart={() => onDragStart(index)}
            aria-hidden="true"
            title="Drag to reorder"
            className="cursor-grab select-none rounded bg-[#f0f4f8] px-2 py-0.5 text-lg leading-none active:cursor-grabbing print:hidden"
          >
            ⇅
          </span>
          {head.bal_header_desc}
          <button
            type="button"
            title="Edit"
            onClick={() => onEdit(head)}
            className="text-[13px] transition hover:scale-110 print:hidden"
          >
            ✏️
          </button>
          {/* Removing a head takes its sub-points with it, so the count is
              spelled out in the confirmation rather than left to be guessed. */}
          <button
            type="button"
            title="Delete this head"
            onClick={() => onDelete(head)}
            className="text-[13px] transition hover:scale-110 print:hidden"
          >
            🗑️
          </button>
        </h3>
        <span className="text-[15px] font-semibold text-[#012970]">{money(head.amount)}</span>
      </div>

      <div className="bg-white">
        {head.subs.map((s) => (
          <div
            key={s.bal_sub_id}
            className="flex items-center justify-between border-b border-slate-100 px-5 py-2.5 last:border-b-0"
          >
            <span className="flex-1 pl-[30px] text-sm text-slate-700">{s.bal_sub_desc}</span>
            <span className="min-w-20 text-right text-sm font-medium text-slate-600">{money(s.amount)}</span>
          </div>
        ))}
        <div className="flex items-center justify-between border-t-2 border-[#012970] bg-slate-50 px-5 py-3 font-bold text-[#012970]">
          <span className="text-[15px]">Total:</span>
          <span className="text-base">{money(total)}</span>
        </div>
      </div>
    </div>
  );
}

/**
 * Balance sheet — replaces BalanceSheet.aspx.
 *
 * The legacy layout: Liabilities and Assets side by side, each head a block of
 * sub-points closed by a Total, draggable within and between the columns, and
 * edited through a single modal that saves the head and its sub-points at once.
 */
export function BalanceSheetEditorPage() {
  const [heads, setHeads] = useState([]);
  const [subPoints, setSubPoints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [headForm, setHeadForm] = useState(null);
  const [confirming, setConfirming] = useState(null);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  // Head order while dragging, as [{ id, compId }]. Null until the first drop,
  // so the sheet follows the server's Seq_order until it is actually reordered
  // — and Save Sequence stays hidden, as btnSaveSequence did.
  const [dragOrder, setDragOrder] = useState(null);
  const dragFrom = useRef(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await reports.balanceSheet();
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

  const grouped = useMemo(() => {
    const withSubs = heads.map((h) => ({
      ...h,
      subs: subPoints.filter((s) => Number(s.bal_head_id) === Number(h.bal_head_id)),
    }));

    // An unsaved drag reorders the sheet in place — including across the two
    // columns, which the connected sortables allowed. The server's order and
    // comp_id stand until Save sequence is pressed.
    if (!dragOrder) return withSubs;
    const byId = new Map(withSubs.map((h) => [Number(h.bal_head_id), h]));
    return dragOrder
      .map(({ id, compId }) => {
        const head = byId.get(id);
        return head ? { ...head, comp_id: compId } : null;
      })
      .filter(Boolean);
  }, [heads, subPoints, dragOrder]);

  /** The heads of one column, in display order. */
  const columnHeads = useCallback(
    (compId) => grouped.filter((h) => Number(h.comp_id) === compId),
    [grouped],
  );

  /** A head's position in the flat list, which is what the drag indexes. */
  const flatIndex = (head) => grouped.findIndex((h) => Number(h.bal_head_id) === Number(head.bal_head_id));

  /**
   * Move the dragged head to where it was dropped. `compId` is the column it
   * landed in, so dragging across columns turns a liability into an asset —
   * what connectWith did on the legacy page.
   */
  const dropOn = (toIndex, compId) => {
    const from = dragFrom.current;
    dragFrom.current = null;
    if (from == null) return;

    const next = grouped.map((h) => ({ id: Number(h.bal_head_id), compId: Number(h.comp_id) }));
    const [moved] = next.splice(from, 1);
    if (!moved) return;
    // Re-read the target after the splice: removing an earlier item shifts
    // everything after it down one.
    const target = from < toIndex ? toIndex - 1 : toIndex;
    next.splice(target, 0, { ...moved, compId });
    setDragOrder(next);
  };

  /** Dropping on the empty area below a column appends to that column. */
  const dropAtEnd = (compId) => {
    const from = dragFrom.current;
    dragFrom.current = null;
    if (from == null) return;

    const next = grouped.map((h) => ({ id: Number(h.bal_head_id), compId: Number(h.comp_id) }));
    const [moved] = next.splice(from, 1);
    if (!moved) return;
    next.push({ ...moved, compId });
    setDragOrder(next);
  };

  /**
   * Save the arrangement. A head that changed columns needs its comp_id
   * written too, which the sequence branch does not touch — so those go
   * through the head save first.
   */
  const saveSequence = async () => {
    setBusy(true);
    setError(null);
    try {
      const byId = new Map(heads.map((h) => [Number(h.bal_head_id), h]));
      for (const { id, compId } of dragOrder) {
        const original = byId.get(id);
        if (!original || Number(original.comp_id) === compId) continue;
        await reports.saveBalanceHead({
          headId: id,
          description: original.bal_header_desc,
          amount: Number(original.amount || 0),
          seqOrder: Number(original.Seq_order || 0),
          compId,
          statusId: 1,
        });
      }

      // Numbered per column, since each column is ordered independently.
      const counters = new Map();
      await reports.balanceHeadSequence(
        dragOrder.map(({ id, compId }) => {
          const n = (counters.get(compId) ?? 0) + 1;
          counters.set(compId, n);
          return { headId: id, sequence: n };
        }),
      );

      setDragOrder(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const grandTotal = (compId) =>
    columnHeads(compId).reduce(
      (sum, h) => sum + Number(h.amount || 0) + h.subs.reduce((s, x) => s + Number(x.amount || 0), 0),
      0,
    );

  const liabilityTotal = grandTotal(LIABILITY);
  const assetTotal = grandTotal(ASSET);

  // The legacy modal edited a head together with all of its sub-points — one
  // Save wrote the header, then every sub-point under it (btnSave_Click).
  const openEditor = (head) =>
    setHeadForm({
      headId: head?.bal_head_id ?? 0,
      description: head?.bal_header_desc ?? '',
      amount: head?.amount ?? '',
      compId: Number(head?.comp_id) === ASSET ? ASSET : LIABILITY,
      seqOrder: head?.Seq_order ?? 0,
      subpoints: (head?.subs ?? []).map((s) => ({
        key: `s${s.bal_sub_id}`,
        subId: s.bal_sub_id,
        description: s.bal_sub_desc ?? '',
        amount: s.amount ?? '',
      })),
    });

  /**
   * Removing a head removes its sub-points with it, so the count goes in the
   * message — a head with ten rows under it should not vanish on a click that
   * looked like it only dropped a title.
   */
  const confirmDeleteHead = (head) =>
    setConfirming({
      title: 'Delete entry',
      message:
        head.subs.length > 0
          ? `Remove "${head.bal_header_desc}" and its ${head.subs.length} sub-point(s)?`
          : `Remove "${head.bal_header_desc}"?`,
      run: async () => {
        await reports.removeBalanceHead(head.bal_head_id);
        // A pending drag order still names the deleted head. Drop it from the
        // arrangement rather than letting Save sequence post a dead id.
        setDragOrder((prev) => {
          if (!prev) return prev;
          const next = prev.filter((x) => x.id !== Number(head.bal_head_id));
          return next.length > 0 ? next : null;
        });
      },
    });

  const setSubpoint = (key, field, value) =>
    setHeadForm((p) => ({
      ...p,
      subpoints: p.subpoints.map((s) => (s.key === key ? { ...s, [field]: value } : s)),
    }));

  const addSubpoint = () =>
    setHeadForm((p) => ({
      ...p,
      // A client-side row has no id yet; the save posts subId 0 for it, which
      // is what the legacy "+ Add Subpoint" template did.
      subpoints: [
        ...p.subpoints,
        { key: `new${p.subpoints.length}${Date.now()}`, subId: 0, description: '', amount: '' },
      ],
    }));

  const removeSubpoint = (key) =>
    setHeadForm((p) => ({ ...p, subpoints: p.subpoints.filter((s) => s.key !== key) }));

  const saveHead = async (event) => {
    event.preventDefault();

    const missing = validateFields(BALANCE_HEAD_FIELDS, headForm);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(BALANCE_HEAD_FIELDS, missing);
      return;
    }

    setBusy(true);
    setError(null);
    try {
      const saved = await reports.saveBalanceHead({
        headId: headForm.headId || 0,
        description: headForm.description,
        amount: Number(headForm.amount || 0),
        compId: headForm.compId,
        seqOrder: Number(headForm.seqOrder || 0),
        statusId: 1,
      });
      // On insert the SP hands back the new id; the sub-points below need it to
      // attach to the head that was just created.
      const headId = headForm.headId || saved?.bal_head_id;

      if (headId) {
        for (const s of headForm.subpoints) {
          // Blank rows are skipped, as in the legacy save loop.
          if (!s.description.trim()) continue;
          await reports.saveBalanceSubPoint({
            subId: s.subId || 0,
            headId: Number(headId),
            description: s.description,
            amount: Number(s.amount || 0),
            statusId: 1,
          });
        }
      }

      setHeadForm(null);
      await load();
      toast.success('Balance sheet head saved successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error('The head could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  if (loading) return <Spinner label="Loading balance sheet…" />;

  return (
    <section>
      <PageHeader
        title="Balance sheet — Liabilities & Assets"
        subtitle={`${heads.length} head(s) · ${subPoints.length} sub-point(s)`}
      >
        <button type="button" className="btn-secondary" onClick={() => window.print()}>
          Print
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={() =>
            setHeadForm({
              headId: 0,
              description: '',
              amount: '',
              compId: LIABILITY,
              seqOrder: heads.length + 1,
              subpoints: [{ key: 'new0', subId: 0, description: '', amount: '' }],
            })
          }
        >
          + Add new entry
        </button>
      </PageHeader>

      <div className="mb-4 grid gap-3 sm:grid-cols-3">
        <StatCard label="Liabilities" value={money(liabilityTotal)} />
        <StatCard label="Assets" value={money(assetTotal)} />
        {/* A balance sheet is meant to balance; the gap is the useful figure. */}
        <StatCard
          label="Difference"
          value={money(liabilityTotal - assetTotal)}
          tone={Math.abs(liabilityTotal - assetTotal) < 0.005 ? 'positive' : 'warning'}
          hint={Math.abs(liabilityTotal - assetTotal) < 0.005 ? 'Balanced' : 'Liabilities and assets differ'}
        />
      </div>

      <ErrorNotice error={error} onRetry={load} />

      {grouped.length === 0 ? (
        <EmptyState title="No balance-sheet heads configured" hint="Add an entry to begin." />
      ) : (
        <>
          {/* The two-column sheet, stacking on narrow screens as the legacy
              @media (max-width: 991px) rule did. */}
          <div className="grid gap-5 lg:grid-cols-2">
            {COLUMNS.map((column) => {
              const items = columnHeads(column.compId);
              return (
                <div
                  key={column.compId}
                  className="overflow-hidden rounded-lg border-2 border-[#012970] print:break-inside-avoid"
                >
                  <div className="bg-gradient-to-r from-[#012970] to-[#024298] px-5 py-3.5 text-center text-lg font-bold text-white">
                    {column.title}
                  </div>
                  <div
                    // Empty space below the last head is a valid drop target,
                    // so a head can be moved into a column that has none.
                    onDragOver={(e) => e.preventDefault()}
                    onDrop={() => dropAtEnd(column.compId)}
                    className="min-h-24"
                  >
                    {items.length === 0 ? (
                      <p className="px-5 py-6 text-center text-sm text-slate-500">
                        No {column.title.toLowerCase()} recorded.
                      </p>
                    ) : (
                      items.map((head) => (
                        <HeadBlock
                          key={head.bal_head_id}
                          head={head}
                          index={flatIndex(head)}
                          onEdit={openEditor}
                          onDelete={confirmDeleteHead}
                          onDragStart={(i) => {
                            dragFrom.current = i;
                          }}
                          onDrop={(i) => dropOn(i, column.compId)}
                        />
                      ))
                    )}
                  </div>
                  <div className="flex items-center justify-between bg-[#012970] px-5 py-3 font-bold text-white">
                    <span>Grand total</span>
                    <span>{money(grandTotal(column.compId))}</span>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Hidden until a drag actually changes the order, exactly as
              btnSaveSequence was (display:none until the sortable fired). */}
          {dragOrder ? (
            <div className="mt-4 flex items-center justify-end gap-3 print:hidden">
              <p className="text-sm text-slate-500">Order changed.</p>
              <button type="button" className="btn-secondary" onClick={() => setDragOrder(null)} disabled={busy}>
                Reset
              </button>
              <button type="button" className="btn-primary" onClick={saveSequence} disabled={busy}>
                {busy ? 'Saving…' : 'Save sequence'}
              </button>
            </div>
          ) : null}
        </>
      )}

      <Modal
        open={Boolean(headForm)}
        title={headForm?.headId ? 'Edit balance sheet entry' : 'Add balance sheet entry'}
        maxWidth="max-w-3xl"
        onClose={() => setHeadForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setHeadForm(null)} disabled={busy}>
              Close
            </button>
            <button type="submit" form="head-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {headForm ? (
          <form id="head-form" onSubmit={saveHead} noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            {/* The legacy .type-selector: two cards, the chosen one filled. */}
            <div className="mb-5 flex gap-5">
              {COLUMNS.map((column) => {
                const selected = headForm.compId === column.compId;
                return (
                  <button
                    key={column.compId}
                    type="button"
                    aria-pressed={selected}
                    onClick={() => setHeadForm((p) => ({ ...p, compId: column.compId }))}
                    className={`flex-1 rounded-lg border-2 p-4 text-center text-sm font-medium transition ${
                      selected
                        ? 'border-[#012970] bg-[#012970] text-white'
                        : 'border-slate-200 text-slate-700 hover:border-[#012970] hover:bg-[#f0f4f8]'
                    }`}
                  >
                    {column.title.replace(/s$/, '')}
                  </button>
                );
              })}
            </div>

            <div className="grid gap-4 sm:grid-cols-3">
              <TextField
                label="Header title"
                name="description"
                required
                error={fieldErrors.description}
                className="sm:col-span-2"
                value={headForm.description}
                onChange={(e) => {
                  const { value } = e.target;
                  setHeadForm((p) => ({ ...p, description: value }));
                }}
              />
              <TextField
                label="Header amount"
                name="amount"
                type="number"
                step="0.01"
                value={headForm.amount}
                onChange={(e) => {
                  const { value } = e.target;
                  setHeadForm((p) => ({ ...p, amount: value }));
                }}
              />
            </div>

            {/* The legacy modal's sub-point cards: each a numbered description
                and amount pair with its own Delete, plus "+ Add Subpoint". */}
            <div className="mt-4 space-y-3">
              {headForm.subpoints.map((s, i) => (
                <div key={s.key} className="rounded-lg border border-slate-200 bg-slate-50 p-4">
                  <div className="mb-2 flex items-center justify-between">
                    <strong className="text-sm text-slate-700">{i + 1})</strong>
                    <button
                      type="button"
                      className="btn-danger text-xs"
                      onClick={() => {
                        // A saved row has to be deleted on the server; the
                        // legacy save loop only ever wrote rows, so dropping
                        // one from the list alone would not remove it.
                        if (s.subId) {
                          setConfirming({
                            title: 'Delete sub-point',
                            message: `Remove "${s.description || 'this sub-point'}"?`,
                            run: () => reports.removeBalanceSubPoint(s.subId),
                            after: () => removeSubpoint(s.key),
                          });
                          return;
                        }
                        removeSubpoint(s.key);
                      }}
                    >
                      Delete
                    </button>
                  </div>
                  <div className="grid gap-4 sm:grid-cols-3">
                    <TextField
                      label="Description"
                      name={`sub-desc-${s.key}`}
                      className="sm:col-span-2"
                      value={s.description}
                      onChange={(e) => setSubpoint(s.key, 'description', e.target.value)}
                    />
                    <TextField
                      label="Amount"
                      name={`sub-amount-${s.key}`}
                      type="number"
                      step="0.01"
                      value={s.amount}
                      onChange={(e) => setSubpoint(s.key, 'amount', e.target.value)}
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-3 text-right">
              <button type="button" className="btn-secondary" onClick={addSubpoint}>
                + Add subpoint
              </button>
            </div>

            <div className="mt-3">
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
            // Deleting from inside the open modal drops the row from the form;
            // the reload behind it would otherwise not reach the form's copy.
            if (confirming.after) confirming.after();
            else await load();
            toast.success(confirming.done ?? 'Deleted successfully.', { title: 'Deleted' });
          } catch (err) {
            setError(err);
            toast.error(err?.message ?? 'That could not be deleted. Please try again.');
          } finally {
            setBusy(false);
            setConfirming(null);
          }
        }}
      />
    </section>
  );
}
