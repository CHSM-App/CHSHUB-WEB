import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { onboarding } from '@/api/onboarding';
import { api } from '@/api/client';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field, FormErrorSummary } from '@/components/ui.jsx';
import { AuthSplitLayout, AuthSubmit, Glyph } from '@/components/AuthLayout.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

/*
 * Replaces new_village.aspx — where a new account went when it registered with
 * the Village option, the way a Society account went to new_society.aspx.
 *
 * Unlike the society form this is one page rather than a wizard, because the
 * legacy village page was: two headings ("Basic Info" and "Contact Info") over
 * a single flat list of fields, with no maintenance-settings section at all.
 * Its fields and their order are kept — registration no, village name, address,
 * contact no, email, state → district → division, pincode.
 */
/*
 * What Submit insists on, in the shape validateFields expects — the same
 * fields that already carry a red asterisk below.
 */
const SETUP_FIELDS = [
  { name: 'registrationNo', label: 'Registration no', required: true },
  { name: 'name', label: 'Village name', required: true },
  { name: 'address', label: 'Address', required: true },
  { name: 'contactNo', label: 'Contact no', required: true, phone: true, digits: true, maxLength: 10 },
  { name: 'email', label: 'E-mail ID', required: true, type: 'email' },
  { name: 'stateId', label: 'State', type: 'select', required: true },
  { name: 'districtId', label: 'District', type: 'select', required: true },
  { name: 'division', label: 'Division', type: 'select', required: true },
];

export default function VillageSetupPage() {
  const navigate = useNavigate();
  const { villageId, refreshUser, logout } = useAuth();

  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [regions, setRegions] = useState({ states: [], districts: [], divisions: [] });
  const [form, setForm] = useState({
    registrationNo: '',
    name: '',
    address: '',
    contactNo: '',
    email: '',
    stateId: '',
    districtId: '',
    division: '',
    pincode: '',
  });

  // Cascading region lists, as the legacy dropdowns' SelectedIndexChanged did.
  // A failure here is reported rather than swallowed: silently empty State and
  // District dropdowns look like a form with nothing to choose, and the page
  // cannot be completed without them.
  useEffect(() => {
    let cancelled = false;
    api
      .get('/masters/regions', {
        params: { stateId: form.stateId || 0, districtId: form.districtId || 0 },
      })
      .then((d) => !cancelled && setRegions(d))
      .catch((err) => !cancelled && setError(err));
    return () => {
      cancelled = true;
    };
  }, [form.stateId, form.districtId]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
    // The complaint goes as soon as it is being answered.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    /*
     * The form carries noValidate, so nothing enforced the asterisks — an
     * empty setup posted straight to sp_village_master. Same pass as every
     * other screen in the app.
     */
    const missing = validateFields(SETUP_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setError(null);
      focusFirstInvalid(SETUP_FIELDS, missing);
      return;
    }

    setError(null);
    setBusy(true);
    try {
      await onboarding.saveVillage(villageId, form);
      // The session still says the village has no name, which is what sent us
      // here — refresh it before navigating or the guard bounces straight back.
      await refreshUser();
      setDone(true);
    } catch (err) {
      setError(err);
      // Success gets its own full screen below, so only the failure needs a
      // toast — the form stays put with what was typed.
      toast.error(err?.message ?? 'The village could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  /* new_village.aspx's btn_save_Click ended with Response.Redirect("login1.aspx"). */
  if (done) {
    return (
      <AuthSplitLayout title="Village created" subtitle="Your village is set up and ready to use.">
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
            Saved successfully. You can now sign in to your village.
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
              boxShadow: '0 4px 12px -2px rgba(201, 64, 64,0.4)',
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
      title="Set up your village"
      subtitle="Tell us about the village this account manages."
    >
      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        <FormErrorSummary count={countErrors(fieldErrors)} />
        <div className="grid gap-4 sm:grid-cols-2">
          <div data-field="registrationNo" className="rounded-md">
          <Field label="Registration No" required name="registrationNo" error={fieldErrors.registrationNo}>
            <input
              className="field-input"
              placeholder="Enter Registration No"
              value={form.registrationNo}
              onChange={setField('registrationNo')}
              required
            />
          </Field>
          </div>
          <div data-field="name" className="rounded-md">
          <Field label="Village Name" required name="name" error={fieldErrors.name}>
            <input
              className="field-input"
              placeholder="Enter Village Name"
              value={form.name}
              onChange={setField('name')}
              required
            />
          </Field>
          </div>
        </div>

        {/* sp_village_master declares @address as nvarchar(50). */}
        <div data-field="address" className="rounded-md">
        <Field label="Address" required name="address" error={fieldErrors.address}>
          <input
            className="field-input"
            placeholder="Enter Address"
            maxLength={50}
            value={form.address}
            onChange={setField('address')}
            required
          />
        </Field>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div data-field="contactNo" className="rounded-md">
          <Field label="Contact No." required name="contactNo" error={fieldErrors.contactNo}>
            <input
              className="field-input"
              type="tel"
              inputMode="numeric"
              maxLength={10}
              placeholder="Enter Contact No."
              value={form.contactNo}
              onChange={setField('contactNo')}
              required
            />
          </Field>
          </div>
          <div data-field="email" className="rounded-md">
          <Field label="E-mail ID" required name="email" error={fieldErrors.email}>
            <input
              className="field-input"
              type="email"
              placeholder="Enter Email"
              value={form.email}
              onChange={setField('email')}
              required
            />
          </Field>
          </div>

          <div data-field="stateId" className="rounded-md">
          <Field label="State" required name="stateId" error={fieldErrors.stateId}>
            <select
              className="field-input"
              value={form.stateId}
              onChange={(e) =>
                // Narrowing the state invalidates the district beneath it.
                setForm((p) => ({ ...p, stateId: e.target.value, districtId: '', division: '' }))
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
          </div>
          <div data-field="districtId" className="rounded-md">
          <Field label="District" required name="districtId" error={fieldErrors.districtId}>
            <select
              className="field-input"
              disabled={!form.stateId}
              value={form.districtId}
              onChange={(e) => setForm((p) => ({ ...p, districtId: e.target.value, division: '' }))}
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
          </div>

          {/*
            sp_village_master takes @division as the division's *name*, not its
            id — unlike sp_society_master, which takes division_id. So the value
            posted here is the label.
          */}
          <div data-field="division" className="rounded-md">
          <Field label="Division" required name="division" error={fieldErrors.division}>
            <select
              className="field-input"
              disabled={!form.districtId}
              value={form.division}
              onChange={setField('division')}
              required
            >
              <option value="">Select…</option>
              {regions.divisions?.map((d) => (
                <option key={d.division_id} value={d.division}>
                  {d.division}
                </option>
              ))}
            </select>
          </Field>
          </div>
          <Field label="Pincode" required>
            <input
              className="field-input"
              inputMode="numeric"
              maxLength={6}
              placeholder="Enter Pin"
              value={form.pincode}
              onChange={setField('pincode')}
              required
            />
          </Field>
        </div>

        <ErrorNotice error={error} />

        <AuthSubmit busy={busy} busyLabel="Saving…">
          Submit Registration
        </AuthSubmit>
      </form>
    </AuthSplitLayout>
  );
}
