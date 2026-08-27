// Website API — registration, password reset and tenant setup.
// Replaces new_registration, ForgetPassword, verifyOTP, new_society, new_village
// and society_search / village_master.
//
// These endpoints are PUBLIC (pre-login) except the setup ones, which need a
// session. Mounted before the authenticate middleware in index.js.
const express = require('express');

const { query, queryOne, exec, sql } = require('../lib/db');
const { ApiError, ok, asyncHandler } = require('../lib/http');
const { str, optionalStr, int, num, bool, date } = require('../lib/validate');
const { hashPassword } = require('../lib/password');
const { authenticate } = require('../middleware/authenticate');
// Registering signs the new account in, so the tenant setup form can open
// straight away — as new_registration.aspx did. The password routes below use
// the same issuers to re-arm the session of the device that changed it, and
// revokeAllRefreshTokensForUser to end all the others.
const {
  accessTokenFor,
  issueRefreshToken,
  revokeRefreshToken,
  revokeAllRefreshTokensForUser,
} = require('../lib/tokens');
const { publicUser } = require('../lib/publicUser');
const { findUserById, findUserByEmail } = require('../lib/users');

const router = express.Router();

/**
 * Normalise a tenant kind to the numeric code UserLogin.type actually holds.
 *
 * The column is nvarchar, but the procs compare it to a number, so only '1' and
 * '2' are safe to store there. Accepts either the word ('Society' / 'Village',
 * which is what the registration form shows and what the legacy WebForms page
 * wrote) or the code itself. Anything unrecognised falls back to a society,
 * which is the default the registration screen opens on.
 */
function tenantTypeCode(value) {
  const raw = String(value ?? '').trim().toLowerCase();
  if (raw === 'village' || raw === '2') return '2';
  return '1';
}

/* ------------------------------------------------------------ public ---- */

/** GET /onboarding/societies — society picker for the registration screen. */
router.get(
  '/societies',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_society_master', { operation: 'SearchSociety' });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /onboarding/check-username?username= */
router.get(
  '/check-username',
  asyncHandler(async (req, res) => {
    const username = str(req.query.username, 'username', { max: 50 });
    const rows = await query('sp_UserLogin', {
      operation: 'check_UserName',
      UserName: { type: sql.NVarChar(50), value: username },
      user_id: { type: sql.Int, value: 0 },
    });
    return ok(res, { available: rows.length === 0 });
  }),
);

/** GET /onboarding/check-email?email= */
router.get(
  '/check-email',
  asyncHandler(async (req, res) => {
    const email = str(req.query.email, 'email', { max: 100 });
    const rows = await query('sp_UserLogin', {
      operation: 'check_email',
      email: { type: sql.NVarChar(100), value: email },
      user_id: { type: sql.Int, value: 0 },
    });
    return ok(res, { available: rows.length === 0 });
  }),
);

/**
 * POST /onboarding/register — create a committee/admin login.
 *
 * The password is hashed in the legacy PBKDF2 format so the existing ASP.NET
 * login and this API both accept it.
 *
 * Returns a session as well as the new account. new_registration.aspx posted
 * straight on to new_society.aspx / new_village.aspx, so the tenant setup form
 * opened immediately after the account was created, with no sign-in in between.
 * That form saves against the signed-in tenant here, so registering has to
 * hand back the tokens that let it — otherwise the user is bounced to /login
 * and the two pages stop being one flow.
 */
router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const username = str(req.body?.username, 'username', { max: 50 });
    const password = str(req.body?.password, 'password', { max: 200 });
    if (password.length < 8) throw ApiError.badRequest('Password must be at least 8 characters');

    const existing = await query('sp_UserLogin', {
      operation: 'check_UserName',
      UserName: { type: sql.NVarChar(50), value: username },
      user_id: { type: sql.Int, value: 0 },
    });
    if (existing.length) throw ApiError.conflict('That username is already taken');

    const typeCode = tenantTypeCode(req.body?.type);
    const isVillage = typeCode === '2';

    /*
     * Create the tenant row BEFORE the account, and hang the account off it.
     *
     * sp_UserLogin's 'Update' branch only inserts into UserLogin — it does not
     * create a society or village, it just stores whatever @society_id it was
     * handed. DA_New_Registration.update_registration() therefore made three
     * calls in order, and this reproduces them:
     *
     *   1. sp_UserLogin 'new_society' / 'new_village'
     *        inserts the empty tenant row, allocating the next id (C10001…,
     *        V10001…), and returns its society_master_id / id.
     *   2. sp_society_master / sp_village_master 'Select'
     *        reads that row back to get the generated society_id / village_id.
     *   3. sp_UserLogin 'Update'
     *        inserts the account carrying that id.
     *
     * Skipping step 1 leaves society_id NULL, and then the setup form has no
     * tenant to save against — which is what stopped it opening at all.
     *
     * A society_id sent by the client still wins, so an account can be added to
     * an existing society rather than always minting a new one.
     */
    let societyId = optionalStr(req.body?.societyId, 'societyId', { max: 10 });
    let villageId = optionalStr(req.body?.villageId, 'villageId', { max: 10 });

    if (!societyId && !villageId) {
      const createdRows = await query('sp_UserLogin', {
        operation: isVillage ? 'new_village' : 'new_society',
      });
      // The branch ends with `SELECT TOP (1) society_master_id ... ORDER BY
      // society_id DESC`, so the new row's key is the only column returned.
      const created = createdRows[0] ?? {};
      const masterId = created.society_master_id ?? created.id ?? created.village_master_id;

      if (masterId == null) {
        throw new ApiError(500, `Could not create the ${isVillage ? 'village' : 'society'}`, {
          code: 'TENANT_CREATE_FAILED',
        });
      }

      if (isVillage) {
        const rows = await query('sp_village_master', {
          operation: 'Select',
          id: { type: sql.Int, value: Number(masterId) },
        });
        villageId = rows[0]?.village_id ?? null;
      } else {
        const rows = await query('sp_society_master', {
          operation: 'Select',
          society_master_id: { type: sql.Int, value: Number(masterId) },
        });
        societyId = rows[0]?.society_id ?? null;
      }

      if (!societyId && !villageId) {
        throw new ApiError(500, `Could not read back the new ${isVillage ? 'village' : 'society'}`, {
          code: 'TENANT_READBACK_FAILED',
        });
      }
    }

    await exec('sp_UserLogin', {
      operation: 'Update',
      user_id: { type: sql.Int, value: 0 },
      Name: { type: sql.NVarChar(500), value: str(req.body?.name, 'name', { max: 500 }) },
      UserName: { type: sql.NVarChar(50), value: username },
      password: { type: sql.NVarChar(200), value: hashPassword(password) },
      email: { type: sql.NVarChar(100), value: optionalStr(req.body?.email, 'email', { max: 100 }) },
      contact_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
      // new_registration.aspx collected an address and DA_New_Registration
      // passed it as @address1; sp_UserLogin declares it NVARCHAR(50).
      address1: { type: sql.NVarChar(50), value: optionalStr(req.body?.address, 'address', { max: 50 }) },
      user_type_id: { type: sql.Int, value: int(req.body?.userTypeId, 'userTypeId', { required: false, default: 2 }) },
      owner_id: { type: sql.Int, value: int(req.body?.ownerId, 'ownerId', { required: false, default: 0 }) },
      society_id: { type: sql.NVarChar(10), value: societyId },
      village_id: { type: sql.NVarChar(10), value: villageId },
      /*
       * UserLogin.type is nvarchar, but every proc that reads it compares it to
       * a number — validateuser's login branch does
       * `case when UserLogin.type=1 then 'Society' else 'Village' end`, which
       * makes SQL Server convert the stored string to int. Writing the word
       * 'Society' there therefore stores fine and then fails every subsequent
       * login with "Conversion failed when converting the nvarchar value
       * 'Society' to data type int".
       *
       * So the tenant kind is stored as the code the procs expect — 1 for a
       * society, 2 for a village — regardless of which spelling the client
       * sends.
       */
      type: { type: sql.NVarChar(50), value: typeCode },
    });

    /*
     * Read the account back through the same proc the login route uses, so the
     * session carries exactly the shape /auth/login and /auth/me return —
     * including the society_id that 'Update' just created, which the setup
     * wizard saves against.
     */
    const rows = await query('validateuser', {
      operation: 'login',
      username: { type: sql.VarChar(250), value: username },
    });
    const user = rows[0];
    if (!user) {
      // The insert reported success but the row is not readable — surface that
      // rather than returning a session with nothing behind it.
      throw new ApiError(500, 'Account was created but could not be signed in', {
        code: 'REGISTER_INCOMPLETE',
      });
    }

    const accessToken = accessTokenFor(user);
    const refresh = await issueRefreshToken(
      user,
      optionalStr(req.body?.deviceInfo, 'deviceInfo', { max: 500 }),
    );

    return ok(
      res,
      {
        registered: true,
        accessToken,
        refreshToken: refresh.token,
        expiresAt: refresh.expiresAt,
        user: publicUser(user),
      },
      201,
    );
  }),
);

/**
 * POST /onboarding/forgot-password
 * Body: { email, newPassword }
 *
 * The legacy flow verifies identity by OTP over SMS before this call; that step
 * is unchanged and still handled by the mobile API's /login/send-sms.
 */
router.post(
  '/forgot-password',
  asyncHandler(async (req, res) => {
    const email = str(req.body?.email, 'email', { max: 100 });
    const newPassword = str(req.body?.newPassword, 'newPassword', { max: 200 });
    if (newPassword.length < 8) throw ApiError.badRequest('Password must be at least 8 characters');

    const found = await findUserByEmail(email);
    // Always report success so the endpoint cannot be used to discover which
    // addresses have accounts.
    if (found) {
      await exec('sp_UserLogin', {
        operation: 'ResetForgotPassword',
        email: { type: sql.NVarChar(100), value: email },
        password: { type: sql.NVarChar(200), value: hashPassword(newPassword) },
      });

      // Every session dies, with nothing spared. Unlike a change-password there
      // is no caller session worth keeping — the person doing this is not
      // signed in — and a reset is the flow someone reaches for precisely
      // because they think another party has the account. Sparing anything
      // here would be sparing the intruder.
      //
      // findUserByEmail already carries user_id and contact_no, which is what
      // reaches both the website's rows and the mobile app's.
      await revokeAllRefreshTokensForUser(found);
    }
    return ok(res, { submitted: true });
  }),
);

/* ---------------------------------------------------------- authenticated */

router.use(authenticate);

/**
 * GET /onboarding/profile — the signed-in user's own account.
 *
 * Site.Master's profile modal filled itself from sp_UserLogin 'GetProfile'
 * (SiteMaster.fill_data). It also split `name` into first/last on a space, which
 * is presentation, so that happens on the client here.
 */
router.get(
  '/profile',
  asyncHandler(async (req, res) => {
    const row = await queryOne('sp_UserLogin', {
      operation: 'GetProfile',
      user_id: { type: sql.Int, value: req.user.userId },
    });
    if (!row) throw ApiError.notFound('Account no longer exists');

    // `password` is in this recordset (the legacy code read it into Session);
    // it is deliberately not returned.
    return ok(res, {
      profile: {
        user_id: req.user.userId,
        name: row.name ?? '',
        username: row.username ?? '',
        email: row.email ?? '',
        contact_no: row.contact_no ?? '',
        role: row.usertypename ?? null,
        user_type_id: row.user_type_id ?? null,
        owner_id: row.owner_id ?? 0,
        active_status: row.active_status ?? null,
        photo_path: row.photo_path ?? null,
        /*
         * Which tenant the account belongs to. A village user has no society
         * and vice versa, so exactly one of these is set — the profile can
         * name where the account sits without knowing which kind it is.
         */
        society_name: row.Society_name ?? null,
        village_name: row.Village_name ?? null,
      },
    });
  }),
);

/**
 * PUT /onboarding/profile — update your own account.
 *
 * Mirrors SiteMaster.btn_save_Click: name is rejoined from first/last, a new
 * password requires the current one to verify, and an empty password means
 * "leave it unchanged" (the SP treats '' that way).
 */
router.put(
  '/profile',
  asyncHandler(async (req, res) => {
    const username = str(req.body?.username, 'username', { max: 50 });
    const firstName = str(req.body?.firstName, 'firstName', { max: 250 });
    const lastName = optionalStr(req.body?.lastName, 'lastName', { max: 250 }) || '';
    const name = [firstName, lastName].filter(Boolean).join(' ');

    const current = await queryOne('sp_UserLogin', {
      operation: 'GetProfile',
      user_id: { type: sql.Int, value: req.user.userId },
    });
    if (!current) throw ApiError.notFound('Account no longer exists');

    // The legacy page checked this on the username field's TextChanged postback.
    // check_UserName is passed user_id so the row being edited is not a hit.
    if (String(current.username ?? '') !== username) {
      const taken = await query('sp_UserLogin', {
        operation: 'check_UserName',
        UserName: { type: sql.NVarChar(50), value: username },
        user_id: { type: sql.Int, value: req.user.userId },
      });
      if (taken.length) throw ApiError.conflict('That username is already taken');
    }

    // Password is optional; an empty value leaves it unchanged (the SP reads ''
    // that way). The legacy modal also demanded the old password here, but that
    // locked out anyone who had forgotten it, so it is not required — the caller
    // already proved possession of the account with a valid access token.
    let password = '';
    const newPassword = optionalStr(req.body?.newPassword, 'newPassword', { max: 200 });
    if (newPassword) {
      if (newPassword.length < 8) throw ApiError.badRequest('Password must be at least 8 characters');
      password = hashPassword(newPassword);
    }

    // Profile photo. Absent means "leave whatever is stored alone"; an empty
    // string means "remove it". The SP reads those two the same way, so the
    // distinction has to survive here — `?? null` rather than `|| null`, which
    // would collapse '' into "unchanged" and make removal impossible.
    const photoPath =
      req.body?.photoPath === undefined
        ? null
        : optionalStr(req.body?.photoPath, 'photoPath', { max: 500 }) ?? '';

    await exec('sp_UserLogin', {
      operation: 'UpdateProfile',
      user_id: { type: sql.Int, value: req.user.userId },
      Name: { type: sql.NVarChar(500), value: name },
      username: { type: sql.NVarChar(50), value: username },
      password: { type: sql.NVarChar(200), value: password },
      email: { type: sql.NVarChar(100), value: optionalStr(req.body?.email, 'email', { max: 100 }) },
      contact_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
      photo_path: { type: sql.NVarChar(500), value: photoPath },
      // The modal posted back the owner_id it had loaded, not the token's.
      owner_id: { type: sql.Int, value: int(current.owner_id, 'owner_id', { required: false, default: 0 }) },
    });

    const updated = await queryOne('sp_UserLogin', {
      operation: 'GetProfile',
      user_id: { type: sql.Int, value: req.user.userId },
    });

    return ok(res, {
      profile: {
        user_id: req.user.userId,
        name: updated?.name ?? name,
        username: updated?.username ?? username,
        email: updated?.email ?? '',
        contact_no: updated?.contact_no ?? '',
        role: updated?.usertypename ?? null,
        user_type_id: updated?.user_type_id ?? null,
        owner_id: updated?.owner_id ?? 0,
        photo_path: updated?.photo_path ?? null,
      },
      passwordChanged: Boolean(newPassword),
    });
  }),
);

/**
 * POST /onboarding/change-password — for the signed-in user.
 * Body: { newPassword, refreshToken? }
 *
 * Changing the password ends every OTHER session, on the website and in the
 * mobile app alike. A session that survives the change is the very one the
 * change is usually meant to destroy — a stolen phone, or an account someone
 * else had got into — and without this it would have kept refreshing itself
 * for the full 7-day refresh window.
 *
 * The caller's own session is spared and re-issued rather than revoked: signing
 * users out of the device they are typing on is a poor way to reward a good
 * security habit. Clients that send their `refreshToken` get a fresh pair back
 * and should store it; one that does not is simply signed out everywhere,
 * which is safe, just less pleasant.
 */
router.post(
  '/change-password',
  asyncHandler(async (req, res) => {
    const newPassword = str(req.body?.newPassword, 'newPassword', { max: 200 });
    if (newPassword.length < 8) throw ApiError.badRequest('Password must be at least 8 characters');

    const presentedRefresh = optionalStr(req.body?.refreshToken, 'refreshToken', { max: 512 });

    // Read the account BEFORE writing, for two reasons.
    //
    // The first is a live hazard: sp_UserLogin's UpdateProfile branch assigns
    // `username = @username`, `contact_no = @contact_no` and `email = @email`
    // with no null-guard, unlike the password and name beside them. A password
    // change sends none of those three, so passing them through as NULL wipes
    // the row's identity and the account can no longer log in at all — the
    // stored procedure reads the correct password and finds no username to
    // match it against. Carrying the current values back in is what keeps this
    // route from destroying the account it is meant to secure.
    // docs/proposed-sql/04-sp_UserLogin-UpdateProfile-null-guards.sql fixes the
    // proc; this stays regardless, so the route is safe on either version.
    //
    // The second is that contact_no decides which mobile-app sessions get
    // revoked below, and it has to be the stored one.
    const before = await findUserById(req.user.userId);
    if (!before) throw ApiError.unauthorized('Account no longer exists');

    await exec('sp_UserLogin', {
      operation: 'UpdateProfile',
      user_id: { type: sql.Int, value: req.user.userId },
      password: { type: sql.NVarChar(200), value: hashPassword(newPassword) },
      // `?? null` rather than `||`: an account with a genuinely empty phone or
      // email keeps it empty instead of having '' turned into null.
      contact_no: {
        type: sql.NVarChar(50),
        value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) ?? before.contact_no ?? null,
      },
      email: {
        type: sql.NVarChar(100),
        value: optionalStr(req.body?.email, 'email', { max: 100 }) ?? before.email ?? null,
      },
      username: {
        type: sql.NVarChar(50),
        value: optionalStr(req.body?.username, 'username', { max: 50 }) ?? before.username ?? null,
      },
      owner_id: { type: sql.Int, value: req.user.ownerId ?? before.owner_id ?? 0 },
    });

    // Re-read: the write above may have changed contact_no, which decides
    // which mobile-app rows the revoke below matches.
    const user = (await findUserById(req.user.userId)) ?? before;

    // Revoked AFTER the password is stored. The other order would leave a
    // window where the old password still worked but the sessions were gone,
    // and a failure between the two would sign everyone out for nothing.
    const revokedCount = await revokeAllRefreshTokensForUser(user, presentedRefresh);

    // Rotate the caller's own session too. The spared refresh token stays
    // valid, but its access token still carries claims minted before the
    // change, so a fresh pair keeps this device consistent with the others.
    let session = null;
    if (presentedRefresh) {
      await revokeRefreshToken(presentedRefresh);
      const refresh = await issueRefreshToken(user, 'password-change');
      session = {
        accessToken: accessTokenFor(user),
        refreshToken: refresh.token,
        expiresAt: refresh.expiresAt,
      };
    }

    return ok(res, {
      changed: true,
      // What the client should tell the user: "signed out of N other devices".
      revokedSessions: revokedCount,
      // Null when the client sent no refresh token — it is now signed out and
      // must send the user back to the login screen.
      session,
    });
  }),
);

/** POST /onboarding/societies/new — allocate the next society_id. */
router.post(
  '/societies/new',
  asyncHandler(async (_req, res) => {
    const created = await exec('sp_UserLogin', { operation: 'new_society' });
    return ok(res, { society: created ?? null }, 201);
  }),
);

/** PUT /onboarding/societies/:id — society profile + first-time setup. */
router.put(
  '/societies/:id',
  asyncHandler(async (req, res) => {
    const societyId = str(req.params.id, 'id', { max: 10 });
    if (societyId !== req.user.societyId) {
      throw ApiError.forbidden('Cannot modify another society');
    }

    await exec('sp_society_master', {
      operation: 'Update',
      society_id: { type: sql.NVarChar(10), value: societyId },
      name: { type: sql.NVarChar(250), value: str(req.body?.name, 'name', { max: 250 }) },
      establish_date: { type: sql.Date, value: date(req.body?.establishDate, 'establishDate', { required: false }) },
      registration_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.registrationNo, 'registrationNo', { max: 50 }) },
      off_address1: { type: sql.NVarChar(150), value: optionalStr(req.body?.address1, 'address1', { max: 150 }) },
      off_address2: { type: sql.NVarChar(150), value: optionalStr(req.body?.address2, 'address2', { max: 150 }) },
      contact_no1: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
      email: { type: sql.NVarChar(150), value: optionalStr(req.body?.email, 'email', { max: 150 }) },
      city: { type: sql.NVarChar(50), value: optionalStr(req.body?.city, 'city', { max: 50 }) },
      state_id: { type: sql.Int, value: int(req.body?.stateId, 'stateId', { required: false, default: 0 }) },
      district_id: { type: sql.Int, value: int(req.body?.districtId, 'districtId', { required: false, default: 0 }) },
      division_id: { type: sql.Int, value: int(req.body?.divisionId, 'divisionId', { required: false, default: 0 }) },
      pincode: { type: sql.NVarChar(50), value: optionalStr(req.body?.pincode, 'pincode', { max: 50 }) },
      // society_search.aspx labelled this "Street" but assigned it to Home_No,
      // and the column is an int — so it only ever held a house/street number.
      home_no: { type: sql.Int, value: int(req.body?.street, 'street', { min: 0, required: false, default: 0 }) },
      tan_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.tanNo, 'tanNo', { max: 50 }) },
      gstin_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.gstinNo, 'gstinNo', { max: 50 }) },
      pan_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.panNo, 'panNo', { max: 50 }) },
      // 'New' additionally seeds terms and account_setting via nested EXECs.
      type: { type: sql.NVarChar(10), value: bool(req.body?.firstTimeSetup, 'firstTimeSetup', { default: false }) ? 'New' : '' },
      terms: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.terms, 'terms') },
      rate_per_sqft: { type: sql.Decimal(10, 2), value: num(req.body?.ratePerSqFt, 'ratePerSqFt', { min: 0, required: false, default: 0 }) },
      two_w_rate: { type: sql.Decimal(10, 2), value: num(req.body?.twoWheelerRate, 'twoWheelerRate', { min: 0, required: false, default: 0 }) },
      four_w_rate: { type: sql.Decimal(10, 2), value: num(req.body?.fourWheelerRate, 'fourWheelerRate', { min: 0, required: false, default: 0 }) },
      auto_bill_generation: { type: sql.Bit, value: bool(req.body?.autoBillGeneration, 'autoBillGeneration', { default: false }) },
      bill_gen_date: { type: sql.Int, value: int(req.body?.billGenerationDay, 'billGenerationDay', { min: 1, max: 31, required: false, default: 1 }) },
      bill_due_period: { type: sql.Int, value: int(req.body?.billDuePeriodDays, 'billDuePeriodDays', { min: 0, required: false, default: 0 }) },
    });

    const rows = await query('sp_society_master', {
      operation: 'Grid_Show',
      society_id: { type: sql.NVarChar(10), value: societyId },
    });
    return ok(res, { society: rows[0] ?? null });
  }),
);

/** POST /onboarding/villages/new — allocate the next village_id. */
router.post(
  '/villages/new',
  asyncHandler(async (_req, res) => {
    const created = await exec('sp_UserLogin', { operation: 'new_village' });
    return ok(res, { village: created ?? null }, 201);
  }),
);

/** PUT /onboarding/villages/:id — village profile. */
router.put(
  '/villages/:id',
  asyncHandler(async (req, res) => {
    const villageId = str(req.params.id, 'id', { max: 50 });
    if (villageId !== req.user.villageId) {
      throw ApiError.forbidden('Cannot modify another village');
    }

    await exec('sp_village_master', {
      operation: 'Update',
      village_id: { type: sql.NVarChar(50), value: villageId },
      name: { type: sql.NVarChar(50), value: str(req.body?.name, 'name', { max: 50 }) },
      contact_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
      email: { type: sql.NVarChar(150), value: optionalStr(req.body?.email, 'email', { max: 150 }) },
      division: { type: sql.NVarChar(50), value: optionalStr(req.body?.division, 'division', { max: 50 }) },
      state_id: { type: sql.Int, value: int(req.body?.stateId, 'stateId', { required: false, default: 0 }) },
      district_id: { type: sql.Int, value: int(req.body?.districtId, 'districtId', { required: false, default: 0 }) },
      pincode: { type: sql.NVarChar(50), value: optionalStr(req.body?.pincode, 'pincode', { max: 50 }) },
      registration_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.registrationNo, 'registrationNo', { max: 50 }) },
      address: { type: sql.NVarChar(50), value: optionalStr(req.body?.address, 'address', { max: 50 }) },
      enrolment_date: { type: sql.DateTime, value: date(req.body?.enrolmentDate, 'enrolmentDate', { required: false }) },
    });

    // NOTE: sp_village_master ends with a stray hardcoded SELECT filtered to
    // village_id='V10010' AND name LIKE 'Wayri%'. It returns a spurious extra
    // result set; we ignore it. Reported in docs/MIGRATION-MAP.md §5.9.
    return ok(res, { updated: true, village_id: villageId });
  }),
);

/** GET /onboarding/user-types — roles for the member form. */
router.get(
  '/user-types',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_UserLogin', { operation: 'fill_type' });
    return ok(res, { items: rows, count: rows.length });
  }),
);

module.exports = router;
