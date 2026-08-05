import { useDeferredValue, useMemo, useState } from 'react';
import { buildings } from '@/api/masters';
import useCrudResource from './useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';

// Field order follows building_search.aspx exactly:
// name > print_name > reg > add1 > add2 > floors > bank > bank_add > branch >
// ifsc > acc_no > email.
const EMPTY = {
  name: '',
  printName: '',
  registrationNo: '',
  address1: '',
  address2: '',
  floors: 0,
  bankName: '',
  bankAddress: '',
  branch: '',
  ifscCode: '',
  accountNo: '',
  email: '',
};

/** Map an API row onto the form shape. */
const toForm = (row) => ({
  name: row.name ?? '',
  printName: row.print_name ?? '',
  registrationNo: row.registration_no ?? '',
  address1: row.address1 ?? '',
  address2: row.address2 ?? '',
  floors: row.no_of_floore ?? 0,
  bankName: row.bank_name ?? '',
  bankAddress: row.bank_add ?? '',
  branch: row.branch ?? '',
  ifscCode: row.ifsc_code ?? '',
  accountNo: row.acc_no ?? '',
  email: row.email ?? '',
});

export default function BuildingsPage() {
  const [search, setSearch] = useState('');
  // Deferring keeps typing responsive while the list refetches.
  const deferredSearch = useDeferredValue(search);
  const params = useMemo(() => ({ search: deferredSearch || undefined }), [deferredSearch]);

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(buildings, { params });

  const [editing, setEditing] = useState(null); // null | { id, form }
  const [confirming, setConfirming] = useState(null);

  const openCreate = () => setEditing({ id: null, form: { ...EMPTY } });
  const openEdit = (row) => setEditing({ id: row.build_id, form: toForm(row) });

  const closeForm = () => {
    setEditing(null);
    setError(null);
  };

  // Read e.target.value eagerly — see ResidentsPage for the full explanation.
  const setField = (key) => (e) => {
    const { value } = e.target;
    setEditing((prev) => ({ ...prev, form: { ...prev.form, [key]: value } }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    try {
      if (editing.id) await update(editing.id, editing.form);
      else await create(editing.form);
      setEditing(null);
    } catch {
      // Error is rendered inside the modal by ErrorNotice.
    }
  };

  const onDelete = async () => {
    try {
      await remove(confirming.build_id);
      setConfirming(null);
    } catch {
      setConfirming(null);
    }
  };

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Buildings</h1>
          <p className="text-sm text-slate-500">{items.length} record(s)</p>
        </div>
        <div className="flex gap-2">
          <input
            className="field-input w-56"
            placeholder="Search buildings…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            aria-label="Search buildings"
          />
          <button type="button" className="btn-primary" onClick={openCreate}>
            Add building
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState
            title="No buildings found"
            hint={search ? 'Try a different search term.' : 'Add the first building to get started.'}
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Name</th>
                  <th className="table-head">Address</th>
                  <th className="table-head">Floors</th>
                  <th className="table-head">Registration no.</th>
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((row) => (
                  <tr key={row.build_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800">{row.name}</td>
                    <td className="table-cell">
                      {[row.address1, row.address2].filter(Boolean).join(', ') || '—'}
                    </td>
                    <td className="table-cell">{row.no_of_floore ?? '—'}</td>
                    <td className="table-cell">{row.registration_no || '—'}</td>
                    <td className="table-cell whitespace-nowrap text-right">
                      <button type="button" className="btn-secondary mr-2" onClick={() => openEdit(row)}>
                        Edit
                      </button>
                      <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
                        Delete
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
        title={editing?.id ? 'Edit building' : 'Add building'}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="building-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="building-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <Field label="Name" required>
              <input className="field-input" value={editing.form.name} onChange={setField('name')} required />
            </Field>
            <Field label="Print name" hint="Shown on bills and receipts">
              <input className="field-input" value={editing.form.printName} onChange={setField('printName')} />
            </Field>
            <Field label="Registration number">
              <input
                className="field-input"
                value={editing.form.registrationNo}
                onChange={setField('registrationNo')}
              />
            </Field>
            <Field label="Address line 1">
              <input className="field-input" value={editing.form.address1} onChange={setField('address1')} />
            </Field>
            <Field label="Address line 2">
              <input className="field-input" value={editing.form.address2} onChange={setField('address2')} />
            </Field>
            <Field label="Number of floors">
              <input
                className="field-input"
                type="number"
                min="0"
                value={editing.form.floors}
                onChange={setField('floors')}
              />
            </Field>
            <Field label="Bank name">
              <input className="field-input" value={editing.form.bankName} onChange={setField('bankName')} />
            </Field>
            <Field label="Bank address">
              <input className="field-input" value={editing.form.bankAddress} onChange={setField('bankAddress')} />
            </Field>
            <Field label="Branch">
              <input className="field-input" value={editing.form.branch} onChange={setField('branch')} />
            </Field>
            <Field label="IFSC code">
              <input className="field-input" value={editing.form.ifscCode} onChange={setField('ifscCode')} />
            </Field>
            <Field label="Account number">
              <input className="field-input" value={editing.form.accountNo} onChange={setField('accountNo')} />
            </Field>
            <Field label="Email">
              <input className="field-input" type="email" value={editing.form.email} onChange={setField('email')} />
            </Field>

            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete building"
        message={`Delete "${confirming?.name}"? Wings and flats must be removed first.`}
        onConfirm={onDelete}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
    </section>
  );
}
