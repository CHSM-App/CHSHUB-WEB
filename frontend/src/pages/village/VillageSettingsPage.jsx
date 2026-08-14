import { useEffect, useState } from 'react';
import { village } from '@/api/modules';
import { ErrorNotice, Field, Spinner } from '@/components/ui.jsx';
import { SettingsCard, ToggleRow } from '../settings/AccountSettingsPage.jsx';
import { useToast } from '@/components/Toast.jsx';

/*
 * Village billing settings — the village_setting row added in
 * SQL/ADD_village_billing_v2.sql.
 *
 * The society side has account_setting.aspx for the equivalent; a village had
 * nothing, so bill generation had no configuration at all and its one
 * hard-coded run billed a fixed village on fixed numbering.
 *
 * Card layout and the toggle control are AccountSettingsPage's, imported
 * rather than copied so the two settings screens stay recognisably the same.
 */

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

function toForm(s) {
  return {
    autoBillGeneration: Boolean(s?.auto_bill_generation),
    billGenDay: s?.bill_gen_day ?? 1,
    propertyTaxMonth: s?.property_tax_month ?? 4,
    dueDays: s?.due_days ?? 30,
    interestRate: s?.interest_rate ?? 0,
    interestAfterDays: s?.interest_after_days ?? 30,
  };
}

export default function VillageSettingsPage() {
  const [form, setForm] = useState(() => toForm(null));
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [saved, setSaved] = useState(false);
  const toast = useToast();

  useEffect(() => {
    let cancelled = false;
    village
      .settings()
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
      await village.saveSettings(form);
      // Read back rather than trusting the form: the SP clamps out-of-range
      // values, so what was saved is not always what was typed.
      const data = await village.settings();
      setForm(toForm(data.settings));
      setSaved(true);
      toast.success('Village settings saved successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The settings could not be saved. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <Spinner />;

  return (
    <section className="max-w-4xl">
      <header className="mb-5">
        <h1 className="text-xl font-bold" style={{ color: '#5c1414' }}>
          Village settings
        </h1>
        <p className="text-sm text-slate-500">How tax bills are raised, and what a late payment costs.</p>
      </header>

      <ErrorNotice error={error} />

      <form onSubmit={onSubmit} noValidate>
        <SettingsCard
          icon="🧾"
          title="Bill generation"
          subtitle="When each period's bills are raised."
        >
          <ToggleRow
            label="Generate bills automatically"
            checked={form.autoBillGeneration}
            onChange={setField('autoBillGeneration')}
          />

          {/*
            The switch does something now: the API runs the generation daily.
            Saying when it runs, and that nothing is raised twice, is what
            stops someone raising the same month by hand as well.
          */}
          {form.autoBillGeneration ? (
            <p className="mt-2 rounded-lg px-3 py-2 text-sm" style={{ background: '#ecfdf5', color: '#065f46' }}>
              Bills are raised overnight on the day of the month chosen below,
              so the day's figures do not change while the office is open. A
              period already billed is never billed again, so raising bills by
              hand as well is safe.
            </p>
          ) : null}

          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            <Field
              label="Day of the month"
              hint="1–28. Later days are not offered: they would skip February."
            >
              <input
                className="field-input"
                type="number"
                min="1"
                max="28"
                value={form.billGenDay}
                onChange={setField('billGenDay')}
              />
            </Field>

            <Field label="Property tax month" hint="Property tax is charged once a year, in this month.">
              <select className="field-input" value={form.propertyTaxMonth} onChange={setField('propertyTaxMonth')}>
                {MONTHS.map((name, i) => (
                  <option key={name} value={i + 1}>
                    {name}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Days to pay" hint="Days from the bill date until it is due.">
              <input
                className="field-input"
                type="number"
                min="0"
                max="365"
                value={form.dueDays}
                onChange={setField('dueDays')}
              />
            </Field>
          </div>

          {/*
            Water and waste are monthly and property tax yearly — that is
            recorded per charge type on Village_payment_type, not here, so a
            charge added later brings its own frequency.
          */}
          <p className="mt-4 text-xs text-slate-500">
            Water and waste charges are raised every month; property tax once a
            year, in the month chosen above.
          </p>
        </SettingsCard>

        <SettingsCard icon="⏰" title="Late payment" subtitle="Interest charged on a bill left unpaid.">
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Interest rate (%)" hint="Leave at 0 to charge no interest.">
              <input
                className="field-input"
                type="number"
                min="0"
                max="100"
                step="0.01"
                value={form.interestRate}
                onChange={setField('interestRate')}
              />
            </Field>

            <Field label="Charged after (days)" hint="Days past the due date before interest starts.">
              <input
                className="field-input"
                type="number"
                min="0"
                max="365"
                value={form.interestAfterDays}
                onChange={setField('interestAfterDays')}
              />
            </Field>
          </div>

          {Number(form.interestRate) > 0 ? (
            <p className="mt-3 rounded-lg px-3 py-2 text-sm" style={{ background: '#fff7ed', color: '#9a3412' }}>
              Interest is not applied to bills yet — this rate is stored, but
              nothing charges it until that step is built.
            </p>
          ) : null}
        </SettingsCard>

        <div className="flex items-center gap-3">
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? 'Saving…' : 'Save settings'}
          </button>
          {saved ? <span className="text-sm font-medium text-green-700">Saved.</span> : null}
        </div>
      </form>
    </section>
  );
}
