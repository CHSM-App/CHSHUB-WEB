import { useEffect, useState } from 'react';
import { accountSettings } from '@/api/settings';
import { ErrorNotice, Field, Spinner } from '@/components/ui.jsx';

const EMPTY = {
  ratePerSqFt: '',
  twoWheelerRate: '',
  fourWheelerRate: '',
  autoBillGeneration: false,
  billGenerationDay: 1,
  billDuePeriodDays: 0,
};

const toForm = (s) => ({
  ratePerSqFt: s?.rate_per_sqfeet ?? '',
  twoWheelerRate: s?.two_wheeler_rate ?? '',
  fourWheelerRate: s?.four_wheeler_rate ?? '',
  autoBillGeneration: Boolean(s?.auto_bill_generation),
  billGenerationDay: s?.bill_gen_date ?? 1,
  billDuePeriodDays: s?.bill_due_period ?? 0,
});

/**
 * Billing configuration for the society. These values feed gen_bill and
 * sp_new_maintenance, so changes here affect the next bill run.
 */
export default function AccountSettingsPage() {
  const [form, setForm] = useState(EMPTY);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    let cancelled = false;
    accountSettings
      .get()
      .then((data) => {
        if (!cancelled) setForm(toForm(data.settings));
      })
      .catch((err) => {
        if (!cancelled) setError(err);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const setField = (key) => (e) => {
    const { value, type, checked } = e.target;
    setSaved(false);
    setForm((prev) => ({ ...prev, [key]: type === 'checkbox' ? checked : value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const data = await accountSettings.save(form);
      setForm(toForm(data.settings));
      setSaved(true);
    } catch (err) {
      setError(err);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <Spinner />;

  return (
    <section className="max-w-3xl">
      <header className="mb-4">
        <h1 className="text-lg font-semibold text-slate-800">Account settings</h1>
        <p className="text-sm text-slate-500">Rates and billing schedule used when generating bills.</p>
      </header>

      <form onSubmit={onSubmit} className="card p-5" noValidate>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Maintenance rate per sq. ft." hint="Multiplied by each flat's carpet area">
            <input
              className="field-input"
              type="number"
              step="0.01"
              min="0"
              value={form.ratePerSqFt}
              onChange={setField('ratePerSqFt')}
            />
          </Field>
          <div />

          <Field label="Two-wheeler parking rate">
            <input
              className="field-input"
              type="number"
              step="0.01"
              min="0"
              value={form.twoWheelerRate}
              onChange={setField('twoWheelerRate')}
            />
          </Field>
          <Field label="Four-wheeler parking rate">
            <input
              className="field-input"
              type="number"
              step="0.01"
              min="0"
              value={form.fourWheelerRate}
              onChange={setField('fourWheelerRate')}
            />
          </Field>

          <Field label="Bill generation day" hint="Day of the month bills are raised (1–31)">
            <input
              className="field-input"
              type="number"
              min="1"
              max="31"
              value={form.billGenerationDay}
              onChange={setField('billGenerationDay')}
            />
          </Field>
          <Field label="Due period (days)" hint="Days after generation that a bill falls due">
            <input
              className="field-input"
              type="number"
              min="0"
              max="365"
              value={form.billDuePeriodDays}
              onChange={setField('billDuePeriodDays')}
            />
          </Field>

          <label className="flex items-center gap-2 sm:col-span-2">
            <input
              type="checkbox"
              className="h-4 w-4 rounded border-slate-300"
              checked={form.autoBillGeneration}
              onChange={setField('autoBillGeneration')}
            />
            <span className="text-sm text-slate-700">
              Generate maintenance bills automatically each month
            </span>
          </label>
        </div>

        <div className="mt-5">
          <ErrorNotice error={error} />
        </div>

        <div className="mt-4 flex items-center gap-3">
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? 'Saving…' : 'Save settings'}
          </button>
          {saved ? <span className="text-sm text-green-700">Saved.</span> : null}
        </div>
      </form>
    </section>
  );
}
