// Website API — router root, mounted at /api/web.
//
// Kept entirely separate from routes/ (the mobile app API): its own auth,
// its own response envelope, its own error handling. Nothing here changes
// behaviour of the existing mobile endpoints.
const express = require('express');

const { errorHandler, notFoundHandler, ok } = require('./lib/http');
const { authenticate } = require('./middleware/authenticate');
const { requireUserType, GROUPS } = require('./middleware/authorize');
const { pool } = require('./lib/db');

const authRoutes = require('./routes/auth');
const buildingRoutes = require('./routes/masters/buildings');
const wingRoutes = require('./routes/masters/wings');
const flatRoutes = require('./routes/masters/flats');
const ownerRoutes = require('./routes/masters/owners');
const familyRoutes = require('./routes/masters/family');
const accountSettingRoutes = require('./routes/settings/accountSettings');
const chargeRoutes = require('./routes/settings/charges');
const termsRoutes = require('./routes/settings/terms');
const societyChargeRoutes = require('./routes/settings/societyCharges');
const billRoutes = require('./routes/billing/bills');
const receiptRoutes = require('./routes/billing/receipts');
const generationRoutes = require('./routes/billing/generation');
const miscMasterRoutes = require('./routes/masters/misc');
const accountRoutes = require('./routes/accounts');
const vendorRoutes = require('./routes/accounts/vendors');
const vendorBillRoutes = require('./routes/accounts/vendorBills');
const ownerExtraRoutes = require('./routes/masters/ownerExtras');
const uploadRoutes = require('./routes/uploads');
const cronRoutes = require('./routes/cron');
const communityRoutes = require('./routes/community');
const reportRoutes = require('./routes/reports');
const villageRoutes = require('./routes/village');
const onboardingRoutes = require('./routes/onboarding');
const pdcRoutes = require('./routes/billing/pdc');

const router = express.Router();

router.use(express.json());
router.use(express.urlencoded({ extended: true }));

/*
 * Unauthenticated health probe for an uptime monitor. Reports app liveness and
 * database connectivity. Returns 503 when the DB is unreachable so a monitor can
 * alert. Exposes no connection string, credentials, or internal detail.
 */
router.get('/health', async (_req, res) => {
  let dbUp = false;
  try {
    if (pool.connected) {
      await pool.request().query('SELECT 1 AS ok');
      dbUp = true;
    }
  } catch (_e) {
    dbUp = false;
  }
  const body = { status: dbUp ? 'up' : 'degraded', api: 'web', db: dbUp ? 'up' : 'down', time: new Date().toISOString() };
  if (dbUp) return ok(res, body);
  return res.status(503).json({ ok: false, error: 'database unavailable', data: body });
});

// Public. onboarding applies `authenticate` internally to its setup routes.
router.use('/auth', authRoutes);
router.use('/onboarding', onboardingRoutes);

/*
 * Scheduled work, for a Plesk task or any external scheduler. Not behind
 * `authenticate` — a scheduler has no user to sign in as — but behind its own
 * shared-secret check, which refuses everything unless CRON_TOKEN is set.
 */
router.use('/cron', cronRoutes);

// Protected areas. authenticate is applied per mount rather than globally so an
// unknown path still falls through to notFoundHandler and reports 404 instead of
// a misleading 401.
// Master data (config) — Chairman/Secretary only. See middleware/authorize.js;
// role checks stay permissive until ROLE_*_IDS are configured from dbo.UserType.
router.use('/masters/buildings', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), buildingRoutes);
router.use('/masters/wings', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), wingRoutes);
router.use('/masters/flats', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), flatRoutes);
router.use('/masters/owners', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), ownerRoutes);
router.use('/masters/family', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), familyRoutes);
router.use('/masters/owner-extras', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), ownerExtraRoutes);
router.use('/uploads', authenticate, uploadRoutes);

// Society configuration — Chairman/Secretary only.
router.use('/settings/account', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), accountSettingRoutes);
router.use('/settings/charges', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), chargeRoutes);
router.use('/settings/terms', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), termsRoutes);
router.use('/settings/society-charges', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), societyChargeRoutes);

// Billing & receipts — Treasurer and above. Mount generation before /bills.
router.use('/billing/generate', authenticate, requireUserType(GROUPS.FINANCE), generationRoutes);
router.use('/billing/pdc', authenticate, requireUserType(GROUPS.FINANCE), pdcRoutes);
router.use('/billing/receipts', authenticate, requireUserType(GROUPS.FINANCE), receiptRoutes);
router.use('/billing/bills', authenticate, requireUserType(GROUPS.FINANCE), billRoutes);

// Remaining master screens (staff, caretakers, contacts, inventory, parking,
// car pooling, loans, society profile, committee members) — Chairman/Secretary.
router.use('/masters', authenticate, requireUserType(GROUPS.SOCIETY_ADMIN), miscMasterRoutes);

// Accounts & vendor-bill approval, financial reports — Treasurer and above.
router.use('/accounts/vendor-bills', authenticate, requireUserType(GROUPS.FINANCE), vendorBillRoutes);
router.use('/accounts/vendors', authenticate, requireUserType(GROUPS.FINANCE), vendorRoutes);
router.use('/accounts', authenticate, requireUserType(GROUPS.FINANCE), accountRoutes);
router.use('/reports', authenticate, requireUserType(GROUPS.FINANCE), reportRoutes);

// Community is open to any authenticated committee member (incl. Member).
router.use('/community', authenticate, communityRoutes);
router.use('/village', authenticate, villageRoutes);

// Terminal handlers, scoped to this router so the mobile API is unaffected.
router.use(notFoundHandler);
router.use(errorHandler);

module.exports = router;
