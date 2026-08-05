var express = require('express');
var db = require("./db");
const { pool } = require('mssql');
var router = express.Router();
const auth = require('./middleware/auth');
const fs = require('fs');
const path = require('path');
/* GET home page. */ 
router.get('/', function(req, res, next) {
    res.send('Welcome to NODE.JS');
   });
//Add Vehicle 
router.delete('/Home/DeleteVehicle/:p_id', function(req, res, next){
    
    db.query("Exec sp_parking_master @operation='Delete', @parking_id="+req.params.p_id,function(err,rows){
        if (err)
            return res.status(500).json({ error: err.message });
        else {
           
            return res.status(200).json({ success:true ,message: "Record Deleted Successfully" });
        } 

    });
});


//Expected Visitor
router.delete('/DeleteExpectedVisitor/:v_id', function(req, res, next) {

    db.query("Exec sp_Visitor @operation='Delete', @visitor_id="+req.params.v_id,function(err,rows){
        if (err)
            return res.status(500).json({ error: err.message });
        else {
          
            return res.status(200).json({success:true , message: "Record Deleted Successfully" });
        }

    });
});


//Add Family
router.delete('/DeleteFamilyMember/:o_ex_id', function(req, res, next) {
    
    db.query("Exec sp_owner_master @operation='D_delete',@o_ex_id="+req.params.o_ex_id,function(err,rows){
        if (err)
            return res.status(500).json({ error: err.message });
        else {
            
            return res.status(200).json({success:true ,  message: "Record Deleted Successfully" });
        }

    });
});

router.delete('/DeleteFamilyVehicle/:id', function(req, res, next) {
    
    db.query("Exec sp_parking @operation='deleteFamilyVehicle',@vehicle_id="+req.params.id,function(err,rows){
        if (err)
            return res.status(500).json({ error: err.message });
        else {
            
            return res.status(200).json({success:true ,  message: "Record Deleted Successfully" });
        }

    });
});


//Helpdesk Request
router.delete('/DeleteHelpdeskRequest/:helpdesk_id', function (req, res, next) {
  
        db.query("Exec sp_helpdesk @operation='DeleteRequest' @helpdesk_id="+req.params.helpdesk_id,function(err,rows){
            return res.status(200).json({success:true , message:"Record Deleted"});  
        });

    });
 


//Product Deatils
    router.delete('/DeleteProduct/:product_id', function (req, res, next) {
        db.query("delete from Product_Sell where product_id="+req.params.product_id,function(err,rows){
            db.query("delete from Product_Images where product_id="+req.params.product_id,function(err,rows){
                return res.status(200).json({success:true , message:"Record Deleted"});  
            });
    
        });
        });



 //Panic Alert       
router.delete('/DeletePanicAlert/:o_id/:contact', function(req, res, next) {
    db.query("delete from panic_alert where owner_id= AND contact="+req.params.o_id,+req.params.contact,function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
        else
        return res.status(200).json({success:true , message:"Record Deleted"});   
});
});

router.delete('/Delete/Helper/Review/:id', function(req, res, next) {
    db.query("Update helperReview set active_status=1 where review_id="+req.params.id,function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
        else
        return res.status(200).json({success:true , message:"Record Deleted"});   
});
});

/*router.delete('/Delete/Helper/UnAssignToFlat/:userfull_contact_id/:maid/:f_id', function(req, res, next) {
    db.query("Update helperWorkAt set active_status=1 where userfull_contact_id= "+req.params.userfull_contact_id+" AND servent_id= "+req.params.maid+" And flat_id="+req.params.f_id,function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
        else
        return res.status(200).json({success:true , message:"Record Deleted"});   
});
});*/


router.delete('/Delete/FacilityBooking/:book_id', function(req, res, next) {
  
    db.query("Exec sp_facility_booking @operation='Delete',@facility_book_id = "+req.params.book_id, function(err, rows) {
        if (err) {
            return res.status(500).json({ error: err.message });
        } else {
            return res.status(200).json({success:true , message: "Record Deleted" });
        }
    });
});

router.delete('/Delete/Facility/Slot/:slot_id', function(req, res, next) {
  
    db.query("Exec sp_facility @operation='Delete_Slot',@slot_id = "+req.params.slot_id, function(err, rows) {
        if (err) {
            return res.status(500).json({ error: err.message });
        } else {
            return res.status(200).json({success:true , message: "Record Deleted" });
        }
    });
});

router.delete('/familyHelper/delete/:id', async (req, res) => {
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

router.delete("/polls/votes/:votingId/:userId", async (req, res) => {
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

router.delete('/DeleteDocuments/:id', function(req, res, next) {
    
    db.query("Exec sp_doc_master @operation='deleteDocuments',@document_id="+req.params.id,function(err,rows){
        if (err)
            return res.status(500).json({ error: err.message });
        else {
            
            return res.status(200).json({success:true ,  message: "Record Deleted Successfully" });
        }

    });
});


router.delete('/Delete/UnAssignToFlat/:helper_work_id', function(req, res, next) {
    db.query("Update helperWorkAt set active_status=1 where helper_work_id="+req.params.helper_work_id,function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
        else
        return res.status(200).json({success:true , message:"Record Deleted"});   
});
});





module.exports = router;