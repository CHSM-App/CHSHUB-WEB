var express = require('express');
var db = require("./db");
const { pool } = require('mssql');
var router = express.Router();
const auth =  require('./middleware/auth');


router.get('/checkUser/:email/:pass', async (req, res) => {
  try {
    const { email, pass } = req.params;

    const result = await db.request()
      .input("operation", "login")
      .input("UserName", email)
      .input("password", pass)
      .execute("validateUser");

    res.json(result.recordset);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

	
router.get('/Login/:society', async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input("operation", "getData")
      .input("Society_id", society)
      .execute("validateUser");

    res.json(result.recordset);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

router.get('/IncomeTracker/:society', async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input("operation", "IncomeChart")
      .input("Society_id", society)
      .execute("sp_dashboard");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Spinner/Build/:society', async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input("operation", "Grid_show")
      .input("society_id", society)
      .execute("sp_building_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Spinner/Vendor/:society', async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input("operation", "Grid_show")
      .input("society_id", society)
      .execute("sp_vendor_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/Spinner/NoticeRecipient', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "GetAllRecipients")
      .execute("sp_notice_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/Spinner/Helpdesk/Status', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "GetAllHelpdeskStatus")
      .execute("sp_helpdesk");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


 // ✅ Example: Safe & Modern Refactored Routes
router.get('/getOwnerList/:id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "GetOwnerList")
      .input("society_id", req.params.id)
      .execute("sp_owner_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/openMeetings/:society', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "Grid_Show")
      .input("society_id", req.params.society)
      .execute("sp_meeting_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/staff/Role/:society', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "Role_show")
      .input("society_id", req.params.society)
      .execute("sp_staff_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/staff/:society', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "Get_Staff")
      .input("society_id", req.params.society)
      .execute("sp_staff_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/getDefaulter/:b_id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "getDefaulter")
      .input("society_id", req.params.b_id)
      .execute("sp_owner_master");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Helpdesk/:id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "Get_Request")
      .input("society_id", req.params.id)
      .execute("sp_helpdesk");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/GetApprovers/:society_id/:user_id', async (req, res) => {
  try {
    const result = await db.request()
      .input("Operation", "add_approver")
      .input("user_id", req.params.user_id)
      .input("society_id", req.params.society_id)
      .execute("sp_society_expense");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/HelpRequestById/:id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "GetRequestById")
      .input("helpdesk_id", req.params.id)
      .execute("sp_helpdesk");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/HelpdeskComments/:id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "GetComments")
      .input("helpdesk_id", req.params.id)
      .execute("sp_helpdesk");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/GetAllExpense/:id/:user_id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "GetAllExpense")
      .input("user_id", req.params.user_id)
      .input("society_id", req.params.id)
      .execute("sp_society_expense");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Getslots/Facility/:facility_id/:society_id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "Grid_Show_Slot")
      .input("facility_id", req.params.facility_id)
      .input("society_id", req.params.society_id)
      .execute("sp_facility");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/RequestCount/:id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "ExpenseCount")
      .input("society_id", req.params.id)
      .execute("sp_society_expense");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/DueMonth/:society_id', async (req, res) => {
  try {
    const result = await db.request()
      .input("operation", "Get_month")
      .input("society_id", req.params.society_id)
      .execute("sp_dashboard");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router; 