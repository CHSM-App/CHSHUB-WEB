var express = require('express');
var db = require("./db");
const sql = require('mssql'); 
var router = express.Router();
var bodyParser = require('body-parser');
router.use(bodyParser.json());
const auth = require('./middleware/auth');
const { requireOwnership } = require('./middleware/ownership');
router.use(bodyParser.urlencoded({ extended: true }));

router.post('/Insert/Notification',  async (req, res) => {
  try {
    const {
      notification_id,
      notification_type,
      user_id,
      user_type,
      society_id,
      title,
      body
    } = req.body;

    const result = await db.request()
      .input("operation", "Update")
      .input("notification_id", notification_id)
      .input("notification_type", notification_type)
      .input("user_id", user_id)
      .input("user_type", user_type)
      .input("seen_status", 0)
      .input("society_id", society_id)
      .input("title", title)
      .input("body", body)
      .execute("sp_notification");

    res.json({ success: true, message: "Notification inserted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});
router.post('/AddFireBaseToken/Owner',  async (req, res) => {
  try {
    const { ownerId, type,token } = req.query;

    const result = await db.request()
      .input("operation", "AddToken")
      .input("owner_id", ownerId)
      .input("login_type", type)
	.input("token",token)
      .execute("sp_owner_master");

    res.json({success:true, message: "Successfully Added" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.post('/NotifyCall/:checked/:owner_id/:type',  async (req, res) => {
  try {
    const notify_app = req.params.checked === "true" ? 1 : 0; // parse correctly as boolean 1/0
    const { owner_id, type } = req.params;

    await db.request()
      .input("operation", "NotifyCall")
      .input("owner_id", owner_id)
      .input("type", type)
      .input("notify_app", notify_app)
      .execute("sp_owner_master");

    res.json({success:true, message: "NotifyCall updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/NotifyApp/:checked/:owner_id/:type',  async (req, res) => {
  try {
    const notify_app = req.params.checked === "true" ? 1 : 0; // convert to 1 or 0
    const { owner_id, type } = req.params;

    await db.request()
      .input("operation", "NotifyApp")
      .input("owner_id", owner_id)
      .input("type", type)
      .input("notify_app", notify_app)
      .execute("sp_owner_master");

    res.json({success:true,  message: "NotifyApp updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

//Expected Visitor
router.post('/insertVisitor',  async (req, res) => {
  try {
    const { flat_id, v_name, vehicle_no, type, society_id, contact_no, purpose, image, pre_date, preference } = req.body;

    await db.request()
      .input("operation", "Update")
      .input("flat_id", flat_id)
      .input("v_name", v_name)
      .input("vehicle_no", vehicle_no)
      .input("type", type)
      .input("society_id", society_id)
      .input("contact_no", contact_no)
      .input("purpose", purpose || type) // same as your original logic
      .input("image", image)
      .input("pre_date", pre_date)
      .input("preference", preference)
      .input("in_user_id", 0)
      .execute("sp_Visitor");

    res.status(200).json({success:true,  message: "Visitor inserted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/AddVisitor/Cab', async (req, res) => {
  try {
    const {  v_name, vehical_no, pre_date, contact_no,company,society_id,owner_id,flat_id} = req.query;

   const result= await db.request()
      .input("operation", "Update")
     
      .input("v_name", v_name)
      .input("vehicle_no", vehical_no)
      .input("pre_date", pre_date)
      .input("contact_no", contact_no)
    .input("company", company)
    .input("society_id", society_id)
	   .input("type", "Cab")
      .input("status", 0) 
    .input("owner_id", owner_id)
        .input("flat_id", flat_id)
      .execute("sp_Visitor");

res.status(200).json({ success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/AddVisitor/Service',  async (req, res) => {
  try {
    const {  v_name, pre_date, contact_no,company,society_id,owner_id,flat_id } = req.query;

   const result= await db.request()
      .input("operation", "Update")
     
      .input("v_name", v_name)
      .input("pre_date", pre_date)
      .input("contact_no", contact_no)
     .input("company", company)
   .input("society_id", society_id)
	   .input("type", "Service")
      .input("status", 0)
    .input("owner_id", owner_id)
      .input("flat_id", flat_id)
      .execute("sp_Visitor");

res.status(200).json({ success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/AddVisitor/Delivery',  async (req, res) => {
  try {
    const {  v_name, pre_date, contact_no,preference,company,society_id,owner_id,flat_id } = req.query;

   const result= await db.request()
      .input("operation", "Update")
      .input("v_name", v_name)
      .input("pre_date", pre_date)
      .input("contact_no", contact_no)
     .input("preference", preference)
     .input("company", company)
   .input("society_id", society_id)
	   .input("type", "Delivery")
      .input("status", 0) 
    .input("owner_id", owner_id)
      .input("flat_id", flat_id)
      .execute("sp_Visitor");

res.status(200).json({success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/AddVisitor/Guest',  async (req, res) => {
  try {
    const { v_name, pre_date, contact_no,society_id,owner_id,flat_id } = req.query;

   const result= await db.request()
      .input("operation", "Update")
  
      .input("v_name", v_name)
      .input("pre_date", pre_date)
      .input("contact_no", contact_no)
   .input("society_id", society_id)
	   .input("type", "Guest")
    .input("status", 0)
    .input("owner_id", owner_id)
      .input("flat_id", flat_id)
      .execute("sp_Visitor");

res.status(200).json({success:true,
  visitor_id: result.recordset[0].visitor_id, 
  gateOtp: result.recordset[0].gateOtp 
});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/visitorAction', async(req, res) => {
	try {
		const {owner_id, visitor_id, status, society_id } = req.body;
		
		const result = await db.request()
			.input("operation", "updateStatus")
			.input("owner_id", owner_id)
			.input("visitor_id", visitor_id)
			.input("status", status)
			.input("society_id", society_id)
			.execute("sp_Visitor");
		
	    res.json({success:true});
  	} catch (err) {
    	res.status(500).json({ error: err.message });
  	}
});


router.post('/Helpdesk',  async (req, res) => {
  try {
    const { flat_id, query, category, category_type,req_service_date, urgency,owner_id ,logintype} = req.body;


    const result = await db.request()
      .input("operation",  "Update")
      .input("flat_id",flat_id)
      .input("query", query)
      .input("category",  category)
      .input("type",  category_type)
      .input("req_service_date",  req_service_date)
      .input("urgency",  urgency)
	     .input("owner_id",  owner_id)
	  .input("logintype",  logintype)
      .execute("sp_Helpdesk");

    res.json({success:true, helpdesk_id: result.recordset[0].helpdesk_id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


//Basic Profile Info
router.post('/ProfileEdit/dob/:pre_mob/:owner_id',  async (req, res) => {
  try {
    const { pre_mob, owner_id } = req.params;
    const { dob, type } = req.body;

    const operation = (type === 'owner') ? "UpdateOwnerDob" : "UpdateOwnerExtensionDob";

    await db.request()
      .input("operation", operation)
      .input("dob", dob)
      .input("pre_mob", pre_mob)
      .input("owner_id", owner_id)
      .execute("sp_owner_master");

    res.status(200).json({ success:true,message: "Date of birth updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/ProfileEdit/Email/:pre_mob/:owner_id',  async (req, res) => {
  try {
    const { pre_mob, owner_id } = req.params;
    const { email, type } = req.body;

    const operation = (type === 'owner') 
      ? "UpdateOwnerEmail" 
      : "UpdateOwnerExtensionEmail";

    await db.request()
      .input("operation", operation)
      .input("email", email)
      .input("pre_mob", pre_mob)
      .input("owner_id", owner_id)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Email updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



router.post('/ProfileEdit/updateMobile/:pre_mob/:owner_id',  async (req, res) => {
  try {
    const { pre_mob, owner_id } = req.params;
    const { type } = req.body;

    const operation = (type === 'owner')
      ? "UpdateOwnerMobile"
      : "UpdateOwnerExtensionMobile";

    await db.request()
      .input("operation", operation)
      .input("pre_mob", pre_mob)
      .input("owner_id", owner_id)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Mobile number updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/ProfileSetting/updateSetting/:pre_mob/:owner_id',  async (req, res) => {
  try {
    const { owner_id, pre_mob } = req.params;
    const { type, phone, email, gate } = req.body;

    const operation = (type === 'owner')
      ? "UpdateOwnerSetting"
      : "UpdateOwnerExtensionSetting";

    await db.request()
      .input("operation", operation)
      .input("owner_id", owner_id)
      .input("pre_mob", pre_mob)
      .input("mask_phone", phone)
      .input("mask_email", email)
      .input("share_gate", gate)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Settings updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/ProfileEdit/JobTitle/:pre_mob/:owner_id',  async (req, res) => {
  try {
    const { owner_id, pre_mob } = req.params;
    const { type, job_title } = req.body;

    const operation = (type === 'owner')
      ? "UpdateOwnerJobTitle"
      : "UpdateOwnerExtensionJobTitle";

    await db.request()
      .input("operation", operation)
      .input("owner_id", owner_id)
      .input("pre_mob", pre_mob)
      .input("job_title", job_title)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Job Title updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/ProfileEdit/Language/:pre_mob/:owner_id',  async (req, res) => {
  try {
    const { owner_id, pre_mob } = req.params;
    const { type, language } = req.body;

    const operation = (type === 'owner')
      ? "UpdateOwnerLanguage"
      : "UpdateOwnerExtensionLanguage";

    await db.request()
      .input("operation", operation)
      .input("owner_id", owner_id)
      .input("pre_mob", pre_mob)
      .input("language", language)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Language updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/HomeNumberEdit/:pre_mob/:flat_id',  async (req, res) => {
  try {
    const { flat_id } = req.params;
    const { home_no } = req.body;

    await db.request()
      .input("operation", "UpdateHomeNumber")
      .input("flat_id", flat_id)
      .input("home_no", home_no)
      .execute("sp_owner_master");

    res.status(200).json({success:true,  message: "Updated Successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/Facilities/Booking',  async function (req, res) {
  try {
    const {
      from_date,
      to_date,
      name,
      flat_id,
      contact,
      from_time,
      to_time,
      society_id,
      amount,
      note,
      facility_id,
    } = req.body;

 // Connect to DB (assuming db.connect() returns a pool)

    const request = db.request();

    request.input('operation', sql.VarChar, 'Update');
    request.input('from_date', sql.VarChar, from_date);
    request.input('to_date', sql.VarChar, to_date); // Handles null automatically
    request.input('name', sql.VarChar, name);
    request.input('flat_no', sql.Int, flat_id);
    request.input('contact', sql.VarChar, contact);
    request.input('from_time', sql.VarChar, from_time);
    request.input('to_time', sql.VarChar, to_time);
    request.input('society_id', society_id);
    request.input('amount', sql.Decimal(10, 2), amount);
    request.input('note', sql.VarChar, note);
    request.input('facility_id', sql.Int, facility_id);

    await request.execute('sp_facility_booking');

    return res.status(200).json({success:true, message: 'Updated Successfully' });
  } catch (err) {
    console.error('Error during facility booking update:', err);
    return res.status(500).json({ error: err.message });
  }
});

//Family Members
router.post('/familyMember', async (req, res) => {
  try {
    const { o_id, f_name, contact, relation, society_id } = req.query;

    await db.request()
      .input("operation", "AddFamilyMember")
      .input("owner_id", o_id)
      .input("f_name", f_name)
      .input("contact", contact)
      .input("relation", relation)
      .input("society_id", society_id)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Family member added successfullyyyyyy" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


//Notification 
router.post('/Notifications2/updateStatus/:id',  async (req, res) => {
  try {
    const { id } = req.params;

    await db.request()
      .input("operation", "UpdateNotificationStatus")
      .input("notify_status_id", id)
      .execute("sp_notification");

    res.status(200).json({success:true, message: "Notification status updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.post('/Notifications/updateStatus/:id',  async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) return res.status(400).json({ success: false, message: "ID is required" });

    const result = await db.request()
      .input("operation", "UpdateNotificationStatus")
      .input("notify_status_id", parseInt(id))
      .execute("sp_notification");

    // Log affected rows for debugging
    console.log("Affected rows:", result.recordset);

    res.status(200).json({ success: true, message: "Notification status updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/Notifications/markAllSeen', async (req, res) => {
  try {
    const { society_id, owner_id, notification_type } = req.body;

    if (!society_id || !owner_id || !notification_type) {
      return res.status(400).json({ success: false, message: "society_id, owner_id and notification_type are required" });
    }

    await db.request()
      .input("operation", "MarkAllSeenByType")
      .input("society_id", society_id)
      .input("owner_id", parseInt(owner_id))
      .input("notification_type", notification_type)
      .execute("sp_notification");

    res.status(200).json({ success: true, message: "Notifications marked as seen" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});


//Add Product
router.post('/AddProduct',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Update')
      .input('active_status', 0) // always 0 for new product
      .input('product_name', req.body.product_name)
      .input('description', req.body.description)
      .input('price', parseFloat(req.body.price))
      .input('warranty', req.body.warranty)
      .input('status', req.body.status)
      .input('available_quantity', parseInt(req.body.available_quantity, 10))
      .input('society_id', req.body.society_id)
      .input('owner_id', parseInt(req.body.owner_id, 10))
      .input('contact_no', req.body.contact_no)
      .input('posted_date', req.body.posted_date) // should be in YYYY-MM-DD format
      .input('availability', req.body.availability)
	.input('type', req.body.type)
      .execute('sp_product');

    res.json({ product_id: result.recordset[0].product_id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/Helper/AddReview',  async (req, res) => {
  try {
    const { usefull_contact_id, owner_id, review, rating, member_id, society_id } = req.body;
 
    const pool = await db;
    await pool.request()
      .input("operation", sql.NVarChar(50), "AddReview")
      .input("usefull_contact_id",  usefull_contact_id)
      .input("owner_id", owner_id)
      .input("review",  review)
      .input("rating", rating)
      .input("member_id", member_id)
      .input("society_id",  society_id)
      .execute("sp_usefull_contact");
 
    res.status(200).json({success:true, message: "Review added successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
 

router.post('/Helper/AssignToFlat',  async (req, res) => {
  try {
    const { helper_id, flat_id, society_id } = req.body;

    await db.request()
      .input("operation", "AssignToFlat")
      .input("usefull_contact_id", helper_id)
      .input("flat_id", flat_id)
      .input("society_id", society_id)
      .execute("sp_usefull_contact");

    res.status(200).json({success:true, message: "Helper assigned to flat successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// Add Vehicle
router.post('/AddVehicle',  async (req, res) => {
  try {
    const { park_for, park_type, model_name, from_date, to_date, vehicle_no, description, place_id, sticker_no, flat_id, society_id, owner_id, status } = req.body;

    await db.request()
      .input("operation", "AddVehicle")
      .input("park_for", park_for)
      .input("park_type", park_type)
      .input("model_name", model_name)
      .input("from_date", from_date)
      .input("to_date", to_date)
      .input("vehicle_no", vehicle_no)
      .input("description", description)
      .input("place_id", place_id)
      .input("sticker_no", sticker_no)
      .input("flat_id", flat_id)
      .input("society_id", society_id)
      .input("owner_id", owner_id)
      .input("status", status)
      .execute("sp_parking");

    res.status(200).json({success:true, message: "Vehicle added/updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/AddHelper',  async (req, res) => {
  try {
    const { type, name, contactNo, type_id } = { 
      type: req.query.type, 
      name: req.body.name, 
      contactNo: req.body.contactNo, 
      type_id: req.query.type_id 
    };

    if (type == 8) {
      // Case 1: Servant/Maid
      await db.request()
        .input("operation", "AddHelperServant")
        .input("s_name", name)
        .input("mobile_no1", contactNo)
        .execute("sp_usefull_contact");
    } else {
      // Case 2: Useful Contact
      await db.request()
        .input("operation", "AddHelperContact")
        .input("p_name", name)
        .input("contact_no", contactNo)
        .input("p_type", type_id)
        .execute("ssp_usefull_contact");
    }

    res.status(200).json({success:true, message: "Helper added successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Example: POST /Helpdesk/UpdateComment?comment_id=12&helpdesk_id=5&status=1
router.post('/Helpdesk/UpdateRequest',  async function (req, res) {
  try {
    const { comment_id, helpdesk_id, status } = req.query;

    const request = db.request();

    request.input('operation', 'updaterequest');
    request.input('comment_id', comment_id);
    request.input('helpdesk_id', helpdesk_id);
    request.input('status', status);

    await request.execute('sp_helpdesk');

    return res.status(200).json({success:true, message: 'Comment updated successfully' });
  } catch (err) {
    console.error('Error during comment update:', err);
    return res.status(500).json({ error: err.message });
  }
});

// Owner Messages
/*router.post('/OwnerMessages',  async (req, res) => {
  try {
    const { flat_id, messages, type, society_id,owner_id,owner_type,message_sub } = req.query;

    await db.request()
      .input("operation", "AddOwnerMessage")
      .input("flat_id", flat_id)
      .input("messages", messages)
      .input("type", type)
      .input("society_id", society_id)
	  .input("owner_id", owner_id)
	   .input("owner_type", owner_type)
	    .input("message_sub", message_sub)
      .execute("sp_owner_master");

    res.status(200).json({success:true, message: "Owner message added successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});*/
router.post('/OwnerMessages',  async (req, res) => {
  try {
    const { flat_id, messages, type, society_id, owner_id, owner_type, message_sub } = req.query;

    const result = await db.request()
      .input("operation", "AddOwnerMessage")
      .input("flat_id", flat_id)
      .input("messages", messages)
      .input("type", type)
      .input("society_id", society_id)
      .input("owner_id", owner_id)
      .input("owner_type", owner_type)
      .input("message_sub", message_sub)
      .execute("sp_owner_master");

    // ✅ Capture inserted ID from SQL
    const insertedId = result.recordset?.[0]?.r_id;

    res.status(200).json({
      success: true,
      r_id: insertedId || 0, // send 0 if not found
      message: "Owner message added successfully",
    });
  } catch (err) {
    console.error("Error adding owner message:", err);
    res.status(500).json({ error: err.message });
  }
});

// Security Alert
router.post('/SecurityAlert12',  async (req, res) => {
  try {
    const { flat_id, type, society_id } = req.query;

    await db.request()
      .input("operation", "AddSecurityAlert")
      .input("flat_id", flat_id)
      .input("type", type)
      .input("society_id", society_id)
      .execute("sp_owner_master");

     const securityId = result.recordset?.[0]?.security_id || 0;

    res.status(200).json({
      success: true,
      securityId,
      message: "Security alert added successfully",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.post('/SecurityAlert',  async (req, res) => {
  try {
    const { flat_id, type, society_id } = req.query;

    const result = await db.request()
      .input("operation", "AddSecurityAlert")
      .input("flat_id", flat_id)
      .input("type", type)
      .input("society_id", society_id)
      .execute("sp_owner_master");

    console.log("SecurityAlert result:", result.recordset); // 🧠 debug

    const securityId = result.recordset?.[0]?.security_id || result.recordset?.[0]?.alert_id || 0;

    res.status(200).json({
      success: true,
      securityId,
      message: "Security alert added successfully",
    });
  } catch (err) {
    console.error("Error adding security alert:", err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/familyVehicle/Add', async (req, res) => {
  try {
    const { society_id, owner_id, vehicle_no, vehicle_type, flat_id, model_name } = req.body;

    const result = await db.request()
      .input("operation", "Insertfamilyvehicle")
      .input("society_id", society_id)
      .input("flat_id", flat_id)
      .input("owner_id", owner_id)
      .input("vehicle_no", vehicle_no)
      .input("vehicle_type", vehicle_type)
		.input("model_name", model_name)
      .execute("sp_parking");

    res.json({ success: true, message: "Vehicle added successfully", data: result.recordset });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post('/familyHelper/Add', async (req, res) => {
  try {
    const { p_type_id, p_name, contact_no, flat_id, society_id} = req.body;

    const result = await db.request()
      .input("operation", "InsertHelper")
      .input("p_type_id", p_type_id)
      .input("p_name", p_name)
      .input("contact_no", contact_no)
      .input("flat_id", flat_id)
	  .input("society_id", society_id)
      .execute("sp_servent_maid_master"); // this is the main SP you’re using

    res.json({
      success: true,
      message: "Helper inserted successfully",
      data: result.recordset
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/polls/:pollId/vote", async (req, res) => {
  try {
    const { pollId } = req.params;
    const { societyId, userId, optionId, userType, allowMultipleVotes, oneVotePerUnit } = req.body;

    const result = await db.request()
      .input("Operation", "INSERT")
      .input("Society_id", societyId)
      .input("User_Id", userId)
      .input("Poll_id", pollId)
      .input("Option_id", optionId)
      .input("User_type", userType)
      .input("AllowMultipleVotes", allowMultipleVotes)
      .input("OneVotePerUnit", oneVotePerUnit)
      .execute("sp_PollVoting");

    res.json({ success: true, data: result.recordset[0].Message });
  } catch (error) {
    console.error("Vote Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.put("/polls/votes/:votingId", async (req, res) => {
  try {
    const { votingId } = req.params;
    const { societyId, optionId, userType } = req.body;

    const result = await db.request()
      .input("Operation", "UPDATE")
      .input("Voting_Id", votingId)
      .input("Society_id", societyId)
      .input("Option_id", optionId)
      .input("User_type", userType)
      .execute("sp_PollVoting");

    res.json({ success: true, data: result.recordset });
  } catch (error) {
    console.error("Update Vote Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});


router.post('/userProfile/update', async (req, res) => {
  try {
    const { owner_id, name, contact_no, email, login} = req.body;

    const result = await db.request()
      .input("operation", "updatePersonDetails")
      .input("name", name)
      .input("email", email)
      .input("contact", contact_no)
      .input("owner_id", owner_id)
	  .input("login_type", login)
      .execute("sp_owner_master"); 

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: result.recordset
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post("/DeleteProfilePhoto", async (req, res) => {
  try {
    const { owner_id, loginType } = req.body;
    if (!owner_id || !loginType) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: owner_id or loginType",
      });
    }
    const pool = await sql.connect();
    const result = await pool.request()
      .input("operation", "ProfileImageDelete")
      .input("owner_id", parseInt(owner_id, 10))
      .input("login_type", loginType)
      .execute("sp_owner_master");
    const dbMessage = result.recordset?.[0]?.message || "Profile image deleted successfully";
    res.status(200).json({
      success: true,
      message: dbMessage,
    });
  } catch (err) {
    console.error("❌ Error deleting profile image:", err);
    res.status(500).json({
      success: false,
      message: "Error deleting profile image",
      error: err.message,
    });
  }
});


router.post("/DeleteStaffPhoto", async (req, res) => {
  try {
    const { staff_id} = req.body;
    if (!staff_id) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: staff_id",
      });
    }
    const pool = await sql.connect();
    const result = await pool.request()
      .input("operation", "UpdateStaffProfile")
      .input("staff_id", parseInt(staff_id, 10))
      .execute("sp_staff_master");
    const dbMessage = result.recordset?.[0]?.message || "Profile image deleted successfully";
    res.status(200).json({
      success: true,
      message: dbMessage,
    });
  } catch (err) {
    console.error("❌ Error deleting profile image:", err);
    res.status(500).json({
      success: false,
      message: "Error deleting profile image",
      error: err.message,
    });
  }
});

/*router.post('/AddReceipt',  async (req, res) => {
  try {
    const {
      society_id,
      flat_id,
      receipt_date,
      pay_mode,
      cheque_no,
      cheque_date,
      bank_name,
      transaction_ref,
      bill_details,
      paid_amount,
      remarks,
      status,
      created_by
    } = req.body;

    const result = await db.request()
      .input("Action", "INSERT")
      .input("SocietyID", society_id)
      .input("FlatID", flat_id)
      .input("ReceiptDate", receipt_date)
      .input("PayMode", pay_mode)
      .input("ChequeNo", cheque_no)
      .input("ChequeDate", cheque_date)
      .input("BankName", bank_name)
      .input("TransactionRef", transaction_ref)
      .input("bills", bill_details)
      .input("PaidAmount", paid_amount)
      .input("Remarks", remarks)
      .input("Status", status)
      .input("CreatedBy", created_by)
      .execute("sp_MaintenanceReceipt");

    const newReceipt = result.recordset[0].receipt_id;

   
    res.status(200).json({
      success: true,
      message: "Receipt inserted successfully",
      receipt: newReceipt
    });
  } catch (err) {
    console.error("Error inserting receipt:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});*/
/*
 * DISABLED for residents. Letting a resident post an arbitrary `paid_amount`
 * here is the financial-integrity hole (audit P0-3): it settles bills for money
 * that may never have been collected, for any flat.
 *
 * Online payments now create the receipt server-side, after Razorpay
 * verification binds the paid amount to a real captured payment
 * (routes/payments.js -> sp_payment_order -> sp_MaintenanceReceipt). Manual and
 * cash receipts are entered by the society through the admin API
 * (web/routes/billing/receipts.js), which is authenticated and society-scoped.
 *
 * Kept as an explicit 403 so an old client build fails loudly rather than
 * silently settling a bill.
 */
router.post('/AddReceipt', (_req, res) =>
  res.status(403).json({
    success: false,
    error: 'Direct receipt creation is disabled. Pay online via /payments, or use admin receipt entry.',
  }));


router.post('/updateProduct', async (req, res) => {
  try {
    const { product_name, description, price, available_quantity, contact_no,product_id,owner_id} = req.body;

    const result = await db.request()
      .input("operation", "ProductUpdate")
      .input("product_name", product_name)
      .input("description", description)
      .input("price", price)
      .input("available_quantity", available_quantity)
	  .input("contact_no", contact_no)
	 .input("product_id", product_id)
	 .input("owner_id", owner_id)
      .execute("sp_product"); 

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: result.recordset
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 