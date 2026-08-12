import { useCallback, useEffect, useMemo, useState } from 'react';
import { village } from '@/api/modules';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';

/*
 * Which charges apply to which house.
 *
 * dbo.house carried gharpatti_charges, water_charges and waste_charges, so
 * every house owed every charge whether or not it had the service — house
 * number 0 has no tap connection and was still being billed for water. This
 * screen edits house_charge instead: a row means the charge applies, and no
 * row means nothing is raised for it.
 *
 * One row per house, one column per charge type, read from
 * Village_payment_type — so a charge added later (a street-light tax, a market
 * fee) appears here on its own, with no change to this file.
 */

const money = (v) =>
  v == null || v === ''
    ? '—'
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/** What the amount is derived from, spelled out for the header. */
const BASIS_LABEL = {
  AREA: 'per sq.ft. of area',
  TAP: 'per tap connection',
  FLAT: 'a fixed amount',
};

const FREQUENCY_LABEL = { Y: 'yearly', M: 'monthly' };

/**
 * The period an amount starts applying to, named the way the charge falls: a
 * yearly charge starts in a year, a monthly one in a month. "from 1 Sep 2026"
 * on a yearly charge would suggest a precision it does not have.
 */
function periodLabel(value, frequency) {
  if (!value) return '';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return frequency === 'Y'
    ? String(d.getUTCFullYear())
    : d.toLocaleDateString(undefined, { month: 'short', year: 'numeric', timeZone: 'UTC' });
}

const blankChargeType = { payment_type: 0, name: '', frequency: 'M', basis: 'FLAT' };

export default function HouseChargesPage() {
  const [rows, setRows] = useState([]);
  const [chargeTypes, setChargeTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  // house_id:payment_type of the cell currently being saved.
  const [savingKey, setSavingKey] = useState(null);
  const [editing, setEditing] = useState(null);
  const [chargeForm, setChargeForm] = useState(null);
  const [savingCharge, setSavingCharge] = useState(false);
  const [removing, setRemoving] = useState(null);

  const load = useCallback(
    () =>
      Promise.all([village.houseCharges(), village.chargeTypes()])
        .then(([grid, types]) => {
          setRows(grid.items ?? []);
          setChargeTypes(types.items ?? []);
        })
        .catch(setError),
    [],
  );

  useEffect(() => {
    let cancelled = false;
    Promise.all([village.houseCharges(), village.chargeTypes()])
      .then(([grid, types]) => {
        if (cancelled) return;
        setRows(grid.items ?? []);
        setChargeTypes(types.items ?? []);
      })
      .catch((err) => !cancelled && setError(err))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  const saveChargeType = async (event) => {
    event.preventDefault();
    setSavingCharge(true);
    setError(null);
    try {
      const body = {
        name: chargeForm.name,
        frequency: chargeForm.frequency,
        basis: chargeForm.basis,
      };
      if (chargeForm.payment_type) await village.updateChargeType(chargeForm.payment_type, body);
      else await village.createChargeType(body);
      setChargeForm(null);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setSavingCharge(false);
    }
  };

  const removeChargeType = async () => {
    try {
      await village.removeChargeType(removing.payment_type);
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setRemoving(null);
    }
  };

  /*
   * The flat house x charge list comes back one row per combination. Fold it
   * into one entry per house, keeping the charge types in the order the server
   * sent them so every house shows the same columns.
   */
  const { houses, types } = useMemo(() => {
    const byHouse = new Map();
    const byType = new Map();

    for (const r of rows) {
      if (!byType.has(r.payment_type)) {
        byType.set(r.payment_type, {
          payment_type: r.payment_type,
          name: r.payment_type_name,
          frequency: r.frequency,
          basis: r.basis,
        });
      }
      if (!byHouse.has(r.house_id)) {
        byHouse.set(r.house_id, {
          house_id: r.house_id,
          house_no: r.house_no,
          area: r.area,
          no_of_tab: r.no_of_tab,
          charges: new Map(),
        });
      }
      byHouse.get(r.house_id).charges.set(r.payment_type, {
        applies: Boolean(r.applies),
        amount: r.amount,
        effectiveFrom: r.effective_from,
        // True while the amount is dated ahead of today: it is stored but not
        // yet what the house is billed.
        pending: Boolean(r.pending),
      });
    }

    return { houses: [...byHouse.values()], types: [...byType.values()] };
  }, [rows]);

  const visible = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return houses;
    return houses.filter((h) => String(h.house_no ?? '').toLowerCase().includes(term));
  }, [houses, search]);

  const save = async (houseId, paymentType, body) => {
    const key = `${houseId}:${paymentType}`;
    setSavingKey(key);
    setError(null);
    try {
      await village.saveHouseCharge({ houseId, paymentType, ...body });
      await load();
    } catch (err) {
      setError(err);
    } finally {
      setSavingKey(null);
    }
  };

  if (loading) return <Spinner />;

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div className="print:w-full print:text-center">
          <h1 className="text-xl font-bold" style={{ color: '#012970' }}>
            Charges
          </h1>
          <p className="text-sm text-slate-500 print:hidden">
            The charges this village raises, and which houses pay each one.
          </p>
        </div>
        <input
          className="field-input w-56 print:hidden"
          placeholder="Search house no…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search house charges"
        />
      </header>

      <ErrorNotice error={error} />

      {/*
        The charges this village levies. Three come with the database; a
        village adds its own here — a street-light tax, a market fee — and it
        appears as a column in the grid below straight away.
      */}
      <div className="card mb-4 overflow-hidden">
        <div className="flex items-center justify-between border-b border-slate-200 px-4 py-2">
          <h2 className="text-sm font-bold" style={{ color: '#012970' }}>
            Charges
          </h2>
          <button
            type="button"
            className="btn-primary print:hidden"
            onClick={() => setChargeForm({ ...blankChargeType })}
          >
            Add charge
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
              <tr>
                <th className="table-head">Charge</th>
                <th className="table-head">Raised</th>
                <th className="table-head">Amount is</th>
                <th className="table-head">Houses</th>
                <th className="table-head">Bills</th>
                <th className="table-head sr-only print:hidden">Actions</th>
              </tr>
            </thead>
            <tbody>
              {chargeTypes.map((t) => (
                <tr key={t.payment_type} className="hover:bg-slate-50">
                  <td className="table-cell font-medium text-slate-800">{t.payment_type_name}</td>
                  <td className="table-cell">{FREQUENCY_LABEL[t.frequency] ?? '—'}</td>
                  <td className="table-cell">{BASIS_LABEL[t.basis] ?? '—'}</td>
                  <td className="table-cell">{t.houses_charged}</td>
                  <td className="table-cell">{t.bills_raised}</td>
                  <td className="table-cell whitespace-nowrap text-right print:hidden">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        type="button"
                        className="btn-secondary"
                        onClick={() =>
                          setChargeForm({
                            payment_type: t.payment_type,
                            name: t.payment_type_name,
                            frequency: t.frequency,
                            basis: t.basis,
                            is_builtin: t.is_builtin,
                            is_locked: t.is_locked ?? t.is_builtin,
                          })
                        }
                      >
                        Edit
                      </button>
                      {/*
                        The three built-in charges cannot be removed: bills
                        refer to them and SQL objects join them by name.
                      */}
                      {t.is_builtin ? null : (
                        <button type="button" className="btn-danger" onClick={() => setRemoving(t)}>
                          Remove
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <h2 className="mb-2 text-sm font-bold" style={{ color: '#012970' }}>
        Which houses pay
      </h2>

      <div className="card overflow-hidden">
        {visible.length === 0 ? (
          <EmptyState title="No houses found" hint="Houses added to this village appear here." />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">House</th>
                  <th className="table-head">Area</th>
                  <th className="table-head">Taps</th>
                  {types.map((t) => (
                    <th key={t.payment_type} className="table-head">
                      {t.name}
                      <span className="block text-[11px] font-normal normal-case text-slate-500">
                        {FREQUENCY_LABEL[t.frequency] ?? ''} · {BASIS_LABEL[t.basis] ?? ''}
                      </span>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {visible.map((h) => (
                  <tr key={h.house_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800">{h.house_no}</td>
                    <td className="table-cell">{h.area ?? '—'}</td>
                    <td className="table-cell">{h.no_of_tab ?? 0}</td>
                    {types.map((t) => {
                      const c = h.charges.get(t.payment_type) ?? { applies: false, amount: null };
                      const key = `${h.house_id}:${t.payment_type}`;
                      const busy = savingKey === key;
                      const isEditing = editing === key;

                      return (
                        <td key={t.payment_type} className="table-cell">
                          <div className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              className="h-4 w-4 rounded border-slate-300"
                              checked={c.applies}
                              disabled={busy}
                              aria-label={`${t.name} applies to house ${h.house_no}`}
                              onChange={(e) =>
                                save(h.house_id, t.payment_type, { applies: e.target.checked })
                              }
                            />

                            {c.applies && isEditing ? (
                              <input
                                className="field-input w-28 py-1 text-sm"
                                type="number"
                                min="0"
                                step="0.01"
                                autoFocus
                                defaultValue={c.amount ?? ''}
                                aria-label={`${t.name} amount for house ${h.house_no}`}
                                onBlur={(e) => {
                                  setEditing(null);
                                  const next = e.target.value;
                                  if (next !== String(c.amount ?? '')) {
                                    save(h.house_id, t.payment_type, { applies: true, amount: next });
                                  }
                                }}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter') e.target.blur();
                                  if (e.key === 'Escape') setEditing(null);
                                }}
                              />
                            ) : c.applies ? (
                              <button
                                type="button"
                                className="text-sm text-slate-700 underline decoration-dotted underline-offset-2"
                                disabled={busy}
                                onClick={() => setEditing(key)}
                              >
                                {busy ? 'Saving…' : money(c.amount)}
                              </button>
                            ) : (
                              <span className="text-sm text-slate-400">Not billed</span>
                            )}
                          </div>

                          {/*
                            When this amount starts being billed. A change made
                            before the period has been billed applies to it; one
                            made after applies from the next period. Without the
                            date on screen the two are indistinguishable, and an
                            amount typed today could sit unused for a month with
                            nothing saying so.
                          */}
                          {c.applies && c.effectiveFrom ? (
                            <span
                              className="mt-0.5 block text-[11px]"
                              style={{ color: c.pending ? '#9a3412' : '#94a3b8' }}
                            >
                              {c.pending ? 'from ' : 'since '}
                              {periodLabel(c.effectiveFrom, t.frequency)}
                            </span>
                          ) : null}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="mt-3 space-y-1 text-xs text-slate-500">
        <p>
          A charge switched off keeps its amount, so switching it back on
          restores what the house was charged before.
        </p>
        {/*
          The rule the dates under each amount follow. Stated once here rather
          than repeated per cell, so the grid stays readable.
        */}
        <p>
          A new amount applies to the current period if it has not been billed
          yet, and from the next one if it has. Bills already raised keep the
          amount they were raised at.
        </p>
      </div>

      <Modal
        open={Boolean(chargeForm)}
        title={chargeForm?.payment_type ? 'Edit charge' : 'Add charge'}
        onClose={() => setChargeForm(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setChargeForm(null)}>
              Cancel
            </button>
            <button type="submit" form="charge-type-form" className="btn-primary" disabled={savingCharge}>
              {savingCharge ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {chargeForm ? (
          <form id="charge-type-form" onSubmit={saveChargeType} className="grid gap-4" noValidate>
            <Field label="Name" required hint="What this charge is called on a bill.">
              <input
                className="field-input"
                autoFocus
                value={chargeForm.name}
                onChange={(e) => setChargeForm((f) => ({ ...f, name: e.target.value }))}
                required
              />
            </Field>

            <Field label="How often it is raised" required>
              <select
                className="field-input"
                value={chargeForm.frequency}
                disabled={chargeForm.is_locked}
                onChange={(e) => setChargeForm((f) => ({ ...f, frequency: e.target.value }))}
              >
                <option value="M">Every month</option>
                <option value="Y">Once a year</option>
              </select>
            </Field>

            <Field
              label="How the amount is worked out"
              required
              hint="The amount itself is set per house in the grid below."
            >
              <select
                className="field-input"
                value={chargeForm.basis}
                disabled={chargeForm.is_locked}
                onChange={(e) => setChargeForm((f) => ({ ...f, basis: e.target.value }))}
              >
                <option value="FLAT">A fixed amount</option>
                <option value="AREA">Per sq.ft. of area</option>
                <option value="TAP">Per tap connection</option>
              </select>
            </Field>

            {/*
              A bill records its period in the shape the charge had when it was
              raised — a month for a monthly charge, nothing for a yearly one.
              Changing the frequency afterwards leaves those bills matching no
              period, so the charge reads as unbilled and is billed again. The
              server refuses it; the form says why rather than letting someone
              try.
            */}
            {chargeForm.is_locked ? (
              <p className="rounded-lg px-3 py-2 text-sm" style={{ background: '#fff7ed', color: '#9a3412' }}>
                {chargeForm.is_builtin
                  ? 'This charge came with the system. It can be renamed, but how often it is raised and how it is worked out are fixed.'
                  : 'Bills have already been raised for this charge. It can be renamed, but how often it is raised and how it is worked out are now fixed — changing them would leave those bills describing a period that no longer exists.'}
              </p>
            ) : null}
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(removing)}
        title="Remove charge"
        message={
          removing
            ? `Stop raising ${removing.payment_type_name}? Bills already raised for it are kept, and it stops appearing against every house.`
            : ''
        }
        confirmLabel="Remove"
        onConfirm={removeChargeType}
        onCancel={() => setRemoving(null)}
      />
    </section>
  );
}
