using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Sockets;
using System.Security.Principal;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Vendor_Bills
    {

        stored st = new stored();

        public Vendor create_Bill(Vendor vendor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", vendor.Sql_Operation));
            data_item.Add(st.create_array("bill_number", vendor.BillNo));
            data_item.Add(st.create_array("bill_date", vendor.BillDate));
            data_item.Add(st.create_array("service", vendor.Service));
            data_item.Add(st.create_array("vendor_id", vendor.vendor_id));
            data_item.Add(st.create_array("notes", vendor.Note));
            data_item.Add(st.create_array("subtotal", vendor.SubTotal));
            data_item.Add(st.create_array("tax_amount", vendor.TaxAmount));
            data_item.Add(st.create_array("total_amount", vendor.TotalAmount));
            data_item.Add(st.create_array("desc", vendor.Description));
            data_item.Add(st.create_array("society_id", vendor.Society_Id));
            data_item.Add(st.create_array("created_by", vendor.User_id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done" && sdr != null && sdr.HasRows)
            {
                sdr.Read();

                // ✅ Check if bill_id is -1 (indicates error)
                int billId = sdr["bill_id"] != DBNull.Value ? Convert.ToInt32(sdr["bill_id"]) : 0;

                if (billId == -1)
                {
                    // ✅ Duplicate staff detected
                    vendor.Bill_id = -1;
                    vendor.Message = sdr["error_message"] != DBNull.Value
                        ? sdr["error_message"].ToString()
                        : "Staff salary bill already exists for this month";

                    // ✅ Store duplicate staff names and bill numbers
                    vendor.DuplicateStaffNames = sdr["duplicate_staff"] != DBNull.Value
                        ? sdr["duplicate_staff"].ToString()
                        : "";
                    vendor.ExistingBillNumbers = sdr["existing_bill_numbers"] != DBNull.Value
                        ? sdr["existing_bill_numbers"].ToString()
                        : "";

                    vendor.Sql_Result = "DUPLICATE";
                }
                else
                {
                    // ✅ Success
                    vendor.Bill_id = billId;
                    vendor.Sql_Result = "Done";
                }
            }
            else
            {
                vendor.Bill_id = 0;
                vendor.Sql_Result = "Failed";
            }

            if (sdr != null)
            {
                sdr.Close();
                sdr.Dispose();
            }

            return vendor;
        }
        public DataTable fill_Bills(string operation, int vendor_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));

            data_item.Add(st.create_array("vendor_id", vendor_id));

            status1 = st.run_query(data_item, "Select", "sp_Vendor_Bill_Payments", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable getBillItems_ApprovalList(Vendor vendor)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", vendor.Sql_Operation));
            data_item.Add(st.create_array("bill_id", vendor.BillNo));
            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable getVendorBills(Vendor vendor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", vendor.Sql_Operation));
            data_item.Add(st.create_array("society_id", vendor.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done" && sdr.HasRows)
                dt.Load(sdr);

            return dt;
        }

        public DataTable grid_show(Vendor vendor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", vendor.Sql_Operation));
            data_item.Add(st.create_array("society_id", vendor.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bill_payments", ref sdr);

            if (status1 == "Done" && sdr.HasRows)
                dt.Load(sdr);

            return dt;
        }

        public Vendor saveVendorBill(Vendor vendor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
       
            data_item.Add(st.create_array("operation", vendor.Sql_Operation));
            data_item.Add(st.create_array("society_id", vendor.Society_Id));
            data_item.Add(st.create_array("vendor_id", vendor.vendor_id));
            data_item.Add(st.create_array("pay_mode", vendor.PayMode));
            data_item.Add(st.create_array("cheque_no", vendor.ChequeNo));
            data_item.Add(st.create_array("cheque_date", vendor.ChequeDate));
            data_item.Add(st.create_array("bank_name", vendor.BankName));
            data_item.Add(st.create_array("transaction_ref", vendor.TransactionRef));
            data_item.Add(st.create_array("bill_details", vendor.BillIds));
            data_item.Add(st.create_array("remarks", vendor.Remark));
            data_item.Add(st.create_array("paid_amount", vendor.TotalAmount));
            data_item.Add(st.create_array("created_by", vendor.User_id));
            data_item.Add(st.create_array("file_path", vendor.FilePath));


            status1 = st.run_query(data_item, "Select", "sp_vendor_bill_payments", ref sdr);

            if(status1 == "Done")
            {
                vendor.Sql_Result = status1;
            }

            return vendor;
  
        }

      
        public Vendor Select_vendor_bill(Vendor vendor)
        {
            ICollection<System.Collections.ArrayList> data_item =
                new List<System.Collections.ArrayList>();

            SqlDataReader dr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", vendor.Sql_Operation));
            data_item.Add(st.create_array("bill_id", vendor.Bill_id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref dr);

            // SAFETY CHECK
            if (dr == null)
            {
                throw new Exception("Database error: Reader is null.");
            }

            if (vendor.Sql_Operation.Equals("select", StringComparison.OrdinalIgnoreCase))
            {
                if (!dr.HasRows)
                {
                    // ✅ HANDLE NO DATA CASE
                    vendor.Message = "No bill data found.";
                    return vendor;
                }

                // ✅ MOVE TO FIRST ROW
                dr.Read();

                vendor.BillNo = dr["bill_number"]?.ToString();

                vendor.BillDate = dr["bill_date"] != DBNull.Value
                    ? Convert.ToDateTime(dr["bill_date"])
                    : DateTime.MinValue;

                vendor.Service = dr["service_type"] != DBNull.Value
                    ? Convert.ToInt32(dr["service_type"])
                    : 0;

                vendor.VendorName = dr["vendor_name"]?.ToString();
                vendor.GstNo = dr["gst_no"]?.ToString();
                vendor.Description = dr["description"]?.ToString();

                vendor.SubTotal = dr["subtotal"] != DBNull.Value
                    ? Convert.ToDecimal(dr["subtotal"])
                    : 0;

                vendor.TaxAmount = dr["tax_amount"] != DBNull.Value
                    ? Convert.ToDecimal(dr["tax_amount"])
                    : 0;

                vendor.TotalAmount = dr["total_amount"] != DBNull.Value
                    ? Convert.ToDecimal(dr["total_amount"])
                    : 0;

                vendor.PaidAmount = dr["paid_amount"] != DBNull.Value
                    ? Convert.ToDecimal(dr["paid_amount"]).ToString("0.00")
                    : "0.00";

                vendor.RemainingAmount = dr["remaining_amount"] != DBNull.Value
                    ? Convert.ToDecimal(dr["remaining_amount"]).ToString("0.00")
                    : "0.00";
            }

            dr.Close();
            dr.Dispose();

            return vendor;
        }


        public void Update_status(Society_Member member)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", member.Sql_Operation));
            data_item.Add(st.create_array("approval_id", member.Approval_id));
            data_item.Add(st.create_array("notes", member.Remark));
            data_item.Add(st.create_array("status", member.Status));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

        }

        public DataTable view_bill(receipt billReceipt)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", billReceipt.Sql_Operation));
            data_item.Add(st.create_array("society_id", billReceipt.Society_Id));
            data_item.Add(st.create_array("bill_id", billReceipt.BillId));


            status1 = st.run_query(data_item, "Select", "sp_vendor_bill_payments", ref sdr);

            if (status1 == "Done" && sdr.HasRows)
                dt.Load(sdr);

            return dt;
        }
       
    }

}