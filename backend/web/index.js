// Website API — router root, mounted at /api/web.
//
// Kept entirely separate from routes/ (the mobile app API): its own auth,
// its own response envelope, its own error handling. Nothing here changes
// behaviour of the existing mobile endpoints.
const express = require('express');

const { errorHandler, notFoundHandler, ok } = require('./lib/http');
const { authenticate } = require('./middleware/authenticate');

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

/** Unauthenticated liveness probe. */
router.get('/health', (_req, res) => ok(res, { status: 'up', api: 'web', time: new Date().toISOString() }));

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
router.use('/masters/buildings', authenticate, buildingRoutes);
router.use('/masters/wings', authenticate, wingRoutes);
router.use('/masters/flats', authenticate, flatRoutes);
router.use('/masters/owners', authenticate, ownerRoutes);
router.use('/masters/family', authenticate, familyRoutes);
router.use('/masters/owner-extras', authenticate, ownerExtraRoutes);
router.use('/uploads', authenticate, uploadRoutes);

router.use('/settings/account', authenticate, accountSettingRoutes);
router.use('/settings/charges', authenticate, chargeRoutes);
router.use('/settings/terms', authenticate, termsRoutes);
router.use('/settings/society-charges', authenticate, societyChargeRoutes);

// Mount generation before /bills so its paths are not shadowed.
router.use('/billing/generate', authenticate, generationRoutes);
router.use('/billing/pdc', authenticate, pdcRoutes);
router.use('/billing/receipts', authenticate, receiptRoutes);
router.use('/billing/bills', authenticate, billRoutes);

// Remaining master screens (staff, caretakers, contacts, inventory, parking,
// car pooling, loans, society profile, committee members).
router.use('/masters', authenticate, miscMasterRoutes);

router.use('/accounts/vendor-bills', authenticate, vendorBillRoutes);
router.use('/accounts/vendors', authenticate, vendorRoutes);
router.use('/accounts', authenticate, accountRoutes);
router.use('/community', authenticate, communityRoutes);
router.use('/reports', authenticate, reportRoutes);
router.use('/village', authenticate, villageRoutes);

// Terminal handlers, scoped to this router so the mobile API is unaffected.
router.use(notFoundHandler);
router.use(errorHandler);

module.exports = router;
