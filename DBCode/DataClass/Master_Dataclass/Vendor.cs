using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;

namespace DBCode.DataClass.Master_Dataclass
{
    public class Vendor
    {
        private string vid;
        private string vname;
        private string contact_person;
        private string address;
        private string service_type;
        private int service;
        private string gst;
        private string contact_no;
        private string email;
        private bool status;
        private string societyid;
        private string Operation;
        private string Result;
        private string name;
        private string search_text;
        private string bill_no;
        private DateTime bill_date;
        private string note;
        private decimal sub_total;
        private decimal tax_amount;
        private decimal total_amount;
        private int bill_id;
        private int user_id;
        private string description;
        private int cost;
        private string remark;
        private int warranty;


        private string bill_ids;
        private string pay_mode;
        private string cheque_no;
        private string cheque_date;
        private string bank_name;
        private string branch;
        private string transaction_ref;
        private string file_path;
        private String status1;
        private string remaining_amount;

        private string paid_amount;
         private string due;

  



        public string FilePath
        {
            get { return file_path; }
            set { file_path = value; }
        }

        public string Remark
        {
            get { return remark; }
            set { remark = value; }
        }

        public int Cost
        {
            get { return cost; }
            set { cost = value; }
        }

        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        public string vendor_id
        {
            get { return vid; }
            set { vid = value; }
        }
        public int User_id
        {
            get { return user_id; }
            set { user_id = value; }
        }
        public int Bill_id
        {
            get { return bill_id; }
            set { bill_id = value; }
        }
        public string VendorName
        {
            get { return vname; }
            set { vname = value; }
        }
        public string ContactPerson
        {
            get { return contact_person; }
            set { contact_person = value; }
        }
        public string Address
        {
            get { return address; }
            set { address = value; }
        }
        public string GstNo
        {
            get { return gst; }
            set { gst = value; }
        }
        public string ServiceType
        {
            get { return service_type; }
            set { service_type = value; }
        }
        public string SearchText
        {
            get { return search_text; }
            set { search_text = value; }
        }
        public string Contact
        {
            get { return contact_no; }
            set { contact_no = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public bool IsActive
        {
            get { return status; }
            set { status = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string Sql_Operation
        {
            get { return Operation; }
            set { Operation = value; }
        }
        public string Sql_Result
        {
            get { return Result; }
            set { Result = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string BillNo
        {
            get { return bill_no; }
            set { bill_no = value; }
        }
        public DateTime BillDate
        {
            get { return bill_date; }
            set { bill_date = value; }
        }
        public string Note
        {
            get { return note; }
            set { note = value; }
        }
        public decimal SubTotal
        {
            get { return sub_total; }
            set { sub_total = value; }
        }
        public int Service
        {
            get { return service; }
            set { service = value; }
        }
        public decimal TaxAmount
        {
            get { return tax_amount; }
            set { tax_amount = value; }
        }
        public decimal TotalAmount
        {
            get { return total_amount; }
            set { total_amount = value; }
        }
        public string BillIds
        {
            get { return bill_ids; }
            set { bill_ids = value; }
        }
        public string PayMode
        {
            get { return pay_mode; }
            set { pay_mode = value; }
        }
        public string ChequeNo
        {
            get { return cheque_no; }
            set { cheque_no = value; }
        }
        public string ChequeDate
        {
            get { return cheque_date; }
            set { cheque_date = value; }
        }
        public string BankName
        {
            get { return bank_name; }
            set { bank_name = value; }
        }
        public string Branch
        {
            get { return branch; }
            set { branch = value; }
        }
        public string TransactionRef
        {
            get { return transaction_ref; }
            set { transaction_ref = value; }
        }
        public int Warranty
        {
            get { return warranty; }
            set { warranty = value; }
        }
        public string Status1
        {
            get { return status1; }
            set { status1 = value; }
        }
        public string RemainingAmount
        {
            get { return remaining_amount; }
            set { remaining_amount = value; }
        }
        public string PaidAmount
        {
            get { return paid_amount; }
            set { paid_amount = value; }
        }
        public string Due
        {
            get { return due; }
            set { due = value; }
        }
        public string VendorIdStr { get; set; }
        public string Message { get; set; }

      
        public string DuplicateStaffNames { get; set; }
        public string ExistingBillNumbers { get; set; }
    }
}