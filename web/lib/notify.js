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
 * routes/firebase.js owns initialisation and is idempotent, so it does not
 * matter whether routes/notify.js got there first.
 */
function messaging() {
  return require('../../routes/firebase').messaging();
}

/**
 * Recipient groups, from sp_notice_master/GetAllRecipients:
 *   1 Owners · 2 Tenants · 3 Owners and Tenants · 4 Members
 *
 * Owners and tenants are both rows in owner_master, split by `type`; members
 * are committee logins in UserLogin.
 *
 * Group 5 is not in that list but sp_owner_master/get_users defines it as
 * everyone — a UNION of the owner/tenant select and the UserLogin one. Polls
 * addressed to "All Members" use it (Vote.aspx.cs:84), and without it here they
 * would fall through to the default and miss every committee member.
 */
const GROUPS = {
  1: { owners: ['Owner'], members: false },
  2: { owners: ['Rent'], members: false },
  3: { owners: ['Owner', 'Rent'], members: false },
  4: { owners: [], members: true },
  5: { owners: ['Owner', 'Rent'], members: true },
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
        SELECT owner_id AS user_id, name, type, token, 'owner' AS source
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
        SELECT user_id, name, 'Member' AS type, token, 'login' AS source
        FROM   UserLogin
        WHERE  society_id = @society_id
          AND  active_status = 0
          AND  token IS NOT NULL
          AND  LTRIM(RTRIM(token)) <> ''`);
    people.push(...result.recordset);
  }

  // One person may hold two records (an owner who is also a committee
  // member). Keyed by person rather than by token: those who have never
  // opened the app share a null token, and keying on that would fold them
  // all into one and lose the rest.
  const byPerson = new Map();
  for (const p of people) {
    const key = `${p.source ?? 'owner'}:${p.user_id}`;
    if (!byPerson.has(key)) byPerson.set(key, p);
  }
  return [...byPerson.values()];
}

/**
 * The residents of one flat — owner, tenant and family alike.
 *
 * findRecipients works in whole-society groups, which is right for a notice.
 * A helpdesk ticket is about one flat, so its people are looked up directly.
 */
async function findFlatResidents(societyId, flatId) {
  const pool = await getPool();
  const result = await pool
    .request()
    .input('society_id', sql.NVarChar(10), societyId)
    .input('flat_id', sql.Int, flatId)
    .query(`
      SELECT owner_id AS user_id, name, type, token, 'owner' AS source
      FROM   owner_master
      WHERE  society_id = @society_id
        AND  flat_id = @flat_id
        AND  active_status = 0`);

  return result.recordset;
}

/**
 * The committee: admin, chairman, secretary, treasurer and members.
 *
 * This is GROUPS[4] — `members: true` — pulled out on its own so a caller can
 * combine it with one flat's residents without notifying the whole society.
 */
async function findCommittee(societyId) {
  const pool = await getPool();
  const result = await pool
    .request()
    .input('society_id', sql.NVarChar(10), societyId)
    .query(`
      SELECT user_id, name, 'Member' AS type, token, 'login' AS source
      FROM   UserLogin
      WHERE  society_id = @society_id
        AND  active_status = 0`);

  return result.recordset;
}

/**
 * The gate staff, who carry the Security app.
 *
 * Their accounts are Staff_Master rows, not UserLogin ones — a separate table
 * that numbers its rows independently, hence `source: 'staff'` so a staff id
 * is never confused with a committee member's.
 *
 * Every active member of the society's staff is included rather than only a
 * "gatekeeper" role: `staff_role` is seeded per deployment as free text, so
 * there is no role id that reliably means the gate. sp_staff_master's grid
 * excludes `role_id != 1`, which suggests 1 is the gate, but nothing else in
 * the schema confirms it — and notifying a caretaker about a visitor is a far
 * smaller fault than a gate that never hears.
 *
 * `user_type` is 'Staff' so sp_notification files it where the Security app's
 * own list looks, as owners and members are filed under theirs.
 */
async function findGateStaff(societyId) {
  const pool = await getPool();
  const result = await pool
    .request()
    .input('society_id', sql.NVarChar(10), societyId)
    .query(`
      SELECT staff_id AS user_id, name, 'Staff' AS type, token, 'staff' AS source
      FROM   Staff_Master
      WHERE  society_id = @society_id
        AND  ISNULL(active_status, 0) = 0`);

  return result.recordset;
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
  try {
    const people = await findRecipients(societyId, recipientsId);
    return await notifyPeople({ societyId, people, type, id, title, body });
  } catch (err) {
    return { sent: 0, failed: 0, recipients: 0, error: err.message };
  }
}

/**
 * Notify a chosen set of people. The sending half of notifyGroup, without the
 * group lookup — for callers that build their own audience.
 */
async function notifyPeople({ societyId, people, type, id, title, body, messageType }) {
  const summary = { sent: 0, failed: 0, recipients: 0 };

  try {
    /*
     * Deduped by person, not by token: someone who has never opened the app
     * has no token, and keying on one would collapse all of them into a
     * single entry and drop the rest.
     *
     * That matters because the in-app list is written for everyone. A
     * resident without a phone token still sees the notification when they
     * next sign in; only the push needs a token.
     */
    const byPerson = new Map();
    for (const p of people) {
      const key = `${p.source ?? 'owner'}:${p.user_id}`;
      if (!byPerson.has(key)) byPerson.set(key, p);
    }

    const unique = [...byPerson.values()];
    summary.recipients = unique.length;
    if (!unique.length) return summary;

    for (const p of unique) {
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

    // One device may serve two records (an owner who is also on the
    // committee); a duplicate push reads as a bug to whoever gets it.
    const tokens = [
      ...new Set(unique.map((p) => p.token).filter((t) => t && String(t).trim())),
    ];

    summary.pushable = tokens.length;
    if (!tokens.length) return summary;

    const response = await messaging().sendEachForMulticast({
      notification: { title, body },
      // The apps switch on this. It defaults to the notification type, which
      // is what notices and events want, but a caller may name it explicitly
      // where the app's handler expects a different word — a visitor arrives
      // as `visitor_entry`, not `visitor`.
      data: { messageType: messageType ?? String(type).toLowerCase() },
      tokens,
    });

    summary.sent = response.successCount;
    summary.failed = response.failureCount;
  } catch (err) {
    summary.error = err.message;
  }

  return summary;
}

/**
 * Who a helpdesk ticket should reach.
 *
 * A complaint is not an announcement, so it does not go to the whole society
 * by default — the audience follows who raised it and how far the problem
 * reaches:
 *
 *   personal   the flat it is about, and the committee who must act on it
 *   community  the same, plus every resident, since a lift or a parking
 *              dispute is everyone's problem
 *
 * Whoever raised it is dropped: they already know, and a push telling you
 * what you just did is noise. `raisedBy` names both the id and the table it
 * came from — owner_master for a resident, UserLogin for the committee — since
 * the two number their rows separately and an id alone would silence the wrong
 * person.
 */
async function notifyHelpdesk({
  societyId,
  flatId,
  categoryType,
  raisedBy,
  type,
  id,
  title,
  body,
}) {
  const isCommunity = String(categoryType).toLowerCase() === 'community';

  const [residents, committee, everyone] = await Promise.all([
    // A community complaint filed by the committee has no flat behind it, and
    // group 3 below reaches those residents anyway.
    flatId ? findFlatResidents(societyId, flatId) : Promise.resolve([]),
    findCommittee(societyId),
    // Owners and tenants across the society. The committee is fetched
    // separately above, so group 3 rather than 5.
    isCommunity ? findRecipients(societyId, 3) : Promise.resolve([]),
  ]);

  const people = [...residents, ...committee, ...everyone].filter((p) => {
    if (!raisedBy) return true;
    const sameTable = (p.source ?? 'owner') === (raisedBy.source ?? 'owner');
    return !(sameTable && Number(p.user_id) === Number(raisedBy.userId));
  });

  return notifyPeople({ societyId, people, type, id, title, body });
}

/**
 * Who a visitor registration should reach.
 *
 * Two audiences, for two different reasons:
 *
 *   the flat   someone is here for them, and they may want to refuse entry —
 *              the resident app treats `visitor_entry` as an approval prompt
 *   the gate   whoever is on the gate has to let the visitor through, and a
 *              visitor registered from the website or the secretary's phone
 *              never passed in front of them
 *
 * A visitor with no flat against them — a contractor for the society itself —
 * still reaches the gate; `findFlatResidents` is simply skipped.
 *
 * `messageType` on the push is `visitor_entry`, which is what routes/notify.js
 * already sends and what the resident app's handler switches on. Sending
 * anything else would file it correctly and then be ignored by the app.
 *
 * Whoever registered the visitor is dropped: a secretary who just filled the
 * form does not need telling. Never throws — the visitor is already saved.
 */
async function notifyVisitor({
  societyId,
  flatId,
  registeredBy,
  type = 'Visitor',
  id,
  title,
  body,
}) {
  try {
    const [residents, staff] = await Promise.all([
      flatId ? findFlatResidents(societyId, flatId) : Promise.resolve([]),
      findGateStaff(societyId),
    ]);

    const people = [...residents, ...staff].filter((p) => {
      if (!registeredBy) return true;
      const sameTable = (p.source ?? 'owner') === (registeredBy.source ?? 'owner');
      return !(sameTable && Number(p.user_id) === Number(registeredBy.userId));
    });

    return await notifyPeople({
      societyId,
      people,
      type,
      id,
      title,
      body,
      messageType: 'visitor_entry',
    });
  } catch (err) {
    return { sent: 0, failed: 0, recipients: 0, error: err.message };
  }
}

module.exports = {
  notifyGroup,
  notifyPeople,
  notifyHelpdesk,
  notifyVisitor,
  findRecipients,
  findFlatResidents,
  findCommittee,
  findGateStaff,
};
