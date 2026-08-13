import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { onboarding } from '@/api/onboarding';
import { lookups } from '@/api/modules';
import { api } from '@/api/client';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field, Modal, Spinner, FormErrorSummary } from '@/components/ui.jsx';
import { PageHeader, TextField } from '@/components/FormControls.jsx';
import { AuthLink, AuthSplitLayout, AuthSubmit, Glyph } from '@/components/AuthLayout.jsx';
import ExcelImport from '@/pages/settings/ExcelImport.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

/*
 * The boxes new_registration.aspx marked `required`. Its needs-validation
 * script blocked the submit while any of them was empty or whitespace, so the
 * same list gates Create Account here.
 */
const REQUIRED_FIELDS = [
  ['name', 'Name'],
  ['address', 'Address'],
  ['contactNo', 'Contact No.'],
  ['email', 'Email'],
  ['username', 'Username'],
  ['password', 'Password'],
  ['confirm', 'Re-enter Password'],
];

/*
 * The format each of those boxes has to be in, on top of being filled. Keyed
 * by name and merged below so the list above stays the single record of what
 * is required, rather than becoming two lists to keep in step.
 */
const REGISTER_FORMATS = {
  contactNo: { phone: true, digits: true, maxLength: 10 },
  email: { type: 'email' },
};

/*
 * The same list in the shape validateFields takes, derived rather than
 * copied so the two cannot drift. The page used to report one combined
 * sentence — 'Please fill in every required field' — which said nothing about
 * which box was empty.
 */
const REGISTER_FIELDS = REQUIRED_FIELDS.map(([name, label]) => ({
  name,
  label,
  required: true,
  ...REGISTER_FORMATS[name],
}));

/** A confirmation panel — the outcome of a submitted form. */
function SuccessNotice({ children }) {
  return (
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
      <p className="text-sm text-green-800">{children}</p>
    </div>
  );
}

/**
 * Replaces new_registration.aspx.
 *
 * The legacy page's fields and their order are kept exactly: the
 * Society/Village radio pair at the top, then Name, Address, Contact No.,
 * Email, a Username that fills itself from the email address, Password and
 * Re-enter Password.
 *
 * No society is chosen here. new_registration.aspx.cs sent the account on to
 * new_society.aspx (or new_village.aspx for the Village option), where the
 * society is named and its address entered — so that belongs to the next step,
 * not this form. That redirect is reproduced: registering returns a session, so
 * submitting this form lands directly on the matching setup page with no
 * sign-in in between, exactly as the legacy flow did.
 *
 * The one behaviour deliberately not reproduced is the pair of OTP "Verify"
 * buttons beside mobile and email: new_registration.aspx.cs generated an OTP,
 * sent it and then never checked what was typed back, so the buttons swapped a
 * field for an OTP box and did nothing else. There is no verify endpoint behind
 * them here.
 */
/*
 * What each onboarding form insists on, in the shape validateFields
 * expects — mirroring asterisks already on the inputs that nothing enforced,
 * since every one of these forms carries noValidate.
 */
const FORGOT_FIELDS = [
  { name: 'email', label: 'Email address', required: true, type: 'email' },
];
const SOCIETY_PROFILE_FIELDS = [{ name: 'name', label: 'Society name', required: true }];
const PASSWORD_FIELDS = [
  { name: 'newPassword', label: 'New password', required: true },
  { name: 'confirm', label: 'Confirm password', required: true },
];

export function RegisterPage() {
  const navigate = useNavigate();
  const { adoptSession } = useAuth();
  const [form, setForm] = useState({
    type: 'Society',
    name: '',
    address: '',
    username: '',
    password: '',
    confirm: '',
    email: '',
    contactNo: '',
  });
  // The legacy page filled the (disabled) username box from the email on its
  // TextChanged postback. Kept, but only until the user types a username of
  // their own — after that, editing the email must not overwrite it.
  const [usernameEdited, setUsernameEdited] = useState(false);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
    // The complaint goes as soon as it is being answered.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  const onEmailChange = (e) => {
    const { value } = e.target;
    setForm((prev) => ({
      ...prev,
      email: value,
      username: usernameEdited ? prev.username : value,
    }));
  };

  const onUsernameChange = (e) => {
    setUsernameEdited(true);
    setForm((prev) => ({ ...prev, username: e.target.value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);

    // new_registration.aspx's needs-validation script rejected a required field
    // holding only whitespace ("Whitespace is not allowed") before any of the
    // format checks below ran.
    const missing = validateFields(REGISTER_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setError(null);
      focusFirstInvalid(REGISTER_FIELDS, missing);
      return;
    }

    // Then its per-type checks, in the same order: the phone box required
    // exactly 10 digits, the email had to match RegularExpressionValidator, and
    // cvPassword compared the two passwords.
    if (!/^\d{10}$/.test(form.contactNo)) {
      setError(new Error('Phone number must be exactly 10 digits'));
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      setError(new Error('Please enter a valid email address'));
      return;
    }
    if (form.password !== form.confirm) {
      setError(new Error('Passwords do not match'));
      return;
    }

    setBusy(true);
    try {
      // btn_save_Click checked the address against sp_UserLogin 'check_Email'
      // before saving anything, and stopped with a message if it was taken.
      const { available } = await onboarding.checkEmail(form.email);
      if (!available) {
        setError(new Error('This Email ID Already Registered With Us'));
        return;
      }

      // Registering hands back a session, so the tenant setup form opens
      // immediately — new_registration.aspx.cs redirected straight to
      // new_society.aspx / new_village.aspx with no sign-in in between.
      const data = await onboarding.register({
        ...form,
        deviceInfo: navigator.userAgent?.slice(0, 500),
      });
      adoptSession(data);
      navigate(form.type === 'Village' ? '/setup/village' : '/setup/society', { replace: true });
    } catch (err) {
      setError(err);
      // Success navigates straight to setup, so only the failure needs saying.
      toast.error(err?.message ?? 'The account could not be created. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthSplitLayout
      wide
      title="Create Account"
      subtitle="Register a committee or admin login."
      footer={
        <>
          Already have an account? <AuthLink to="/login">Sign in</AuthLink>
        </>
      }
    >
      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        <FormErrorSummary count={countErrors(fieldErrors)} />
        {/* The Society / Village radio pair the legacy page opened with. */}
        <fieldset className="flex items-center gap-5">
          <legend className="sr-only">Account type</legend>
          {['Society', 'Village'].map((option) => (
            <label key={option} className="flex cursor-pointer items-center gap-2 text-sm">
              <input
                type="radio"
                name="type"
                value={option}
                checked={form.type === option}
                onChange={setField('type')}
                style={{ accentColor: 'var(--accent-strong)' }}
              />
              <span style={{ color: 'var(--ink)' }}>{option}</span>
            </label>
          ))}
        </fieldset>

        {/* Fields follow new_registration.aspx's own order and placeholders:
            Name, Address, Contact No., Email, Username, Password,
            Re-enter Password. */}
        <Field label="Name" name="name" required error={fieldErrors.name}>
          <input
            className="field-input"
            placeholder="Enter Name"
            value={form.name}
            onChange={setField('name')}
            required
          />
        </Field>

        <Field label="Address" required>
          <input
            className="field-input"
            placeholder="Enter Address"
            maxLength={50}
            value={form.address}
            onChange={setField('address')}
            required
          />
        </Field>

        <Field label="Contact No." required>
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

        <Field label="Email" required>
          <input
            className="field-input"
            type="email"
            placeholder="Enter Email"
            value={form.email}
            onChange={onEmailChange}
            required
          />
        </Field>

        {/* The legacy username box was disabled and filled from the email.
            Kept editable: a username you cannot correct is a dead end if the
            address is already taken. */}
        <Field label="Username" required>
          <input
            className="field-input"
            placeholder="Username"
            autoComplete="username"
            value={form.username}
            onChange={onUsernameChange}
            required
          />
        </Field>

        <TextField
          label="Password"
          name="password"
          type="password"
          required
          placeholder="Enter Password"
          autoComplete="new-password"
          value={form.password}
          onChange={setField('password')}
        />

        <TextField
          label="Re-enter Password"
          name="confirm"
          type="password"
          required
          placeholder="Re-enter Password"
          autoComplete="new-password"
          value={form.confirm}
          onChange={setField('confirm')}
        />

        <ErrorNotice error={error} />

        <AuthSubmit busy={busy} busyLabel="Creating…">
          Create Account
        </AuthSubmit>
      </form>
    </AuthSplitLayout>
  );
}

/** Replaces ForgetPassword.aspx. */
export function ForgotPasswordPage() {
  const [form, setForm] = useState({ email: '', newPassword: '', confirm: '' });
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [done, setDone] = useState(false);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
    // The complaint goes as soon as it is being answered.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    const missing = validateFields(FORGOT_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setError(null);
      focusFirstInvalid(FORGOT_FIELDS, missing);
      return;
    }

    setError(null);
    if (form.newPassword !== form.confirm) {
      setError(new Error('Passwords do not match'));
      return;
    }
    setBusy(true);
    try {
      await onboarding.forgotPassword({ email: form.email, newPassword: form.newPassword });
      setDone(true);
    } catch (err) {
      setError(err);
      // A confirmation screen replaces the form on success; this is for the
      // case where it does not.
      toast.error(err?.message ?? 'The password could not be reset. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthSplitLayout
      title="Reset password"
      subtitle="Set a new password for your account."
      footer={<AuthLink to="/login">Back to sign in</AuthLink>}
    >
      {done ? (
        <SuccessNotice>
          If an account exists for that email address, its password has been updated. You can now
          sign in.
        </SuccessNotice>
      ) : (
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <FormErrorSummary count={countErrors(fieldErrors)} />
          <Field label="Email address" name="email" required error={fieldErrors.email}>
            <input
              className="field-input"
              type="email"
              placeholder="Enter your email"
              value={form.email}
              onChange={setField('email')}
              required
            />
          </Field>
          <TextField
            label="New password"
            name="newPassword"
            type="password"
            required
            placeholder="Enter new password"
            autoComplete="new-password"
            hint="At least 8 characters"
            value={form.newPassword}
            onChange={setField('newPassword')}
          />
          <TextField
            label="Confirm password"
            name="confirm"
            type="password"
            required
            placeholder="Re-enter new password"
            autoComplete="new-password"
            value={form.confirm}
            onChange={setField('confirm')}
          />

          <ErrorNotice error={error} />

          <AuthSubmit busy={busy} busyLabel="Updating…">
            Reset password
          </AuthSubmit>
        </form>
      )}
    </AuthSplitLayout>
  );
}

/** Society profile and first-time setup. Replaces new_society / society_search. */
export function SocietyProfilePage() {
  const { societyId } = useAuth();
  const [form, setForm] = useState(null);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [saved, setSaved] = useState(false);
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState(false);
  const [importing, setImporting] = useState(false);
  const [regions, setRegions] = useState({ states: [], districts: [], divisions: [] });

  useEffect(() => {
    let cancelled = false;
    lookups
      .society()
      .then((d) => {
        if (cancelled) return;
        const s = d.society ?? {};
        setForm({
          name: s.name ?? '',
          registrationNo: s.registration_no ?? '',
          address1: s.off_address1 ?? '',
          address2: s.off_address2 ?? '',
          contactNo: s.contact_no1 ?? '',
          email: s.email ?? '',
          city: s.city ?? '',
          pincode: s.pincode ?? '',
          panNo: s.pan_no ?? '',
          gstinNo: s.gstin_no ?? '',
          tanNo: s.tan_no ?? '',
          establishDate: s.establish_date ? String(s.establish_date).slice(0, 10) : '',
          // State / district / division and street were on society_search.aspx
          // and saved by its code-behind, but were absent from this form.
          stateId: s.state_id ? String(s.state_id) : '',
          districtId: s.district_id ? String(s.district_id) : '',
          divisionId: s.division_id ? String(s.division_id) : '',
          street: s.home_no ? String(s.home_no) : '',
        });
      })
      .catch((err) => !cancelled && setError(err));
    return () => {
      cancelled = true;
    };
  }, []);

  // Cascading region lists, refetched as the selection narrows — the legacy
  // page did the same on each dropdown's SelectedIndexChanged.
  useEffect(() => {
    let cancelled = false;
    api
      .get('/masters/regions', {
        params: {
          stateId: form?.stateId || 0,
          districtId: form?.districtId || 0,
        },
      })
      .then((d) => !cancelled && setRegions(d))
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [form?.stateId, form?.districtId]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setSaved(false);
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    const missing = validateFields(SOCIETY_PROFILE_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setError(null);
      focusFirstInvalid(SOCIETY_PROFILE_FIELDS, missing);
      return;
    }

    setBusy(true);
    setError(null);
    try {
      await onboarding.saveSociety(societyId, form);
      setSaved(true);
      toast.success('Society profile saved successfully.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The society profile could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  if (!form) return <Spinner />;

  // society_search.aspx listed the society in a grid and opened the form from
  // its Edit button, rather than showing the form straight away.
  const row = {
    name: form.name,
    registration_no: form.registrationNo,
    address: [form.address1, form.address2].filter(Boolean).join(', '),
    contact_no: form.contactNo,
  };
  const matches =
    !search.trim() ||
    Object.values(row).some((v) => String(v ?? '').toLowerCase().includes(search.trim().toLowerCase()));

  return (
    <section>
      {/* Same header shape as every other list screen: title on the left,
          search and actions on the right. */}
      <PageHeader title="Society" subtitle="Details printed on bills, receipts and reports.">
        <input
          className="field-input w-56"
          placeholder="Search…"
          aria-label="Search societies"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <button type="button" className="btn-primary" onClick={() => setImporting(true)}>
          Import Data
        </button>
      </PageHeader>

      <div className="card overflow-hidden">
        <table className="min-w-full">
          <thead>
            <tr>
              <th className="table-head">No</th>
              <th className="table-head">Name</th>
              <th className="table-head">Registration No</th>
              <th className="table-head">Address</th>
              <th className="table-head">Contact No</th>
              <th className="table-head">Edit</th>
            </tr>
          </thead>
          <tbody>
            {matches ? (
              <tr>
                <td className="table-cell">1</td>
                <td className="table-cell">{row.name || '—'}</td>
                <td className="table-cell">{row.registration_no || '—'}</td>
                <td className="table-cell">{row.address || '—'}</td>
                <td className="table-cell">{row.contact_no || '—'}</td>
                <td className="table-cell">
                  <button
                    type="button"
                    className="text-blue-600 hover:underline"
                    aria-label="Edit society"
                    onClick={() => setEditing(true)}
                  >
                    ✎
                  </button>
                </td>
              </tr>
            ) : (
              <tr>
                <td className="table-cell" colSpan={6}>
                  No societies match “{search}”.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <Modal
        open={editing}
        title="Society"
        onClose={() => setEditing(false)}
        footer={
          <>
            {saved ? <span className="mr-auto text-sm text-green-700">Saved.</span> : null}
            <button type="button" className="btn-secondary" onClick={() => setEditing(false)}>
              Close
            </button>
            {/* Outside the <form>, so submit it by id. */}
            <button type="submit" form="society-form" className="btn-primary" disabled={busy}>
              {busy ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
      <form id="society-form" onSubmit={onSubmit} noValidate>
        <FormErrorSummary count={countErrors(fieldErrors)} />
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Society name" name="name" required error={fieldErrors.name}>
            <input className="field-input" value={form.name} onChange={setField('name')} required />
          </Field>
          <Field label="Registration number">
            <input className="field-input" value={form.registrationNo} onChange={setField('registrationNo')} />
          </Field>
          <Field label="Address line 1">
            <input className="field-input" value={form.address1} onChange={setField('address1')} />
          </Field>
          <Field label="Address line 2">
            <input className="field-input" value={form.address2} onChange={setField('address2')} />
          </Field>
          <Field label="Contact number">
            <input className="field-input" value={form.contactNo} onChange={setField('contactNo')} />
          </Field>
          <Field label="Email">
            <input className="field-input" type="email" value={form.email} onChange={setField('email')} />
          </Field>

          {/* State → district → division, cascading as on society_search.aspx. */}
          <Field label="State">
            <select
              className="field-input"
              value={form.stateId}
              onChange={(e) =>
                // Narrowing the state invalidates the district and division
                // beneath it, so clear them rather than leave a stale pair.
                setForm((p) => ({ ...p, stateId: e.target.value, districtId: '', divisionId: '' }))
              }
            >
              <option value="">Select…</option>
              {regions.states?.map((s) => (
                <option key={s.state_id} value={s.state_id}>
                  {s.state}
                </option>
              ))}
            </select>
          </Field>
          <Field label="District">
            <select
              className="field-input"
              disabled={!form.stateId}
              value={form.districtId}
              onChange={(e) => setForm((p) => ({ ...p, districtId: e.target.value, divisionId: '' }))}
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

          <Field label="City">
            <input className="field-input" value={form.city} onChange={setField('city')} />
          </Field>
          <Field label="Street" hint="Street or house number">
            <input
              className="field-input"
              type="number"
              min="0"
              value={form.street}
              onChange={setField('street')}
            />
          </Field>
          <Field label="Pincode">
            <input className="field-input" value={form.pincode} onChange={setField('pincode')} />
          </Field>
          <Field label="PAN">
            <input className="field-input" value={form.panNo} onChange={setField('panNo')} />
          </Field>
          <Field label="GSTIN">
            <input className="field-input" value={form.gstinNo} onChange={setField('gstinNo')} />
          </Field>
          <Field label="TAN">
            <input className="field-input" value={form.tanNo} onChange={setField('tanNo')} />
          </Field>
          <Field label="Established on">
            <input className="field-input" type="date" value={form.establishDate} onChange={setField('establishDate')} />
          </Field>
        </div>

        <div className="mt-5">
          <ErrorNotice error={error} />
        </div>
      </form>
      </Modal>

      <Modal open={importing} title="Import Data" onClose={() => setImporting(false)}>
        <ExcelImport onDone={() => setImporting(false)} />
      </Modal>
    </section>
  );
}

/** Change your own password. */
export function ChangePasswordPage() {
  const [form, setForm] = useState({ newPassword: '', confirm: '' });
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [saved, setSaved] = useState(false);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setSaved(false);
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    const missing = validateFields(PASSWORD_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      setError(null);
      focusFirstInvalid(PASSWORD_FIELDS, missing);
      return;
    }

    setError(null);
    if (form.newPassword !== form.confirm) {
      setError(new Error('Passwords do not match'));
      return;
    }
    setBusy(true);
    try {
      await onboarding.changePassword({ newPassword: form.newPassword });
      setSaved(true);
      setForm({ newPassword: '', confirm: '' });
      toast.success('Your password has been changed.', { title: 'Saved' });
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The password could not be changed. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <section className="max-w-md">
      <header className="mb-4">
        <h1 className="text-lg font-semibold text-slate-800">Change password</h1>
      </header>
      <form onSubmit={onSubmit} className="card space-y-4 p-5" noValidate>
        <FormErrorSummary count={countErrors(fieldErrors)} />
        <Field label="New password" required hint="At least 8 characters">
          <input className="field-input" type="password" autoComplete="new-password" value={form.newPassword} onChange={setField('newPassword')} required />
        </Field>
        <Field label="Confirm password" required>
          <input className="field-input" type="password" autoComplete="new-password" value={form.confirm} onChange={setField('confirm')} required />
        </Field>
        <ErrorNotice error={error} />
        <div className="flex items-center gap-3">
          <button type="submit" className="btn-primary" disabled={busy}>
            {busy ? 'Updating…' : 'Change password'}
          </button>
          {saved ? <span className="text-sm text-green-700">Password updated.</span> : null}
        </div>
      </form>
    </section>
  );
}
