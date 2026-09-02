/*
 * Deletion endpoints for the mobile apps.
 *
 * Two things were wrong with every route in this file and have been fixed
 * throughout:
 *
 *   1. None of them required a token. `auth` was imported and never used, and
 *      app.js mounted this router at '/' with no `protect`, so anonymous
 *      callers could delete records by id over the open internet.
 *
 *   2. Ids were concatenated into SQL. `@parking_id=` + req.params.p_id let a
 *      caller close the statement and append their own — a full injection into
 *      a connection with write access to the whole database.
 *
 * `protect` is attached per route rather than with router.use, because this
 * router is mounted at '/': middleware registered here would run for every
 * request the server receives, including /login.
 *
 * Still outstanding: these handlers delete whatever id they are given. A token
 * proves the caller is *a* resident, not that the record is theirs. Ownership
 * checks belong in the stored procedures, scoped by the caller's identity.
 */
var express = require('express');
var db = require("./db");
var router = express.Router();
const protect = require('./middleware/protect');
const { requireOwnership } = require('./middleware/ownership');

/* GET home page. */
router.get('/', function(req, res, next) {
    res.send('Welcome to NODE.JS');
   });

/**
 * Run a stored procedure with named parameters and answer with `body`.
 * Replaces the repeated db.query(string concatenation) in this file.
 */
function callProc(res, procName, params, body) {
    const request = db.request();
    for (const [name, value] of Object.entries(params)) {
        request.input(name, value);
    }
    request.execute(procName, function (err) {
        if (err) return res.status(500).json({ error: err.message });
        return res.status(200).json(body);
    });
}

//Add Vehicle
router.delete('/Home/DeleteVehicle/:p_id', protect, requireOwnership('parking', r => r.params.p_id), function(req, res, next){
    callProc(res, 'sp_parking_master',
        { operation: 'Delete', parking_id: req.params.p_id },
        { success: true, message: "Record Deleted Successfully" });
});


//Expected Visitor
router.delete('/DeleteExpectedVisitor/:v_id', protect, requireOwnership('visitor', r => r.params.v_id), function(req, res, next) {
    callProc(res, 'sp_Visitor',
        { operation: 'Delete', visitor_id: req.params.v_id },
        { success: true, message: "Record Deleted Successfully" });
});


//Add Family
router.delete('/DeleteFamilyMember/:o_ex_id', protect, requireOwnership('ownerext', r => r.params.o_ex_id), function(req, res, next) {
    callProc(res, 'sp_owner_master',
        { operation: 'D_delete', o_ex_id: req.params.o_ex_id },
        { success: true, message: "Record Deleted Successfully" });
});

router.delete('/DeleteFamilyVehicle/:id', protect, requireOwnership('vehicle', r => r.params.id), function(req, res, next) {
    callProc(res, 'sp_parking',
        { operation: 'deleteFamilyVehicle', vehicle_id: req.params.id },
        { success: true, message: "Record Deleted Successfully" });
});


//Helpdesk Request
// The old query read "@operation='DeleteRequest' @helpdesk_id=" — no comma
// between the arguments — and its callback ignored `err`, so a failure was
// reported to the app as a successful delete.
router.delete('/DeleteHelpdeskRequest/:helpdesk_id', protect, function (req, res, next) {
    callProc(res, 'sp_helpdesk',
        { operation: 'DeleteRequest', helpdesk_id: req.params.helpdesk_id },
        { success: true, message: "Record Deleted" });
});


//Product Deatils
router.delete('/DeleteProduct/:product_id', protect, function (req, res, next) {
    // Images first: they reference the product, and the original deleted the
    // product before its images, which leaves orphans if the second fails.
    const request = db.request().input('product_id', req.params.product_id);
    request.query('delete from Product_Images where product_id=@product_id', function (err) {
        if (err) return res.status(500).json({ error: err.message });

        db.request()
            .input('product_id', req.params.product_id)
            .query('delete from Product_Sell where product_id=@product_id', function (err2) {
                if (err2) return res.status(500).json({ error: err2.message });
                return res.status(200).json({ success: true, message: "Record Deleted" });
            });
    });
});



 //Panic Alert
// The original read "where owner_id= AND contact=" + o_id, with `contact` passed
// as a stray second argument — invalid SQL, so this route always failed.
router.delete('/DeletePanicAlert/:o_id/:contact', protect, function(req, res, next) {
    db.request()
        .input('owner_id', req.params.o_id)
        .input('contact', req.params.contact)
        .query('delete from panic_alert where owner_id=@owner_id AND contact=@contact', function (err) {
            if (err) return res.status(500).json({ error: err.message });
            return res.status(200).json({ success: true, message: "Record Deleted" });
        });
});

router.delete('/Delete/Helper/Review/:id', protect, function(req, res, next) {
    db.request()
        .input('review_id', req.params.id)
        .query('Update helperReview set active_status=1 where review_id=@review_id', function (err) {
            if (err) return res.status(500).json({ error: err.message });
            return res.status(200).json({ success: true, message: "Record Deleted" });
        });
});


router.delete('/Delete/FacilityBooking/:book_id', protect, function(req, res, next) {
    callProc(res, 'sp_facility_booking',
        { operation: 'Delete', facility_book_id: req.params.book_id },
        { success: true, message: "Record Deleted" });
});

router.delete('/Delete/Facility/Slot/:slot_id', protect, function(req, res, next) {
    callProc(res, 'sp_facility',
        { operation: 'Delete_Slot', slot_id: req.params.slot_id },
        { success: true, message: "Record Deleted" });
});

router.delete('/familyHelper/delete/:id', protect, async (req, res) => {
  try {
    const helperId = req.params.id;

    const result = await db.request()
      .input("operation", "deleteFamilyHelper")
      .input("helper_id", helperId)
      .execute("sp_usefull_contact");

    res.json({
      success: true,
      message: "Helper deleted successfully",
      data: result.recordset
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete("/polls/votes/:votingId/:userId", protect, async (req, res) => {
  try {
    const { votingId, userId } = req.params;

    const result = await db.request()
      .input("Operation", "DELETE")
      .input("Voting_Id", votingId)
      .input("User_Id", parseInt(userId))
      .execute("sp_PollVoting");

    res.json({ success: true, data: result.recordset });
  } catch (error) {
    console.error("Delete Vote Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.delete('/DeleteDocuments/:id', protect, requireOwnership('document', r => r.params.id), function(req, res, next) {
    callProc(res, 'sp_doc_master',
        { operation: 'deleteDocuments', document_id: req.params.id },
        { success: true, message: "Record Deleted Successfully" });
});


router.delete('/Delete/UnAssignToFlat/:helper_work_id', protect, function(req, res, next) {
    db.request()
        .input('helper_work_id', req.params.helper_work_id)
        .query('Update helperWorkAt set active_status=1 where helper_work_id=@helper_work_id', function (err) {
            if (err) return res.status(500).json({ error: err.message });
            return res.status(200).json({ success: true, message: "Record Deleted" });
        });
});


module.exports = router;
