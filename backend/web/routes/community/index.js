// Website API — Community.
// Replaces notice_search, event_search, meeting_search/meeting_details,
// facility_booking, visitor_search, support_ticket, suggestion_request,
// upload_doc_search and Vote.
const express = require('express');

const { query, queryOne, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date, time, oneOf } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');
const { notifyGroup } = require('../../lib/notify');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
const SOC50 = (v) => ({ type: sql.NVarChar(50), value: v });

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

    // event_search.aspx has no recipient picker, so everyone is told — group 3,
    // owners and tenants.
    const notified = await notifyGroup({
      societyId: req.societyId,
      recipientsId: 3,
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

    // meeting_search.aspx has no recipient picker either.
    const notified = await notifyGroup({
      societyId: req.societyId,
      recipientsId: 3,
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
    const rows = await query('sp_Visitor', {
      operation: 'Grid_Show',
      society_id: SOC50(req.societyId),
    });
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
    return ok(res, { visitor: created ?? null }, 201);
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
    const rows = await query('sp_helpdesk', {
      operation: 'GetTickets',
      society_id: SOC50(req.societyId),
      owner_id: { type: sql.Int, value: 0 },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/helpdesk/statuses',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_helpdesk', { operation: 'GetAllHelpdeskStatus' });
    return ok(res, { items: rows });
  }),
);

router.get(
  '/helpdesk/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const [ticket, comments] = await Promise.all([
      query('sp_helpdesk', { operation: 'GetRequestById', helpdesk_id: { type: sql.Int, value: id } }),
      query('sp_helpdesk', { operation: 'GetComments', helpdesk_id: { type: sql.Int, value: id } }),
    ]);
    if (!ticket[0]) throw ApiError.notFound('Ticket not found');
    return ok(res, { ticket: ticket[0], comments });
  }),
);

router.put(
  '/helpdesk/:id/status',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_helpdesk', {
      operation: 'UpdateStatus',
      helpdesk_id: { type: sql.Int, value: id },
      status: { type: sql.Int, value: int(req.body?.status, 'status', { min: 1 }) },
    });
    return ok(res, { helpdesk_id: id });
  }),
);

router.post(
  '/helpdesk/:id/comments',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_helpdesk', {
      operation: 'InsertComments',
      helpdesk_id: { type: sql.Int, value: id },
      owner_id: { type: sql.Int, value: req.user.ownerId ?? req.user.userId },
      flat_id: { type: sql.Int, value: int(req.body?.flatId, 'flatId', { required: false, default: 0 }) },
      type: { type: sql.NVarChar(50), value: optionalStr(req.body?.type, 'type', { max: 50 }) || 'Admin' },
      description: { type: sql.NVarChar(sql.MAX), value: str(req.body?.comment, 'comment') },
    });
    return ok(res, { added: true }, 201);
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

/**
 * GET /community/notifications — the bell dropdown in Site.Master.
 *
 * sp_dashboard 'Notification' returns only unseen rows (seen_status = 0) for
 * this society and user, newest first, with `timestamp` already run through
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
      society_id: SOC(req.societyId),
      user_id: { type: sql.Int, value: req.user.userId },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

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
 * GET /community/messages/count — unread badge.
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
      society_id: SOC(req.societyId),
    });
    const unread = rows.filter((r) => Number(r.view_status) === 0).length;
    return ok(res, { unread });
  }),
);

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
