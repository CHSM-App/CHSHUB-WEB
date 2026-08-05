// Website API — Dashboards and reports.
// Replaces dashboard, Admin_Dashboard, agm_report, Audit, BalanceSheet,
// Profit_loss_report, Paid_amountreport, recent_activity and the print pages.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ok, asyncHandler } = require('../../lib/http');
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

/** GET /reports/owner-ledger?ownerId=&buildingId=&from=&to= */
router.get(
  '/owner-ledger',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'ownerwise_maintenance',
      society_id: SOC50(req.societyId),
      owner_id: { type: sql.Int, value: int(req.query.ownerId, 'ownerId', { min: 1 }) },
      build_id: { type: sql.Int, value: int(req.query.buildingId, 'buildingId', { required: false, default: 0 }) },
      date1: { type: sql.SmallDateTime, value: date(req.query.from, 'from') },
      date2: { type: sql.SmallDateTime, value: date(req.query.to, 'to') },
    });
    return ok(res, { items: rows, count: rows.length });
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
 * GET /reports/balance-sheet — society balance sheet.
 * sp_balancesheet is keyed by village_id, but the table stores whichever tenant
 * id was written; pass the society id through the same parameter.
 */
router.get(
  '/balance-sheet',
  asyncHandler(async (req, res) => {
    const [heads, subPoints] = await Promise.all([
      query('sp_balancesheet', {
        operation: 'get_main_points',
        village_id: { type: sql.NVarChar(10), value: req.societyId },
      }),
      query('sp_balancesheet', {
        operation: 'get_sub_point',
        village_id: { type: sql.NVarChar(10), value: req.societyId },
      }),
    ]);
    return ok(res, { heads, subPoints });
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
    await exec('sp_auditor_question_master', {
      operation: 'Update',
      audt_ques_id: { type: sql.Int, value: int(req.body?.questionId, 'questionId', { required: false, default: 0 }) },
      question_desc: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.question, 'question') },
      answer_desc: { type: sql.NVarChar(500), value: optionalStr(req.body?.answer, 'answer', { max: 500 }) },
      status_id: { type: sql.Int, value: int(req.body?.statusId, 'statusId', { required: false, default: 1 }) },
      audit_header_id: { type: sql.Int, value: int(req.body?.headerId, 'headerId', { required: false, default: 0 }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { saved: true }, 201);
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
      village_id: { type: sql.NVarChar(10), value: req.societyId },
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
      village_id: { type: sql.NVarChar(10), value: req.societyId },
    });
    return ok(res, { saved: true }, 201);
  }),
);

/** DELETE /reports/balance-sheet/sub-points/:id */
router.delete(
  '/balance-sheet/sub-points/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_balancesheet', { operation: 'Delete', bal_sub_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, bal_sub_id: id });
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
