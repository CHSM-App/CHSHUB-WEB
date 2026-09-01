 var express = require('express');
var db = require("./db");
var router = express.Router();
var http=require('http');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const auth = require('./middleware/auth');


router.get('/getLoginData/:contact', async (req, res) => {
  try {
    const { contact } = req.params;
 if (!contact) return res.status(400).json({ error: 'Mobile Number required' });
    const result = await db.request()
      .input("operation", "CheckUserByContact")
      .input("contact_no", contact)
      .execute("sp_staff_master");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/getvisitorList',  async (req, res) => {
  try {
    const { SocietyId } = req.query;
 if (!SocietyId) return res.status(400).json({ error: 'SocietyId required' });
    const result = await db.request()
      .input("operation", "GetVisitorList")
      .input("society_id", SocietyId)
      .execute("sp_Visitor");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/getVisitorHistory', async (req, res) => {
  try {
    const { SocietyId, startDate, endDate } = req.query;
    if (!SocietyId) return res.status(400).json({ error: 'SocietyId required' });
    const result = await db.request()
      .input("operation", "GetVisitorHistory")
      .input("society_id", SocietyId)
      .input("start_date", startDate || null)
      .input("end_date", endDate || null)
      .execute("sp_Visitor");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/getRegularVisitor',  async (req, res) => {
  try {
    const { society } = req.query;
if (!society) return res.status(400).json({ error: 'SocietyId required' });
    const result = await db.request()
      .input("operation", "GetRegularVisitor")
      .input("society_id", society)
      .execute("sp_Visitor");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/directory/Residence/:id',  async (req, res) => {
  try {
    const { id } = req.params;
if (!id) return res.status(400).json({ error: 'SocietyId required' });
    const result = await db.request()
      .input("operation", "GetResidenceDirectory")
      .input("society_id", id)
      .execute("sp_owner_master");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/directory/Committee/:id',  async (req, res) => {
  try {
    const { id } = req.params;
if (!id) return res.status(400).json({ error: 'SocietyId required' });
    const result = await db.request()
      .input("operation", "GetCommitteeDirectory")
      .input("society_id", id)
      .execute("sp_UserLogin");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/staffList/:society', function(req, res, next) {
    
     db.request()
            .input("society_id", req.params.society)
            .query("select * from staff_master where active_status=0 and society_id=@society_id", function(err,rows){
         if(err)
            return res.status(500).json({error:err.message});      
        res.json(rows.recordset);
 });
 });
router.get('/staffExitList/:society',  async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input("operation", "GetStaffExitList")
      .input("society_id", society)
      .execute("sp_staff_master");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/Spinner/unit/:society', async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input("operation", "GetUnitList")
      .input("society_id", society)
      .execute("sp_owner_master");

    res.status(200).json(result.recordset);
  } catch (err) {
    console.error("❌ Error in /Spinner/unit/:society:", err); // log full error
    res.status(500).json({ error: err.message, details: err });
  }
});



router.get('/getTokens/:society_id/:type', async (req, res) => {
  try {
    const {  society_id, type } = req.params;

    const result = await db.request()
      .input("operation","GetTokensByFlat")
      .input("society_id", society_id)
      .input("flat_id", type)
      .execute("sp_UserLogin");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/StaffAttendance/:staff_id?', async (req, res) => {
    try {
        const staff_id = req.params.staff_id || 0;

        const result = await db.request()
            .input("operation", "GetAttendace")
            .input("staff_id", parseInt(staff_id))
            .execute("sp_staff_master");

        res.status(200).json({
            success: true,
            records: result.recordset
        });
    } catch (err) {
        console.error('Get Attendance Error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// Get Current Status (Check if staff is checked in)
router.get('/StaffAttendance/status/:staff_id', async (req, res) => {
    try {
        const staff_id = req.params.staff_id;

        const result = await db.request()
            .input("operation", "GetAttendace")
            .input("staff_id", parseInt(staff_id))
            .execute("sp_staff_master");

        const activeRecord = result.recordset.find(r => r.status === 1);

        res.status(200).json({
            success: true,
            isCheckedIn: !!activeRecord,
            currentAttendance: activeRecord || null
        });
    } catch (err) {
        console.error('Get Status Error:', err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

router.get('/GetEmergencyAlertPreference/:society_id/:alert_type', async (req, res) => {
  try {
    const { society_id, alert_type } = req.params;

    if (!society_id || !alert_type) {
      return res.status(400).json({
        success: false,
        message: "society_id and alert_type are required"
      });
    }

    const result = await db.request()
      .input("operation", "GetBySocietyAndType")
      .input("society_id", society_id)
      .input("alert_type", alert_type)
      .execute("sp_emergency_alert_preferences");

    if (result.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        message: "No preference found"
      });
    }

    const data = result.recordset[0];
    data.selected_buildings = data.selected_buildings
      ? JSON.parse(data.selected_buildings)
      : [];

    res.json({ success: true, data });
  } catch (err) {
    console.error("ERROR ===>", err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});


// GET: Get Active Alerts
router.get('/GetActiveAlerts', async (req, res) => {
  try {
   const result = await db.request()
      .input("operation", "GetActive")
      .execute("sp_emergency_alert_preferences");

    const alerts = result.recordset.map(alert => {
      if (alert.selected_buildings) {
        try {
          alert.selected_buildings = JSON.parse(alert.selected_buildings);
        } catch (e) {
          alert.selected_buildings = [];
        }
      }
      return alert;
    });

    res.json({
      success: true,
      data: alerts
    });
  } catch (err) {
    console.error("ERROR ===>", err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});


router.get('/attendance/today/:society_id', async (req, res) => {
  try {
    const { society_id } = req.params;

    const result = await db.request()
      .input("operation", "GetStaffAttendance")
      .input("society_id", society_id)
      .execute("sp_staff_attendance");

    res.status(200).json(result.recordset);
  } catch (err) {
    console.error("❌ Error ", err); // log full error
    res.status(500).json({ error: err.message, details: err });
  }
});

router.get('/buildingList/:society_id', async (req, res) => {
  try {
    const { society_id } = req.params;

    const result = await db.request()
      .input("operation", "SocietywiseBuilding")
      .input("society_id", society_id)
      .execute("sp_emergency_alert_preferences");

    res.status(200).json(result.recordset);
  } catch (err) {
    console.error("❌ Error ", err); // log full error
    res.status(500).json({ error: err.message, details: err });
  }
});

router.get('/committeeContact/:society_id', async (req, res) => {
  try {
    const { society_id } = req.params;

    const result = await db.request()
      .input("operation", "GetCommitteeContact")
      .input("society_id", society_id)
      .execute("sp_Visitor");

    res.status(200).json(result.recordset);
  } catch (err) {
    console.error("❌ Error ", err); // log full error
    res.status(500).json({ error: err.message, details: err });
  }
});

module.exports = router; 