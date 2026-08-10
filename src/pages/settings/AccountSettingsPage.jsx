import { useEffect, useState } from 'react';
import { accountSettings } from '@/api/settings';
import { ErrorNotice, Field, Spinner } from '@/components/ui.jsx';

/**
 * The ON/OFF switches account_setting.aspx rendered as OFF/ON dropdowns, in the
 * order and wording that page used. Grouped into the same five headings:
 * Additional/Supplementary Billing, Billing, Voucher Entry, Payment, Reminder.
 *
 * `column` is the account_setting column the value is read back from; `field`
 * is what the API accepts.
 */
const TOGGLES = [
  { field: 'memberOpeningBalance', column: 'mem_open_bal', label: 'Additional Member Opening Balance Button' },
  { field: 'memberChargesButton', column: 'mem_charge_btn', label: 'Additional Member Charges Button' },
  { field: 'memberChargeAllocation', column: 'mem_charge_allocation', label: 'Additional Member Charge Allocation' },
  { field: 'receiptsButton', column: 'receipt_btn', label: 'Additional Receipts Button' },
  { field: 'gstRounding', column: 'gst_round', label: 'GST Rounding' },
  { field: 'chargesRounding', column: 'charge_round', label: 'Charges Rounding' },
  { field: 'paymentVoucherMultiEntry', column: 'payment_voucher', label: 'Multi entry in Payment voucher' },
  { field: 'debitNoteVoucherMultiEntry', column: 'debit_note_voucher', label: 'Multi entry in Debit note voucher' },
  { field: 'creditNoteVoucherMultiEntry', column: 'credit_note_voucher', label: 'Multi entry in Credit note voucher' },
  { field: 'journalVoucherMultiEntry', column: 'general_voucher', label: 'Multi entry in Journal voucher' },
  { field: 'receiptVoucherMultiEntry', column: 'receipt_voucher', label: 'Multi entry in Receipt voucher' },
  { field: 'buildingWisePayment', column: 'build_wise_payment', label: 'Maintain Building Wise Payment' },
  { field: 'reminderEmailForDues', column: 'remainder_email_dues', label: 'Send Reminder Email For Dues' },
];

const byField = (name) => TOGGLES.find((t) => t.field === name);

const toForm = (s) => ({
  ratePerSqFt: s?.rate_per_sqfeet ?? '',
  twoWheelerRate: s?.two_wheeler_rate ?? '',
  fourWheelerRate: s?.four_wheeler_rate ?? '',
  // Not shown on this screen — account_setting.aspx had no equivalent fields.
  // They are still loaded and sent back untouched, because the save writes the
  // whole row: dropping them would reset the monthly bill run to its defaults
  // (auto-generation off, day 1, due period 0).
  autoBillGeneration: Boolean(s?.auto_bill_generation),
  billGenerationDay: s?.bill_gen_date ?? 1,
  billDuePeriodDays: s?.bill_due_period ?? 0,
  ...Object.fromEntries(TOGGLES.map((t) => [t.field, Boolean(s?.[t.column])])),
});

/**
 * Billing configuration for the society — replaces account_setting.aspx.
 *
 * These values feed gen_bill and sp_new_maintenance, so changes here affect the
 * next bill run.
 */
export default function AccountSettingsPage() {
  const [form, setForm] = useState(() => toForm(null));
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
    <section className="max-w-4xl">
      <header className="mb-5">
        <h1 className="text-xl font-bold" style={{ color: '#012970' }}>
          Account settings
        </h1>
        <p className="text-sm text-slate-500">Rates and options used when generating bills.</p>
      </header>

      <form onSubmit={onSubmit} noValidate>
        {/* Section order and headings follow account_setting.aspx exactly. */}
        <SettingsCard
          icon="➕"
          title="Additional / Supplementary Billing"
          subtitle="Extra buttons shown on the member and receipt screens."
        >
          {['memberOpeningBalance', 'memberChargesButton', 'memberChargeAllocation', 'receiptsButton'].map(
            (name) => (
              <ToggleRow
                key={name}
                label={byField(name).label}
                checked={form[name]}
                onChange={setField(name)}
              />
            ),
          )}
        </SettingsCard>

        <SettingsCard icon="🧾" title="Billing" subtitle="Rounding and the rates each bill is built from.">
          {['gstRounding', 'chargesRounding'].map((name) => (
            <ToggleRow key={name} label={byField(name).label} checked={form[name]} onChange={setField(name)} />
          ))}

          <div className="grid gap-4 pt-4 sm:grid-cols-2">
            <Field label="Rate per Sq. Feet" hint="Multiplied by each flat's carpet area">
              <input
                className="field-input"
                type="number"
                step="0.01"
                min="0"
                placeholder="Enter rate"
                value={form.ratePerSqFt}
                onChange={setField('ratePerSqFt')}
              />
            </Field>
            <div className="hidden sm:block" />

            <Field label="2 Wheeler Parking Rate">
              <input
                className="field-input"
                type="number"
                step="0.01"
                min="0"
                placeholder="Enter rate"
                value={form.twoWheelerRate}
                onChange={setField('twoWheelerRate')}
              />
            </Field>
            <Field label="4 Wheeler Parking Rate">
              <input
                className="field-input"
                type="number"
                step="0.01"
                min="0"
                placeholder="Enter rate"
                value={form.fourWheelerRate}
                onChange={setField('fourWheelerRate')}
              />
            </Field>
          </div>
        </SettingsCard>

        <SettingsCard
          icon="📒"
          title="Voucher Entry"
          subtitle="Allow more than one line per voucher of each type."
        >
          {[
            'paymentVoucherMultiEntry',
            'debitNoteVoucherMultiEntry',
            'creditNoteVoucherMultiEntry',
            'journalVoucherMultiEntry',
            'receiptVoucherMultiEntry',
          ].map((name) => (
            <ToggleRow key={name} label={byField(name).label} checked={form[name]} onChange={setField(name)} />
          ))}
        </SettingsCard>

        <SettingsCard icon="💳" title="Payment">
          <ToggleRow
            label={byField('buildingWisePayment').label}
            checked={form.buildingWisePayment}
            onChange={setField('buildingWisePayment')}
          />
        </SettingsCard>

        <SettingsCard icon="🔔" title="Reminder">
          <ToggleRow
            label={byField('reminderEmailForDues').label}
            checked={form.reminderEmailForDues}
            onChange={setField('reminderEmailForDues')}
          />
        </SettingsCard>

        <ErrorNotice error={error} />

        {/* Sticks to the bottom of the viewport: the form is long enough that
            Save would otherwise sit far below the switch being changed. */}
        <div className="sticky bottom-0 mt-4 flex items-center gap-3 border-t border-slate-200 bg-white/95 py-3 backdrop-blur">
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? 'Saving…' : 'Save'}
          </button>
          {saved ? (
            <span
              className="rounded-lg px-3 py-1.5 text-sm font-medium"
              style={{ background: '#e7f6ec', color: '#0f7a3d' }}
              role="status"
            >
              ✓ Saved.
            </span>
          ) : null}
        </div>
      </form>
    </section>
  );
}

/** One titled group of settings — the legacy page's .box-header + .box-body. */
function SettingsCard({ icon, title, subtitle, children }) {
  return (
    <div className="mb-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm sm:p-5">
      <div className="mb-3 flex items-start gap-3 border-b border-slate-100 pb-3">
        <span
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-base"
          style={{ background: '#e8effc' }}
          aria-hidden="true"
        >
          {icon}
        </span>
        <div>
          <h2 className="text-sm font-bold" style={{ color: '#012970' }}>
            {title}
          </h2>
          {subtitle ? <p className="text-sm text-slate-500">{subtitle}</p> : null}
        </div>
      </div>
      {children}
    </div>
  );
}

/**
 * A single setting as a switch. The legacy page used OFF/ON dropdowns; a switch
 * is the same two states with less work to read and to flip, and it keeps the
 * ON/OFF wording visible so the mapping stays obvious.
 */
function ToggleRow({ label, checked, onChange }) {
  return (
    <label className="flex cursor-pointer items-center justify-between gap-4 border-b border-slate-100 py-2.5 last:border-b-0">
      <span className="text-sm text-slate-700">{label}</span>

      <span className="flex shrink-0 items-center gap-2">
        <span
          className="w-8 text-right text-xs font-semibold"
          style={{ color: checked ? '#0f7a3d' : '#94a3b8' }}
        >
          {checked ? 'ON' : 'OFF'}
        </span>
        <span className="relative inline-flex">
          <input type="checkbox" className="peer sr-only" checked={checked} onChange={onChange} />
          <span
            className="block h-6 w-11 rounded-full transition-colors peer-focus-visible:ring-2 peer-focus-visible:ring-blue-400 peer-focus-visible:ring-offset-2"
            style={{ background: checked ? '#1d4ed8' : '#cbd5e1' }}
          />
          <span
            className="pointer-events-none absolute left-0.5 top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform"
            style={{ transform: checked ? 'translateX(20px)' : 'none' }}
          />
        </span>
      </span>
    </label>
  );
}
