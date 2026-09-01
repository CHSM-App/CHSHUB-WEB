// Website API — Community.
// Replaces notice_search, event_search, meeting_search/meeting_details,
// facility_booking, visitor_search, support_ticket, suggestion_request,
// upload_doc_search and Vote.
const express = require('express');

const { query, queryOne, exec, sql, getPool } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date, time, oneOf } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');
const {
  notifyGroup,
  notifyPeople,
  notifyHelpdesk,
  notifyVisitor,
  findFlatResidents,
  findCommittee,
} = require('../../lib/notify');
const { nocOfficers, addNocOfficers } = require('../../lib/nocOfficers');

const router = express.Router();

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
const SOC50 = (v) => ({ type: sql.NVarChar(50), value: v });

/* ------------------------------------------------------- shell endpoints -- */

/*
 * The alerts bell and the message count in the topbar, which every signed-in
 * account has — including a village one, whose society_id is NULL.
 *
 * These sit above the society guard below for that reason: behind it they
 * returned 403 on every page a village account opened, which the client
 * surfaced as "Network Error" beside whatever the page had actually loaded.
 * They are still scoped, by whichever tenant the token carries.
 */
function tenantId(req) {
  return req.user?.societyId || req.user?.villageId || null;
}

/**
 * GET /community/notifications — the bell dropdown in Site.Master.
 *
 * sp_dashboard 'Notification' returns only unseen rows (seen_status = 0) for
 * this tenant and user, newest first, with `timestamp` already run through
 * GetRelativeTime — so it arrives as "2 hours ago", not a date.
 *
 * The procedure is sp_dashboard, not sp_UserLogin: BL_User_Login.get_notification
 * reads like a login call but its DA (DA_User_Login.cs:150) runs sp_dashboard.
 */
router.get(
  '/notifications',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'Notification',
      society_id: SOC(tenantId(req)),
      user_id: { type: sql.Int, value: req.user.userId },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /community/messages/count — the unread badge on the envelope icon.
 *
 * Counted from the same GetMessages rows the page lists, NOT from
 * get_messages_count. That branch counts every unread row in owner_Messages
 * regardless of `type`, while GetMessages reads owner_messages_vw filtered to
 * type = 'admin' — so the two disagree whenever a message has another type.
 *
 * They do disagree today: every stored message is type = 'security', so
 * get_messages_count reports unread messages the page can never show, and the
 * badge would never clear no matter how many were opened. Counting the listed
 * rows keeps the badge and the list telling the same story.
 */
router.get(
  '/messages/count',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_owner_master', {
      operation: 'GetMessages',
      society_id: SOC(tenantId(req)),
    });
    const unread = rows.filter((r) => Number(r.view_status) === 0).length;
    return ok(res, { unread });
  }),
);

/*
 * Society-only below this line. A village's announcements are not notices —
 * they live in village_announcement and are served by /village/announcements,
 * which scopes by village_id.
 */
router.use(requireSociety);

/* ----------------------------------------------------------------- notices */

router.get(
  '/notices',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const rows = await query('sp_notice_master', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(200), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/notices/recipients',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_notice_master', { operation: 'GetAllRecipients' });
    return ok(res, { items: rows });
  }),
);

router.post(
  '/notices',
  asyncHandler(async (req, res) => {
    const title = str(req.body?.title, 'title', { max: 150 });
    const description = optionalStr(req.body?.description, 'description', { max: 500 });
    const recipientsId = int(req.body?.recipientsId, 'recipientsId', { required: false, default: 0 });

    const created = await exec('sp_notice_master', {
      operation: 'Update',
      notice_id: { type: sql.Int, value: 0 },
      name: { type: sql.NVarChar(150), value: title },
      description: { type: sql.NVarChar(500), value: description },
      valid_to: { type: sql.SmallDateTime, value: date(req.body?.validTo, 'validTo', { required: false }) },
      recipients_id: { type: sql.Int, value: recipientsId },
      society_id: SOC(req.societyId),
    });

    // After the save, never before: a push must not be able to lose the notice.
    const notified = await notifyGroup({
      societyId: req.societyId,
      recipientsId,
      type: 'Notice',
      id: created?.notice_id ?? 0,
      title,
      body: description || title,
    });

    return ok(res, { notice_id: created?.notice_id ?? null, notified }, 201);
  }),
);

router.put(
  '/notices/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_notice_master', {
      operation: 'Update',
      notice_id: { type: sql.Int, value: id },
      name: { type: sql.NVarChar(150), value: str(req.body?.title, 'title', { max: 150 }) },
      description: { type: sql.NVarChar(500), value: optionalStr(req.body?.description, 'description', { max: 500 }) },
      date: { type: sql.Date, value: date(req.body?.date, 'date', { required: false }) },
      valid_to: { type: sql.SmallDateTime, value: date(req.body?.validTo, 'validTo', { required: false }) },
      recipients_id: { type: sql.Int, value: int(req.body?.recipientsId, 'recipientsId', { required: false, default: 0 }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { notice_id: id });
  }),
);

router.delete(
  '/notices/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_notice_master', { operation: 'Delete', notice_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, notice_id: id });
  }),
);

/* ------------------------------------------------------------------ events */

router.get(
  '/events',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_event_master', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/events',
  asyncHandler(async (req, res) => {
    const name = str(req.body?.name, 'name', { max: 150 });
    const description = optionalStr(req.body?.description, 'description', { max: 500 });

    const created = await exec('sp_event_master', {
      operation: 'Update',
      event_id: { type: sql.Int, value: 0 },
      event_name: { type: sql.NVarChar(150), value: name },
      description: { type: sql.NVarChar(500), value: description },
      from_date: { type: sql.SmallDateTime, value: date(req.body?.fromDate, 'fromDate') },
      to_date: { type: sql.SmallDateTime, value: date(req.body?.toDate, 'toDate') },
      society_id: SOC(req.societyId),
    });

    // event_search.aspx has no recipient picker, so everyone is told — group 5,
    // owners and tenants plus the committee. Group 3 left the secretary and
    // the admins out of the event they had just scheduled.
    const notified = await notifyGroup({
      societyId: req.societyId,
      recipientsId: 5,
      type: 'Event',
      id: created?.event_id ?? 0,
      title: name,
      body: description || name,
    });

    return ok(res, { event_id: created?.event_id ?? null, notified }, 201);
  }),
);

router.put(
  '/events/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_event_master', {
      operation: 'Update',
      event_id: { type: sql.Int, value: id },
      event_name: { type: sql.NVarChar(150), value: str(req.body?.name, 'name', { max: 150 }) },
      description: { type: sql.NVarChar(500), value: optionalStr(req.body?.description, 'description', { max: 500 }) },
      from_date: { type: sql.SmallDateTime, value: date(req.body?.fromDate, 'fromDate') },
      to_date: { type: sql.SmallDateTime, value: date(req.body?.toDate, 'toDate') },
      society_id: SOC(req.societyId),
    });
    return ok(res, { event_id: id });
  }),
);

router.delete(
  '/events/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_event_master', { operation: 'Delete', event_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, event_id: id });
  }),
);

/* ---------------------------------------------------------------- meetings */

router.get(
  '/meetings',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const rows = await query('sp_meeting_master', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(200), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/meetings',
  asyncHandler(async (req, res) => {
    const subject = str(req.body?.subject, 'subject', { max: 150 });
    const details = optionalStr(req.body?.details, 'details', { max: 1000 });

    const created = await exec('sp_meeting_master', {
      operation: 'Update',
      meet_id: { type: sql.Int, value: 0 },
      subject: { type: sql.NVarChar(150), value: subject },
      details: { type: sql.NVarChar(1000), value: details },
      meeting_date: { type: sql.Date, value: date(req.body?.meetingDate, 'meetingDate') },
      meeting_time: { type: sql.DateTime, value: time(req.body?.meetingTime, 'meetingTime', { required: false }) },
      society_id: SOC(req.societyId),
    });

    // meeting_search.aspx has no recipient picker either, so a meeting goes to
    // the whole society — group 5, which unlike 3 includes the committee. A
    // committee meeting that never reached the committee was the wrong default.
    const notified = await notifyGroup({
      societyId: req.societyId,
      recipientsId: 5,
      type: 'Meeting',
      id: created?.meet_id ?? 0,
      title: subject,
      body: details || subject,
    });

    return ok(res, { created: true, notified }, 201);
  }),
);

router.put(
  '/meetings/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_meeting_master', {
      operation: 'Update',
      meet_id: { type: sql.Int, value: id },
      subject: { type: sql.NVarChar(150), value: str(req.body?.subject, 'subject', { max: 150 }) },
      details: { type: sql.NVarChar(1000), value: optionalStr(req.body?.details, 'details', { max: 1000 }) },
      meeting_date: { type: sql.Date, value: date(req.body?.meetingDate, 'meetingDate') },
      meeting_time: { type: sql.DateTime, value: time(req.body?.meetingTime, 'meetingTime', { required: false }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { meet_id: id });
  }),
);

router.delete(
  '/meetings/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_meeting_master', { operation: 'Delete', meet_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, meet_id: id });
  }),
);

/* -------------------------------------------------------------- facilities */

router.get(
  '/facilities',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_facility', {
      operation: 'Grid_Show',
      society_id: SOC50(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/facilities',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_facility', {
      operation: 'Update',
      facility_id: { type: sql.Int, value: 0 },
      name: { type: sql.NVarChar(50), value: str(req.body?.name, 'name', { max: 50 }) },
      cost: { type: sql.Decimal(18, 2), value: num(req.body?.cost, 'cost', { min: 0, required: false, default: 0 }) },
      description: { type: sql.NVarChar(50), value: optionalStr(req.body?.description, 'description', { max: 50 }) },
      capacity: { type: sql.Int, value: int(req.body?.capacity, 'capacity', { min: 0, required: false, default: 0 }) },
      slot: { type: sql.Int, value: int(req.body?.slots, 'slots', { min: 0, required: false, default: 0 }) },
      isActive: { type: sql.Bit, value: req.body?.isActive === false ? 0 : 1 },
      society_id: SOC50(req.societyId),
    });
    return ok(res, { facility_id: created?.facility_id ?? null }, 201);
  }),
);

router.delete(
  '/facilities/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_facility', { operation: 'Delete', facility_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, facility_id: id });
  }),
);

router.get(
  '/facility-bookings',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    let rows = await query('sp_facility_booking', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });

    /*
     * The SP's Search branch works, but matches `LIKE @search + '%'` — a
     * prefix only, so "edding" finds nothing while "Wedding" does. Every other
     * screen here matches anywhere in the value, so filter for consistency
     * across the columns the grid shows.
     */
    if (search) {
      const needle = search.toLowerCase();
      const matches = (v) => String(v ?? '').toLowerCase().includes(needle);
      rows = rows.filter(
        (r) =>
          matches(r.name) ||
          matches(r.build_name) ||
          matches(r.Unit) ||
          matches(r.pre_mob) ||
          matches(r.facility_name) ||
          matches(r.amount),
      );
    }

    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /community/facility-bookings/lookups — the pickers on
 * facility_booking.aspx: which facility, and which resident it is booked for.
 */
router.get(
  '/facility-bookings/lookups',
  asyncHandler(async (req, res) => {
    const [facilities, residents] = await Promise.all([
      query('sp_facility_booking', { operation: 'fill_facilities', society_id: SOC(req.societyId) }),
      query('sp_facility_booking', { operation: 'fill_owner', society_id: SOC(req.societyId) }),
    ]);

    return ok(res, {
      facilities: facilities.map((f) => ({
        facility_id: f.facility_id,
        name: f.name,
        cost: f.cost,
        // 1 Day, 2 Hour, 3 Slot — how the facility is booked.
        slot: f.slot,
      })),
      // fill_owner returns the whole owner row; the picker needs three fields.
      residents: residents.map((r) => ({
        owner_id: r.owner_id,
        flat_id: r.flat_id,
        name: r.name,
        contact: r.pre_mob,
        address: r.off_addr1,
      })),
    });
  }),
);

/** GET /community/facility-bookings/charge?facilityId= — cost and booking basis. */
router.get(
  '/facility-bookings/charge',
  asyncHandler(async (req, res) => {
    const facilityId = int(req.query.facilityId, 'facilityId', { min: 1 });
    const rows = await query('sp_facility_booking', {
      operation: 'GetCharge',
      facility_id: { type: sql.Int, value: facilityId },
      society_id: SOC(req.societyId),
    });
    return ok(res, { charge: rows[0] ?? null });
  }),
);

/**
 * POST /community/facility-bookings — book a facility.
 *
 * Replaces the Add form on facility_booking.aspx. The 'Update' branch inserts
 * when facility_book_id is 0, as the other masters do.
 */
router.post(
  '/facility-bookings',
  asyncHandler(async (req, res) => {
    await exec('sp_facility_booking', {
      operation: 'Update',
      facility_book_id: { type: sql.Int, value: 0 },
      facility_id: { type: sql.Int, value: int(req.body?.facilityId, 'facilityId', { min: 1 }) },
      // The date the booking is made for, distinct from the from/to range.
      book_date: { type: sql.Date, value: date(req.body?.bookDate, 'bookDate', { required: false }) },
      /*
       * The insert writes `flat_id` from **@flat_no**, while the update path
       * reads @flat_id — so a new booking sent only as @flat_id lands with
       * flat_id = 0, and facility_booking_vw (which joins owner_search_vw on
       * flat_id) then shows no building, unit or phone. Send both.
       */
      flat_no: { type: sql.Int, value: int(req.body?.flatId, 'flatId', { min: 0, required: false, default: 0 }) },
      flat_id: { type: sql.Int, value: int(req.body?.flatId, 'flatId', { min: 0, required: false, default: 0 }) },
      name: { type: sql.NVarChar(100), value: str(req.body?.name, 'name', { max: 100 }) },
      address: { type: sql.NVarChar(250), value: optionalStr(req.body?.address, 'address', { max: 250 }) },
      contact: { type: sql.NVarChar(15), value: optionalStr(req.body?.contact, 'contact', { max: 15 }) },
      from_date: { type: sql.Date, value: date(req.body?.fromDate, 'fromDate') },
      to_date: { type: sql.Date, value: date(req.body?.toDate, 'toDate', { required: false }) },
      // Clock times, not dates — see lib/validate.js.
      from_time: { type: sql.DateTime, value: time(req.body?.fromTime, 'fromTime', { required: false }) },
      to_time: { type: sql.DateTime, value: time(req.body?.toTime, 'toTime', { required: false }) },
      amount: { type: sql.Decimal(18, 2), value: num(req.body?.amount, 'amount', { min: 0, required: false, default: 0 }) },
      note: { type: sql.NVarChar(500), value: optionalStr(req.body?.note, 'note', { max: 500 }) },
      society_in: { type: sql.Int, value: req.body?.societyIn ? 1 : 0 },
      society_id: SOC(req.societyId),
    });

    return ok(res, { created: true }, 201);
  }),
);

router.delete(
  '/facility-bookings/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_facility_booking', {
      operation: 'Delete',
      facility_book_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, facility_book_id: id });
  }),
);

/* ---------------------------------------------------------------- visitors */

router.get(
  '/visitors',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    let rows = await query('sp_Visitor', {
      operation: 'Grid_Show',
      society_id: SOC50(req.societyId),
    });

    /*
     * Filtered here rather than in the SP, as facility-bookings is.
     *
     * The route took `search` from the app and dropped it: the gate log came
     * back whole whatever was typed, so the search box on the visitors screen
     * looked broken. sp_Visitor's own Search branch is no help either — it
     * matches `LIKE @search + '%'` against the name alone, so a flat number or
     * a phone number finds nothing, and "awar" misses "Pawar".
     */
    if (search) {
      const needle = search.toLowerCase();
      const matches = (v) => String(v ?? '').toLowerCase().includes(needle);
      rows = rows.filter(
        (r) =>
          matches(r.v_name) ||
          matches(r.flat_no) ||
          matches(r.build_wing) ||
          matches(r.contact_no) ||
          matches(r.type) ||
          matches(r.company) ||
          matches(r.vehicle_no),
      );
    }

    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/visitors/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_Visitor', {
      operation: 'details',
      visitor_id: { type: sql.Int, value: id },
      society_id: SOC50(req.societyId),
    });
    if (!rows[0]) throw ApiError.notFound('Visitor not found');
    return ok(res, { visitor: rows[0] });
  }),
);

/**
 * visitor_search.aspx showed a different panel per visitor type — guest, cab,
 * delivery, service — but every panel wrote the same three columns: the
 * per-type boxes (txtCabCompany / txtDeliveryCompany / txtServiceCompany, and
 * so on) were UI aliases, all assigned to Vehical_No / company / location in
 * the code-behind. So the API takes one canonical shape and the UI decides
 * which labels to show.
 */
function visitorParams(body, societyId) {
  return {
    v_name: { type: sql.NVarChar(50), value: str(body?.name, 'name', { max: 50 }) },
    type: { type: sql.NVarChar(50), value: str(body?.type, 'type', { max: 50 }) },
    contact_no: { type: sql.NVarChar(15), value: optionalStr(body?.contactNo, 'contactNo', { max: 15 }) },
    flat_id: { type: sql.Int, value: int(body?.flatId, 'flatId', { min: 0, required: false, default: 0 }) },
    build_id: { type: sql.Int, value: int(body?.buildId, 'buildId', { min: 0, required: false, default: 0 }) },
    vehicle_no: { type: sql.NVarChar(50), value: optionalStr(body?.vehicleNo, 'vehicleNo', { max: 50 }) },
    company: { type: sql.NVarChar(100), value: optionalStr(body?.company, 'company', { max: 100 }) },
    location: { type: sql.NVarChar(200), value: optionalStr(body?.location, 'location', { max: 200 }) },
    purpose: { type: sql.NVarChar(200), value: optionalStr(body?.purpose, 'purpose', { max: 200 }) },
    preference: { type: sql.NVarChar(50), value: optionalStr(body?.preference, 'preference', { max: 50 }) },
    image: { type: sql.NVarChar(500), value: optionalStr(body?.image, 'image', { max: 500 }) },
    in_date: { type: sql.SmallDateTime, value: date(body?.inDate, 'inDate', { required: false }) },
    out_date: { type: sql.SmallDateTime, value: date(body?.outDate, 'outDate', { required: false }) },
    in_time: { type: sql.SmallDateTime, value: time(body?.inTime, 'inTime', { required: false }) },
    out_time: { type: sql.SmallDateTime, value: time(body?.outTime, 'outTime', { required: false }) },
    pre_date: { type: sql.SmallDateTime, value: date(body?.expectedDate, 'expectedDate', { required: false }) },
    status: { type: sql.Int, value: int(body?.status, 'status', { min: 0, required: false, default: 0 }) },
    owner_id: { type: sql.Int, value: int(body?.ownerId, 'ownerId', { min: 0, required: false, default: 0 }) },
    in_user_id: { type: sql.Int, value: int(body?.inUserId, 'inUserId', { min: 0, required: false, default: 0 }) },
    society_id: SOC50(societyId),
  };
}

/** Confirm a visitor belongs to this society before updating or deleting it. */
async function assertVisitor(societyId, id) {
  const rows = await query('sp_Visitor', {
    operation: 'details',
    visitor_id: { type: sql.Int, value: id },
    society_id: SOC50(societyId),
  });
  if (!rows[0]) throw ApiError.notFound('Visitor not found');
  return rows[0];
}

/**
 * "Ganesh Bhavan A 101", for a push that names where the visitor is headed.
 *
 * Best-effort: a flat that cannot be read still leaves a usable message, so a
 * lookup failure must not cost the notification.
 */
async function flatLabel(societyId, flatId) {
  if (!flatId) return null;
  try {
    const rows = await query('sp_flat_master', {
      operation: 'Grid_Show',
      society_id: { type: sql.NVarChar(50), value: societyId },
    });
    const flat = rows.find((r) => Number(r.flat_id) === Number(flatId));
    if (!flat) return null;

    return [flat.build_wing ?? flat.name, flat.flat_no].filter(Boolean).join(' ') || null;
  } catch {
    return null;
  }
}

/** POST /community/visitors — register a visitor. */
router.post(
  '/visitors',
  asyncHandler(async (req, res) => {
    // The Update branch inserts when visitor_id = 0 and returns the new id
    // alongside the gate OTP it generates.
    const created = await exec('sp_Visitor', {
      operation: 'Update',
      visitor_id: { type: sql.Int, value: 0 },
      ...visitorParams(req.body, req.societyId),
    });

    /*
     * After the save, never before: a failed push must not lose the visitor.
     *
     * The flat hears because someone has arrived for them, and the gate hears
     * because a visitor registered from the website or the secretary's phone
     * never passed in front of whoever has to let them in.
     */
    const flatId = int(req.body?.flatId, 'flatId', { min: 0, required: false, default: 0 });
    const name = str(req.body?.name, 'name', { max: 50 });
    const where = await flatLabel(req.societyId, flatId);
    const visitorType = optionalStr(req.body?.type, 'type', { max: 50 });

    const notified = await notifyVisitor({
      societyId: req.societyId,
      flatId: flatId || null,
      registeredBy: { userId: req.user.userId, source: 'login' },
      type: 'Visitor',
      id: created?.visitor_id ?? 0,
      title: 'Visitor at the gate',
      body: [
        name,
        visitorType ? `(${visitorType})` : null,
        where ? `for ${where}` : null,
      ]
        .filter(Boolean)
        .join(' '),
    });

    return ok(res, { visitor: created ?? null, notified }, 201);
  }),
);

/** PUT /community/visitors/:id */
router.put(
  '/visitors/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await assertVisitor(req.societyId, id);

    await exec('sp_Visitor', {
      operation: 'Update',
      visitor_id: { type: sql.Int, value: id },
      ...visitorParams(req.body, req.societyId),
    });
    return ok(res, { visitor: await assertVisitor(req.societyId, id) });
  }),
);

/**
 * POST /community/visitors/:id/checkout — stamp the exit.
 * 'VisitorOut' sets out_date/out_time from GETDATE() and status = 3.
 */
router.post(
  '/visitors/:id/checkout',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await assertVisitor(req.societyId, id);

    await exec('sp_Visitor', {
      operation: 'VisitorOut',
      visitor_id: { type: sql.Int, value: id },
    });
    return ok(res, { visitor: await assertVisitor(req.societyId, id) });
  }),
);

/** DELETE /community/visitors/:id — soft delete (active_status = 1). */
router.delete(
  '/visitors/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await assertVisitor(req.societyId, id);

    await exec('sp_Visitor', {
      operation: 'Delete',
      visitor_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, visitor_id: id });
  }),
);

/* ---------------------------------------------------------------- helpdesk */

router.get(
  '/helpdesk',
  asyncHandler(async (req, res) => {
    const [rows, flats] = await Promise.all([
      query('sp_helpdesk', {
        operation: 'GetTickets',
        society_id: SOC50(req.societyId),
        owner_id: { type: sql.Int, value: 0 },
      }),
      query('sp_flat_master', { operation: 'Grid_Show', society_id: SOC(req.societyId) }),
    ]);

    /*
     * GetTickets takes `name` and `Unit` from whoever raised the ticket, not
     * from the flat the ticket is about. For a resident's own complaint those
     * are the same flat; for one a secretary files on someone's behalf they
     * are not, and the row showed the secretary's own unit against a
     * complaint about someone else's.
     *
     * `name` is left as the SP sends it — that is who raised it, which is what
     * should be shown — and the flat is corrected from hr.flat_id.
     */
    const byId = new Map(flats.map((f) => [Number(f.flat_id), f]));

    const items = rows.map((r) => {
      const flat = byId.get(Number(r.flat_id));

      // A community complaint the committee filed carries no flat. GetTickets
      // still fills Unit and build_name from whoever raised it, which would
      // put the secretary's own flat against a complaint about the lift — so
      // they are cleared rather than left to mislead.
      if (!flat) {
        return Number(r.flat_id) ? r : { ...r, build_name: null, flat_no: null, Unit: null };
      }

      const building = flat.build_wing || [flat.name, flat.w_name].filter(Boolean).join(' ');

      return {
        ...r,
        build_name: building || r.build_name,
        flat_no: flat.flat_no ?? r.flat_no,
        Unit: [building, flat.flat_no].filter(Boolean).join(' ') || r.Unit,
      };
    });

    return ok(res, { items, count: items.length });
  }),
);

router.get(
  '/helpdesk/statuses',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_helpdesk', { operation: 'GetAllHelpdeskStatus' });
    return ok(res, { items: rows });
  }),
);

/*
 * GET /community/helpdesk/lookups — the pickers on the raise-complaint form:
 * the complaint category, and which flat it is being raised for.
 *
 * Registered before '/helpdesk/:id' so Express does not read "lookups" as an
 * id and fail on the int() check.
 *
 * The resident app reads its categories from `users/category`, which calls
 * sp_usefull_contact rather than sp_helpdesk — the category list is shared
 * with the useful-contacts directory. The same branch is used here so both
 * apps offer the same list.
 */
router.get(
  '/helpdesk/lookups',
  asyncHandler(async (req, res) => {
    const [categories, flats] = await Promise.all([
      // 'ComplaintType', not 'GetCategories' — the branch behind
      // `users/Complainttype`, which is what the resident app's working
      // helpdesk page reads. Its raise_complaint.dart screen calls
      // GetCategories instead, but that screen never saves (its insert is
      // commented out), so the helpdesk page is the one to follow.
      query('sp_usefull_contact', { operation: 'ComplaintType' }),
      query('sp_flat_master', { operation: 'Grid_Show', society_id: SOC(req.societyId) }),
    ]);

    // Both passed through unreshaped, as `users/category` does for the
    // resident app: hand-picking columns here would turn any difference in
    // what the SP names them into silent nulls, where passing the rows on
    // lets the pickers fall back the way the rest of the app does.
    return ok(res, { categories, flats });
  }),
);

/*
 * POST /community/helpdesk — raise a complaint on a resident's behalf.
 *
 * sp_Helpdesk's Update branch is the same one the resident app posts to via
 * `insert/Helpdesk`; it returns the new helpdesk_id. `logintype` tells the SP
 * who raised it — 'admin' here, since the secretary is filing it rather than
 * the resident.
 */
router.post(
  '/helpdesk',
  asyncHandler(async (req, res) => {
    const ownerId = req.user.ownerId ?? req.user.userId;

    /*
     * GetTickets joins HelpdeskRequest to owner_search_vw on BOTH owner_id and
     * `hr.logintype = u.login_type` — the procedure's own comment marks that
     * line "THIS IS KEY". The view only holds 'Owner' and 'Rent', so a ticket
     * written with any other logintype is saved but can never be listed.
     *
     * Writing 'admin' did exactly that: the row landed in the table and the
     * helpdesk list stayed empty. The secretary's own type from the view is
     * used instead, so the ticket joins and appears.
     */
    const pool = await getPool();
    const found = await pool
      .request()
      .input('owner_id', sql.Int, ownerId)
      .input('society_id', sql.NVarChar(50), req.societyId)
      .query(`
        SELECT TOP 1 type FROM (
          SELECT owner_id, type, society_id FROM owner_search_vw
          UNION ALL
          SELECT o_ex_id AS owner_id, 'Family' AS type, society_id FROM owner_family
        ) u
        WHERE u.owner_id = @owner_id AND u.society_id = @society_id
      `);

    // The same union GetTickets builds, scoped to this society — an account
    // that only exists in owner_family is a 'Family' login, and writing
    // 'Owner' for it would leave the ticket unjoinable just as 'admin' did.
    //
    // 'Owner' remains the fallback: it is what every committee account seen
    // so far carries, and it is the only type that can match when the lookup
    // finds nothing.
    const loginType = found.recordset[0]?.type ?? 'Owner';

    // A complaint is always about a flat — a lift or a parking dispute is
    // still reported from one — so flatId is required for both kinds, which
    // is what every ticket in the table already carries.
    const complaint = str(req.body?.query, 'query');
    const categoryType =
      optionalStr(req.body?.categoryType, 'categoryType', { max: 50 }) || 'personal';

    /*
     * A personal complaint is about one flat, so it must name one. A community
     * complaint — a lift, the parking — belongs to the society rather than to
     * any flat, and the secretary filing one has no flat to give.
     *
     * 0 rather than NULL: the column is what sp_Helpdesk writes and every
     * existing row carries a number, so a sentinel keeps the type steady.
     */
    const flatId =
      categoryType === 'community'
        ? int(req.body?.flatId, 'flatId', { required: false, default: 0 })
        : int(req.body?.flatId, 'flatId', { min: 1 });

    const row = await exec('sp_Helpdesk', {
      operation: 'Update',
      flat_id: { type: sql.Int, value: flatId },
      query: { type: sql.NVarChar(sql.MAX), value: complaint },
      category: { type: sql.Int, value: int(req.body?.category, 'category', { min: 1 }) },
      type: { type: sql.NVarChar(50), value: categoryType },
      req_service_date: { type: sql.NVarChar(50), value: null },
      // A flag, not a scale — support_ticket.aspx reads anything non-zero as
      // Urgent, so the form sends 1 or 0.
      urgency: { type: sql.Int, value: req.body?.urgency ? 1 : 0 },
      owner_id: { type: sql.Int, value: ownerId },
      logintype: { type: sql.NVarChar(50), value: loginType },
    });

    const helpdeskId = row?.helpdesk_id ?? null;

    // After the save, never before: a push must not be able to lose the
    // ticket. The secretary raising it is dropped from the audience — they
    // are the one who just filed it.
    const notified = await notifyHelpdesk({
      societyId: req.societyId,
      flatId,
      categoryType,
      raisedBy: { userId: req.user.userId, source: 'login' },
      type: 'Helpdesk',
      id: helpdeskId ?? 0,
      title: categoryType === 'community' ? 'New community complaint' : 'New complaint',
      body: complaint.length > 120 ? `${complaint.slice(0, 117)}...` : complaint,
    });

    return ok(res, { helpdesk_id: helpdeskId, notified }, 201);
  }),
);

/** The wording for a status id, so a push says what changed. */
async function statusLine(status) {
  const rows = await query('sp_helpdesk', { operation: 'GetAllHelpdeskStatus' });
  const match = rows.find((r) => Number(r.status_id ?? r.id) === Number(status));
  const name = match?.status_name ?? match?.status ?? match?.name;

  return name ? `Your complaint is now ${name}.` : 'Your complaint has been updated.';
}

/**
 * Notify the flat a ticket belongs to.
 *
 * Used for the things that happen *after* a ticket exists — a status move, a
 * reply — where the audience is the resident waiting on an answer rather than
 * the committee or the society.
 */
async function notifyHelpdeskFlat(req, helpdeskId, { title, body }) {
  const pool = await getPool();
  const found = await pool
    .request()
    .input('helpdesk_id', sql.Int, helpdeskId)
    .query('SELECT flat_id FROM HelpdeskRequest WHERE helpdesk_id = @helpdesk_id');

  const flatId = found.recordset[0]?.flat_id;

  // A community complaint the committee filed has no flat to answer to, so
  // the committee itself hears the outcome. Without this the reply on such a
  // ticket would reach nobody at all.
  const people = flatId
    ? await findFlatResidents(req.societyId, flatId)
    : await findCommittee(req.societyId);

  return notifyPeople({
    societyId: req.societyId,
    people,
    type: 'Helpdesk',
    id: helpdeskId,
    title,
    body,
  });
}

/**
 * One ticket, read straight from the tables.
 *
 * Used when GetRequestById's flat_id join excludes a ticket (see the caller).
 * The column names mirror that branch exactly — `categoryName`, `Unit`,
 * `build_name`, `image` — so the client cannot tell which path served it.
 *
 * The flat is the one the ticket is about; the name is whoever raised it.
 */
async function helpdeskDetailFallback(pool, id, societyId) {
  const result = await pool.request().input('helpdesk_id', sql.Int, id).query(`
    SELECT TOP 1
      hr.query,
      STUFF((
        SELECT ',' + hi.documents FROM HelpdeskImages hi
        WHERE hi.helpdesk_id = hr.helpdesk_id
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS image,
      hr.helpdesk_id,
      hr.status,
      hr.urgency,
      hr.flat_id,
      hr.type AS category_type,
      ct.c_type_name AS categoryName,
      CONVERT(VARCHAR(20), hr.req_service_date, 106) AS req_service_date,
      CONVERT(VARCHAR(20), hr.date, 100) AS date,
      v.name
    FROM HelpdeskRequest hr
    LEFT JOIN complaint_type ct ON ct.c_type_id = hr.category
    LEFT JOIN owner_search_vw v ON v.owner_id = hr.owner_id
    WHERE hr.helpdesk_id = @helpdesk_id
  `);

  const row = result.recordset[0];
  if (!row) return null;

  // The building is not a column on flat_master — it comes from the wing join
  // Grid_Show already does, so that branch supplies it rather than a hand-
  // written join that would have to guess at the schema.
  const flats = await query('sp_flat_master', {
    operation: 'Grid_Show',
    society_id: SOC(societyId),
  });

  const flat = flats.find((f) => Number(f.flat_id) === Number(row.flat_id));
  if (!flat) return row;

  const building = flat.build_wing || [flat.name, flat.w_name].filter(Boolean).join(' ');

  return {
    ...row,
    build_id: flat.build_id ?? null,
    build_name: building || null,
    Unit: [building, flat.flat_no].filter(Boolean).join(' ') || null,
  };
}

router.get(
  '/helpdesk/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const pool = await getPool();
    const [ticket, comments, images] = await Promise.all([
      query('sp_helpdesk', { operation: 'GetRequestById', helpdesk_id: { type: sql.Int, value: id } }),
      query('sp_helpdesk', { operation: 'GetComments', helpdesk_id: { type: sql.Int, value: id } }),
      // HelpdeskImages has no SP branch of its own — the mobile uploader
      // inserts into it directly, so it is read directly too. Photos may have
      // come from either app, so both paths are served.
      pool
        .request()
        .input('helpdesk_id', sql.Int, id)
        .query('SELECT documents FROM HelpdeskImages WHERE helpdesk_id = @helpdesk_id'),
    ]);
    /*
     * GetRequestById joins UserData on flat_id AND owner_id AND logintype, so
     * it only returns a ticket whose raiser lives in the flat it is about.
     * That holds for a resident's own complaint and fails for every one a
     * secretary files on someone else's behalf — the branch returned nothing
     * and the page said "Ticket not found" for a ticket plainly in the list.
     *
     * The row is rebuilt from the tables directly when that happens, so the
     * thread opens either way.
     */
    const row = ticket[0] ?? (await helpdeskDetailFallback(pool, id, req.societyId));
    if (!row) throw ApiError.notFound('Ticket not found');

    return ok(res, {
      ticket: row,
      comments,
      images: (images.recordset ?? []).map((r) => r.documents).filter(Boolean),
    });
  }),
);

router.put(
  '/helpdesk/:id/status',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const status = int(req.body?.status, 'status', { min: 1 });

    await exec('sp_helpdesk', {
      operation: 'UpdateStatus',
      helpdesk_id: { type: sql.Int, value: id },
      status: { type: sql.Int, value: status },
    });

    // Only the flat that raised it: a status move is an answer to them, not
    // news for the society — even on a community complaint, where the whole
    // society was told once and does not need every step after it.
    const notified = await notifyHelpdeskFlat(req, id, {
      title: 'Complaint updated',
      body: await statusLine(status),
    });

    return ok(res, { helpdesk_id: id, notified });
  }),
);

router.post(
  '/helpdesk/:id/comments',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const comment = str(req.body?.comment, 'comment');

    await exec('sp_helpdesk', {
      operation: 'InsertComments',
      helpdesk_id: { type: sql.Int, value: id },
      owner_id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
      flat_id: { type: sql.Int, value: int(req.body?.flatId, 'flatId', { required: false, default: 0 }) },
      type: { type: sql.NVarChar(50), value: optionalStr(req.body?.type, 'type', { max: 50 }) || 'Admin' },
      description: { type: sql.NVarChar(sql.MAX), value: comment },
    });

    // The committee replying is the whole point of the thread, so the flat
    // hears about it. A resident's own reply reaches nobody here — that is
    // the resident app's call to make, not this one's.
    const notified = await notifyHelpdeskFlat(req, id, {
      title: 'Reply on your complaint',
      body: comment.length > 120 ? `${comment.slice(0, 117)}...` : comment,
    });

    return ok(res, { added: true, notified }, 201);
  }),
);

/* ------------------------------------------------------------- suggestions */

router.get(
  '/suggestions',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 50 });
    const rows = await query('sp_suggestion_request_master', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(50), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/suggestions/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const row = await queryOne('sp_suggestion_request_master', {
      operation: 'Select',
      sug_id: { type: sql.Int, value: id },
    });
    if (!row) throw new ApiError(404, 'Suggestion not found');
    return ok(res, row);
  }),
);

// Subject and details, the two fields suggestion_request.aspx's modal carried.
router.post(
  '/suggestions',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_suggestion_request_master', {
      operation: 'Update',
      sug_id: { type: sql.Int, value: 0 },
      subject: { type: sql.NVarChar(250), value: str(req.body?.subject, 'subject', { max: 250 }) },
      details: { type: sql.NVarChar(500), value: str(req.body?.details, 'details', { max: 500 }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { sug_id: created?.sug_id ?? null }, 201);
  }),
);

router.put(
  '/suggestions/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_suggestion_request_master', {
      operation: 'Update',
      sug_id: { type: sql.Int, value: id },
      subject: { type: sql.NVarChar(250), value: str(req.body?.subject, 'subject', { max: 250 }) },
      details: { type: sql.NVarChar(500), value: str(req.body?.details, 'details', { max: 500 }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { updated: true, sug_id: id });
  }),
);

router.delete(
  '/suggestions/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_suggestion_request_master', {
      operation: 'Delete',
      sug_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, sug_id: id });
  }),
);

/* --------------------------------------------------------------- documents */

router.get(
  '/documents',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const rows = await query('sp_upload_doc', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(200), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.delete(
  '/documents/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_upload_doc', { operation: 'Delete', file_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, file_id: id });
  }),
);

/* -------------------------------------------------------- noc certificates */

/**
 * Which officers sign this society's NOC certificate, and what they are called.
 *
 * Set per society, because how many officers sign is fixed by its own bye-laws
 * and by whoever is being asked to act on the certificate — one society signs
 * with both, another with the secretary alone, and plenty print "President"
 * where the code says chairman.
 *
 * Falls back to both officers under their usual names, which is what the sheet
 * printed before this was configurable, so a society that has never opened the
 * setting sees no change. A failed read falls back the same way rather than
 * failing the certificate.
 */
async function nocSignatories(societyId) {
  const fallback = { mode: 'Both', secretary: 'Secretary', chairman: 'Chairman' };

  try {
    const row = await queryOne('sp_account_setting', {
      operation: 'select',
      society_id: SOC(societyId),
    });
    if (!row) return fallback;

    return {
      mode: row.noc_signatories || fallback.mode,
      secretary: row.noc_secretary_label || fallback.secretary,
      chairman: row.noc_chairman_label || fallback.chairman,
    };
  } catch {
    return fallback;
  }
}

/*
 * The no-objection certificates a society has issued.
 *
 * The wording is written by the caller and stored as sent, for every type.
 * A certificate is a legal statement fixed when it was signed: rewording the
 * society's standard clause later must not change what an already-issued
 * certificate reads, so the server does not derive the clause from the type.
 */

router.get(
  '/noc',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const [rows, signatories] = await Promise.all([
      query('sp_noc_certificate', {
        operation: search ? 'Search' : 'Grid_Show',
        society_id: SOC(req.societyId),
        ...(search ? { search: { type: sql.NVarChar(200), value: search } } : {}),
      }),
      nocSignatories(req.societyId),
    ]);
    // Sent with the list rather than fetched per certificate: it is one
    // setting for the whole society, and every sheet the client prints from
    // these rows needs it.
    return ok(res, { items: rows, count: rows.length, signatories });
  }),
);

/**
 * GET /community/noc/members — who a certificate can be issued to.
 *
 * Name, flat and building for every resident, which is exactly what the
 * certificate form fills in. Picked from a list rather than typed: a NOC names
 * a member and a flat, and a mistyped flat number produces a certificate the
 * society cannot stand behind.
 *
 * Both owners and tenants, because both ask for certificates — a tenant needs
 * one for a gas connection or a police verification as readily as an owner
 * needs one for a sale.
 *
 * Declared above /noc/:id so Express does not read "members" as an id.
 */
router.get(
  '/noc/members',
  asyncHandler(async (req, res) => {
    const soc = SOC(req.societyId);
    // A society with no tenants at all still has to list its owners, so one
    // side failing must not empty the picker.
    const safe = (p) => p.catch(() => []);

    const [owners, tenants] = await Promise.all([
      safe(query('sp_owner_master', {
        operation: 'Grid_Show',
        type: { type: sql.NVarChar(10), value: 'owner' },
        society_id: soc,
      })),
      safe(query('sp_owner_master', {
        operation: 'Grid_Show',
        type: { type: sql.NVarChar(10), value: 'tenant' },
        society_id: soc,
      })),
    ]);

    const items = [
      ...owners.map((r) => ({ ...r, _kind: 'owner' })),
      ...tenants.map((r) => ({ ...r, _kind: 'tenant' })),
    ]
      .filter((r) => r.name)
      .map((r) => ({
        // Owners and tenants are numbered independently, so an owner_id alone
        // can name two different people. The picker keys on this, and two
        // options sharing a key would collapse into one.
        id: `${r._kind}-${r.owner_id}`,
        owner_id: r.owner_id,
        flat_id: r.flat_id,
        name: r.name,
        flat_no: r.flat_no ?? null,
        building_name: r.build_name ?? null,
        type: r._kind,
      }))
      .sort((a, b) => String(a.name).localeCompare(String(b.name)));

    return ok(res, { items, count: items.length });
  }),
);

router.get(
  '/noc/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const row = await queryOne('sp_noc_certificate', {
      operation: 'Select',
      noc_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
    });
    if (!row) throw new ApiError(404, 'Certificate not found');
    return ok(res, row);
  }),
);

const NOC_TYPES = ['NoDues', 'SaleTransfer', 'Renovation', 'Mortgage', 'General', 'Other'];

router.post(
  '/noc',
  asyncHandler(async (req, res) => {
    const nocType = oneOf(req.body?.nocType, 'nocType', NOC_TYPES, { required: false }) || 'General';

    const created = await exec('sp_noc_certificate', {
      operation: 'Update',
      noc_id: { type: sql.Int, value: 0 },
      society_id: SOC(req.societyId),
      noc_type: { type: sql.NVarChar(20), value: nocType },
      // Only an 'Other' certificate names itself; the rest are titled by type.
      custom_title: {
        type: sql.NVarChar(150),
        value: nocType === 'Other'
          ? str(req.body?.customTitle, 'customTitle', { max: 150 })
          : null,
      },
      clause: { type: sql.NVarChar(1000), value: str(req.body?.clause, 'clause', { max: 1000 }) },
      member_name: { type: sql.NVarChar(150), value: str(req.body?.memberName, 'memberName', { max: 150 }) },
      flat_no: { type: sql.NVarChar(50), value: str(req.body?.flatNo, 'flatNo', { max: 50 }) },
      building_name: { type: sql.NVarChar(100), value: optionalStr(req.body?.buildingName, 'buildingName', { max: 100 }) },
      purpose: { type: sql.NVarChar(300), value: optionalStr(req.body?.purpose, 'purpose', { max: 300 }) },
      remarks: { type: sql.NVarChar(1000), value: optionalStr(req.body?.remarks, 'remarks', { max: 1000 }) },
      issued_on: { type: sql.Date, value: date(req.body?.issuedOn, 'issuedOn', { required: false }) },
      // Absent means the certificate does not lapse, not a missing value.
      valid_till: { type: sql.Date, value: date(req.body?.validTill, 'validTill', { required: false }) },
      created_by: { type: sql.Int, value: req.user?.userId ?? null },
    });

    /*
     * Tie the certificate back to the request it came from, when there was
     * one. The member's screen reads the serial off their request, and the
     * secretary's list shows which requests have produced a letter — both go
     * through noc_request.noc_id.
     *
     * A failure here leaves the certificate issued and the request without its
     * number, which is worth reporting but not worth refusing the certificate
     * over: it exists, it has a serial, and it can be printed.
     */
    const requestId = int(req.body?.requestId, 'requestId', {
      min: 1,
      required: false,
    });

    let linkError = null;
    if (requestId && created?.noc_id) {
      try {
        await exec('sp_noc_request', {
          operation: 'Link_Certificate',
          request_id: { type: sql.Int, value: requestId },
          society_id: SOC(req.societyId),
          noc_id: { type: sql.Int, value: created.noc_id },
        });
      } catch (err) {
        linkError = err.message;
      }
    }

    return ok(
      res,
      {
        noc_id: created?.noc_id ?? null,
        serial_no: created?.serial_no ?? null,
        request_id: requestId ?? null,
        linkError,
      },
      201,
    );
  }),
);

router.put(
  '/noc/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const nocType = oneOf(req.body?.nocType, 'nocType', NOC_TYPES, { required: false }) || 'General';

    const updated = await exec('sp_noc_certificate', {
      operation: 'Update',
      noc_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      noc_type: { type: sql.NVarChar(20), value: nocType },
      custom_title: {
        type: sql.NVarChar(150),
        value: nocType === 'Other'
          ? str(req.body?.customTitle, 'customTitle', { max: 150 })
          : null,
      },
      clause: { type: sql.NVarChar(1000), value: str(req.body?.clause, 'clause', { max: 1000 }) },
      member_name: { type: sql.NVarChar(150), value: str(req.body?.memberName, 'memberName', { max: 150 }) },
      flat_no: { type: sql.NVarChar(50), value: str(req.body?.flatNo, 'flatNo', { max: 50 }) },
      building_name: { type: sql.NVarChar(100), value: optionalStr(req.body?.buildingName, 'buildingName', { max: 100 }) },
      purpose: { type: sql.NVarChar(300), value: optionalStr(req.body?.purpose, 'purpose', { max: 300 }) },
      remarks: { type: sql.NVarChar(1000), value: optionalStr(req.body?.remarks, 'remarks', { max: 1000 }) },
      issued_on: { type: sql.Date, value: date(req.body?.issuedOn, 'issuedOn', { required: false }) },
      valid_till: { type: sql.Date, value: date(req.body?.validTill, 'validTill', { required: false }) },
    });

    return ok(res, { noc_id: updated?.noc_id ?? id, serial_no: updated?.serial_no ?? null });
  }),
);

router.delete(
  '/noc/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_noc_certificate', {
      operation: 'Delete',
      noc_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
    });
    return ok(res, { deleted: true, noc_id: id });
  }),
);

/* ---------------------------------------------------------- noc requests -- */

/*
 * The NOC a member asks for, and the committee's decision on it.
 *
 * A certificate under /noc is what the society issued. These endpoints cover
 * everything before that: the member asking, approvers deciding, and — because
 * a NOC is only worth anything signed — the signed letter being collected from
 * the office.
 *
 * Status codes come from vendor_bills, which is the approval pattern this
 * follows: 1 Pending, 2 Approved, 4 Rejected, plus 5 Ready and 6 Collected for
 * the two paper steps. 3 is skipped; it means Paid there and nothing here.
 */

const NOC_REQUEST_STATUS = {
  PENDING: 1,
  APPROVED: 2,
  REJECTED: 4,
  READY: 5,
  COLLECTED: 6,
};

/** The certificate wording a type gets when the secretary has not written one. */
const NOC_DEFAULT_CLAUSE = {
  NoDues:
    'to the member named above, who has no dues outstanding to the society as on the date of this certificate.',
  SaleTransfer:
    'to the sale and transfer of the said flat by the member named above, subject to the transferee complying with the bye-laws of the society.',
  Renovation:
    'to the internal renovation of the said flat by the member named above, provided no structural change is made and the work is carried out within the hours permitted by the society.',
  Mortgage:
    'to the said flat being mortgaged by the member named above to a bank or financial institution for the purpose stated, the society retaining its lien for any dues.',
  General:
    'to the request of the member named above for the purpose stated.',
  Other:
    'to the request of the member named above for the purpose stated.',
};

/** One request, scoped to the caller's society. */
async function loadNocRequest(requestId, societyId) {
  const row = await queryOne('sp_noc_request', {
    operation: 'Select',
    request_id: { type: sql.Int, value: requestId },
    society_id: SOC(societyId),
  });
  if (!row) throw ApiError.notFound('NOC request not found');
  return row;
}

/**
 * GET /community/noc-requests — the secretary's list.
 *
 * Pending first, then approved awaiting signature, then ready to collect.
 */
router.get(
  '/noc-requests',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const rows = await query('sp_noc_request', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
      search: { type: sql.NVarChar(200), value: search },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);


/**
 * GET /community/noc-requests/approvers — who this society's NOCs go to.
 *
 * Shown on the request so the secretary can see who it will be sent to before
 * sending it; the list is not chosen, only displayed.
 *
 * Declared above /noc-requests/:id so Express does not read "approvers" as an
 * id and answer 400.
 */
router.get(
  '/noc-requests/approvers',
  asyncHandler(async (req, res) => {
    const items = await nocOfficers(req.societyId);
    return ok(res, { items, count: items.length });
  }),
);

/**
 * GET /community/noc-requests/:id — one request with who was asked to decide.
 */
router.get(
  '/noc-requests/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const request = await loadNocRequest(id, req.societyId);

    let approvals = await query('sp_noc_request', {
      operation: 'Get_Approvals',
      request_id: { type: sql.Int, value: id },
    });

    /*
     * A pending request with nobody on it gets the society's offices put on it
     * here.
     *
     * Requests are assigned when they are raised, so this covers the two cases
     * where that did not happen: rows created before assignment moved to the
     * raise, and a raise whose assignment failed after the request itself was
     * written. Without it those requests open with no Approve button and no
     * way to get one — a dead end for the committee.
     *
     * Only while pending: a settled request must not collect new approvers
     * afterwards. Best effort, because reading a request must not fail on it.
     */
    if (!approvals.length && Number(request.status) === NOC_REQUEST_STATUS.PENDING) {
      try {
        await addNocOfficers(req.societyId, id);
        approvals = await query('sp_noc_request', {
          operation: 'Get_Approvals',
          request_id: { type: sql.Int, value: id },
        });
      } catch {
        // The request still opens; it simply has nobody to approve it yet.
      }
    }

    return ok(res, { ...request, approvals });
  }),
);

/**
 * POST /community/noc-requests — raise a request.
 *
 * The member's app is the usual caller. The secretary may also raise one on
 * behalf of somebody who asked at the desk, which is why memberName and flatNo
 * are taken from the body rather than the token.
 */
router.post(
  '/noc-requests',
  asyncHandler(async (req, res) => {
    const nocType =
      oneOf(req.body?.nocType, 'nocType', NOC_TYPES, { required: false }) || 'General';

    const created = await exec('sp_noc_request', {
      operation: 'Insert',
      society_id: SOC(req.societyId),
      flat_id: { type: sql.Int, value: int(req.body?.flatId, 'flatId', { required: false }) },
      requested_by: { type: sql.Int, value: req.user?.userId ?? null },
      member_name: { type: sql.NVarChar(150), value: str(req.body?.memberName, 'memberName', { max: 150 }) },
      flat_no: { type: sql.NVarChar(50), value: str(req.body?.flatNo, 'flatNo', { max: 50 }) },
      building_name: { type: sql.NVarChar(100), value: optionalStr(req.body?.buildingName, 'buildingName', { max: 100 }) },
      noc_type: { type: sql.NVarChar(20), value: nocType },
      custom_title: {
        type: sql.NVarChar(150),
        value: nocType === 'Other' ? str(req.body?.customTitle, 'customTitle', { max: 150 }) : null,
      },
      purpose: { type: sql.NVarChar(300), value: str(req.body?.purpose, 'purpose', { max: 300 }) },
    });

    const requestId = created?.request_id ?? null;

    /*
     * Put the society's offices on it straight away, as the member's app does.
     * A request that arrives with nobody on it makes the committee click "send
     * for approval" before they can approve — a step that chooses nothing,
     * since every request goes to the same offices.
     *
     * Best effort: a failure leaves the request raised and unassigned rather
     * than losing it, and opening it puts the offices on.
     */
    if (requestId) {
      try {
        await addNocOfficers(req.societyId, requestId);
      } catch {
        // The request stands; the approvers can be added on opening it.
      }
    }

    // The committee has something waiting for them. Notifying is not what the
    // caller asked for, so a failure here must not fail the request itself.
    try {
      const committee = await findCommittee(req.societyId);
      await notifyPeople({
        societyId: req.societyId,
        people: committee,
        type: 'noc',
        id: requestId,
        title: 'New NOC request',
        body: `${req.body?.memberName ?? 'A member'} (${req.body?.flatNo ?? ''}) has requested a ${nocType} NOC.`,
      });
    } catch {
      /* the request stands whether or not the push went out */
    }

    return ok(res, { request_id: requestId }, 201);
  }),
);

/**
 * PUT /community/noc-requests/:id/draft — the secretary settles the wording.
 *
 * The clause falls back to the standard wording for the type, so a secretary
 * who has nothing to add can approve without writing anything. The SP refuses
 * once the request has left Pending: after that the certificate carries the
 * words that were agreed to, and the draft must not drift away from them.
 */
router.put(
  '/noc-requests/:id/draft',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const request = await loadNocRequest(id, req.societyId);

    if (Number(request.status) !== NOC_REQUEST_STATUS.PENDING) {
      throw ApiError.conflict('The wording can only be edited while the request is pending');
    }

    const nocType =
      oneOf(req.body?.nocType, 'nocType', NOC_TYPES, { required: false }) || request.noc_type || 'General';
    const clause =
      optionalStr(req.body?.clause, 'clause', { max: 1000 }) || NOC_DEFAULT_CLAUSE[nocType];

    await exec('sp_noc_request', {
      operation: 'Update_Draft',
      request_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      noc_type: { type: sql.NVarChar(20), value: nocType },
      custom_title: {
        type: sql.NVarChar(150),
        value: nocType === 'Other'
          ? str(req.body?.customTitle, 'customTitle', { max: 150 })
          : null,
      },
      clause: { type: sql.NVarChar(1000), value: clause },
      purpose: { type: sql.NVarChar(300), value: optionalStr(req.body?.purpose, 'purpose', { max: 300 }) },
      remarks: { type: sql.NVarChar(1000), value: optionalStr(req.body?.remarks, 'remarks', { max: 1000 }) },
      valid_till: { type: sql.Date, value: date(req.body?.validTill, 'validTill', { required: false }) },
    });

    return ok(res, { request_id: id });
  }),
);

/**
 * POST /community/noc-requests/:id/approvers — send it for approval.
 *
 * Who it goes to is the society's own officers, not a list chosen per request:
 * the people who approve a NOC are the people who sign it, and that is fixed
 * by which accounts the society has. Picking them by hand meant the secretary
 * working out who the chairman was from a list of every committee account,
 * every single time.
 *
 * Re-sending is safe — the SP ignores anyone already on the request rather
 * than resetting a decision they have given.
 */
router.post(
  '/noc-requests/:id/approvers',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const request = await loadNocRequest(id, req.societyId);

    if (Number(request.status) !== NOC_REQUEST_STATUS.PENDING) {
      throw ApiError.conflict('This request has already been decided');
    }

    const officers = await addNocOfficers(req.societyId, id);
    if (!officers.length) {
      throw ApiError.badRequest(
        'This society has no secretary, chairman or admin account to approve a NOC',
      );
    }

    const approvals = await query('sp_noc_request', {
      operation: 'Get_Approvals',
      request_id: { type: sql.Int, value: id },
    });

    // Tell only the people who are actually being asked, and only those still
    // waiting — re-saving the list must not re-ping somebody who has answered.
    try {
      const committee = await findCommittee(req.societyId);
      const pending = new Set(
        approvals.filter((a) => Number(a.approval_status) === 1).map((a) => String(a.user_id)),
      );
      await notifyPeople({
        societyId: req.societyId,
        people: committee.filter((p) => pending.has(String(p.user_id))),
        type: 'noc',
        id,
        title: 'NOC awaiting your approval',
        body: `${request.member_name ?? 'A member'} (${request.flat_no ?? ''}) — ${request.noc_type ?? 'NOC'}.`,
      });
    } catch {
      /* the approvers are recorded whether or not the push went out */
    }

    return ok(res, { request_id: id, approvals });
  }),
);

/**
 * POST /community/noc-requests/:id/approvals/:approvalId — approve or reject.
 *
 * A decision may only be recorded by the approver it was asked of; without
 * that check anyone in the society could answer in someone else's name and
 * the trail would name the wrong person. Same rule as vendor bills.
 *
 * When this approval is the last one outstanding the SP moves the request to
 * Approved, and the certificate is issued here from the agreed draft. A
 * rejection settles the request on its own.
 */
router.post(
  '/noc-requests/:id/approvals/:approvalId',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const approvalId = int(req.params.approvalId, 'approvalId', { min: 1 });
    const decision = oneOf(req.body?.decision, 'decision', ['approve', 'reject']);
    const remarks = optionalStr(req.body?.remarks, 'remarks', { max: 500 });

    // The member is shown this, and "rejected, no reason given" is not an
    // answer they can act on.
    if (decision === 'reject' && !remarks) {
      throw ApiError.badRequest('A remark is required when rejecting a request');
    }

    await loadNocRequest(id, req.societyId);

    const approvals = await query('sp_noc_request', {
      operation: 'Get_Approvals',
      request_id: { type: sql.Int, value: id },
    });
    const approval = approvals.find((a) => String(a.approval_id) === String(approvalId));
    if (!approval) throw ApiError.notFound('Approval not found on this request');

    if (String(approval.user_id) !== String(req.user.userId)) {
      throw ApiError.forbidden('This approval was asked of someone else');
    }
    // Re-answering would overwrite the recorded decision and, on a request the
    // SP has already settled, move it back out of that state.
    if (Number(approval.approval_status) !== NOC_REQUEST_STATUS.PENDING) {
      throw ApiError.conflict('This approval has already been answered');
    }

    const settled = await exec('sp_noc_request', {
      operation: 'Update_Status',
      approval_id: { type: sql.Int, value: approvalId },
      status: {
        type: sql.Int,
        value: decision === 'approve' ? NOC_REQUEST_STATUS.APPROVED : NOC_REQUEST_STATUS.REJECTED,
      },
      approval_remark: { type: sql.NVarChar(500), value: remarks },
    });

    /*
     * Approving does not write the certificate.
     *
     * It used to, straight from the request's own wording. But the letter
     * carries more than the request does — the member's name as it should
     * read, the wing, an issue date, whether it lapses — and a certificate is
     * fixed the moment it is issued. Writing it here meant the society's only
     * chance to get those right had already passed by the time anyone saw the
     * document.
     *
     * The secretary now issues it from the certificate form, which opens
     * filled in from the approved request. POST /community/noc creates it and
     * links it back through Link_Certificate.
     */

    // Tell the member how it went. Approved is deliberately not "come and
    // collect it" — the letter still has to be signed, and the secretary
    // gives out the appointment separately.
    try {
      const flatId = Number(settled?.flat_id ?? 0) || null;
      const residents = flatId ? await findFlatResidents(req.societyId, flatId) : [];
      if (residents.length) {
        await notifyPeople({
          societyId: req.societyId,
          people: residents,
          type: 'noc',
          id,
          title: decision === 'approve' ? 'NOC request approved' : 'NOC request rejected',
          body:
            decision === 'approve'
              ? Number(settled?.status) === NOC_REQUEST_STATUS.APPROVED
                ? 'Your NOC has been approved. The society will tell you when to collect the signed copy.'
                : 'One approval is in. Your NOC request is still with the committee.'
              : `Your NOC request was rejected: ${remarks}`,
        });
      }
    } catch {
      /* the decision stands whether or not the push went out */
    }

    return ok(res, {
      request_id: id,
      approval_id: approvalId,
      decision,
      status: settled?.status ?? null,
      noc_id: settled?.noc_id ?? null,
    });
  }),
);

/**
 * POST /community/noc-requests/:id/ready — the letter is signed; set the
 * collection appointment.
 *
 * Also the way an appointment is moved: the SP accepts this from Ready as
 * well as Approved, and the member is told again each time.
 */
router.post(
  '/noc-requests/:id/ready',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const request = await loadNocRequest(id, req.societyId);

    if (![NOC_REQUEST_STATUS.APPROVED, NOC_REQUEST_STATUS.READY].includes(Number(request.status))) {
      throw ApiError.conflict('Only an approved request can be made ready for collection');
    }

    const collectionDate = date(req.body?.collectionDate, 'collectionDate');
    const collectionTime = optionalStr(req.body?.collectionTime, 'collectionTime', { max: 60 });
    const collectionNote = optionalStr(req.body?.collectionNote, 'collectionNote', { max: 300 });

    await exec('sp_noc_request', {
      operation: 'Set_Ready',
      request_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      collection_date: { type: sql.Date, value: collectionDate },
      collection_time: { type: sql.NVarChar(60), value: collectionTime },
      collection_note: { type: sql.NVarChar(300), value: collectionNote },
    });

    try {
      const flatId = Number(request.flat_id ?? 0) || null;
      const residents = flatId ? await findFlatResidents(req.societyId, flatId) : [];
      if (residents.length) {
        const when = [collectionDate, collectionTime].filter(Boolean).join(', ');
        await notifyPeople({
          societyId: req.societyId,
          people: residents,
          type: 'noc',
          id,
          title: 'NOC ready to collect',
          body: [
            `Your NOC ${request.serial_no ? `(${request.serial_no}) ` : ''}is signed and ready.`,
            when ? `Please collect it from the society office on ${when}.` : 'Please collect it from the society office.',
            collectionNote,
          ]
            .filter(Boolean)
            .join(' '),
        });
      }
    } catch {
      /* the appointment stands whether or not the push went out */
    }

    return ok(res, { request_id: id, collection_date: collectionDate });
  }),
);

/**
 * POST /community/noc-requests/:id/collected — it was handed over.
 *
 * collectedBy is free text: the member often sends somebody else, and who took
 * the certificate away is the fact worth keeping.
 */
router.post(
  '/noc-requests/:id/collected',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const request = await loadNocRequest(id, req.societyId);

    if (Number(request.status) !== NOC_REQUEST_STATUS.READY) {
      throw ApiError.conflict('Only a request that is ready for collection can be marked collected');
    }

    const collectedBy =
      optionalStr(req.body?.collectedBy, 'collectedBy', { max: 150 }) || request.member_name;

    await exec('sp_noc_request', {
      operation: 'Set_Collected',
      request_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      collected_by: { type: sql.NVarChar(150), value: collectedBy },
    });

    return ok(res, { request_id: id, collected_by: collectedBy });
  }),
);

/** DELETE /community/noc-requests/:id — soft delete. */
router.delete(
  '/noc-requests/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await loadNocRequest(id, req.societyId);
    await exec('sp_noc_request', {
      operation: 'Delete',
      request_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
    });
    return ok(res, { deleted: true, request_id: id });
  }),
);

/* ------------------------------------------------------------------- polls */

/**
 * ddlAudience value -> notification recipients group, per Vote.aspx.cs:84.
 *
 * The two numbering schemes are unrelated, so this cannot be an identity map:
 * audience 3 means "owners only" but the owners group is 1, and audience 1
 * means "all members" but that group is 5.
 */
const POLL_AUDIENCE_RECIPIENTS = { 1: 5, 2: 4, 3: 1, 4: 2 };

router.get(
  '/polls',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_polls', {
      Mode: 'GetPolls',
      society_id: SOC50(req.societyId),
      user_id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/polls/:id/votes',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_polls', {
      Mode: 'pollVotes',
      PollId: { type: sql.Int, value: id },
      society_id: SOC50(req.societyId),
      user_id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * POST /community/polls — start a poll. Replaces Vote.aspx.
 *
 * Three steps, in this order, exactly as btnStartPoll_Click did:
 *
 *   1. sp_polls   Mode='INSERT'      -> creates the poll, returns its PollId
 *   2. sp_PollOptions Operation='INSERT' -> splits the comma-joined options
 *                                           into poll_Options rows
 *   3. notify the chosen audience    -> a "New Poll" alert per recipient
 *
 * Steps 1 and 2 are both required. sp_polls writes the option text into the
 * Polls.options column but never creates poll_Options rows, and every read path
 * — GetPolls, pollVotes, SELECTALL — joins poll_Options. A poll created with
 * only the first call has no options to show or vote on.
 */
router.post(
  '/polls',
  asyncHandler(async (req, res) => {
    const topic = str(req.body?.topic, 'topic', { max: 200 });
    const description = optionalStr(req.body?.description, 'description', { max: 1000 });
    const expiryDate = date(req.body?.expiryDate, 'expiryDate');

    const rawOptions = Array.isArray(req.body?.options) ? req.body.options : [];
    const options = rawOptions.map((o) => String(o ?? '').trim()).filter(Boolean);
    if (options.length < 2) throw ApiError.badRequest('Provide at least two options for the poll');
    if (options.some((o) => o.includes(','))) {
      // sp_PollOptions splits on commas with STRING_SPLIT, so a comma inside an
      // option would silently become two options.
      throw ApiError.badRequest('Poll options cannot contain a comma');
    }

    // ddlAudience on Vote.aspx offered exactly these four values.
    const audience = oneOf(
      optionalStr(req.body?.audience, 'audience', { max: 50 }) ?? '1',
      'audience',
      ['1', '2', '3', '4'],
    );

    const joined = options.join(',');

    const created = await exec('sp_polls', {
      Mode: 'INSERT',
      PollId: { type: sql.Int, value: 0 },
      user_id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
      Topic: { type: sql.NVarChar(200), value: topic },
      Description: { type: sql.NVarChar(1000), value: description },
      ExpiryDate: { type: sql.DateTime, value: expiryDate },
      AllowMultipleVotes: {
        type: sql.Int,
        value: req.body?.allowMultipleVotes ? 1 : 0,
      },
      OneVotePerUnit: { type: sql.Int, value: req.body?.oneVotePerUnit ? 1 : 0 },
      Audience: { type: sql.NVarChar(50), value: audience },
      options: { type: sql.NVarChar(sql.MAX), value: joined },
      society_id: SOC50(req.societyId),
    });

    // PollId is per-society (MAX(PollId)+1 within the society), not an identity.
    const pollId = int(created?.PollId, 'PollId', { required: false, default: 0 });
    if (!pollId) throw ApiError.badRequest('The poll could not be created');

    await exec('sp_PollOptions', {
      Operation: 'INSERT',
      PollId: { type: sql.Int, value: pollId },
      Options: { type: sql.NVarChar(sql.MAX), value: joined },
    });

    // The audience value chosen on the form is not the recipients group id;
    // btnStartPoll_Click translates between them (Vote.aspx.cs:84):
    //   1 all members -> 5 · 2 association committee -> 4
    //   3 owners only -> 1 · 4 tenants only          -> 2
    const recipientsId = POLL_AUDIENCE_RECIPIENTS[audience] ?? 0;

    // Best-effort, as in the legacy page: the poll exists either way, and a
    // push failure must not report the creation as failed.
    let notified = 0;
    if (recipientsId) {
      try {
        notified = await notifyGroup({
          societyId: req.societyId,
          recipientsId,
          type: 'Poll',
          id: pollId,
          title: 'New Poll',
          body: 'Your Vote is Valuable',
        });
      } catch {
        notified = 0;
      }
    }

    return ok(res, { poll: created ?? null, PollId: pollId, options, notified }, 201);
  }),
);

/**
 * POST /community/polls/:id/vote — cast a vote on one option.
 *
 * Replaces VoteService.asmx/SaveVote, which the poll card called on click.
 *
 * sp_PollVoting enforces every rule itself and reports back in a `Message`
 * column, so none of it is re-implemented here:
 *
 *   OneVotePerUnit=1     -> rejects if anyone in the same flat already voted
 *   AllowMultipleVotes=0 -> a second vote MOVES the existing one to the new
 *                           option rather than adding another
 *   AllowMultipleVotes=1 -> one vote per option; re-voting the same option is
 *                           rejected
 *
 * The flags come from the poll row, not the request: a client that sent its own
 * could vote as many times as it liked.
 */
router.post(
  '/polls/:id/vote',
  asyncHandler(async (req, res) => {
    const pollId = int(req.params.id, 'id', { min: 1 });
    const optionId = int(req.body?.optionId, 'optionId', { min: 1 });

    const poll = await queryOne('sp_polls', {
      Mode: 'SELECT',
      PollId: { type: sql.Int, value: pollId },
      society_id: SOC50(req.societyId),
    });
    if (!poll) throw ApiError.notFound('Poll not found');

    const result = await exec('sp_PollVoting', {
      Operation: 'INSERT',
      Society_id: { type: sql.NVarChar(10), value: req.societyId },
      User_Id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
      Poll_id: { type: sql.Int, value: pollId },
      Option_id: { type: sql.Int, value: optionId },
      User_type: { type: sql.NVarChar(10), value: req.user.userTypeId ? 'Member' : 'Owner' },
      AllowMultipleVotes: { type: sql.Int, value: Number(poll.AllowMultipleVotes) ? 1 : 0 },
      OneVotePerUnit: { type: sql.Int, value: Number(poll.OneVotePerUnit) ? 1 : 0 },
    });

    // The refusals ("Someone from your flat has already voted…", "Already voted
    // for this option") come back as a Message with no Voting_Id. Surface them
    // as a 400 so the card can say why the click did nothing.
    const message = result?.Message ?? '';
    if (!result || (result.Voting_Id === undefined && !/success/i.test(message))) {
      throw ApiError.badRequest(message || 'Your vote could not be recorded');
    }

    return ok(res, { message, Voting_Id: result.Voting_Id ?? null });
  }),
);

/**
 * DELETE /community/polls/:id
 *
 * 'DELETEALL', not 'DELETE': the plain mode removes only the Polls row, leaving
 * poll_Options and poll_voting rows behind with no parent. DELETEALL clears all
 * three in one transaction, which is what Vote.aspx used
 * (DeletePollFromDatabase sets sql_operation = "deleteall").
 *
 * It also scopes by @user_id, so a poll can only be deleted by whoever started
 * it — the legacy page hid the delete cross on everyone else's cards.
 */
router.delete(
  '/polls/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_polls', {
      Mode: 'DELETEALL',
      PollId: { type: sql.Int, value: id },
      user_id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
      society_id: SOC50(req.societyId),
    });
    return ok(res, { deleted: true, PollId: id });
  }),
);

/* -------------------------------------------------------- notifications */

/* GET /community/notifications is mounted above the society guard, with the
   message count — both are topbar features a village account has too. */

/**
 * PUT /community/notifications/:id/seen — mark one alert as read.
 *
 * The SP's 'UpdateStatus' branch filters `where notify_status_id = @user_id`,
 * so the row id has to be passed as @user_id. That reads like a bug but is what
 * the procedure does, and the legacy page relied on it: DA_User_Login.cs:369
 * assigns details.NoticeId to the "user_id" parameter for exactly this call.
 */
router.put(
  '/notifications/:id/seen',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_dashboard', {
      operation: 'UpdateStatus',
      user_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
    });
    return ok(res, { seen: true, notify_status_id: id });
  }),
);

/* ------------------------------------------------------ resident messages */

/** GET /community/messages — messages residents sent to the committee. */
router.get(
  '/messages',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_owner_master', {
      operation: 'GetMessages',
      society_id: SOC(req.societyId),
    });
    const unread = rows.filter((r) => Number(r.view_status) === 0).length;
    return ok(res, { items: rows, count: rows.length, unread });
  }),
);

/**
 * GET /community/messages/count is mounted above the society guard, with the
 * notifications bell — both are topbar features a village account has too.
 */

/** PUT /community/messages/:id/read — mark one message read. */
router.put(
  '/messages/:id/read',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_owner_master', {
      operation: 'updateViewStatus',
      r_id: { type: sql.Int, value: id },
    });
    return ok(res, { read: true, r_id: id });
  }),
);

module.exports = router;
