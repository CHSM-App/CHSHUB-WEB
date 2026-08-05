/**
 * Resolving a stored file path to something the browser can open.
 *
 * Paths in this database were written by three different generations of the
 * app, so a single column holds four shapes:
 *
 *   staff/1785921102958-527564359.pdf          uploaded through this API
 *   /Documents/Docs/Gokuldham/StaffDetails.pdf legacy web path
 *   https://app.chshub.co.in/upload/...        absolute URL
 *   D:\VengurlaTech\...\MaintenanceReport.pdf  Windows disk path
 *
 * The last one is not reachable over HTTP at all — it is a path on the old
 * server's filesystem. Rather than emit a link that 404s, `openableUrl`
 * returns null for it so callers can say why nothing can be shown.
 */

const UPLOAD_CATEGORIES = [
  'owner-photos',
  'owner-documents',
  'agreements',
  'police-verification',
  'staff',
  'vendor-bills',
  'society-documents',
  'helpdesk',
  'products',
];

/** A Windows drive path (`D:\...`) or a UNC share (`\\server\...`). */
export function isLocalDiskPath(value) {
  const s = String(value ?? '').trim();
  return /^[a-zA-Z]:[\\/]/.test(s) || s.startsWith('\\\\');
}

/**
 * URL the browser can open, or null when the stored value cannot be served.
 */
export function openableUrl(value) {
  const s = String(value ?? '').trim();
  if (!s) return null;
  if (isLocalDiskPath(s)) return null;

  // Already absolute.
  if (/^https?:\/\//i.test(s)) return s;

  // Uploaded through this API: "<category>/<filename>".
  const [head, ...rest] = s.split('/');
  if (rest.length === 1 && UPLOAD_CATEGORIES.includes(head)) {
    return `/api/web/uploads/file/${head}/${encodeURIComponent(rest[0])}`;
  }

  // Legacy web path — served by the old site from its own root.
  return s.startsWith('/') ? s : `/${s}`;
}

/** True when the URL is served by this API and therefore needs the bearer token. */
export function needsAuth(url) {
  return typeof url === 'string' && url.startsWith('/api/web/');
}

/**
 * Fetches a protected file and returns a blob: URL for it.
 *
 * `<iframe src>` and `<a href>` cannot carry an Authorization header, so
 * pointing them at /api/web/uploads/file/... gets a 401. Going through the
 * axios client attaches the token (and refreshes it if needed), and the blob
 * URL that comes back can be shown or downloaded normally.
 *
 * The caller owns the returned URL and must revoke it — see `revokeBlobUrl`.
 */
export async function fetchProtectedUrl(url, client) {
  const response = await client.get(url, { responseType: 'blob' });
  return URL.createObjectURL(response.data);
}

export function revokeBlobUrl(url) {
  if (url && url.startsWith('blob:')) URL.revokeObjectURL(url);
}

/** Why a stored value cannot be opened, for showing to the user. */
export function unopenableReason(value) {
  const s = String(value ?? '').trim();
  if (!s) return 'No file uploaded.';
  if (isLocalDiskPath(s)) {
    return 'This file was stored as a path on the old server rather than uploaded, so it cannot be opened from here. Re-upload it to attach a copy.';
  }
  return null;
}
