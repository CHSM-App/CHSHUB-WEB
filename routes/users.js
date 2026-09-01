var express = require('express');
var db = require("./db");
var router = express.Router();
var http=require('http');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const auth = require('./middleware/auth');
let refreshTokens = [];

router.get('/SearchSociety',  async function (req, res) {
  try {
    const result = await db.request()
	.input('operation','SearchSociety')
	.execute('sp_SearchSociety');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Home/BasicInfo', auth, async (req, res) => {

  try {
    const { pre_mob, fId, OwnerId } = req.query;

    const flatId = parseInt(fId, 10);
    const ownerId = parseInt(OwnerId, 10);

    if (!pre_mob || !Number.isInteger(flatId) || !Number.isInteger(ownerId) || flatId <= 0 || ownerId <= 0) {
      return res.status(400).json({ error: 'Valid pre_mob, fId and OwnerId are required' });
    }

    const result = await db.request()
	 .input('operation', 'GetBasicInfo')
      .input('pre_mob', pre_mob)
      .input('flat_id', flatId)
	 .input('owner_id', ownerId)
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    console.error('BasicInfo error:', err);
    res.status(500).json({ error: 'Could not fetch basic info' });
  }
});


router.get('/Home/GetHobbies/:owner_id/:type',async (req, res) => {
  try {
    const { owner_id, type } = req.params;

    const result = await db.request()
      .input('operation', 'Select_Hobby')  // Fixed value
      .input('type', type)                 // From URL param
      .input('owner_id', parseInt(owner_id, 10)) // Ensure it's a number
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/category', async (req, res) => {
  try {
     const result = await db.request()
      .input('operation', 'GetCategories')
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/Home/GetAreaOfWork/:owner_id/:type',  async (req, res) => {
  try {
    const { owner_id, type } = req.params;

    // Validate and sanitize input
    const ownerIdInt = parseInt(owner_id, 10);
    if (isNaN(ownerIdInt)) {
      return res.status(400).json({ error: 'Invalid owner_id' });
    }

    const result = await db.request()
      .input('operation', 'Select_Work')  // Fixed SP parameter
      .input('type', type)                // Passed safely as a parameter
      .input('owner_id', ownerIdInt)      // Ensures it's numeric
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/FindHelper/:society',  async (req, res) => {
  try {
    const { society } = req.params;

    const result = await db.request()
      .input('operation', 'WorkDetails') // fixed value
      .input('society_id', society)      // safely passed as parameter
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// ✅ Get Help Request by ID (safe)
router.get('/HelpRequestById',  async (req, res, next) => {
  try {
 // your db connection (make sure db returns pool)
    const result = await db.request()
      .input("operation", "GetRequestById")
      .input("helpdesk_id", req.query.id)
      .execute("sp_helpdesk");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ✅ Get Helpdesk Comments by ID (safe)
router.get('/HelpdeskComments', async (req, res, next) => {
  try {

    const result = await db.request()
      .input("operation",  "GetComments")
      .input("helpdesk_id",  req.query.id) 
      .execute("sp_helpdesk");

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/HelperDetails/:society',  async (req, res) => {
  try {
    const societyId = req.params.society;

    const result = await db.request()
	.input('operation','HelperDetails')
      .input('society_id', societyId)  // Pass as parameter
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
/*router.get('/Helpdesk',   async (req, res) => {
  try {
    const result = await db.request()
	 .input('operation', 'GetTickets')
	.input('society_id', req.query.societyID)
      .execute('sp_helpdesk'); // No parameters

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});*/
router.get('/Helpdesk', async (req, res) => {
  try {
    const societyID = req.query.societyID;   // get from query params
    const ownerID = req.query.ownerID;       // get from query params

    if (!societyID || !ownerID) {
      return res.status(400).json({ error: 'societyID and ownerID are required' });
    }

    const result = await db.request()
      .input('operation', 'GetTickets')
      .input('society_id', societyID)
      .input('owner_id', ownerID)
      .execute('sp_helpdesk');

    res.json(result.recordset);

  } catch (err) {
    console.error('Helpdesk API error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/HelpdeskBYOwner/:id',  async (req, res) => {
  try {
    const flatId = parseInt(req.params.id, 10); // Ensure it's an integer

    const result = await db.request()
	.input('operation','HelpdeskByOwner')
      .input('flat_id', flatId)
      .execute('sp_helpdesk');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/FindHelper/Info/Review/:helper_id/:type',  async (req, res) => {
  try {
    const helperId = parseInt(req.params.helper_id, 10); // ensure integer
    const type = req.params.type; // string

    const result = await db.request()
	.input('operation','HelperReview')
      .input('helper_id', helperId)
      .input('type', type)
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/FindHelper/Info/worksAt/:helper_id/:type', async (req, res) => {
  try {
    const helperId = parseInt(req.params.helper_id, 10); // ensure integer
    const type = req.params.type;

    const result = await db.request()
	.input('operation','HelperWorkAt')
      .input('helper_id', helperId)
      .input('type', type)
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
/*router.get('/familyMembersowner/:owner_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'FamilyMembers')
      .input('owner_id', parseInt(req.params.owner_id, 10))
      .execute('sp_usefull_contact');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});*/

router.get('/Home/TotalDue/:flat_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'TotalDue')
      .input('flat_id', parseInt(req.params.flat_id, 10))
      .execute('sp_new_maintenance');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Home/DueHistory/:owner_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'DueHistory')
      .input('flat_id', parseInt(req.params.owner_id, 10))
      .execute('sp_new_maintenance');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Emergency Contacts
router.get('/more/EmergencyContacts',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'EmergencyContacts')
      .execute('sp_usefull_contact');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Vendors
router.get('/more/Vendors/:society_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Vendors')
      .input('society_id', req.params.society)
      .execute('sp_more');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Committee Members
router.get('/more/Committee/:society',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Committee')
      .input('society_id', req.params.society)
      .execute('sp_usefull_contact');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Neighbours
router.get('/more/Neighbours/:society',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Neighbours')
	 .input('society_id', req.params.society)
      .execute('sp_usefull_contact');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/Community/Broadcast',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Broadcast')
      .input('society_id', req.query.society_id)
	 .input('owner_id', req.query.owner_id) 
      .execute('sp_usefull_contact');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Facilities List
router.get('/Facilities/:society_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Facilities')
      .input('society_id',req.params.society_id)
      .execute('sp_usefull_contact');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/Facilities/BookingList/:flat_id',   async function (req, res) {
  try {
    const flatId = parseInt(req.params.flat_id, 10);

    if (isNaN(flatId)) {
      return res.status(400).json({ error: 'Invalid flat_id' });
    }

    const result = await db
      .request()
      .input('Operation', 'GetBookingList')
      .input('flat_id', flatId)
      .execute('sp_facility_booking');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/facility/Slot/:facility_id/:date',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'GetSlots')
      .input('facility_id', parseInt(req.params.facility_id, 10))
      .input('date', req.params.date) // must be in YYYY-MM-DD format
      .execute('sp_facility_booking');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Notifications/:society_id/:owner_id',  async (req, res) => {
	

  try {
    const result = await db.request()
      .input('operation', 'GetNotifications')
      .input('society_id', req.params.society_id)
      .input('owner_id', req.params.owner_id)
      .execute('sp_notification');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Visitingtype',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'GetVisitingTypes')
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/ProductBuy/:society_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'GetProductsForSociety')
      .input('society_id', req.params.society_id)
      .execute('sp_product');
      
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*router.get('/ProductBuy/ViewProduct',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'GetProductDetails')
      .input('product_id', req.query.product_id)
      .execute('sp_product');
      
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});*/

router.get('/ProductBuy/ViewProduct/:product_id',  async (req, res) => {
  try {
    const productId = req.params.product_id; // get ID from URL path
   // const pool = await db.connect(); // or your connection logic

    const result = await db.request()
      .input('operation', 'GetProductDetails')
      .input('product_id',  productId)
      .execute('sp_product');

    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});



// Get products by owner
router.get('/OwnerProductBuy/:society_id/:owner_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'GetOwnerProducts')
      .input('society_id', req.params.society_id)
      .input('owner_id', req.params.owner_id)
      .execute('sp_product');
      
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET today’s visitors or all visitors by flat
router.get('/visitor/:date/:flat_id', async (req, res) => {
  try {
    const operation = req.params.date === "today" ? "today" : "byFlat";

    const result = await db.request()
      .input('operation', operation)
      .input('flat_id', req.params.flat_id)
      .execute('sp_visitor');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET all visitors by flat (legacy endpoint)
router.get('/visitor/:flat_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'byFlat')
      .input('flat_id', req.params.flat_id)
      .execute('sp_visitor');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// GET visitor details
router.get('/VisitorDetails/:society/:visitor_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'details')
      .input('society_id', req.params.society)
      .input('visitor_id', req.params.visitor_id)
      .execute('sp_visitor');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/NotificationDetails/:society/:type/:id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', req.params.type)   // Notice, Event, Visitor, Maintenance
      .input('society_id', req.params.society)
      .input('id', req.params.id)
      .execute('sp_notification');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/SelectPanicAlert/:owner_id', function (req, res,next) {
    db.request()
      .input("owner_id", req.params.owner_id)
      .query("SELECT name,contact,type from panic_alert where owner_id=@owner_id", function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
       res.json(rows.recordset);
});
});

/*router.get('/Maintenance/:flat_id/:bill_id',async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Select')
      .input('bill_id', req.params.bill_id)
      .input('flat_id', req.params.flat_id)
      .execute('sp_maintanance_cal');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});*/


router.get('/Maintenance/:flat_id/:bill_id',async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Select')
      .input('bill_id', req.params.bill_id)
      .input('flat_id', req.params.flat_id)
      .execute('sp_maintanance_cal');

    console.log('Maintenance recordsets count:', result.recordsets.length);
    result.recordsets.forEach((rs, i) => console.log(`recordset[${i}] rows:`, rs.length));

    const data = result.recordsets[result.recordsets.length - 1] || [];
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/Receipt/:receipt',async (req, res) => {
  try {
    const result = await db.request()
	.input('Action', 'GetReceipt')
      .input('ReceiptID', req.params.receipt)
      .execute('sp_MaintenanceReceipt');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/ParkingSlotNo/:park_for/:society_id',  async (req, res) => {
  try {
    const result = await db.request()
	.input('operation','ParkingSlot')
      .input('park_for', req.params.park_for)
      .input('society_id', req.params.society_id)
      .execute('sp_parking');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/VehicleList/:flat_id/:society_id',  async (req, res) => {
  try {
    const result = await db.request()
	.input('operation' ,'VehicleList')
      .input('flat_id', req.params.flat_id)
      .input('society_id', req.params.society_id)
      .execute('sp_parking');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Checkcontact/:pre_mob/:society_id/:build_wing_id', function (req, res,next) {
    db.request()
      .input("pre_mob", req.params.pre_mob)
      .input("society_id", req.params.society_id)
      .input("w_id", req.params.build_wing_id)
      .query("SELECT * from userdata where active_status=0 and pre_mob=@pre_mob and society_id=@society_id and w_id=@w_id", function(err,rows){
        if(err)
           return res.status(500).json({error:err.message}); 
        else
             
       res.json(rows.recordset);
});
});
router.get('/AllReadyExistMember/:Mobile/:society_id/:build_wing_id', function (req, res,next) {
    db.request()
      .input("Mobile", req.params.Mobile)
      .input("society_id", req.params.society_id)
      .input("build_wing_id", req.params.build_wing_id)
      .query("SELECT * from UserLogin where active_status=0 and Mobile=@Mobile and society_id=@society_id and build_wing_id=@build_wing_id", function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
       res.json(rows.recordset);
});
});

router.get('/SearchFlat/:society_id/:build_wing_id', function(req, res, next) {
    
    db.request()
      .input("society_id", req.params.society_id)
      .input("build_wing_id", req.params.build_wing_id)
      .query("select distinct flat_no from customer_flat where active_status=0 and society_id=@society_id and build_wing_id=@build_wing_id", function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
       res.json(rows.recordset);
});
});

router.get('/Notification/Count/:user_id/:society_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'Count')
      .input('user_id', req.params.user_id)
      .input('society_id', req.params.society_id)
      .execute('sp_notification');

    res.json(result.recordset[0]);  // returns { notification_count: X }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/HomeNoFetch/:pre_mob/:flat_id',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'HomeNoFetch')
      .input('pre_mob', req.params.pre_mob)
      .input('flat_id', req.params.flat_id)
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/FamilyMembers/:flat_id',async function (req, res,next)  {
    try {
    const result = await db.request()
      .input('operation', 'GetFamily')
      .input('flat_id', req.params.flat_id)
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/HelperList/:flat_id/:society_id',async function (req, res,next) {
    try {
    const result = await db.request()
      .input('operation', 'getHelperList')
      .input('flat_id', req.params.flat_id)
	.input('society_id', req.params.society_id)
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/SocietyPolls/:user_id/:society_id/:Audience', async (req, res) => {
	const userId=req.params.user_id;
	const audience=req.params.Audience||0
  try {
    const pollsResult = await db.request()
      .input('Mode', 'GetPolls')
      .input('user_id', userId)
      .input('society_id', req.params.society_id)
	  .input('Audience',audience)
      .execute('sp_polls');

    const polls = pollsResult.recordset; // ✅ this is the array

    for (let poll of polls) {
      const optionsResult = await db.request()
        .input('Mode', 'pollVotes')
        .input('pollId', poll.PollId) // ✅ should use poll, not polls
        .execute('sp_polls');

      const options = optionsResult.recordset;

      if (userId != 0) {
        const userVotesResult = await db.request()
          .input('Mode', 'UserVotes')
          .input('pollId', poll.PollId) // ✅ typo fixed: poll not polls
          .input('user_id', req.params.user_id)
          .input('society_id', req.params.society_id)
          .execute('sp_polls');

        const userVotes = userVotesResult.recordset;
        const votedOptionIds = userVotes.map(vote => vote.option_id);

        poll.options = options.map(option => ({
          ...option,
          isSelected: votedOptionIds.includes(option.OptionId)
        }));
      } else {
        poll.options = options.map(option => ({
          ...option,
          isSelected: false
        }));
      }
    }

    res.json({
      success: true,
      polls
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch polls",
      error: error.message
    });
  }
});


router.get('/familyHelper/getPersonList', async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'fill_list')
      .execute('sp_usefull_contact');

    res.json(result.recordset);  
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/FamilyMemberHelper/:flat_id',async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'getFamilyHelpers')
	  .input('flat_id' , req.params.flat_id)
      .execute('sp_usefull_contact');

    res.json(result.recordset);  
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get("/polls/:pollId/votes", async (req, res) => {
  try {
    const { pollId } = req.params;

    const result = await db.request()
      .input("Operation", "SELECT")
      .input("Poll_id", pollId)
      .execute("sp_PollVoting");

    res.json({ success: true, votes: result.recordset });
  } catch (error) {
    console.error("Fetch Votes Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});


router.get('/OwnerDocumentsList/:flat_id',async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'GetOwnerDocs')
	  .input('flat_id' , req.params.flat_id)
      .execute('sp_doc_master');

    res.json(result.recordset);  
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/Complainttype',  async (req, res) => {
  try {
    const result = await db.request()
      .input('operation', 'ComplaintType')
      .execute('sp_usefull_contact');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 