// Scheduled jobs, extracted from app.js so they no longer run as a side effect
// of module load. app.js's node-cron and the /api/web/cron HTTP endpoints both
// call the same guarded functions here.
//
// Each job is idempotent in SQL (a period already billed is skipped), so a
// double trigger is safe; the in-process lock below additionally stops a job
// overlapping ITSELF (a slow run meeting the next tick, or node-cron meeting a
// Plesk HTTP trigger).
const db = require('../routes/db');
const firebase = require('../routes/firebase');
const logger = require('./logger');

const running = new Set();

async function runJob(name, fn) {
  if (running.has(name)) {
    logger.warn({ job: name }, 'job already running; skipped');
    return { ran: false, reason: 'already-running' };
  }
  running.add(name);
  const started = Date.now();
  try {
    await fn();
    logger.info({ job: name, ms: Date.now() - started }, 'job completed');
    return { ran: true };
  } catch (err) {
    logger.error({ job: name, err, category: 'cron' }, 'job failed');
    throw err; // let the caller (cron route) surface a 500 so failures are visible
  } finally {
    running.delete(name);
  }
}

async function _sendMaintenanceNotifications() {
  const result = await db.request()
    .input('operation', 'send_notification')
    .execute('sp_maintenance_charges');
  const rows = result.recordset || [];
  for (const row of rows) {
    if (!row.token) continue;
    const message = {
      token: row.token,
      notification: {
        title: 'Maintenance Payment Reminder',
        body: `Hello Resident 👋
This is a gentle reminder that your maintenance payment is pending.

⏳ ${row.remaining_days} days remaining
📅 Due date: ${row.due_date}
💰 Amount: ₹${row.total_amount}

Please make the payment on time to avoid late charges. Thank you!`,
      },
      data: {
        messageType: 'maintenance_payment',
        daysLeft: String(row.daysLeft),
        date: String(row.date),
        amount: String(row.amount),
      },
    };
    try {
      await firebase.messaging().send(message);
    } catch (err) {
      logger.warn({ err: err.message, category: 'fcm' }, 'maintenance notification send failed for one token');
    }
  }
}

async function _cleanupRefreshTokens() {
  await db.request().input('operation', 'AutoTask').execute('ManageRefreshToken');
}

async function _generateSocietyBills() {
  await db.request().execute('gen_bill');
}

async function _generateVillageBills() {
  await db.request().input('operation', 'Auto').execute('sp_village_bill_run');
}

module.exports = {
  sendMaintenanceNotifications: () => runJob('maintenance-notifications', _sendMaintenanceNotifications),
  cleanupRefreshTokens: () => runJob('token-cleanup', _cleanupRefreshTokens),
  generateSocietyBills: () => runJob('society-bills', _generateSocietyBills),
  generateVillageBills: () => runJob('village-bills', _generateVillageBills),
};
