import { useState } from 'react';
import { pdc } from '@/api/onboarding';
import useCrudResource from '../masters/useCrudResource';
import DateRangeReport, { money, day } from '../DateRangeReport.jsx';
import { EmptyState, ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';

const EMPTY = { ownerId: '', wingId: '', chequeNo: '', amount: '', chequeDate: '' };

/** Post-dated cheques on file. Replaces pdc_reminder_search.aspx. */
export function PdcPage() {
  const { items, loading, error, saving, create, update, refresh, setError } = useCrudResource(pdc);
  const [editing, setEditing] = useState(null);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setEditing((prev) => ({ ...prev, form: { ...prev.form, [key]: value } }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    const body = {
      ...editing.form,
      ownerId: Number(editing.form.ownerId),
      wingId: editing.form.wingId ? Number(editing.form.wingId) : 0,
    };
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
    } catch {
      // Shown in the modal.
    }
  };

  const flag = (v, label) =>
    v ? <span className="rounded bg-slate-100 px-2 py-0.5 text-xs">{label}</span> : null;

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Post-dated cheques</h1>
          <p className="text-sm text-slate-500">{items.length} cheque(s) on file</p>
        </div>
        <button type="button" className="btn-primary" onClick={() => setEditing({ id: null, form: { ...EMPTY } })}>
          Add cheque
        </button>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState title="No cheques recorded" />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Cheque no.</th>
                  <th className="table-head">Resident</th>
                  <th className="table-head">Unit</th>
                  <th className="table-head">Cheque date</th>
                  <th className="table-head text-right">Amount</th>
                  <th className="table-head">Status</th>
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((row) => (
                  <tr key={row.pdc_rem_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800">{row.chqno}</td>
                    <td className="table-cell">{row.name}</td>
                    <td className="table-cell">{row.Unit}</td>
                    <td className="table-cell">{day(row.che_date)}</td>
                    <td className="table-cell text-right">{money(row.che_amount)}</td>
                    <td className="table-cell space-x-1">
                      {flag(row.che_dep, 'Deposited')}
                      {flag(row.che_ret, 'Returned')}
                      {flag(row.che_can, 'Cancelled')}
                      {!row.che_dep && !row.che_ret && !row.che_can ? (
                        <span className="text-xs text-slate-500">Pending</span>
                      ) : null}
                    </td>
                    <td className="table-cell text-right">
                      <button
                        type="button"
                        className="btn-secondary"
                        onClick={() =>
                          setEditing({
                            id: row.pdc_rem_id,
                            form: {
                              ownerId: row.owner_id ?? '',
                              wingId: '',
                              chequeNo: row.chqno ?? '',
                              amount: row.che_amount ?? '',
                              chequeDate: row.che_date ? String(row.che_date).slice(0, 10) : '',
                            },
                          })
                        }
                      >
                        Edit
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Edit cheque' : 'Add cheque'}
        onClose={() => {
          setEditing(null);
          setError(null);
        }}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setEditing(null)} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="pdc-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="pdc-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <Field label="Owner ID" required>
              <input className="field-input" type="number" value={editing.form.ownerId} onChange={setField('ownerId')} required />
            </Field>
            <Field label="Cheque number" required>
              <input className="field-input" value={editing.form.chequeNo} onChange={setField('chequeNo')} required />
            </Field>
            <Field label="Amount" required>
              <input className="field-input" type="number" step="0.01" value={editing.form.amount} onChange={setField('amount')} required />
            </Field>
            <Field label="Cheque date" required>
              <input className="field-input" type="date" value={editing.form.chequeDate} onChange={setField('chequeDate')} required />
            </Field>
            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>
    </section>
  );
}

/** Cheques falling due in a window. Replaces pdc_clearing.aspx. */
export function PdcClearingPage() {
  return (
    <DateRangeReport
      title="Cheque clearing"
      subtitle="Cheques dated within the selected period"
      load={pdc.clearing}
      render={(d) =>
        d.items.length === 0 ? (
          <EmptyState title="No cheques due in this period" />
        ) : (
          <div className="card overflow-hidden">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Cheque no.</th>
                  <th className="table-head">Resident</th>
                  <th className="table-head">Cheque date</th>
                  <th className="table-head text-right">Amount</th>
                  <th className="table-head">Status</th>
                </tr>
              </thead>
              <tbody>
                {d.items.map((r) => (
                  <tr key={r.pdc_rem_id}>
                    <td className="table-cell font-medium text-slate-800">{r.chqno}</td>
                    <td className="table-cell">{r.owner_name}</td>
                    <td className="table-cell">{day(r.che_date)}</td>
                    <td className="table-cell text-right">{money(r.che_amount)}</td>
                    <td className="table-cell">
                      {r.che_dep ? 'Deposited' : r.che_ret ? 'Returned' : r.che_can ? 'Cancelled' : 'Pending'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {/* Depositing a cheque raises a receipt through sp_receipt, so the
                action is deliberately left out until the write paths are
                verified against a test database. */}
            <p className="border-t border-slate-200 px-4 py-3 text-xs text-slate-500">
              Marking a cheque deposited also raises a receipt. That action is disabled until the
              financial write paths have been verified.
            </p>
          </div>
        )
      }
    />
  );
}
