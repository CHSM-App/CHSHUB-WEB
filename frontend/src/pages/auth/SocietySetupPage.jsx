import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { onboarding } from '@/api/onboarding';
import { api } from '@/api/client';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field } from '@/components/ui.jsx';
import { findInvalidFormats } from '@/components/formValidation.js';
import RichTextField from '@/components/RichTextField.jsx';
import { AuthSplitLayout, AuthSubmit, Glyph } from '@/components/AuthLayout.jsx';
import { useToast } from '@/components/Toast.jsx';

/*
 * Replaces new_society.aspx — the four-step wizard a new account was sent to
 * straight after registering.
 *
 * The legacy page's steps, their titles and their fields are kept in order:
 *
 *   1  Basic Information   name, establish date, registration no, terms
 *   2  Contact Information office address 1/2, contact number, email
 *   3  Location Details    state → district → division, city, street, pincode
 *   4  Regular Maintenance per sq ft / 2W / 4W rates, generation day,
 *                          due period, auto-generate switch
 *
 * PUT /onboarding/societies/:id already accepts every one of these; the
 * `firstTimeSetup` flag maps to the legacy 'New' operation, which additionally
 * seeds the terms and account_setting rows.
 */

const STEPS = [
  {
    title: 'Basic Information',
    icon: <><circle cx="12" cy="12" r="9" /><path d="M12 16v-4M12 8h.01" /></>,
  },
  {
    title: 'Contact Information',
    icon: <><rect x="3" y="5" width="18" height="14" rx="2" /><path d="M8 11a2 2 0 1 0 0-4 2 2 0 0 0 0 4ZM5 17c.5-2 1.7-3 3-3s2.5 1 3 3M15 9h4M15 13h4" /></>,
  },
  {
    title: 'Location Details',
    icon: <><path d="M12 21s7-5.6 7-11a7 7 0 1 0-14 0c0 5.4 7 11 7 11Z" /><circle cx="12" cy="10" r="2.5" /></>,
  },
  {
    title: 'Regular Maintenance Settings',
    icon: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 7.9 19.4a1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H2a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.5-1.1 1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3H8a1.6 1.6 0 0 0 1-1.5V2a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8V8a1.6 1.6 0 0 0 1.5 1H22a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1Z" /></>,
  },
];

/*
 * The fields new_society.aspx marked with a red asterisk, per step.
 *
 * The legacy page listed exactly these in validateStep() and then never ran the
 * check — the body is `return true` with the list commented out — so its
 * asterisks were decoration and a half-filled society could be submitted. The
 * fields are the legacy's; enforcing them is the deliberate difference, because
 * a starred field that does not stop you is a broken promise.
 */
const REQUIRED = [
  ['name', 'establishDate', 'registrationNo'],
  ['address1', 'contactNo', 'email'],
  ['stateId', 'districtId', 'city', 'street', 'pincode'],
  ['ratePerSqFt', 'twoWheelerRate', 'fourWheelerRate', 'billGenerationDay', 'billDuePeriodDays'],
];

/*
 * The boxes on step 2 that have a shape as well as having to be filled, in the
 * form validateFields takes. Being non-empty was the only test here, so a
 * society saved with "abc" as its e-mail and a three-digit contact number.
 */
const FORMATTED = [
  { name: 'contactNo', label: 'Contact number', phone: true, digits: true, maxLength: 10 },
  { name: 'email', label: 'Email ID', type: 'email' },
];

export default function SocietySetupPage() {
  const navigate = useNavigate();
  const { societyId, refreshUser, logout } = useAuth();

  const [step, setStep] = useState(0);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const toast = useToast();
  const [regions, setRegions] = useState({ states: [], districts: [], divisions: [] });
  const [form, setForm] = useState({
    // Step 1
    name: '',
    establishDate: '',
    registrationNo: '',
    terms: '',
    // Step 2
    address1: '',
    address2: '',
    contactNo: '',
    email: '',
    // Step 3
    stateId: '',
    districtId: '',
    divisionId: '',
    city: '',
    street: '',
    pincode: '',
    // Step 4 — the legacy page's own defaults (gen day 1, due period 15).
    ratePerSqFt: '',
    twoWheelerRate: '',
    fourWheelerRate: '',
    billGenerationDay: '1',
    billDuePeriodDays: '15',
    autoBillGeneration: false,
  });

  // Cascading region lists, refetched as the selection narrows — the legacy
  // page did the same on each dropdown's SelectedIndexChanged.
  useEffect(() => {
    let cancelled = false;
    api
      .get('/masters/regions', {
        params: { stateId: form.stateId || 0, districtId: form.districtId || 0 },
      })
      .then((d) => !cancelled && setRegions(d))
      // Reported rather than swallowed: empty State and District dropdowns look
      // like a form with nothing to choose, and the step cannot be completed
      // without them.
      .catch((err) => !cancelled && setError(err));
    return () => {
      cancelled = true;
    };
  }, [form.stateId, form.districtId]);

  const setField = (key) => (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const isLast = step === STEPS.length - 1;

  /** Required fields still empty on a given step. */
  const missingOn = (i) => REQUIRED[i].filter((k) => String(form[k] ?? '').trim() === '');

  /*
   * name -> message for anything on this step that is filled but the wrong
   * shape. Scoped to the step's own fields so a bad e-mail on step 2 cannot
   * block step 4, which does not show it.
   */
  const badFormatOn = (i) =>
    findInvalidFormats(
      FORMATTED.filter((f) => REQUIRED[i].includes(f.name)),
      form,
    );

  const stepComplete = missingOn(step).length === 0;

  const onSubmit = async (event) => {
    event.preventDefault();

    // A step will not be left until its own starred fields are filled.
    if (!stepComplete) {
      setError(new Error('Please fill in every required field on this step.'));
      return;
    }

    // Filled is not the same as usable — the contact number and e-mail have to
    // be the right shape before the step is left, or the mistake is only found
    // three steps later when the save fails.
    const malformed = Object.values(badFormatOn(step));
    if (malformed.length) {
      setError(new Error(malformed[0]));
      return;
    }

    // Enter inside an input would otherwise submit from step 1.
    if (!isLast) {
      setError(null);
      setStep((s) => s + 1);
      return;
    }

    // Earlier steps can still be short if the user jumped back and cleared
    // something, so re-check all of them before saving and return to the first
    // one that is missing anything.
    const short = REQUIRED.findIndex((_, i) => missingOn(i).length > 0);
    if (short !== -1) {
      setStep(short);
      setError(new Error(`Please fill in every required field on ${STEPS[short].title}.`));
      return;
    }

    // Same for a field edited into the wrong shape after its step was passed.
    const wrong = REQUIRED.findIndex((_, i) => Object.keys(badFormatOn(i)).length > 0);
    if (wrong !== -1) {
      setStep(wrong);
      setError(new Error(Object.values(badFormatOn(wrong))[0]));
      return;
    }

    setError(null);
    setBusy(true);
    try {
      await onboarding.saveSociety(societyId, { ...form, firstTimeSetup: true });
      // The stored session still carries the society_name this account had
      // before the save — empty. Refresh it so the topbar shows the new name.
      await refreshUser();
      setDone(true);
    } catch (err) {
      setError(err);
      // Success replaces the whole screen below, so only the failure needs a
      // toast — the form stays put with every step's answers.
      toast.error(err?.message ?? 'The society could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  /*
   * new_society.aspx ended on a SweetAlert — "Society Created Successfully. You
   * Can Now Login to your Society" — and then sent the browser to login1.aspx.
   * The wording is kept; signing out on the way is what makes "now login" true,
   * since registering had already signed this account in.
   */
  if (done) {
    return (
      <AuthSplitLayout
        title="Society created"
        subtitle="Your society is set up and ready to use."
      >
        <div
          className="flex items-start gap-3 rounded-lg border p-4"
          style={{ borderColor: '#bbf7d0', background: '#f0fdf4' }}
        >
          <span className="mt-0.5 shrink-0 text-green-600" aria-hidden="true">
            <Glyph>
              <circle cx="12" cy="12" r="9" />
              <path d="m8.5 12.5 2.5 2.5 4.5-5" />
            </Glyph>
          </span>
          <p className="text-sm text-green-800">
            Society Created Successfully. You can now sign in to your society.
          </p>
        </div>

        <div className="mt-5">
          <button
            type="button"
            className="btn-primary w-full"
            style={{
              background: 'var(--grad-accent)',
              borderColor: 'var(--accent-strong)',
              borderRadius: '8px',
              padding: '11px 16px',
              fontSize: '0.9375rem',
              fontWeight: 600,
              boxShadow: '0 4px 12px -2px rgba(78,115,223,0.4)',
            }}
            onClick={async () => {
              await logout();
              navigate('/login', { replace: true });
            }}
          >
            Go to sign in
          </button>
        </div>
      </AuthSplitLayout>
    );
  }

  return (
    <AuthSplitLayout
      wide
      title="Set up your society"
      subtitle={`Step ${step + 1} of ${STEPS.length} — ${STEPS[step].title}`}
    >
      {/*
        Step rail. Each dot carries its step's glyph; completed steps show a
        tick, so the row reports progress rather than only position.
      */}
      <ol className="mb-6 flex items-center" aria-label="Setup progress">
        {STEPS.map((s, i) => {
          const stepDone = i < step;
          const current = i === step;
          return (
            <li key={s.title} className={`flex items-center ${i < STEPS.length - 1 ? 'flex-1' : ''}`}>
              <span
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition-colors"
                style={{
                  background: stepDone || current ? 'var(--grad-accent)' : '#eef2f9',
                  color: stepDone || current ? '#fff' : '#9aa3b2',
                  boxShadow: current ? '0 0 0 4px rgba(78,115,223,0.15)' : 'none',
                }}
                aria-current={current ? 'step' : undefined}
                title={s.title}
              >
                {stepDone ? (
                  <Glyph size={16}>
                    <path d="m5 12.5 4.5 4.5L19 7" />
                  </Glyph>
                ) : (
                  <Glyph size={16}>{s.icon}</Glyph>
                )}
              </span>
              {i < STEPS.length - 1 ? (
                <span
                  className="mx-1.5 h-0.5 flex-1 rounded-full"
                  style={{ background: stepDone ? 'var(--accent)' : '#e3e6f0' }}
                  aria-hidden="true"
                />
              ) : null}
            </li>
          );
        })}
      </ol>

      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        {step === 0 ? (
          <>
            <Field label="Society Name" required>
              <input
                className="field-input"
                placeholder="Enter Society Name"
                value={form.name}
                onChange={setField('name')}
                required
              />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Establish Date" required>
                <input
                  className="field-input"
                  type="date"
                  value={form.establishDate}
                  onChange={setField('establishDate')}
                  required
                />
              </Field>
              <Field label="Registration No" required>
                <input
                  className="field-input"
                  placeholder="Enter Registration Number"
                  value={form.registrationNo}
                  onChange={setField('registrationNo')}
                  required
                />
              </Field>
            </div>
            {/* editor1 — the TinyMCE box under the legacy step 1's
                "Terms & Conditions" section divider. */}
            <RichTextField
              label="Terms & Conditions"
              value={form.terms}
              onChange={(v) => setForm((prev) => ({ ...prev, terms: v }))}
            />
          </>
        ) : null}

        {step === 1 ? (
          <>
            <Field label="Office Address" required>
              <input
                className="field-input"
                placeholder="Enter Primary Address"
                value={form.address1}
                onChange={setField('address1')}
                required
              />
            </Field>
            <Field label="Alternate Address">
              <input
                className="field-input"
                placeholder="Enter Alternate Address"
                value={form.address2}
                onChange={setField('address2')}
              />
            </Field>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Contact Number" required>
                <input
                  className="field-input"
                  type="tel"
                  inputMode="numeric"
                  maxLength={10}
                  placeholder="Enter 10-digit Mobile Number"
                  value={form.contactNo}
                  onChange={setField('contactNo')}
                  required
                />
              </Field>
              <Field label="Email ID" required>
                <input
                  className="field-input"
                  type="email"
                  placeholder="Enter Email Address"
                  value={form.email}
                  onChange={setField('email')}
                  required
                />
              </Field>
            </div>
          </>
        ) : null}

        {step === 2 ? (
          <>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="State" required>
                <select
                  className="field-input"
                  value={form.stateId}
                  onChange={(e) =>
                    // Narrowing the state invalidates the district and division
                    // beneath it, so clear them rather than leave a stale pair.
                    setForm((p) => ({ ...p, stateId: e.target.value, districtId: '', divisionId: '' }))
                  }
                  required
                >
                  <option value="">Select…</option>
                  {regions.states?.map((s) => (
                    <option key={s.state_id} value={s.state_id}>
                      {s.state}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label="District" required>
                <select
                  className="field-input"
                  disabled={!form.stateId}
                  value={form.districtId}
                  onChange={(e) => setForm((p) => ({ ...p, districtId: e.target.value, divisionId: '' }))}
                  required
                >
                  <option value="">Select…</option>
                  {regions.districts?.map((d) => (
                    <option key={d.district_id} value={d.district_id}>
                      {d.district}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label="Division">
                <select
                  className="field-input"
                  disabled={!form.districtId}
                  value={form.divisionId}
                  onChange={setField('divisionId')}
                >
                  <option value="">Select…</option>
                  {regions.divisions?.map((d) => (
                    <option key={d.division_id} value={d.division_id}>
                      {d.division}
                    </option>
                  ))}
                </select>
              </Field>
              <Field label="City" required>
                <input
                  className="field-input"
                  placeholder="Enter City Name"
                  value={form.city}
                  onChange={setField('city')}
                  required
                />
              </Field>
              {/* society_search.aspx labelled this "Street" but assigned it to
                  Home_No, and the column is an int. */}
              <Field label="Street/Home No" required>
                <input
                  className="field-input"
                  type="number"
                  min="0"
                  placeholder="Enter Street/Home Number"
                  value={form.street}
                  onChange={setField('street')}
                  required
                />
              </Field>
              <Field label="Pincode" required>
                <input
                  className="field-input"
                  inputMode="numeric"
                  maxLength={6}
                  placeholder="Enter 6-digit PIN"
                  value={form.pincode}
                  onChange={setField('pincode')}
                  required
                />
              </Field>
            </div>
          </>
        ) : null}

        {step === 3 ? (
          <>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Per Sq. Feet Rate" required>
                <input
                  className="field-input"
                  type="number"
                  min="0"
                  step="0.01"
                  placeholder="Enter rate per sq. ft."
                  value={form.ratePerSqFt}
                  onChange={setField('ratePerSqFt')}
                  required
                />
              </Field>
              <Field label="2 Wheeler Rate" required>
                <input
                  className="field-input"
                  type="number"
                  min="0"
                  step="0.01"
                  placeholder="Enter 2 wheeler parking rate"
                  value={form.twoWheelerRate}
                  onChange={setField('twoWheelerRate')}
                  required
                />
              </Field>
              <Field label="4 Wheeler Rate" required>
                <input
                  className="field-input"
                  type="number"
                  min="0"
                  step="0.01"
                  placeholder="Enter 4 wheeler parking rate"
                  value={form.fourWheelerRate}
                  onChange={setField('fourWheelerRate')}
                  required
                />
              </Field>
              <Field label="Generation Day (1-31)" required>
                <input
                  className="field-input"
                  type="number"
                  min="1"
                  max="31"
                  placeholder="Enter day of month"
                  value={form.billGenerationDay}
                  onChange={setField('billGenerationDay')}
                  required
                />
              </Field>
              <Field label="Due Date Period (days)" required>
                <input
                  className="field-input"
                  type="number"
                  min="0"
                  placeholder="Enter number of days"
                  value={form.billDuePeriodDays}
                  onChange={setField('billDuePeriodDays')}
                  required
                />
              </Field>
            </div>

            {/* chk_auto_gen — the legacy switch, as a labelled row. */}
            <label
              className="flex cursor-pointer items-center gap-3 rounded-lg p-3"
              style={{ background: '#f7f9fd', border: '1px solid var(--line)' }}
            >
              <input
                type="checkbox"
                className="h-4 w-4"
                checked={form.autoBillGeneration}
                onChange={setField('autoBillGeneration')}
                style={{ accentColor: 'var(--accent-strong)' }}
              />
              <span className="text-sm font-semibold" style={{ color: 'var(--ink)' }}>
                Auto Generate Maintenance
              </span>
            </label>
          </>
        ) : null}

        <ErrorNotice error={error} />

        {/* wizard-actions: Previous on the left, Next / Submit on the right. */}
        <div className="flex items-center gap-3 pt-1">
          {step > 0 ? (
            <button type="button" className="btn-secondary" onClick={() => setStep((s) => s - 1)}>
              Previous
            </button>
          ) : null}
          <div className="ml-auto w-full sm:w-auto sm:min-w-[200px]">
            {isLast ? (
              <AuthSubmit busy={busy} busyLabel="Submitting…" disabled={!stepComplete}>
                Submit Registration
              </AuthSubmit>
            ) : (
              <AuthSubmit busy={false} disabled={!stepComplete}>
                Next
              </AuthSubmit>
            )}
          </div>
        </div>
      </form>
    </AuthSplitLayout>
  );
}
