import { useEffect, useRef, useState } from 'react';
import { onboarding } from '@/api/onboarding';
import { api } from '@/api/client';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field, FormErrorSummary, Modal, Spinner } from '@/components/ui.jsx';
import { useToast } from '@/components/Toast.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';

/**
 * Your own account, as a dialog — the profile modal Site.Master opened from the
 * header dropdown (SiteMaster.fill_data / btn_save_Click, #profile_model).
 *
 * Data is loaded when the dialog opens, the same as the legacy version calling
 * fill_data() on the button's server click rather than on every page load.
 * The disabled first/last name, the username duplicate check and the
 * old-password-required rule all carry over.
 */
/*
 * What Save insists on, in the shape validateFields expects — the two
 * fields already starred. The password pair is checked separately below,
 * because it only applies while that section is open.
 */
const PROFILE_FIELDS = [
  { name: 'username', label: 'Username', required: true },
  { name: 'email', label: 'Email address', required: true, type: 'email' },
];

export default function ProfileDialog({ open, onClose }) {
  const { user } = useAuth();
  const [form, setForm] = useState(null);
  const [role, setRole] = useState('');
  const [photoUrl, setPhotoUrl] = useState(null);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last save found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [showPassword, setShowPassword] = useState(false);
  const [reveal, setReveal] = useState({ next: false, confirm: false });
  const fileRef = useRef(null);

  // Load on open, and reset on close so the next open is not showing stale
  // values or a half-filled password section.
  useEffect(() => {
    if (!open) {
      setForm(null);
      setError(null);
      setSaved(false);
      setShowPassword(false);
      setReveal({ next: false, confirm: false });
      return undefined;
    }

    let cancelled = false;
    onboarding
      .profile()
      .then((d) => {
        if (cancelled) return;
        const p = d.profile ?? {};
        // The legacy modal split `name` on spaces: first word into First Name,
        // last word into Last Name. Anything in between was dropped on save.
        const parts = String(p.name ?? '').trim().split(/\s+/).filter(Boolean);
        setForm({
          firstName: parts[0] ?? '',
          lastName: parts.length > 1 ? parts[parts.length - 1] : '',
          username: p.username ?? '',
          email: p.email ?? '',
          contactNo: p.contact_no ?? '',
          newPassword: '',
          confirm: '',
        });
        setRole(p.role ?? '');
        setPhotoUrl(p.photo_path ? `/api/web/uploads/file/${p.photo_path}` : null);
      })
      .catch((err) => !cancelled && setError(err));

    return () => {
      cancelled = true;
    };
  }, [open]);

  const setField = (key) => (e) => {
    const { value } = e.target;
    setSaved(false);
    setForm((prev) => ({ ...prev, [key]: value }));
    // The complaint goes as soon as it is being answered.
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
  };

  const onPickPhoto = async (event) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    setError(null);
    setBusy(true);
    try {
      const body = new FormData();
      body.append('files', file);
      const d = await api.post('/uploads/profile-photos', body);
      const item = d.items?.[0];
      if (item?.url) setPhotoUrl(item.url);
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);
    setSaved(false);

    // The form carries noValidate, so nothing enforced the asterisks — a
    // cleared username posted straight through.
    const missing = validateFields(PROFILE_FIELDS, form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(PROFILE_FIELDS, missing);
      return;
    }

    if (showPassword && form.newPassword && form.newPassword !== form.confirm) {
      setError(new Error('Passwords do not match'));
      return;
    }

    setBusy(true);
    try {
      await onboarding.saveProfile({
        firstName: form.firstName,
        lastName: form.lastName,
        username: form.username,
        email: form.email,
        contactNo: form.contactNo,
        // Omitted entirely unless the password section is open and filled in —
        // the SP reads '' as "leave the password alone".
        ...(showPassword && form.newPassword ? { newPassword: form.newPassword } : {}),
      });
      const changedPassword = showPassword && Boolean(form.newPassword);
      setSaved(true);
      setShowPassword(false);
      setForm((prev) => ({ ...prev, newPassword: '', confirm: '' }));
      toast.success(
        changedPassword ? 'Profile and password updated.' : 'Profile updated successfully.',
        { title: 'Saved' },
      );
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'Your profile could not be saved. Please try again.');
    } finally {
      setBusy(false);
    }
  };

  const initial = (form?.firstName || user?.name || '?').trim().charAt(0).toUpperCase();

  return (
    <Modal
      open={open}
      title="Profile"
      onClose={onClose}
      maxWidth="max-w-3xl"
      footer={
        <>
          <button type="button" className="btn-secondary flex-1 sm:flex-none" onClick={onClose}>
            Close
          </button>
          <button
            type="submit"
            form="profile-form"
            className="btn-primary flex-1 sm:flex-none"
            disabled={busy || !form}
          >
            {busy ? 'Updating…' : 'Update'}
          </button>
        </>
      }
    >
      {!form ? (
        error ? (
          <ErrorNotice error={error} />
        ) : (
          <Spinner />
        )
      ) : (
        <form id="profile-form" onSubmit={onSubmit} noValidate>
          <FormErrorSummary count={countErrors(fieldErrors)} />
          {/* Cover banner with the avatar overlapping it — the modal's
              .cover-image / .profile-container, restyled. The soft radial
              highlights keep the flat gradient from looking like a plain bar. */}
          <div
            className="relative -mx-5 -mt-4 h-28 overflow-hidden sm:h-32"
            style={{
              backgroundImage:
                'radial-gradient(circle at 18% 120%, rgba(255,255,255,0.30), transparent 45%),' +
                'radial-gradient(circle at 82% -20%, rgba(255,255,255,0.22), transparent 50%),' +
                'linear-gradient(120deg, #5c1414 0%, #a82a2a 55%, #e56b6b 100%)',
            }}
          >
            <span
              className="pointer-events-none absolute -right-6 -top-10 h-32 w-32 rounded-full"
              style={{ background: 'rgba(255,255,255,0.10)' }}
              aria-hidden="true"
            />
            <span
              className="pointer-events-none absolute -bottom-14 left-10 h-28 w-28 rounded-full"
              style={{ background: 'rgba(255,255,255,0.08)' }}
              aria-hidden="true"
            />
          </div>

          <div className="-mt-14 flex flex-col items-center gap-3 text-center sm:-mt-16 sm:flex-row sm:items-end sm:gap-5 sm:text-left">
            <button
              type="button"
              className="group relative h-28 w-28 shrink-0 overflow-hidden rounded-full transition-transform duration-200 hover:scale-[1.03] focus-visible:scale-[1.03] focus-visible:outline-none sm:h-32 sm:w-32"
              style={{ border: '4px solid #fff', boxShadow: '0 10px 26px rgba(92, 20, 20,0.28)' }}
              onClick={() => fileRef.current?.click()}
              title="Change profile photo"
            >
              {photoUrl ? (
                <img src={photoUrl} alt="Profile" className="h-full w-full object-cover" />
              ) : (
                <span
                  className="flex h-full w-full items-center justify-center text-4xl font-bold text-white"
                  style={{ background: 'linear-gradient(135deg, #a82a2a, #e56b6b)' }}
                >
                  {initial}
                </span>
              )}
              <span className="absolute inset-0 flex flex-col items-center justify-center bg-black/55 text-[11px] font-medium leading-tight text-white opacity-0 transition-opacity duration-200 group-hover:opacity-100 group-focus-visible:opacity-100">
                <span className="text-lg">📷</span>
                Change
                <br />
                photo
              </span>
              {/* Small always-visible affordance, so the hover overlay is a
                  bonus rather than the only hint that this is clickable. */}
              <span
                className="absolute bottom-1 right-1 flex h-7 w-7 items-center justify-center rounded-full text-xs text-white shadow-md"
                style={{ background: '#a82a2a', border: '2px solid #fff' }}
                aria-hidden="true"
              >
                ✎
              </span>
            </button>
            <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onPickPhoto} />

            <div className="min-w-0 pb-1">
              <p className="truncate text-xl font-bold" style={{ color: '#5c1414' }}>
                {[form.firstName, form.lastName].filter(Boolean).join(' ') || user?.name}
              </p>
              <div className="mt-1.5 flex flex-wrap items-center justify-center gap-2 sm:justify-start">
                {role ? (
                  <span
                    className="rounded-full px-3 py-1 text-xs font-semibold"
                    style={{ background: '#fbeaea', color: '#a82a2a' }}
                  >
                    {role}
                  </span>
                ) : null}
                <span
                  className="truncate rounded-full px-3 py-1 text-xs font-medium text-slate-600"
                  style={{ background: '#f1f5f9' }}
                >
                  @{form.username}
                </span>
              </div>
            </div>
          </div>

          {/* At-a-glance contact row. Read-only mirrors of the fields below —
              the legacy modal showed these only as inputs. */}
          <div className="mt-5 grid gap-3 sm:grid-cols-2">
            <SummaryTile icon="✉️" label="Email" value={form.email} />
            <SummaryTile icon="📞" label="Contact" value={form.contactNo} />
          </div>

          <div className="mt-5 surface rounded-2xl p-4 sm:p-5">
            <div className="mb-4 flex items-start gap-3">
              <span
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-base"
                style={{ background: '#fbeaea' }}
                aria-hidden="true"
              >
                👤
              </span>
              <div>
                <h3 className="text-sm font-semibold" style={{ color: '#5c1414' }}>
                  Account Settings
                </h3>
                <p className="text-sm text-slate-500">Here you can change your account information</p>
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              {/* First and last name were read-only in the modal: the name of
                  record lives on the member/owner master, not on the login. */}
              <Field label="First Name">
                <input className="field-input" value={form.firstName} disabled placeholder="First Name" />
              </Field>
              <Field label="Last Name">
                <input className="field-input" value={form.lastName} disabled placeholder="Last Name" />
              </Field>

              <div data-field="username" className="rounded-md">
              <Field label="Username" required name="username" error={fieldErrors.username}>
                <input
                  className="field-input"
                  value={form.username}
                  onChange={setField('username')}
                  maxLength={50}
                  required
                />
              </Field>
              </div>
              <div data-field="email" className="rounded-md">
              <Field label="Email Address" required name="email" error={fieldErrors.email}>
                <input
                  className="field-input"
                  type="email"
                  value={form.email}
                  onChange={setField('email')}
                  maxLength={100}
                  required
                />
              </Field>
              </div>

              <div className="sm:col-span-2">
                <Field label="Contact">
                  <input
                    className="field-input"
                    type="tel"
                    inputMode="numeric"
                    value={form.contactNo}
                    onChange={setField('contactNo')}
                    maxLength={10}
                    placeholder="Enter Contact"
                  />
                </Field>
              </div>
            </div>
          </div>

          {/* Collapsed by default, exactly like showPasswordFields() in the modal. */}
          <div className="mt-4 surface rounded-2xl p-4 sm:p-5">
            <button
              type="button"
              className="flex w-full items-center gap-3 text-left"
              onClick={() => setShowPassword((v) => !v)}
              aria-expanded={showPassword}
            >
              <span
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-base"
                style={{ background: '#fbeaea' }}
                aria-hidden="true"
              >
                🔒
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-semibold" style={{ color: '#5c1414' }}>
                  Change Password
                </span>
                <span className="block text-xs text-slate-500">
                  Set a new password — your old one is not needed
                </span>
              </span>
              <span
                className="shrink-0 text-xs text-slate-400 transition-transform duration-200"
                style={{ transform: showPassword ? 'rotate(180deg)' : 'none' }}
                aria-hidden="true"
              >
                ▼
              </span>
            </button>

            {showPassword ? (
              <div className="mt-4 grid gap-4 sm:grid-cols-2">
                <Field label="Enter Password" required hint="At least 8 characters">
                  <PasswordInput
                    value={form.newPassword}
                    onChange={setField('newPassword')}
                    placeholder="Enter Password"
                    shown={reveal.next}
                    onToggle={() => setReveal((r) => ({ ...r, next: !r.next }))}
                  />
                </Field>

                <Field
                  label="Re-enter Password"
                  required
                  error={
                    form.confirm && form.newPassword !== form.confirm
                      ? 'Passwords do not match'
                      : undefined
                  }
                >
                  <PasswordInput
                    value={form.confirm}
                    onChange={setField('confirm')}
                    placeholder="Re-enter Password"
                    shown={reveal.confirm}
                    onToggle={() => setReveal((r) => ({ ...r, confirm: !r.confirm }))}
                  />
                </Field>
              </div>
            ) : null}
          </div>

          <div className="mt-4">
            <ErrorNotice error={error} />
            {saved ? (
              <p
                className="rounded-lg px-3 py-2 text-sm font-medium"
                style={{ background: '#e7f6ec', color: '#0f7a3d' }}
                role="status"
              >
                ✓ Profile updated.
              </p>
            ) : null}
          </div>
        </form>
      )}
    </Modal>
  );
}

/** Read-only summary chip for the contact row under the hero. */
function SummaryTile({ icon, label, value }) {
  return (
    <div className="surface flex items-center gap-3 rounded-2xl px-3 py-2.5">
      <span
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-base"
        style={{ background: '#f1f5f9' }}
        aria-hidden="true"
      >
        {icon}
      </span>
      <div className="min-w-0">
        <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">{label}</p>
        <p className="truncate text-sm font-medium text-slate-700">{value || '—'}</p>
      </div>
    </div>
  );
}

/** Password box with the eye toggle the legacy modal had on each field. */
function PasswordInput({ value, onChange, placeholder, shown, onToggle }) {
  return (
    <div className="flex">
      <input
        className="field-input"
        style={{ borderTopRightRadius: 0, borderBottomRightRadius: 0 }}
        type={shown ? 'text' : 'password'}
        autoComplete="new-password"
        value={value}
        onChange={onChange}
        placeholder={placeholder}
      />
      <button
        type="button"
        className="px-3 text-sm text-slate-500 hover:bg-slate-50"
        style={{
          border: '1px solid #ced4da',
          borderLeft: 0,
          borderTopRightRadius: '0.25rem',
          borderBottomRightRadius: '0.25rem',
        }}
        onClick={onToggle}
        aria-label={shown ? 'Hide password' : 'Show password'}
      >
        {shown ? '🙈' : '👁'}
      </button>
    </div>
  );
}
