// Website API — push notifications for notices, events and meetings.
//
// The legacy pages meant to do this: notice_search.aspx.cs and its siblings
// loop over the SP result calling send_notification() and generate_notification().
// But sp_notice_master/Update returns a single column — notice_id — with no
// user_id, type or token, so that loop never had rows to iterate and no
// notification was ever sent. sp_event_master and sp_meeting_master do not
// mention tokens at all.
//
// Recipients are therefore resolved here, per the recipient group the notice
// was addressed to.
const admin = require('firebase-admin');

const { query, getPool, sql } = require('./db');

/**
 * routes/notify.js already calls initializeApp at require time, and calling it
 * twice throws. Reuse the default app when one exists.
 */
function messaging() {
  if (!admin.apps.length) {
    const serviceAccount = require('../../routes/serviceAccountKey.json');
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }
  return admin.messaging();
}

/**
 * Recipient groups, from sp_notice_master/GetAllRecipients:
 *   1 Owners · 2 Tenants · 3 Owners and Tenants · 4 Members
 *
 * Owners and tenants are both rows in owner_master, split by `type`; members
 * are committee logins in UserLogin.
 */
const GROUPS = {
  1: { owners: ['Owner'], members: false },
  2: { owners: ['Rent'], members: false },
  3: { owners: ['Owner', 'Rent'], members: false },
  4: { owners: [], members: true },
};

/**
 * Everyone a notice addressed to `recipientsId` should reach, with their FCM
 * token. Rows without a token are dropped — there is nothing to push to.
 */
async function findRecipients(societyId, recipientsId) {
  const group = GROUPS[Number(recipientsId)] ?? GROUPS[3];
  const pool = await getPool();
  const people = [];

  if (group.owners.length) {
    const result = await pool
      .request()
      .input('society_id', sql.NVarChar(10), societyId)
      .query(`
        SELECT owner_id AS user_id, name, type, token
        FROM   owner_master
        WHERE  society_id = @society_id
          AND  active_status = 0
          AND  token IS NOT NULL
          AND  LTRIM(RTRIM(token)) <> ''`);

    people.push(
      ...result.recordset.filter((r) => group.owners.includes(String(r.type).trim())),
    );
  }

  if (group.members) {
    const result = await pool
      .request()
      .input('society_id', sql.NVarChar(10), societyId)
      .query(`
        SELECT user_id, name, 'Member' AS type, token
        FROM   UserLogin
        WHERE  society_id = @society_id
          AND  active_status = 0
          AND  token IS NOT NULL
          AND  LTRIM(RTRIM(token)) <> ''`);
    people.push(...result.recordset);
  }

  // One device may serve two records (an owner who is also a committee member).
  const byToken = new Map();
  for (const p of people) if (!byToken.has(p.token)) byToken.set(p.token, p);
  return [...byToken.values()];
}

/** Record the notification against a user so the app's list shows it. */
async function recordNotification({ societyId, userId, userType, type, id, title, body }) {
  await query('sp_notification', {
    operation: 'Update',
    notification_id: { type: sql.Int, value: Number(id) || 0 },
    notification_type: { type: sql.NVarChar(50), value: type },
    user_id: { type: sql.Int, value: Number(userId) || 0 },
    user_type: { type: sql.NVarChar(50), value: userType ?? '' },
    seen_status: { type: sql.Int, value: 0 },
    society_id: { type: sql.NVarChar(10), value: societyId },
    title: { type: sql.NVarChar(200), value: title },
    body: { type: sql.NVarChar(500), value: body },
  });
}

/**
 * Notify a recipient group about a notice, event or meeting.
 *
 * Never throws: a failed push must not lose the notice that was just saved.
 * The caller gets a summary to return to the user, so a silent failure is not
 * mistaken for success.
 *
 * @returns {{sent:number, failed:number, recipients:number, error?:string}}
 */
async function notifyGroup({ societyId, recipientsId, type, id, title, body }) {
  const summary = { sent: 0, failed: 0, recipients: 0 };

  try {
    const people = await findRecipients(societyId, recipientsId);
    summary.recipients = people.length;
    if (!people.length) return summary;

    // Record first: the in-app list should hold the item even if FCM is down.
    for (const p of people) {
      try {
        await recordNotification({
          societyId,
          userId: p.user_id,
          userType: p.type,
          type,
          id,
          title,
          body,
        });
      } catch {
        // One bad row must not stop the rest.
      }
    }

    const response = await messaging().sendEachForMulticast({
      notification: { title, body },
      // The app switches on this to open the right screen.
      data: { messageType: String(type).toLowerCase() },
      tokens: people.map((p) => p.token),
    });

    summary.sent = response.successCount;
    summary.failed = response.failureCount;
  } catch (err) {
    summary.error = err.message;
  }

  return summary;
}

module.exports = { notifyGroup, findRecipients };
