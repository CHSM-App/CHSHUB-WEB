// Website API — Dashboards and reports.
// Replaces dashboard, Admin_Dashboard, agm_report, Audit, BalanceSheet,
// Profit_loss_report, Paid_amountreport, recent_activity and the print pages.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ok, asyncHandler, ApiError } = require('../../lib/http');
const { int, num, str, date, optionalStr } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
const SOC50 = (v) => ({ type: sql.NVarChar(50), value: v });

/** GET /reports/dashboard — headline figures for the landing page. */
router.get(
  '/dashboard',
  asyncHandler(async (req, res) => {
    const soc = SOC50(req.societyId);

    // Each of these is an independent SP branch; one failing should not blank
    // the whole dashboard, so failures degrade to empty rather than throwing.
    const safe = (p) => p.catch(() => []);

    const [tickets, residents, income, monthly, activity, defaulters, updates] = await Promise.all([
      safe(query('sp_dashboard', { operation: 'Get_Ticket', society_id: soc })),
      safe(query('sp_dashboard', { operation: 'getResidents', society_id: soc })),
      safe(
        query('sp_dashboard', {
          operation: 'IncomeChart',
          society_id: soc,
          date2: { type: sql.SmallDateTime, value: new Date() },
        }),
      ),
      safe(query('sp_dashboard', { operation: 'Get_Month', society_id: soc })),
      safe(query('sp_dashboard', { operation: 'RecentActivity', society_id: soc })),
      safe(query('sp_dashboard', { operation: 'defaulter_show', society_id: soc })),
      // Weekly Updates card on dashboard.aspx.
      safe(query('sp_dashboard', { operation: 'Updates', society_id: soc })),
    ]);

    return ok(res, {
      tickets: tickets[0] ?? null,
      residentCount: residents[0]?.residents ?? 0,
      incomeSplit: income,
      monthlyDues: monthly,
      recentActivity: activity.slice(0, 20),
      weeklyUpdates: updates,
      defaulters: { count: defaulters.length, totalDue: defaulters.reduce((s, r) => s + Number(r.due || 0), 0) },
    });
  }),
);

/**
 * GET /reports/income-split?to= — the Income Tracker donut for a period.
 *
 * Backs the ⋮ menu on dashboard.aspx (This Month / Last Month / This Year).
 * Note the SP ignores its @date1: it forces the start to MIN(gen_date) and
 * only applies @date2 as the upper bound, so the three options differ solely
 * in where the period ends. Kept as-is rather than "fixed" — the numbers must
 * match what the legacy dashboard showed.
 */
router.get(
  '/income-split',
  asyncHandler(async (req, res) => {
    const to = date(req.query.to, 'to', { required: false }) ?? new Date();
    const rows = await query('sp_dashboard', {
      operation: 'IncomeChart',
      society_id: SOC50(req.societyId),
      date2: { type: sql.SmallDateTime, value: to },
    });
    return ok(res, { items: rows });
  }),
);

/** GET /reports/expense-chart?type=  — 2 = all, otherwise bill_type. */
router.get(
  '/expense-chart',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'ExpenseChart',
      society_id: SOC50(req.societyId),
      expense: { type: sql.Int, value: int(req.query.type, 'type', { required: false, default: 2 }) },
    });
    return ok(res, { items: rows });
  }),
);

/** GET /reports/activity — full recent-activity feed. */
router.get(
  '/activity',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'RecentActivityAll',
      society_id: SOC50(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /reports/owner-ledger?ownerId=&buildingId=&from=&to=
 * ownerwise_maintenance.aspx — "Owner wise Maintenance Bill Reports".
 *
 * The SP returns four kinds of row, tagged by `seq`: 1 opening balance,
 * 2 the transactions, 3 total balance, 4 closing balance. The legacy grid
 * highlighted 1, 3 and 4 with CSS nth-child rules; `seq` carries that
 * intent properly, so the page colours off it.
 *
 * Its Period and transaction CTEs both filter on build_id, so a request
 * without one returns the balance rows and no transactions at all — the
 * legacy page always had a building selected (Page_Load defaulted it to 1),
 * so buildingId is required here rather than quietly defaulting to 0.
 */
router.get(
  '/owner-ledger',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'ownerwise_maintenance',
      society_id: SOC50(req.societyId),
      owner_id: { type: sql.Int, value: int(req.query.ownerId, 'ownerId', { min: 1 }) },
      build_id: { type: sql.Int, value: int(req.query.buildingId, 'buildingId', { min: 1 }) },
      date1: { type: sql.SmallDateTime, value: date(req.query.from, 'from') },
      date2: { type: sql.SmallDateTime, value: date(req.query.to, 'to') },
    });

    // Only seq = 2 rows are real transactions; the rest are computed balances
    // and would double-count in a total.
    const tx = rows.filter((r) => Number(r.seq) === 2);
    return ok(res, {
      items: rows,
      count: tx.length,
      totals: {
        maintenance: tx.reduce((s, r) => s + Number(r.Maintenance || 0), 0),
        payment: tx.reduce((s, r) => s + Number(r.Payment || 0), 0),
      },
    });
  }),
);

/** GET /reports/agm?from=&to= — income/expense heads for the AGM report. */
router.get(
  '/agm',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'GetAgm',
      SocietyID: SOC(req.societyId),
      start_date: { type: sql.Date, value: date(req.query.from, 'from') },
      end_date: { type: sql.Date, value: date(req.query.to, 'to') },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /reports/income-expense — year-on-year income vs expense.
 * Uses the auditor SP's Grid_Bind_CD branch, which full-outer-joins
 * yearwise_income and yearwise_expense.
 */
router.get(
  '/income-expense',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_auditor_question_master', {
      operation: 'Grid_Bind_CD',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /reports/admin-dashboard — platform view across societies.
 * Replaces Admin_Dashboard.aspx.
 */
router.get(
  '/admin-dashboard',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'society_receipt',
      society_id: SOC50(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /reports/dashboard-updates — upcoming notices, events and meetings. */
router.get(
  '/updates',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'Updates',
      society_id: SOC50(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /reports/profit-loss?from=&to=
 * Income (vw_agm_union) against expenditure (vw_ExpenseDetails), which is what
 * Profit_loss_report.aspx and v_profite_loss.aspx render.
 */
router.get(
  '/profit-loss',
  asyncHandler(async (req, res) => {
    const pool = await require('../../lib/db').getPool();
    const from = date(req.query.from, 'from');
    const to = date(req.query.to, 'to');

    const result = await pool
      .request()
      .input('society_id', sql.NVarChar(10), req.societyId)
      .input('from', sql.Date, from)
      .input('to', sql.Date, to)
      .query(`
        SELECT 'income' AS side, description, SUM(amount) AS amount
        FROM   vw_agm_union
        WHERE  society_id = @society_id AND gen_date BETWEEN @from AND @to
        GROUP  BY description
        UNION ALL
        SELECT 'expense' AS side, description, SUM(total_paid) AS amount
        FROM   vw_ExpenseDetails
        WHERE  society_id = @society_id AND bill_date BETWEEN @from AND @to
        GROUP  BY description`);

    const rows = result.recordset;
    const income = rows.filter((r) => r.side === 'income');
    const expense = rows.filter((r) => r.side === 'expense');
    const sum = (list) => list.reduce((s, r) => s + Number(r.amount || 0), 0);

    return ok(res, {
      income,
      expense,
      totalIncome: sum(income),
      totalExpense: sum(expense),
      surplus: sum(income) - sum(expense),
    });
  }),
);

/**
 * GET /reports/paid-amounts?from=&to= — collections in a period.
 * Replaces Paid_amountreport.aspx.
 */
router.get(
  '/paid-amounts',
  asyncHandler(async (req, res) => {
    const pool = await require('../../lib/db').getPool();
    const result = await pool
      .request()
      .input('society_id', sql.NVarChar(10), req.societyId)
      .input('from', sql.Date, date(req.query.from, 'from'))
      .input('to', sql.Date, date(req.query.to, 'to'))
      .query(`
        SELECT receipt_no, [date], name, unit, paid_amount, pay_mode,
               transaction_ref, bill_status, Billno, bill_ref
        FROM   receipt_search_vw
        WHERE  society_id = @society_id AND CAST([date] AS DATE) BETWEEN @from AND @to
        ORDER  BY [date] DESC`);

    const rows = result.recordset;
    return ok(res, {
      items: rows,
      count: rows.length,
      total: rows.reduce((s, r) => s + Number(r.paid_amount || 0), 0),
    });
  }),
);

/**
 * The tenant id sp_balancesheet is keyed by, read the way BalanceSheet.aspx
 * read it.
 *
 * Every other page in the legacy app passed Session["society_id"]; the balance
 * sheet alone passed Session["village_id"] (BalanceSheet.aspx.cs:81, 91, 206,
 * 222, 237). For a society login that session value is empty, so the rows it
 * wrote carry village_id = '' and it reads them back by the same empty string.
 *
 * That is why the ASPX renders a sheet the API could not find: sending the real
 * society id matches nothing. Matching the legacy key keeps the two pages
 * showing the same rows.
 *
 * It is a bug in the legacy page — an empty key is shared by every society, so
 * those rows are effectively global. Once the rows are assigned to a society,
 * this falls back to the society id on its own and the helper can go away.
 */
const balanceTenant = (req) => ({
  type: sql.NVarChar(10),
  value: req.user?.villageId ?? '',
});

/**
 * GET /reports/balance-sheet — society balance sheet.
 *
 * Reads by the legacy tenant key, then falls back to the society id so a sheet
 * written under a proper id is still found.
 */
router.get(
  '/balance-sheet',
  asyncHandler(async (req, res) => {
    const fetch = (tenant) =>
      Promise.all([
        query('sp_balancesheet', {
          operation: 'get_main_points',
          village_id: tenant,
        }),
        query('sp_balancesheet', {
          operation: 'get_sub_point',
          village_id: tenant,
        }),
      ]);

    let [heads, subPoints] = await fetch(balanceTenant(req));

    // Nothing under the legacy key — try the society id, which is what a sheet
    // created through this API is stored under.
    if (heads.length === 0) {
      [heads, subPoints] = await fetch({ type: sql.NVarChar(10), value: req.societyId });
    }

    // get_sub_point is not filtered by head, so it returns the tenant's every
    // sub-point; keep only those belonging to a head that was actually read.
    const headIds = new Set(heads.map((h) => Number(h.bal_head_id)));
    return ok(res, { heads, subPoints: subPoints.filter((s) => headIds.has(Number(s.bal_head_id))) });
  }),
);

/**
 * GET /reports/shop-maintenance?payMethod=&date= — printshop.aspx's report.
 *
 * The legacy page built its WHERE clause by concatenating the two filter boxes
 * straight into SQL (`pay_method like '<text>%'`, `m_date = '<text>'`) and ran
 * it through a raw command. Both branches read the same shop_vw rows the
 * Grid_Show branch returns, so this asks the SP for those and filters here —
 * same result, without the injection.
 *
 * The filter values are the distinct pay_method values already on the society's
 * rows, which is what filldrop() offered in the dropdown.
 */
router.get(
  '/shop-maintenance',
  asyncHandler(async (req, res) => {
    const payMethod = optionalStr(req.query.payMethod, 'payMethod', { max: 50 });
    const on = date(req.query.date, 'date', { required: false });

    const rows = await query('sp_shop_maintenance', {
      operation: 'Grid_Show',
      society_id: SOC50(req.societyId),
    });

    // `like '<text>%'` in the original — a prefix match, not equality.
    const byMethod = payMethod
      ? rows.filter((r) => String(r.pay_method ?? '').toLowerCase().startsWith(payMethod.toLowerCase()))
      : rows;
    const items = on
      ? byMethod.filter((r) => r.m_date && new Date(r.m_date).toDateString() === on.toDateString())
      : byMethod;

    // The dropdown listed the methods present on this society's rows.
    const payMethods = [...new Set(rows.map((r) => r.pay_method).filter(Boolean))].sort();

    return ok(res, {
      items,
      count: items.length,
      total: items.reduce((s, r) => s + Number(r.amt || 0), 0),
      payMethods,
    });
  }),
);

/* ------------------------------------------------------------------- audit */

router.get(
  '/audit/headers',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_auditor_question_master', {
      operation: 'get_main_points',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/audit/questions',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_auditor_question_master', {
      operation: 'get_questions',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/audit/society-info',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_auditor_question_master', {
      operation: 'get_Society_Info',
      society_id: SOC(req.societyId),
    });
    return ok(res, { info: rows[0] ?? null });
  }),
);

router.post(
  '/audit/headers',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_auditor_question_master', {
      operation: 'insert_header',
      audit_header_id: { type: sql.Int, value: int(req.body?.headerId, 'headerId', { required: false, default: 0 }) },
      audt_header_desc: {
        type: sql.NVarChar(100),
        value: optionalStr(req.body?.description, 'description', { max: 100 }),
      },
      status_id: { type: sql.Int, value: int(req.body?.statusId, 'statusId', { required: false, default: 1 }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { audt_header_id: created?.audt_header_id ?? null }, 201);
  }),
);

router.post(
  '/audit/questions',
  asyncHandler(async (req, res) => {
    const headerId = int(req.body?.headerId, 'headerId', { required: false, default: 0 });

    // A question saved against another society's header is returned by
    // get_questions but its header is not returned by get_main_points, so the
    // page shows it as "unsectioned" with no way to fix it. The SP now rejects
    // this too; checking here turns that into a clear 400 rather than the
    // generic 500 a RAISERROR would produce.
    const [header] = await query('sp_auditor_question_master', {
      operation: 'get_main_points',
      society_id: SOC(req.societyId),
    }).then((rows) => rows.filter((r) => Number(r.audt_header_id) === headerId));

    if (!header) throw ApiError.badRequest('That audit section does not belong to this society');

    await exec('sp_auditor_question_master', {
      operation: 'Update',
      audt_ques_id: { type: sql.Int, value: int(req.body?.questionId, 'questionId', { required: false, default: 0 }) },
      question_desc: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.question, 'question') },
      answer_desc: { type: sql.NVarChar(500), value: optionalStr(req.body?.answer, 'answer', { max: 500 }) },
      status_id: { type: sql.Int, value: int(req.body?.statusId, 'statusId', { required: false, default: 1 }) },
      audit_header_id: { type: sql.Int, value: headerId },
      society_id: SOC(req.societyId),
    });
    return ok(res, { saved: true }, 201);
  }),
);

/**
 * POST /reports/audit/headers/sequence — reorder the sections.
 *
 * Audit.aspx let the auditor drag the main points into order and saved the
 * whole arrangement in one go (btnSaveSequence_Click looped the dragged list
 * through the SP's Update_Sequence branch). get_main_points already returns
 * them ordered by SequenceOrder, so this is what makes that ordering settable.
 */
router.post(
  '/audit/headers/sequence',
  asyncHandler(async (req, res) => {
    const items = Array.isArray(req.body?.items) ? req.body.items : [];
    if (items.length === 0) throw ApiError.badRequest('items is required');

    // Validated up front so a bad entry cannot leave the order half-applied.
    const ordered = items.map((item, i) => ({
      headerId: int(item?.headerId, `items[${i}].headerId`, { min: 1 }),
      sequence: int(item?.sequence, `items[${i}].sequence`, { min: 1 }),
    }));

    for (const { headerId, sequence } of ordered) {
      await exec('sp_auditor_question_master', {
        operation: 'Update_Sequence',
        audit_header_id: { type: sql.Int, value: headerId },
        sequence: { type: sql.Int, value: sequence },
        society_id: SOC(req.societyId),
      });
    }
    return ok(res, { saved: true, count: ordered.length });
  }),
);

/* ------------------------------------------------- balance sheet editing */

/** POST /reports/balance-sheet/heads — add or update a head. */
router.post(
  '/balance-sheet/heads',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_balancesheet', {
      operation: 'insert_header',
      bal_head_id: { type: sql.Int, value: int(req.body?.headId, 'headId', { required: false, default: 0 }) },
      bal_header_desc: { type: sql.NVarChar(100), value: str(req.body?.description, 'description', { max: 100 }) },
      amount: { type: sql.Decimal(18, 2), value: num(req.body?.amount, 'amount', { min: 0, required: false, default: 0 }) },
      status_id: { type: sql.Int, value: int(req.body?.statusId, 'statusId', { required: false, default: 1 }) },
      Seq_order: { type: sql.Int, value: int(req.body?.seqOrder, 'seqOrder', { required: false, default: 0 }) },
      comp_id: { type: sql.Int, value: int(req.body?.compId, 'compId', { required: false, default: 0 }) },
      // Written under the same key it is read by, so an edit does not move the
      // head out of the sheet it was edited from.
      village_id: balanceTenant(req),
    });
    return ok(res, { bal_head_id: created?.bal_head_id ?? null }, 201);
  }),
);

/** POST /reports/balance-sheet/sub-points — add or update a sub-point. */
router.post(
  '/balance-sheet/sub-points',
  asyncHandler(async (req, res) => {
    await exec('sp_balancesheet', {
      operation: 'Update',
      bal_sub_id: { type: sql.Int, value: int(req.body?.subId, 'subId', { required: false, default: 0 }) },
      bal_head_id: { type: sql.Int, value: int(req.body?.headId, 'headId', { min: 1 }) },
      bal_sub_desc: { type: sql.NVarChar(50), value: str(req.body?.description, 'description', { max: 50 }) },
      amount: { type: sql.Decimal(18, 2), value: num(req.body?.amount, 'amount', { min: 0, required: false, default: 0 }) },
      status_id: { type: sql.Int, value: int(req.body?.statusId, 'statusId', { required: false, default: 1 }) },
      village_id: balanceTenant(req),
    });
    return ok(res, { saved: true }, 201);
  }),
);

/**
 * POST /reports/balance-sheet/heads/sequence — reorder the heads.
 *
 * BalanceSheet.aspx let the two columns be dragged and saved the whole
 * arrangement in one go (btnSaveSequence_Click looped the dragged list through
 * the SP's Update_Seq_order branch). get_main_points already returns the heads
 * ordered by Seq_order, so this is what makes that ordering settable.
 */
router.post(
  '/balance-sheet/heads/sequence',
  asyncHandler(async (req, res) => {
    const items = Array.isArray(req.body?.items) ? req.body.items : [];
    if (items.length === 0) throw ApiError.badRequest('items is required');

    // Validated up front so a bad entry cannot leave the order half-applied.
    const ordered = items.map((item, i) => ({
      headId: int(item?.headId, `items[${i}].headId`, { min: 1 }),
      sequence: int(item?.sequence, `items[${i}].sequence`, { min: 1 }),
    }));

    for (const { headId, sequence } of ordered) {
      await exec('sp_balancesheet', {
        operation: 'Update_Seq_order',
        bal_head_id: { type: sql.Int, value: headId },
        Seq_order: { type: sql.Int, value: sequence },
        village_id: balanceTenant(req),
      });
    }
    return ok(res, { saved: true, count: ordered.length });
  }),
);

/**
 * The heads the caller's sheet is built from, by id. Used to check ownership
 * before a delete — the SP's Delete branches take only an id, so without this
 * any society could remove another's rows by guessing one.
 */
const readOwnHeadIds = async (req) => {
  const tenant = balanceTenant(req);
  let heads = await query('sp_balancesheet', { operation: 'get_main_points', village_id: tenant });
  if (heads.length === 0) {
    heads = await query('sp_balancesheet', {
      operation: 'get_main_points',
      village_id: { type: sql.NVarChar(10), value: req.societyId },
    });
  }
  return new Set(heads.map((h) => Number(h.bal_head_id)));
};

/** DELETE /reports/balance-sheet/sub-points/:id */
router.delete(
  '/balance-sheet/sub-points/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    // The sub-point has to hang off one of this sheet's heads.
    const subs = await query('sp_balancesheet', { operation: 'Select', bal_sub_id: { type: sql.Int, value: id } });
    const sub = subs[0];
    if (!sub) throw ApiError.badRequest('That sub-point does not exist');

    const ownHeads = await readOwnHeadIds(req);
    if (!ownHeads.has(Number(sub.bal_head_id))) {
      throw ApiError.badRequest('That sub-point does not belong to this society');
    }

    await exec('sp_balancesheet', { operation: 'Delete', bal_sub_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, bal_sub_id: id });
  }),
);

/**
 * DELETE /reports/balance-sheet/heads/:id — remove a whole head.
 *
 * BalanceSheet.aspx could add and edit heads but never remove one, so the SP
 * had no branch for it; FIX_balancesheet_delete_and_ids.sql adds DeleteHeader,
 * which hides the head and its sub-points together. Applying that script is
 * what makes this route work.
 */
router.delete(
  '/balance-sheet/heads/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const ownHeads = await readOwnHeadIds(req);
    if (!ownHeads.has(id)) throw ApiError.badRequest('That head does not belong to this society');

    await exec('sp_balancesheet', {
      operation: 'DeleteHeader',
      bal_head_id: { type: sql.Int, value: id },
      village_id: balanceTenant(req),
    });
    return ok(res, { deleted: true, bal_head_id: id });
  }),
);

/** DELETE /reports/audit/questions/:id */
router.delete(
  '/audit/questions/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_auditor_question_master', {
      operation: 'Delete',
      audt_ques_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, audt_ques_id: id });
  }),
);

module.exports = router;
