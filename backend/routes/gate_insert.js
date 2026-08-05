var express = require('express');
var db = require("./db");
const sql = require('mssql'); 
//const { pool } = require('mssql');
var router = express.Router();
const auth = require('./middleware/auth');
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

function timeStringToUtcDate(timeStr) {
  if (!timeStr) return null;

  const [h, m, s = 0] = timeStr.split(':').map(Number);
  return new Date(Date.UTC(1970, 0, 1, h, m, s));
}


router.post('/visitor',  async (req, res) => {
  try {
    const {
      flat_id,
      v_name,
      vehicle_no,
      in_date,
      type,
      society_id,
      contact_no,
      purpose,
      image,
      in_user_id,
      Approver_Name,
      status,
      visitor_id
    } = req.body;

    const result = await db.request()
      .input("operation", "Update")
      .input("flat_id", flat_id)
      .input("v_name", v_name)
      .input("vehicle_no", vehicle_no)
      .input("in_date", in_date)
      .input("type", type)
      .input("society_id", society_id)
      .input("contact_no", contact_no)
      .input("purpose", purpose)
      .input("image", image)
      .input("in_user_id", in_user_id)
      .input("Approver_Name", Approver_Name)
      .input("status", status)
      .input("visitor_id", visitor_id)
      .execute("sp_Visitor");

    // Return the newly created/updated visitor_id
    return res.status(200).json({
      visitor_id: result.recordset[0]?.visitor_id || 0
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

router.post('/updateVisitor',  async (req, res) => {
  try {
    const { action, user_id, visitor_id } = req.body;

    const result = await db.request()
      .input("operation", action === "IN" ? "VisitorCheckIn" : "VisitorCheckOut")
      .input("in_user_id", user_id)
      .input("visitor_id", visitor_id)
      .execute("sp_Visitor");

    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

router.post('/StaffEntry',  async (req, res) => {
  try {
    const { action, staff_id, user_id } = req.body;

    await db.request()
      .input("operation", action === "IN" ? "StaffCheckIn" : "StaffCheckOut")
      .input("staff_id", staff_id)
      .input("user_id", user_id)
      .execute("sp_staff_master");

    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

router.post('/Visitor/ApproveStatus/:id',  async (req, res) => {
  try {
    const { id } = req.params;
    const { name, status, preference } = req.body;

    await db.request()
      .input("operation", "UpdateApproveStatus")
      .input("visitor_id", id)
      .input("Approver_Name", name)
      .input("status", status)
      .input("preference", preference || null)
      .execute("sp_Visitor");

    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});


router.post('/updateGateKeeper12/:staff_id', async (req, res) => {
  try {
    const { staff_id } = req.params;
    const { name, address, contact_no, email } = req.body;

    await db.request()
      .input("operation", "UpdateGateKeeper")
      .input("staff_id",  parseInt(staff_id)) 
      .input("name", name)
      .input("address", address)
      .input("contact_no", contact_no)
      .input("email", email)
      .execute("sp_staff_master");

    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
// Correct route - remove extra "gate"
router.post('/updateGateKeeper/:staff_id', async (req, res) => {
  try {
    const { staff_id } = req.params;
    const { name, address, contact_no, email } = req.body;
    
    await db.request()
      .input("operation", "UpdateGateKeeper")
      .input("staff_id", parseInt(staff_id)) 
      .input("name", name)
      .input("address", address)
      .input("contact_no", contact_no)
      .input("email", email)
      .execute("sp_staff_master");
      
    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

router.post('/AddVisitor/Guest', async (req, res) => {
  try {
    const { flat_id, v_name, pre_date, contact_no,purpose,society_id,location,image } = req.query;

   const result= await db.request()
      .input("operation", "Update")
      .input("flat_id", flat_id)
      .input("v_name", v_name)
      .input("in_date", pre_date)
      .input("contact_no", contact_no)
      .input("purpose", purpose)
    .input("society_id", society_id)
       .input("location", location)
	   .input("type", "Guest") 
    .input("status", 2) 
      .execute("sp_Visitor");

res.status(200).json({success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/AddVisitor/Cab', async (req, res) => {
  try {
    const { flat_id, v_name, vehical_no, pre_date, contact_no,company,society_id,location } = req.query;

   const result= await db.request()
      .input("operation", "Update")
      .input("flat_id", flat_id)
      .input("v_name", v_name)
      .input("vehicle_no", vehical_no)
      .input("in_date", pre_date)
      .input("contact_no", contact_no)
    .input("company", company)
    .input("society_id", society_id)
       .input("location", location)
	   .input("type", "Cab")
      .input("status", 2) 
      .execute("sp_Visitor");

res.status(200).json({ success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/AddVisitor/Service', async (req, res) => {
  try {
    const { flat_id, v_name, pre_date, contact_no, company, vehical_no, society_id } = req.query;

    const result = await db.request()
      .input("operation", "Update")
      .input("flat_id", flat_id)
      .input("v_name", v_name)
      .input("in_date", pre_date)
      .input("contact_no", contact_no)
      .input("company", company)
      .input("vehicle_no", vehical_no)
      .input("society_id", society_id)
      .input("type", "Service")
      .input("status", 2)
      .execute("sp_Visitor");

    res.status(200).json({
      success: true,
      visitor_id: result.recordset[0].visitor_id,
      gateOtp: result.recordset[0].gateOtp
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


router.post('/AddVisitor/Delivery', async (req, res) => {
  try {
    const { flat_id, v_name, pre_date, contact_no,purpose,company,vehical_no,society_id } = req.query;

   const result= await db.request()
      .input("operation", "Update")
      .input("flat_id", flat_id)
      .input("v_name", v_name)
      .input("in_date", pre_date)
      .input("contact_no", contact_no)
     .input("purpose", purpose)
     .input("company", company)
  .input("vehicle_no", vehical_no)
   .input("society_id", society_id)
	   .input("type", "Delivery")
      .input("status", 2) 
      .execute("sp_Visitor");

res.status(200).json({success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/updateToken', async (req, res) => {
  try {
    const { staff_id } = req.params;

    const result = await db.request()
      .input("operation", "updateToken")
      .input("staff_id", staffId)
	  .input("token", token)
      .execute("sp_staff_master");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/VisitorInsideStatus', async (req, res) => {
  try {
    const { visitor_id } = req.query;

    const result = await db.request()
      .input("operation", "VisitorIn")
      .input("visitor_id", visitor_id)
      .execute("sp_Visitor");

    res.status(200).json({ message: "Successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/updatePreVisitorStatus', async (req, res) => {
  try {
    const { visitor_id, entry_type, guest_name } = req.query;

    const result = await db.request()
      .input("operation", "VisitorIn")
      .input("visitor_id", visitor_id)
      .execute("sp_Visitor");

    // 👉 Extract token list from DB result
    const tokens = result.recordset
      .map(r => r.token)
      .filter(t => !!t); // remove null/empty

    if (!tokens.length) {
      return res.status(200).json({
        message: "Updated, but no tokens available",
        data: result.recordset
      });
    }

    const message = {
      notification: {
        title: `${entry_type} Arrived`,
        body: `${guest_name} has Arrived at the society`
      },
      data: {
        messageType: 'visitor_Pre_entry'
      },
      tokens
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    return res.status(200).json({
      message: "Notification sent successfully",
      notificationResult: response,
      data: result.recordset
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


router.post('/VisitorWaitingStatus', async (req, res) => {
  try {
    const { visitor_id } = req.query;

    const result = await db.request()
      .input("operation", "VisitorOut")
      .input("visitor_id", visitor_id)
      .execute("sp_Visitor");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/StaffAttendance/EntryExit', async (req, res) => {
  try {
    const { staff_id, status } = req.body;

    if (!staff_id) {
      return res.status(400).json({
        success: false,
        message: 'staff_id required'
      });
    }

      const result = await db.request()
        .input("operation", "CheckInOut")
        .input("staff_id", staff_id)
	  	.input("status", status)
        .execute("sp_staff_attendance");

    res.status(200).json(result.recordset);
    }catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});



//----------- EMERGENCY ALERT POST API ----------------------//
router.post('/AddEmergencyAlert', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      society_id,
      alert_type,           // Water | Gas | Power | Fire
      alert_scope,          // Society | Building | Flat
      selected_buildings,   // array [1,2,3]
      start_time,
      end_time,
      morning_start_time,
      morning_end_time,
      evening_start_time,
      evening_end_time,
      has_evening,
      created_by
    } = req.body;

    // ✅ Required validation
    if (!society_id || !alert_type || !created_by) {
      return res.status(400).json({
        success: false,
        message: "society_id, alert_type and created_by are required"
      });
    }

    await db.request()
      .input("operation", sql.NVarChar, "Upsert")
      .input("society_id", sql.NVarChar(50), society_id)
      .input("alert_type", sql.NVarChar(20), alert_type)
      .input("alert_scope", sql.NVarChar(20), alert_scope)
      .input("selected_buildings", sql.NVarChar(sql.MAX), JSON.stringify(selected_buildings || []))
    //  .input("start_time", sql.DATETIME, start_time)
      //.input("end_time", sql.DATETIME, end_time)
 //.input("morning_start_time", sql.DATETIME, morning_start_time || null)
  //.input("morning_end_time", sql.DATETIME, morning_end_time || null)
  //.input("evening_start_time", sql.DATETIME, has_evening ? evening_start_time : null)
  //.input("evening_end_time", sql.DATETIME, has_evening ? evening_end_time : null)
	  .input("start_time", sql.Time, timeStringToUtcDate(start_time))
.input("end_time", sql.Time, timeStringToUtcDate(end_time))
.input("morning_start_time", sql.Time, timeStringToUtcDate(morning_start_time) || null)
.input("morning_end_time", sql.Time, timeStringToUtcDate(morning_end_time) || null)
.input("evening_start_time", sql.Time, has_evening ? timeStringToUtcDate(evening_start_time) : null)
.input("evening_end_time", sql.Time, has_evening ? timeStringToUtcDate(evening_end_time) : null)

      .input("has_evening", sql.Bit, has_evening ? 1 : 0)
      .input("created_by", sql.Int, created_by)
	
      .execute("sp_emergency_alert_preferences");

    res.json({
      success: true,
      message: "Emergency alert saved successfully"
    });

  } catch (err) {
    console.error("ERROR ===>", err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

//----------- EMERGENCY ALERT POST API ----------------------//
router.post('/AddEmergencyAlert11', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      society_id,
      alert_type,
      alert_scope,          // Society | Building | Flat
      selected_buildings,
      start_time,
      end_time,
      morning_start_time,
      morning_end_time,
      evening_start_time,
      evening_end_time,
      has_evening,
      created_by,
      building_schedules
    } = req.body;

    // ✅ Mandatory fields
    if (!society_id || !alert_type || !alert_scope || !created_by) {
      return res.status(400).json({
        success: false,
        message: "society_id, alert_type, alert_scope and created_by are required"
      });
    }

    // ✅ Society level validation
    if (alert_scope === 'Society' && (!start_time || !end_time)) {
      return res.status(400).json({
        success: false,
        message: "start_time and end_time are required for society alerts"
      });
    }

    // ✅ Building level validation
    if (alert_scope === 'Building') {
      if (!Array.isArray(building_schedules) || building_schedules.length === 0) {
        return res.status(400).json({
          success: false,
          message: "building_schedules is required for building alerts"
        });
      }

      for (const b of building_schedules) {
        if (!b.building_id || !b.start_time || !b.end_time) {
          return res.status(400).json({
            success: false,
            message: "Each building must have building_id, start_time, end_time"
          });
        }
      }
    }

    await db.request()
      .input("operation", sql.NVarChar, "Upsert")
      .input("society_id", sql.NVarChar(50), society_id)
      .input("alert_type", sql.NVarChar(20), alert_type)
      .input("alert_scope", sql.NVarChar(20), alert_scope)
      .input(
        "selected_buildings",
        sql.NVarChar(sql.MAX),
        JSON.stringify(selected_buildings || [])
      )

      // 👇 Only for Society scope
      .input("start_time", sql.DATETIME, alert_scope === 'Society' ? start_time : null)
      .input("end_time", sql.DATETIME, alert_scope === 'Society' ? end_time : null)

      .input("morning_start_time", sql.DATETIME, morning_start_time || null)
      .input("morning_end_time", sql.DATETIME, morning_end_time || null)
      .input("evening_start_time", sql.DATETIME, has_evening ? evening_start_time : null)
      .input("evening_end_time", sql.DATETIME, has_evening ? evening_end_time : null)
      .input("has_evening", sql.Bit, has_evening ? 1 : 0)
      .input("created_by", sql.Int, created_by)

      // 👇 Only for Building scope
      .input(
        "building_schedules",
        sql.NVarChar(sql.MAX),
        alert_scope === 'Building'
          ? JSON.stringify(building_schedules)
          : null
      )
      .execute("sp_emergency_alert_preferences");

    res.json({
      success: true,
      message: "Emergency alert saved successfully"
    });

  } catch (err) {
    console.error("ERROR ===>", err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

router.post('/update/attendance', async (req, res) => {
  try {
    const { staff_id, status } = req.body;

    const statusInt = parseInt(status, 10);   // convert to integer

    const result = await db.request()
      .input("operation", "Attendance")
      .input("staff_id", staff_id)
      .input("status", sql.Int, statusInt)    // explicitly send as INT
      .execute("sp_staff_attendance");

    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
router.post('/EmergencyAlert/CustomMessage', async (req, res) => {
  try {
    const {
      society_id,
      alert_type,
      alert_scope,
      selected_buildings,
      alert_title,
      message,
      created_by
    } = req.body;

    // Validation
    if (!society_id || !alert_type || !alert_scope || !alert_title || !message || !created_by) {
      return res.status(400).json({
        success: false,
        message: "society_id, alert_type, alert_scope, alert_title, message, and created_by are required"
      });
    }

    // Execute SP and assign result to a variable
   const result = await db.request()
  .input("operation", sql.NVarChar, "InsertCustomMessage")
  .input("society_id", sql.NVarChar(50), society_id)
  .input("alert_type", sql.NVarChar(20), alert_type)
  .input("alert_scope", sql.NVarChar(20), alert_scope)
  .input("selected_buildings", sql.NVarChar(sql.MAX), JSON.stringify(selected_buildings || []))
  .input("alert_title", sql.NVarChar(200), alert_title)
  .input("message", sql.NVarChar(sql.MAX), message)
  .input("created_by", sql.Int, created_by)
  .execute("sp_emergency_alert_preferences"); // ✅ now stored

    // Get SP response
    const spResponse = result.recordset[0]; // now result is defined

    res.status(200).json({
      success: spResponse.success === 1,
      message: spResponse.message
    });

  } catch (err) {
    console.error("ERROR ===>", err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});


module.exports = router; 