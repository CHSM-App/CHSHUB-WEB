// Website API — Community.
// Replaces notice_search, event_search, meeting_search/meeting_details,
// facility_booking, visitor_search, support_ticket, suggestion_request,
// upload_doc_search and Vote.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date, time } = require('../../lib/validate');
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
 * Options are stored as one comma-joined string in Polls.options, which is what
 * the legacy page wrote (`string.Join(",", optionsList)`); it also required at
 * least two, so that rule is kept.
 *
 * Audience maps to a recipients group in the legacy page:
 *   1 all members · 2 associate committee · 3 managing committee
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
      // options is a comma-joined column, so a comma inside an option would
      // silently split it into two.
      throw ApiError.badRequest('Poll options cannot contain a comma');
    }

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
      Audience: {
        type: sql.NVarChar(50),
        value: optionalStr(req.body?.audience, 'audience', { max: 50 }) ?? '1',
      },
      options: { type: sql.NVarChar(sql.MAX), value: options.join(',') },
      society_id: SOC50(req.societyId),
    });

    return ok(res, { poll: created ?? null, options }, 201);
  }),
);

/** DELETE /community/polls/:id */
router.delete(
  '/polls/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_polls', {
      Mode: 'DELETE',
      PollId: { type: sql.Int, value: id },
      society_id: SOC50(req.societyId),
    });
    return ok(res, { deleted: true, PollId: id });
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

/** GET /community/messages/count — unread badge. */
router.get(
  '/messages/count',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_owner_master', {
      operation: 'get_messages_count',
      society_id: SOC(req.societyId),
    });
    return ok(res, { unread: rows[0]?.message_count ?? 0 });
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
