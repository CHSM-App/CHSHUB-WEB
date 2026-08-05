import { useCallback, useMemo, useState } from 'react';

/**
 * Form state plus validation — replaces the asp:*Validator controls.
 *
 * Rules are declared per field:
 *   { required, email, mobile, minLength, maxLength, min, max, pattern,
 *     match: 'otherField', custom: (value, values) => string | null }
 *
 * Validation runs on blur and on submit, matching the legacy behaviour where a
 * validator fires when a field loses focus.
 */
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MOBILE_RE = /^[0-9+\-\s()]{6,15}$/;

export function validateField(value, rules = {}, values = {}, label = 'This field') {
  const empty = value === undefined || value === null || String(value).trim() === '';

  if (rules.required && empty) return `${label} is required`;
  if (empty) return null; // Nothing further to check on an empty optional field.

  const s = String(value).trim();

  if (rules.email && !EMAIL_RE.test(s)) return 'Enter a valid email address';
  if (rules.mobile && !MOBILE_RE.test(s)) return 'Enter a valid contact number';
  if (rules.minLength && s.length < rules.minLength)
    return `${label} must be at least ${rules.minLength} characters`;
  if (rules.maxLength && s.length > rules.maxLength)
    return `${label} must be at most ${rules.maxLength} characters`;

  if (rules.min !== undefined || rules.max !== undefined) {
    const n = Number(s);
    if (Number.isNaN(n)) return `${label} must be a number`;
    if (rules.min !== undefined && n < rules.min) return `${label} must be at least ${rules.min}`;
    if (rules.max !== undefined && n > rules.max) return `${label} must be at most ${rules.max}`;
  }

  if (rules.pattern && !rules.pattern.test(s)) return rules.patternMessage || `${label} is not valid`;
  if (rules.match && s !== String(values[rules.match] ?? '')) return rules.matchMessage || 'Values do not match';
  if (rules.custom) return rules.custom(value, values);

  return null;
}

export default function useForm(initial = {}, schema = {}) {
  const [values, setValues] = useState(initial);
  const [errors, setErrors] = useState({});
  const [touched, setTouched] = useState({});

  const setValue = useCallback((name, value) => {
    setValues((prev) => ({ ...prev, [name]: value }));
    // Clear the error as soon as the user edits; it is re-checked on blur.
    setErrors((prev) => (prev[name] ? { ...prev, [name]: null } : prev));
  }, []);

  /** onChange handler for a named field; reads the value eagerly. */
  const field = useCallback(
    (name) => ({
      value: values[name] ?? '',
      onChange: (e) => {
        const t = e.target;
        setValue(name, t.type === 'checkbox' ? t.checked : t.value);
      },
      onBlur: () => {
        setTouched((prev) => ({ ...prev, [name]: true }));
        const rule = schema[name];
        if (rule) {
          setErrors((prev) => ({
            ...prev,
            [name]: validateField(values[name], rule, values, rule.label),
          }));
        }
      },
      name,
    }),
    [values, schema, setValue],
  );

  const validateAll = useCallback(() => {
    const next = {};
    for (const [name, rule] of Object.entries(schema)) {
      const message = validateField(values[name], rule, values, rule.label);
      if (message) next[name] = message;
    }
    setErrors(next);
    setTouched(Object.fromEntries(Object.keys(schema).map((k) => [k, true])));
    return Object.keys(next).length === 0;
  }, [values, schema]);

  const reset = useCallback((next = initial) => {
    setValues(next);
    setErrors({});
    setTouched({});
  }, [initial]);

  const isValid = useMemo(() => Object.values(errors).every((e) => !e), [errors]);

  return {
    values,
    setValues,
    setValue,
    errors,
    touched,
    field,
    validateAll,
    reset,
    isValid,
    // Convenience for rendering: only show an error once the field was touched.
    errorFor: (name) => (touched[name] ? errors[name] : null),
  };
}
