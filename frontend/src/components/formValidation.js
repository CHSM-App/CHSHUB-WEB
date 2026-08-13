/**
 * The validation pass both families of list screen share.
 *
 * GenericCrudPage and MasterScreen grew separate submit handlers, and their
 * validation drifted: one named every empty field, the other showed a single
 * banner naming the first. Same rules and same wording from here, so a form
 * behaves the same whichever component happens to render it.
 */

/*
 * Deliberately loose. An address-literal check ("something@something.tld") is
 * what a form can honestly assert; RFC 5322 in a regex rejects addresses that
 * are in fact deliverable, and only sending mail proves the rest.
 */
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

/*
 * Ten digits, which is what an Indian subscriber number is: an optional +91 or
 * 0 trunk prefix, then exactly ten. Anything shorter is a half-typed number and
 * anything longer a slip, and both were saving before.
 *
 * Spaces, dashes and brackets are stripped before the test rather than
 * rejected — a pasted "+91 98765 43210" is a number the user considers valid,
 * and refusing it teaches them nothing except which punctuation this form
 * dislikes.
 */
const PHONE_RE = /^(?:\+?91|0)?[0-9]{10}$/;

/** Drops the separators people paste; they are not errors. */
function stripPhonePunctuation(value) {
  return String(value).replace(/[\s\-()./]/g, '');
}

/**
 * name -> message for every required field left blank.
 *
 * Fields hidden by `showIf` are skipped — an input that is not on screen
 * cannot be filled in — as are derived fields, which are computed rather than
 * typed into.
 */
export function findMissingRequired(fields, values) {
  const missing = {};
  for (const f of fields) {
    if (!f.required) continue;
    if (f.showIf && !f.showIf(values)) continue;
    if (f.derive) continue;
    const v = values[f.name];
    if (v === null || v === undefined || String(v).trim() === '') {
      missing[f.name] = requiredMessage(f);
    }
  }
  return missing;
}

/**
 * name -> message for every field whose value is the wrong shape.
 *
 * Only fields that carry a format are checked, and only once they hold
 * something: an optional email left blank is fine, and complaining about the
 * shape of an empty box on top of the required message says the same thing
 * twice. A field is checked when it declares `type: 'email'` or `phone: true`.
 *
 * The same `showIf` / `derive` skips as the required pass, for the same
 * reasons — a hidden field cannot be corrected, and a computed one is not the
 * user's to fix.
 */
export function findInvalidFormats(fields, values) {
  const invalid = {};
  for (const f of fields) {
    if (f.showIf && !f.showIf(values)) continue;
    if (f.derive) continue;

    const raw = values[f.name];
    if (raw === null || raw === undefined || String(raw).trim() === '') continue;
    const v = String(raw).trim();

    if (f.type === 'email' && !EMAIL_RE.test(v)) {
      invalid[f.name] = 'Enter a valid email address, like name@example.com';
    } else if (f.phone && !PHONE_RE.test(stripPhonePunctuation(v))) {
      // Says the rule, not just that the value broke it: "invalid" on a
      // 9-digit number leaves the user recounting to find the missing one.
      invalid[f.name] = 'Enter a 10-digit contact number, like 98765 43210';
    }
  }
  return invalid;
}

/**
 * Every complaint a submit should raise: empty required fields first, then the
 * filled-in ones that are the wrong shape.
 *
 * The two passes cannot collide — a field is either blank or it is not — so the
 * merge order is presentational only. Call sites use this rather than the two
 * halves so a screen cannot pick up one pass and miss the other, which is how
 * the email and phone boxes went unchecked on every page in the first place.
 */
export function validateFields(fields, values) {
  return { ...findMissingRequired(fields, values), ...findInvalidFormats(fields, values) };
}

/**
 * What to do, not just what is wrong (WCAG 3.3.3). "Charge type is required"
 * on a dropdown leaves the user looking for somewhere to type; "Select a
 * charge type" names the action.
 */
export function requiredMessage(field) {
  const label = String(field.label ?? 'value').toLowerCase();
  if (field.type === 'select') return `Select a ${label}`;
  if (field.type === 'file') return `Attach the ${label}`;
  if (field.type === 'checkbox') return `Tick ${label} to continue`;
  return `Enter the ${label}`;
}

/**
 * Scroll to the first rejected field, put the cursor in it, and flash it.
 *
 * Marking the fields is not enough on a form that scrolls: the dialog body
 * holds two columns of inputs, so pressing Save with an off-screen field blank
 * looked like nothing happened at all. `fields` is walked rather than the
 * error object so the target is the first in form order, not insertion order.
 */
export function focusFirstInvalid(fields, errors, root = document) {
  const first = fields.find((f) => errors[f.name]);
  if (!first) return;

  // After paint, so the error markup this targets exists.
  requestAnimationFrame(() => {
    const safe = CSS.escape(first.name);
    /*
     * Two shapes of form to find the field in. GenericCrudPage wraps each
     * control in a [data-field] div; the FormControls used by MasterScreen
     * render their own wrapper and put id="f-{name}" on the input itself, so
     * fall back to that and step up to its container to flash.
     */
    const wrapper = root.querySelector(`[data-field="${safe}"]`);
    const input = wrapper
      ? wrapper.querySelector('input, select, textarea')
      : root.getElementById?.(`f-${first.name}`) ?? root.querySelector(`#f-${safe}`);
    const flashTarget = wrapper ?? input?.closest('div');
    if (!flashTarget && !input) return;

    // Optional call: jsdom does not implement scrollIntoView, and a throw here
    // is unhandled rather than caught by the submit's own try/catch.
    (flashTarget ?? input).scrollIntoView?.({ behavior: 'smooth', block: 'center' });
    if (flashTarget) {
      flashTarget.classList.add('field-flash');
      flashTarget.addEventListener(
        'animationend',
        () => flashTarget.classList.remove('field-flash'),
        { once: true },
      );
    }
    input?.focus({ preventScroll: true });
  });
}

/** How many complaints are live. Cleared entries are left as undefined. */
export function countErrors(errors) {
  return Object.values(errors).filter(Boolean).length;
}

/**
 * Screen titles are plural ("Buildings", "Parking Places") but a toast talks
 * about the one record just saved, so it is singularised for the message.
 *
 * Only the regular -s/-ies endings are handled; a title that does not follow
 * them ("Address", "Premises") is left alone rather than mangled.
 */
export function singularise(title) {
  if (/ies$/i.test(title)) return title.replace(/ies$/i, 'y');
  if (/(ss|us|is)$/i.test(title)) return title;
  return title.replace(/s$/i, '');
}
