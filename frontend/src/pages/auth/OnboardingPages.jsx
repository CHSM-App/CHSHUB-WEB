import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { onboarding } from '@/api/onboarding';
import { lookups } from '@/api/modules';
import { api } from '@/api/client';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field, Modal, Spinner } from '@/components/ui.jsx';
import { PageHeader } from '@/components/FormControls.jsx';
import ExcelImport from '@/pages/settings/ExcelImport.jsx';

/** Card shell shared by the pre-login screens. */
function AuthCard({ title, subtitle, children, footer }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-4">
      <div className="card w-full max-w-md p-6">
        <h1 className="text-lg font-semibold text-slate-800">{title}</h1>
        {subtitle ? <p className="mt-1 text-sm text-slate-500">{subtitle}</p> : null}
        {children}
        {footer ? <div className="mt-4 text-center text-sm text-slate-500">{footer}</div> : null}
      </div>
    </div>
  );
}

/** Replaces new_registration.aspx. */
export function RegisterPage() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    name: '',
    username: '',
    password: '',
    confirm: '',
    email: '',
    contactNo: '',
    societyId: '',
  });
  const [societies, setSocieties] = useState([]);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);

  useEffect(() => {
    onboarding
      .societies()
      .then((d) => setSocieties(d.items ?? []))
      .catch(() => {});
  }, []);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);
    if (form.password !== form.confirm) {
      setError(new Error('Passwords do not match'));
      return;
    }
    setBusy(true);
    try {
      await onboarding.register(form);
      setDone(true);
      setTimeout(() => navigate('/login'), 1500);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  if (done) {
    return (
      <AuthCard title="Registration submitted" subtitle="Redirecting you to sign in…">
        <p className="mt-4 text-sm text-green-700">Your account has been created.</p>
      </AuthCard>
    );
  }

  // Society list is deduplicated: the view returns one row per flat.
  const uniqueSocieties = Array.from(
    new Map(societies.map((s) => [s.society_id, s])).values(),
  );

  return (
    <AuthCard
      title="Create an account"
      subtitle="Register a committee or admin login"
      footer={<Link to="/login" className="text-blue-600 hover:underline">Back to sign in</Link>}
    >
      <form onSubmit={onSubmit} className="mt-6 space-y-4" noValidate>
        <Field label="Full name" required>
          <input className="field-input" value={form.name} onChange={setField('name')} required />
        </Field>
        <Field label="Society">
          <select className="field-input" value={form.societyId} onChange={setField('societyId')}>
            <option value="">Select a society…</option>
            {uniqueSocieties.map((s) => (
              <option key={s.society_id} value={s.society_id}>
                {s.society_name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Username" required>
          <input className="field-input" autoComplete="username" value={form.username} onChange={setField('username')} required />
        </Field>
        <Field label="Email">
          <input className="field-input" type="email" value={form.email} onChange={setField('email')} />
        </Field>
        <Field label="Contact number">
          <input className="field-input" value={form.contactNo} onChange={setField('contactNo')} />
        </Field>
        <Field label="Password" required hint="At least 8 characters">
          <input className="field-input" type="password" autoComplete="new-password" value={form.password} onChange={setField('password')} required />
        </Field>
        <Field label="Confirm password" required>
          <input className="field-input" type="password" autoComplete="new-password" value={form.confirm} onChange={setField('confirm')} required />
        </Field>

        <ErrorNotice error={error} />

        <button type="submit" className="btn-primary w-full" disabled={busy}>
          {busy ? 'Creating…' : 'Create account'}
        </button>
      </form>
    </AuthCard>
  );
}

/** Replaces ForgetPassword.aspx. */
export function ForgotPasswordPage() {
  const [form, setForm] = useState({ email: '', newPassword: '', confirm: '' });
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
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
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthCard
      title="Reset password"
      subtitle="Set a new password for your account"
      footer={<Link to="/login" className="text-blue-600 hover:underline">Back to sign in</Link>}
    >
      {done ? (
        <p className="mt-6 text-sm text-green-700">
          If an account exists for that email address, its password has been updated. You can now
          sign in.
        </p>
      ) : (
        <form onSubmit={onSubmit} className="mt-6 space-y-4" noValidate>
          <Field label="Email address" required>
            <input className="field-input" type="email" value={form.email} onChange={setField('email')} required />
          </Field>
          <Field label="New password" required hint="At least 8 characters">
            <input className="field-input" type="password" autoComplete="new-password" value={form.newPassword} onChange={setField('newPassword')} required />
          </Field>
          <Field label="Confirm password" required>
            <input className="field-input" type="password" autoComplete="new-password" value={form.confirm} onChange={setField('confirm')} required />
          </Field>

          <ErrorNotice error={error} />

          <button type="submit" className="btn-primary w-full" disabled={busy}>
            {busy ? 'Updating…' : 'Reset password'}
          </button>
        </form>
      )}
    </AuthCard>
  );
}

/** Society profile and first-time setup. Replaces new_society / society_search. */
export function SocietyProfilePage() {
  const { societyId } = useAuth();
  const [form, setForm] = useState(null);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
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
    setBusy(true);
    setError(null);
    try {
      await onboarding.saveSociety(societyId, form);
      setSaved(true);
    } catch (err) {
      setError(err);
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
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Society name" required>
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
  const [saved, setSaved] = useState(false);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setSaved(false);
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const onSubmit = async (event) => {
    event.preventDefault();
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
    } catch (err) {
      setError(err);
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
