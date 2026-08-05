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

//schedule job at 10:00 AM daily
cron.schedule('0 10 * * *', () => {
  GenerateBill()
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
 