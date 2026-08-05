import { describe, it, expect, vi } from 'vitest';
import {
  openableUrl,
  isLocalDiskPath,
  unopenableReason,
  needsAuth,
  fetchProtectedUrl,
  revokeBlobUrl,
} from './storedFile.js';

// Every shape below is taken from real staff_master rows in the live database.
describe('openableUrl', () => {
  it('serves a file uploaded through this API', () => {
    expect(openableUrl('staff/1785921102958-527564359.pdf')).toBe(
      '/api/web/uploads/file/staff/1785921102958-527564359.pdf',
    );
  });

  it('encodes filenames containing spaces or brackets', () => {
    expect(openableUrl('staff/Maintenance Report (1).pdf')).toBe(
      '/api/web/uploads/file/staff/Maintenance%20Report%20(1).pdf',
    );
  });

  it('passes an absolute URL through unchanged', () => {
    const url = 'https://app.chshub.co.in/upload/ProfilePhoto/2/riya.png';
    expect(openableUrl(url)).toBe(url);
  });

  it('keeps a legacy web path as a root-relative link', () => {
    expect(openableUrl('/Documents/Docs/Gokuldham/StaffDetails.pdf')).toBe(
      '/Documents/Docs/Gokuldham/StaffDetails.pdf',
    );
  });

  it('gives a root-relative link to a legacy path with no leading slash', () => {
    expect(openableUrl('Documents/Docs/x.pdf')).toBe('/Documents/Docs/x.pdf');
  });

  it('refuses a Windows disk path rather than emitting a dead link', () => {
    expect(
      openableUrl('D:\\VengurlaTech\\society\\Society2024\\Documents\\MaintenanceReport (1)(3).pdf'),
    ).toBeNull();
  });

  it('refuses a UNC share path', () => {
    expect(openableUrl('\\\\fileserver\\share\\id.pdf')).toBeNull();
  });

  it('returns null for empty or missing values', () => {
    expect(openableUrl('')).toBeNull();
    expect(openableUrl(null)).toBeNull();
    expect(openableUrl(undefined)).toBeNull();
  });
});

describe('isLocalDiskPath', () => {
  it('recognises drive letters and UNC paths', () => {
    expect(isLocalDiskPath('D:\\a\\b.pdf')).toBe(true);
    expect(isLocalDiskPath('c:/a/b.pdf')).toBe(true);
    expect(isLocalDiskPath('\\\\srv\\share')).toBe(true);
  });

  it('does not mistake a URL or a relative path for one', () => {
    expect(isLocalDiskPath('https://x.com/a.pdf')).toBe(false);
    expect(isLocalDiskPath('staff/a.pdf')).toBe(false);
  });
});

describe('needsAuth', () => {
  it('flags files served by this API, which sit behind the bearer token', () => {
    expect(needsAuth('/api/web/uploads/file/staff/a.pdf')).toBe(true);
  });

  it('does not flag an external URL or a legacy path', () => {
    expect(needsAuth('https://app.chshub.co.in/upload/a.png')).toBe(false);
    expect(needsAuth('/Documents/Docs/a.pdf')).toBe(false);
    expect(needsAuth(null)).toBe(false);
  });
});

describe('fetchProtectedUrl', () => {
  it('requests the file as a blob through the given client', async () => {
    const blob = new Blob(['pdf'], { type: 'application/pdf' });
    const client = { get: vi.fn(async () => ({ data: blob })) };

    const url = await fetchProtectedUrl('/api/web/uploads/file/staff/a.pdf', client);

    expect(client.get).toHaveBeenCalledWith('/api/web/uploads/file/staff/a.pdf', {
      responseType: 'blob',
    });
    expect(url).toMatch(/^blob:/);
    revokeBlobUrl(url);
  });
});

describe('unopenableReason', () => {
  it('explains an empty value', () => {
    expect(unopenableReason('')).toMatch(/no file uploaded/i);
  });

  it('explains a disk path and says what to do about it', () => {
    expect(unopenableReason('D:\\a\\b.pdf')).toMatch(/re-upload/i);
  });

  it('has nothing to say about a servable path', () => {
    expect(unopenableReason('staff/a.pdf')).toBeNull();
  });
});
