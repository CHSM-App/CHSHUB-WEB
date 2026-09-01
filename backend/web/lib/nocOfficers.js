/**
 * Who decides a NOC request in a society, and putting them on one.
 *
 * Shared because both halves of the product raise requests: the member's app
 * posts to /insert/community/noc-request, the website to /api/web/community.
 * Both have to reach the same people, and a second copy of this rule would
 * drift the moment one of them changed.
 */
const { getPool, sql } = require('./db');

/**
 * The society's office-holders — admin, secretary and chairman.
 *
 * Whichever of the three exist all get the request. The offices are worked out
 * from the accounts the society actually has rather than picked per request:
 * they are the same people every time, and choosing from a list of every
 * committee account meant working out who the chairman was on each one.
 *
 * UserType, from the database: 1 admin, 2 Secretary, 3 Chairman, 4 Member,
 * 6 Treasurer. Members and the treasurer hold no office that decides a
 * certificate, so they are left out.
 */
async function nocOfficers(societyId) {
  const pool = await getPool();
  const result = await pool
    .request()
    .input('society_id', sql.NVarChar(10), societyId)
    .query(`
      SELECT u.user_id, u.name, u.user_type_id, t.UserTypeName AS role
      FROM   UserLogin u
      LEFT   JOIN UserType t ON t.UserTypeId = u.user_type_id
      WHERE  u.society_id = @society_id
        AND  u.active_status = 0
        AND  u.user_type_id IN (1, 2, 3)
      ORDER BY u.user_type_id`);

  return result.recordset;
}

/**
 * Put every one of those offices on a request.
 *
 * Called when the request is raised, so the committee opens it to an Approve
 * button rather than to a "send for approval" step they would have to click
 * first. Re-running is safe: sp_noc_request's Add_Approver ignores anyone
 * already on the request rather than resetting a decision they have given.
 *
 * Returns the officers it added, for the caller that wants to notify them.
 */
async function addNocOfficers(societyId, requestId) {
  const pool = await getPool();
  const officers = await nocOfficers(societyId);

  for (const officer of officers) {
    await pool
      .request()
      .input('operation', sql.NVarChar(20), 'Add_Approver')
      .input('request_id', sql.Int, requestId)
      .input('user_id', sql.Int, officer.user_id)
      .execute('sp_noc_request');
  }

  return officers;
}

module.exports = { nocOfficers, addNocOfficers };
