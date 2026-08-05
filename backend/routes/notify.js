const express = require("express");
const app = express();
var db = require("./db")
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
var router = express.Router();


router.post("/send-notifications", (req, res) => {
  const { tokens, title, body } = req.body;
	
  const message = {
   
    notification: {
      title: title,
      body: body
    },
   data: {
    messageType: 'visitor_entry'
  },
    tokens: tokens,
  };
  
  admin.messaging().sendEachForMulticast(message)
    .then((response) =>{
      res.status(200).send(`Notification sent successfully: ${response}`);
    })
    .catch((error) =>{
        console.error("Error sending notifications:", error);
      res.status(500).send(`Error sending notification: ${error}`);
      
    });
}); 
 
router.post("/send-datamessage", async (req, res) => {
  try {
    const {
      tokens,
      image,
      body,
      staff_token,
      visitorName,
      visitorId,
      unit
    } = req.body;

    if (!tokens || !tokens.length) {
      return res.status(400).json({ error: "No tokens provided" });
    }

    const message = {
      notification: {
        title: "Visitor on the Gate",
        body: body || "A visitor is waiting at the gate",
      },
      data: {
        messageType: "visitor_entry",
        imageUrl: image || "",
        staff_token: staff_token || "",
        visitorName: visitorName || "Visitor",
        visitorId: String(visitorId || ""),
        entryType: "Guest",
        unit: unit || "Unknown",
      },
      tokens
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    response.responses.forEach((r, i) => {
      if (!r.success) {
        console.error(
          "❌ Token failed:",
          tokens[i],
          r.error?.code,
          r.error?.message
        );
      }
    });

    // ✅ THIS WAS MISSING
    return res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount
    });

  } catch (error) {
    console.error("❌ Error sending datamessage:", error);
    return res.status(500).json({ error: "Failed to send notification" });
  }
});

router.post("/send-datamessage-security", async (req, res) => {
  try {
    const {
      body,
      tokens,
      visitorName,
      visitorId,
      unit,
      owner_name,
      owner_id,
      status,
      image // <- add this if you expect it in body
    } = req.body;

    if (!tokens || !tokens.length) {
      return res.status(400).json({ error: "No tokens provided" });
    }

    const message = {
      notification: {
        title: `${owner_name} Responded`,
        body: body,
      },
      data: {
        messageType: "visitor_entry",
        imageUrl: image ? String(image) : "",
        staff_token: "",              
        visitorName: visitorName || "Visitor",
        visitorId: String(visitorId || ""), 
        entryType: "Guest",
        unit: unit || "Unknown",
        status: String(status ?? "")
      },
      tokens
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    response.responses.forEach((r, i) => {
      if (!r.success) {
        console.error(
          "❌ Token failed:",
          tokens[i],
          r.error?.code,
          r.error?.message
        );
      }
    });

    return res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount
    });

  } catch (error) {
    console.error("❌ Error sending datamessage:", error);
    return res.status(500).json({ error: "Failed to send notification" });
  }
});


router.post('/GateKeeperApp/Insert/NewToken', async (req, res) => {
  try {
    const { staff_id, token } = req.query;

    if (!staff_id || !token) {
      return res.status(400).json({
        success: false,
        message: "staff_id and token are required"
      });
    }
    const result = await db.request()
      .input("operation", "UpdateNewToken")
      .input("staff_id", staff_id)
      .input("token", token)
      .execute("sp_staff_master");

    res.json({
      success: true,
      message: "Token updated successfully",
      rowsAffected: result.rowsAffected[0]
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message
    });
  }
});
router.post('/OwnerApp/Insert/NewToken', function (req, res) {
  var sql = "";
  if(req.query.type=="Owner")
      sql="Update owner_master set token='"+req.query.token+"' where owner_id="+req.query.owner_id
  else
  sql="Update owner_extension set token='"+req.query.token+"' where o_ex_id="+req.query.owner_id
  db.query(sql, function (err, result) {
      if (err)
          return res.status(500).json({ error: err.message });
      else{
         
          return res.status(200).json({success:true, message:"Successfully"})
      }
  });
});
router.post('/AdminApp/Insert/NewToken', function (req, res) {
 
  sql="Update UserLogin set token='"+req.body.token+"' where user_id="+req.body.user_id
  db.query(sql, function (err, result) {
      if (err)
          return res.status(500).json({ error: err.message });
      else{
         
          return res.status(200).json({message:"Successfully"})
      }
  });
});
router.get('/Gatekeeper/Token/:staff_id', function(req, res, next) {
  // const table=req.params.tablename
  
   db.query("select * from Staff_master where  active_status=0 and staff_id= '"+req.params.staff_id+"'",function(err,rows){
       if(err)
          return res.status(500).json({error:err.message});      
      res.json(rows.recordset);
});
});
router.get('/Owner/Society/GetAllToken/:society/:type', function(req, res, next) {
  var sql="Exec sp_owner_master @operation='get_users' , @recipients_id='"+req.params.type+"', @society_id='"+req.params.society+"'"
   db.query(sql,function(err,rows){
       if(err)   
          return res.status(500).json({error:err.message});      
      res.json(rows.recordset);
});
});

router.get('/Admin/Society/GetAllToken/:society', function(req, res, next) {
  var sql="select web_token,token,user_id from UserLogin where  active_status=0 and  token is not null or web_token is not null and society_id= '"+req.params.society+"'"
   db.query(sql,function(err,rows){
       if(err) 
          return res.status(500).json({error:err.message});      
      res.json(rows.recordset);
});
});
router.post("/insert/notification",function(req,res,next){
  var sql="Exec sp_notification @operation='Update',@notification_id="+req.body.notification_id+",@notification_type='"+req.body.notification_type+"',@user_id="+req.body.user_id+",@user_type='"+req.body.user_type+"', @seen_status=0, @society_id='"+req.body.society_id+"',@title='"+req.body.title+"', @body='"+req.body.body+"'"

  db.query(sql,function(err,rows){
  if (err)
    return res.status(500).json({ error: err.message });
else{
   
    return res.status(200).json({message:"Successfully"})
}
});
});


router.post("/owner-response1", async (req, res) => {  
  const { visitorId, response, staffToken, ownerId, flatId } = req.body;

  if (!visitorId || !response || !staffToken) {
    return res.status(400).json({ error: "Missing fields" });
  }

  // 1️⃣ Save Owner response in DB  
  await sql.query`
    INSERT INTO VisitorResponse (visitor_id, owner_id, flat_id, response, response_time)
    VALUES (${visitorId}, ${ownerId}, ${flatId}, ${response}, GETDATE())
  `;

  // 2️⃣ Send Notification to staff  
  const message = {
    notification: {
      title: "Owner Response",
      body: `Owner has selected: ${response}`
    },
    data: {
      messageType: "owner_response",
      visitorId: visitorId.toString(),
      response: response,
      flatId: flatId.toString()
    },
    token: staffToken
  };

  try {
    await admin.messaging().send(message);
    res.json({ success: true, message: "Response sent to staff" });

  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "Notification sending failed" });
  }
});


router.post("/visitor-response", (req, res) => {
  const { staff_token, visitorId, response } = req.body;

  if (!staff_token || !visitorId || !response) {
    return res.status(400).json({ error: "Missing fields" });
  }

  const message = {
    data: {
      messageType: "visitor_response",
      visitorId: visitorId.toString(),
      response: response, // "APPROVED" or "DENIED"
    },
    token: staff_token,
  };

  admin.messaging().send(message)
    .then(() => {
      res.status(200).json({ message: "Response sent to staff" });
    })
    .catch((err) => {
      console.error("FCM error:", err);
      res.status(500).json({ error: "Failed sending response" });
    });
});


router.post("/send-alert-notifications", async (req, res) => {
  try {
    const {
      society_id,
      buildings,        // <-- list (array)
      staff_id,
      notification_type,
      title,
      body
    } = req.body;

    // 🔹 Convert buildings list -> comma separated
    const buildingCsv = Array.isArray(buildings)
      ? buildings.join(",")
      : buildings || "";

    // 1️⃣ Get user tokens + userIds (now passing society + buildings)
    const result = await db.request()
      .input("operation", "getTokensUserId")
      .input("society_id", society_id)
      .input("buildings", buildingCsv)
      .execute("sp_emergency_alert_preferences");

    const rows = result.recordset || [];

    if (!rows.length) {
      return res.status(404).json({ message: "No users found to notify" });
    }

    // All targeted users get a notify_status record regardless of whether
    // they currently have an FCM token registered (e.g. first-login users).
    const allUserIds = rows.map(r => r.owner_id);
    const tokens = rows.map(r => r.token).filter(Boolean);

    let successCount = 0;
    let failureCount = 0;

    if (tokens.length) {
      const message = {
        notification: { title, body },
        data: { messageType: "Alert" },
        tokens
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      successCount = response.successCount;
      failureCount = response.failureCount;
    }

    const userIdCsv = allUserIds.join(",");

    await db.request()
      .input("operation", "InsertNotify")
      .input("society_id", society_id)
      .input("notification_type", notification_type)
      .input("title", title)
      .input("body", body)
      .input("user_ids", userIdCsv)
      .execute("sp_emergency_alert_preferences");

    return res.status(200).json({
      message: "Notification logged for all users; push sent where a token was available",
      success: successCount,
      failure: failureCount
    });

  } catch (error) {
    console.error("Error sending notifications:", error);
    return res.status(500).json({ error: error, });
  }
});


module.exports = router; 