 var createError = require('http-errors');
var express = require('express');
const cron = require('node-cron');
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

require('dotenv').config({ path: __dirname + '/.env' });
var path = require('path');
const cors = require('cors');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
const http = require('http');
var  insertRouter=require('./routes/insert')
var  loginRouter=require('./routes/login')
var  testRouter=require('./routes/test')
var  uploadRouter=require('./routes/uploadfile')
var indexRouter = require('./routes/deleteapi');
var usersRouter = require('./routes/users');
var notifyRouter = require('./routes/notify');
var dataRouter = require('./routes/gatekeeper');
var insertGate = require('./routes/gate_insert');
var communityRouter = require('./routes/community');
var insertCommunity = require('./routes/insert_community');
var fileAccess = require('./routes/fileAccess');
const protect = require('./routes/middleware/protect');
var webApi = require('./web');            // website (admin) API — see web/index.js
var db=require('./routes/db');
var app = express();




// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');
app.use(cors());


app.set('trust proxy', true);  
app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/',   indexRouter);
app.use('/insert', protect, insertRouter);    //should add protected here 
app.use('/test', protect, testRouter);
app.use('/login', loginRouter);
app.use('/users', usersRouter);
app.use('/upload', uploadRouter);
app.use('/data',protect, dataRouter);          //should add protected here
app.use('/community',protect, communityRouter);
app.use('/insert/gate', protect,insertGate);    //should add protected here 
app.use('/insert/community', protect, insertCommunity);
app.use('/notify', protect, notifyRouter);    //should add protected here
app.use('/file', fileAccess);

// Website (admin) API. Self-contained: brings its own auth, validation and
// error handling, so it cannot affect the mobile routes mounted above.
app.use('/api/web', webApi);
app.get('/privacy-policy', (req, res) => {
  res.sendFile(path.join(__dirname, 'routes', 'privacy-policy.html'));
});
app.get('/delete-account', (req, res) => {
  res.sendFile(path.join(__dirname, 'routes', 'delete-account.html'));
});
//catch 404 and forward to error handler


async function sendMaintenancePaymentNotifications() {
  try {
    // 1️⃣ Call stored procedure  
	   const result = await db.request()
	.input('operation','send_notification')
	.execute('sp_maintenance_charges');

    const rows = result.recordset;

    if (!rows || rows.length === 0) {
      console.log("No notification data found.");
      return;
    }

    // 2️⃣ Loop through each row & send notification
    for (const row of rows) {
      if (!row.token) continue;

      const message = {
        token: row.token,
        notification: {
          title: "Maintenance Payment Reminder",
          body: `Hello Resident 👋
This is a gentle reminder that your maintenance payment is pending.

⏳ ${row.remaining_days} days remaining
📅 Due date: ${row.due_date}
💰 Amount: ₹${row.total_amount}

Please make the payment on time to avoid late charges. Thank you!`
        },
        data: {
          messageType: "maintenance_payment",
          daysLeft: String(row.daysLeft),
          date: String(row.date),
          amount: String(row.amount)
        }
      };

      try {
        await admin.messaging().send(message);
        console.log(`Notification sent to token: ${row.token}`);
      } catch (err) {
        console.error(`Failed for token ${row.token}`, err.message);
      }
    }
  } catch (error) {
    console.error("Error sending maintenance notifications:", error);
  }
}



async function cleanupRefreshTokens() {
  try {
   const result = await db.request()
      .input('operation', 'AutoTask')
      .execute('ManageRefreshToken');

  } catch (err) {
   
	  	 console.error(err);
  }
}
/*
 * Village tax bills, the counterpart to GenerateBill above.
 *
 * Called with no village and no period: sp_village_bill_run's 'Auto' branch
 * works out both, the way gen_bill does for societies. It bills each village
 * whose village_setting has auto_bill_generation on and whose bill_gen_day is
 * today, and holds yearly charges back until the month named by
 * property_tax_month so property tax is not attempted every month.
 *
 * Nothing is raised twice: a house and charge already billed for the period is
 * skipped, so a restart on the same day is harmless. That also means the run
 * on boot below costs nothing when the day's bills already exist.
 *
 * node-cron rather than a SQL Server Agent job, matching the society side —
 * the API is deployed to Plesk, where Agent is generally unavailable, and this
 * runs inside the Node process instead.
 */
async function GenerateVillageBill() {
  try {
    await db.request()
      .input('operation', 'Auto')
      .execute('sp_village_bill_run');

  } catch (err) {
    console.error('Village bill generation failed:', err);
  }
}

async function GenerateBill() {
  try {
   const result = await db.request()

      .execute('gen_bill');

  } catch (err) {
    
	 console.error(err);
  }
}
 
app.use((err, req, res, next) => {
  console.error("Unhandled Error:", err);

  // If response already sent (like 401), do nothing
  if (res.headersSent) {
    return next(err);
  }

  return res.status(500).json({ msg: "Internal Server Error" });
});


sendMaintenancePaymentNotifications();
cleanupRefreshTokens();
GenerateBill();
GenerateVillageBill();

//schedule job at 10:00 AM daily
cron.schedule('0 10 * * *', () => {
  GenerateBill()
});

/*
 * Village tax bills at 02:00, not 10:00 like the society run above.
 *
 * Bills are raised overnight so the day's figures do not change under anyone:
 * a run at 10:00 lands while the office is open, and a clerk part-way through
 * taking a payment would see the outstanding amounts grow as they worked.
 * Overnight also means a bad run has hours to be spotted before anyone acts on
 * it, and the month-end is genuinely over by then.
 *
 * 02:00 rather than midnight: backups and other nightly work cluster at 00:00.
 *
 * This only fires if the Node process happens to be running at 02:00, which on
 * Plesk it may not be — an idle app is recycled. GET /api/web/village/bill-run/auto
 * exists for a Plesk scheduled task to call, and that does not depend on this
 * process being up. Both are safe to run: a period already billed is skipped.
 */
cron.schedule('0 2 * * *', () => {
  GenerateVillageBill()
});

//schedule job at 10:00 AM daily
cron.schedule('0 10 * * *', () => {
  sendMaintenancePaymentNotifications();
});

// Schedule the job at 12:00 AM every day
cron.schedule('0 0 * * *', () => {
  cleanupRefreshTokens(); // Call your function here
});




const PORT=process.env.PORT || 8000
app.listen(PORT,function(){
  console.log("Listning on :"+PORT);
})

module.exports = app;
 