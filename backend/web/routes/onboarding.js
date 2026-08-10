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

const router = express.Router();

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

    await exec('sp_UserLogin', {
      operation: 'Update',
      user_id: { type: sql.Int, value: 0 },
      Name: { type: sql.NVarChar(500), value: str(req.body?.name, 'name', { max: 500 }) },
      UserName: { type: sql.NVarChar(50), value: username },
      password: { type: sql.NVarChar(200), value: hashPassword(password) },
      email: { type: sql.NVarChar(100), value: optionalStr(req.body?.email, 'email', { max: 100 }) },
      contact_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
      user_type_id: { type: sql.Int, value: int(req.body?.userTypeId, 'userTypeId', { required: false, default: 2 }) },
      owner_id: { type: sql.Int, value: int(req.body?.ownerId, 'ownerId', { required: false, default: 0 }) },
      society_id: { type: sql.NVarChar(10), value: optionalStr(req.body?.societyId, 'societyId', { max: 10 }) },
      village_id: { type: sql.NVarChar(10), value: optionalStr(req.body?.villageId, 'villageId', { max: 10 }) },
      type: { type: sql.NVarChar(50), value: optionalStr(req.body?.type, 'type', { max: 50 }) || '1' },
    });

    return ok(res, { registered: true }, 201);
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

    const found = await query('sp_UserLogin', {
      operation: 'check_email',
      email: { type: sql.NVarChar(100), value: email },
      user_id: { type: sql.Int, value: 0 },
    });
    // Always report success so the endpoint cannot be used to discover which
    // addresses have accounts.
    if (found.length) {
      await exec('sp_UserLogin', {
        operation: 'ResetForgotPassword',
        email: { type: sql.NVarChar(100), value: email },
        password: { type: sql.NVarChar(200), value: hashPassword(newPassword) },
      });
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

    await exec('sp_UserLogin', {
      operation: 'UpdateProfile',
      user_id: { type: sql.Int, value: req.user.userId },
      Name: { type: sql.NVarChar(500), value: name },
      username: { type: sql.NVarChar(50), value: username },
      password: { type: sql.NVarChar(200), value: password },
      email: { type: sql.NVarChar(100), value: optionalStr(req.body?.email, 'email', { max: 100 }) },
      contact_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
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
      },
      passwordChanged: Boolean(newPassword),
    });
  }),
);

/** POST /onboarding/change-password — for the signed-in user. */
router.post(
  '/change-password',
  asyncHandler(async (req, res) => {
    const newPassword = str(req.body?.newPassword, 'newPassword', { max: 200 });
    if (newPassword.length < 8) throw ApiError.badRequest('Password must be at least 8 characters');

    await exec('sp_UserLogin', {
      operation: 'UpdateProfile',
      user_id: { type: sql.Int, value: req.user.userId },
      password: { type: sql.NVarChar(200), value: hashPassword(newPassword) },
      contact_no: { type: sql.NVarChar(50), value: optionalStr(req.body?.contactNo, 'contactNo', { max: 50 }) },
      email: { type: sql.NVarChar(100), value: optionalStr(req.body?.email, 'email', { max: 100 }) },
      username: { type: sql.NVarChar(50), value: optionalStr(req.body?.username, 'username', { max: 50 }) },
      owner_id: { type: sql.Int, value: req.user.ownerId ?? 0 },
    });
    return ok(res, { changed: true });
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
