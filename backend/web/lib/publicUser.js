/**
 * The signed-in user, as clients are allowed to see it.
 *
 * Shared by /auth/login, /auth/me and /onboarding/register — registering signs
 * the new account straight in, so all three have to hand back the same shape or
 * the client's stored session changes meaning depending on how it was created.
 *
 * The rows these read carry the password hash; picking fields explicitly is
 * what keeps it from being echoed back.
 */
function publicUser(row) {
  return {
    user_id: row.user_id,
    name: row.name,
    username: row.username,
    user_type_id: row.user_type_id,
    user_type: row.UserTypeName ?? null,
    society_id: row.society_id ?? null,
    society_name: row.Society_name ?? null,
    village_id: row.village_id ?? null,
    village_name: row.village_name ?? null,
    tenant_type: row.type ?? null, // 'Society' | 'Village'
    owner_id: row.owner_id ?? null,
    email: row.email ?? null,
    contact_no: row.contact_no ?? null,
  };
}

module.exports = { publicUser };
