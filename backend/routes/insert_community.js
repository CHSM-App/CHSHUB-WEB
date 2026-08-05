var express = require('express');
const auth = require('./middleware/auth');
var db = require("./db");
const sql = require('mssql'); 
var router = express.Router();
router.post('/event', function (req, res) { 
       db.query( 
        "Exec sp_notice_master @operation='Update',@event_name='" +  req.body.name + "',@description='"+req.body.description+"',@from_date='"+req.body.date+"',@to_date='"  + req.body.valid_to +
         "',@society_id='" +req.body.society_id + "'" , function (err, result) {
        if (err)
            return res.status(500).json({ error: err.message });
        else{
            if (req.body.event_id == 0)
                return res.json({ event_id: result.recordset[0].event_id })
            return res.status(200).json({event_id:result.recordset[0].event_id})
        }
    });
});
router.post('/notice', function (req, res) {
    var sql = "Exec sp_notice_master @operation='Update',@name='" +  req.body.name + "',@description='"+req.body.description+"',@date='"+req.body.date+"',@valid_to='" + req.body.valid_to + "',@society_id='" +req.body.society_id + "'";
    db.query(sql, function (err, result) {
        if (err)
            return res.status(500).json({ error: err.message });
        else{
            if (req.body.notice_id == 0)
                return res.json({ notice_id: result.recordset[0].notice_id })
            return res.status(200).json({event_id:result.recordset[0].notice_id})
        }
    });
});
router.post('/staff', function (req, res) {
    var sql = "Exec sp_staff_master @operation='Update',@name='" + req.body.name + "',@address='"+req.body.address+"',@contact_no'"+req.body.contact_no +"',@email='" + req.body.email + "',@date_of_join='" + req.body.date_of_join + "',@society_id='" +req.body.society_id + "',@role_id=" + req.body.Role + ",@image='" +req.body.image+"'";
 
    db.query(sql, function (err, result) {
        if (err)
            return res.status(500).json({ error: err.message });
        else{
            return res.status(200).json({message:"Successfully"})
        }
    });
});

router.post('/Facility', function (req, res, next) {
console.log("Exec sp_facility @operation='Update', @facility_id=" + req.body.facility_id + ",@name='" + req.body.name + "', @slot=" + req.body.slot + " , @description='" + req.body.description + "' , @society_id='" + req.body.society_id + "', @cost='" + req.body.cost + "'")
    db.query("Exec sp_facility @operation='Update', @facility_id=" + req.body.facility_id + ",@name='" + req.body.name + "', @slot=" + req.body.slot + " , @description='" + req.body.description + "' , @society_id='" + req.body.society_id + "', @cost='" + req.body.cost + "'", function (err, rows) {
        if (err)
            return res.status(500).json({ error: err.message });
        else {

            if (req.body.facility_id == 0)

                return res.json({ facility_id: rows.recordset[0].facility_id })
            
            return res.status(200).json({ message: "Successfully" })
        }
    });
});

router.post('/Facility/Slots', function(req, res, next) {
    db.query("Exec sp_facility @operation='S_Update',@slot_id=0, @facility_id="+req.body.facility_id+ ",@start_time='"+req.body.start_time+"', @end_time='"+req.body.end_time+"' , @society_id='"+req.body.society_id+"'",function(err,rows){
        if(err)
           return res.status(500).json({error:err.message});      
        return res.status(200).json({message:"Successfully"})
});
});

router.post('/Expense', function (req, res, next) {
db.query("Exec sp_society_expense @operation='Update', @build_id=" + req.body.build_id + ",@date='" + req.body.date + "', @ex_type=" + req.body.ex_type + " , @ex_details='" + req.body.ex_details + "', @comments='" + req.body.comments + "', @ex_name='" + req.body.ex_name + "', @amount='" + req.body.amount + "', @tds='" + req.body.tds + "', @tax='" + req.body.tax + "', @f_amount='" + req.body.f_amount + "' , @society_id='" + req.body.society_id + "', @regular='" + req.body.regular + "', @add_maintanance=1, @status=" + req.body.status, function (err, rows) {
        if (err)
            return res.status(500).json({ error: err.message });
        else {

            if (req.body.expense_id == 0)

                return res.json({ expense_id: rows.recordset[0].expense_id })
            
            return res.status(200).json({ message: "Successfully" })
        }
    });
});

router.post('/Expense/Approval', function (req, res, next) {
   

    db.query("Exec sp_approvar @operation='Update', @user_id=" + req.body.user_id + ",@expense_id=" + req.body.expense_id , function (err, rows) {
        if (err)
            return res.status(500).json({ error: err.message });
        else {          
            return res.status(200).json({ message: "Successfully" })
        }
    });
});

router.post('/comments',  async (req, res, next) => {
  try {
    const {  helpdesk_id, owner_id, flat_id, type, description } = req.body;
    await db.request()
      .input("operation",  "InsertComments")
      .input("helpdesk_id",helpdesk_id)
      .input("owner_id", owner_id)
      .input("flat_id",  flat_id)
      .input("type",  type)
      .input("description",  description)
      .execute("sp_helpdesk");

    res.status(200).json({ message: "Comment inserted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/ManageFacility/:f_id/:status', function (req, res, next) {

    db.query("Update facilities set status="+req.params.status+" where facility_id = "+req.params.f_id, function (err, rows) {
        if (err)
            return res.status(500).json({ error: err.message });
        else {
            return res.status(200).json({ message: "Successfully" })
        }
    });
});

module.exports = router; 