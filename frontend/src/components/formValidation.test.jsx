import { describe, expect, it } from 'vitest';
import {
  findInvalidFormats,
  findMissingRequired,
  validateFields,
} from './formValidation.js';

/*
 * Every screen's email and contact box went unchecked: the shared pass only
 * asked whether a field was empty, so "abc" saved as an address and "12" as a
 * phone number. These cover the shapes that actually reach the forms.
 */
describe('findInvalidFormats', () => {
  const FIELDS = [
    { name: 'email', label: 'Email', type: 'email' },
    { name: 'contactNo', label: 'Contact no', phone: true },
  ];

  it('passes an address and a number that are the right shape', () => {
    expect(
      findInvalidFormats(FIELDS, { email: 'owner@example.com', contactNo: '9876543210' }),
    ).toEqual({});
  });

  it.each([
    ['no @ at all', 'abc'],
    ['nothing before the @', '@example.com'],
    ['no domain', 'owner@'],
    ['no dot in the domain', 'owner@example'],
    ['a single-letter tld', 'owner@example.c'],
    ['an embedded space', 'ow ner@example.com'],
  ])('rejects an email with %s', (_why, value) => {
    expect(findInvalidFormats(FIELDS, { email: value }).email).toMatch(/valid email/);
  });

  it.each([
    ['far too short', '12'],
    ['nine digits', '987654321'],
    ['eleven digits', '98765432101'],
    ['letters', '98765abcde'],
    ['far too long', '1234567890123456'],
  ])('rejects a contact number that is %s', (_why, value) => {
    expect(findInvalidFormats(FIELDS, { contactNo: value }).contactNo).toMatch(/10-digit/);
  });

  /*
   * Ten is the subscriber number; the trunk and country prefixes sit on top of
   * it rather than counting towards it.
   */
  it.each(['9876543210', '+919876543210', '919876543210', '09876543210'])(
    'accepts %s — ten digits, prefix or not',
    (value) => {
      expect(findInvalidFormats(FIELDS, { contactNo: value })).toEqual({});
    },
  );

  /*
   * The separators people paste are not errors. A number copied out of a
   * contacts app arrives spaced or bracketed, and refusing it teaches the user
   * only which punctuation the form dislikes.
   */
  it.each(['+91 98765 43210', '(022) 4567-8901', '98765-43210', '020.2345.6789'])(
    'accepts %s, punctuation and all',
    (value) => {
      expect(findInvalidFormats(FIELDS, { contactNo: value })).toEqual({});
    },
  );

  it('leaves an empty optional field alone', () => {
    // Nothing to be the wrong shape yet, and on a required field the missing
    // pass already has something to say about it.
    expect(findInvalidFormats(FIELDS, { email: '', contactNo: '   ' })).toEqual({});
  });

  it('ignores a field that declares no format', () => {
    expect(findInvalidFormats([{ name: 'name', label: 'Name' }], { name: '@@@' })).toEqual({});
  });

  it('skips a hidden field, which the user cannot correct', () => {
    const hidden = [{ name: 'email', label: 'Email', type: 'email', showIf: () => false }];
    expect(findInvalidFormats(hidden, { email: 'nonsense' })).toEqual({});
  });

  it('skips a derived field, which is computed rather than typed', () => {
    const derived = [{ name: 'email', label: 'Email', type: 'email', derive: () => 'x' }];
    expect(findInvalidFormats(derived, { email: 'nonsense' })).toEqual({});
  });
});

describe('validateFields', () => {
  const FIELDS = [
    { name: 'name', label: 'Name', required: true },
    { name: 'email', label: 'Email', type: 'email', required: true },
    { name: 'contactNo', label: 'Contact no', phone: true },
  ];

  it('reports both an empty required field and a malformed one together', () => {
    const errors = validateFields(FIELDS, { name: '', email: 'nope', contactNo: '9876543210' });
    expect(errors.name).toBe('Enter the name');
    expect(errors.email).toMatch(/valid email/);
    expect(errors.contactNo).toBeUndefined();
  });

  it('asks a required-and-empty field to be filled, not reformatted', () => {
    // A field cannot be both blank and the wrong shape, so the two passes never
    // disagree about one name — the user is told to fill it in, once.
    const errors = validateFields(FIELDS, { name: 'A', email: '' });
    expect(errors.email).toBe('Enter the email');
  });

  it('is clean when every field is filled and well-formed', () => {
    expect(
      validateFields(FIELDS, {
        name: 'A Patil',
        email: 'a.patil@example.com',
        contactNo: '+91 98765 43210',
      }),
    ).toEqual({});
  });

  it('still finds what the required pass alone would have', () => {
    const values = { name: '', email: '', contactNo: '' };
    expect(validateFields(FIELDS, values)).toEqual(findMissingRequired(FIELDS, values));
  });
});
