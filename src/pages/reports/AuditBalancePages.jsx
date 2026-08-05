import { useCallback, useEffect, useMemo, useState } from 'react';
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

  const saveHeader = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post('/reports/audit/headers', {
        headerId: headerForm.headerId || 0,
        description: headerForm.description,
        statusId: 1,
      });
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

  const grouped = useMemo(
    () =>
      headers.map((h) => ({
        ...h,
        questions: questions.filter((q) => Number(q.audt_header_id) === Number(h.audt_header_id)),
      })),
    [headers, questions],
  );

  const ungrouped = questions.filter(
    (q) => !headers.some((h) => Number(h.audt_header_id) === Number(q.audt_header_id)),
  );

  if (loading) return <Spinner label="Loading audit sheet…" />;

  return (
    <section>
      <PageHeader
        title="Audit questionnaire"
        subtitle={`${headers.length} section(s) · ${questions.length} question(s)`}
      >
        <button type="button" className="btn-secondary" onClick={() => window.print()}>
          Print
        </button>
        <button
          type="button"
          className="btn-secondary"
          onClick={() => setHeaderForm({ headerId: 0, description: '' })}
        >
          Add section
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

      {grouped.length === 0 && ungrouped.length === 0 ? (
        <EmptyState title="No audit questions configured" hint="Add a section, then questions under it." />
      ) : (
        <div className="space-y-4">
          {grouped.map((section) => (
            <div key={section.audt_header_id} className="card overflow-hidden">
              <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3">
                <h2 className="text-sm font-semibold text-slate-800">{section.audt_header_desc}</h2>
                <button
                  type="button"
                  className="btn-secondary text-xs print:hidden"
                  onClick={() =>
                    setHeaderForm({
                      headerId: section.audt_header_id,
                      description: section.audt_header_desc,
                    })
                  }
                >
                  Edit section
                </button>
              </div>
              {section.questions.length === 0 ? (
                <p className="px-4 py-4 text-sm text-slate-500">No questions in this section.</p>
              ) : (
                <ol className="divide-y divide-slate-100">
                  {section.questions.map((q, i) => (
                    <li key={q.audt_ques_id} className="flex items-start justify-between gap-4 p-4">
                      <div className="flex-1">
                        <p className="text-sm text-slate-800">
                          {i + 1}. {q.question_desc}
                        </p>
                        <p className="mt-1 text-sm text-slate-600">
                          <span className="font-medium">Answer:</span> {q.answer_desc || '—'}
                        </p>
                      </div>
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
          ))}

          {ungrouped.length ? (
            <div className="card overflow-hidden">
              <h2 className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">
                Unsectioned questions
              </h2>
              <ol className="divide-y divide-slate-100">
                {ungrouped.map((q) => (
                  <li key={q.audt_ques_id} className="p-4">
                    <p className="text-sm text-slate-800">{q.question_desc}</p>
                    <p className="mt-1 text-sm text-slate-600">{q.answer_desc || '—'}</p>
                  </li>
                ))}
              </ol>
            </div>
          ) : null}
        </div>
      )}

      <Modal
        open={Boolean(headerForm)}
        title={headerForm?.headerId ? 'Edit section' : 'Add section'}
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
              label="Section name"
              name="description"
              required
              value={headerForm.description}
              onChange={(e) => {
                const { value } = e.target;
                setHeaderForm((p) => ({ ...p, description: value }));
              }}
            />
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
