using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class Inventory
    {
        private int itemid;
        private string itemname;
        private string category;
        private string description;
        private int quantity;
        private int supplierid;
        private string unit;
        private string location;
        private DateTime? purchaseDate;
        private decimal purchaseCost;
        private string supplierName;
        private string conditionStatus;
        private DateTime? lastAuditDate;
        private string remarks;
        private DateTime createdAt;
        private DateTime updatedAt;
       
        private string societyid;
        private string operation;
        private int vendor_bill_id;
        private string result;
        private int tax;
        private int total_amount;
        private int warranty;
        private DateTime? warranty_last_date;


        // Primary Key

        public int Total_Amount
        {
            get { return total_amount; }
            set { total_amount = value; }
        }
        public int Tax
        {
            get { return tax; }
            set { tax = value; }
        }
        public int Vendor_bill_ID
        {
            get { return vendor_bill_id; }
            set { vendor_bill_id = value; }
        }
        public int Item_Id
        {
            get { return itemid; }
            set { itemid = value; }
        }

        // Item name
        public string Item_Name
        {
            get { return itemname; }
            set { itemname = value; }
        }

        // Category (Electrical, Cleaning, etc.)
        public string Category
        {
            get { return category; }
            set { category = value; }
        }

        // Description
        public string Description
        {
            get { return description; }
            set { description = value; }
        }

        // Quantity
        public int Quantity
        {
            get { return quantity; }
            set { quantity = value; }
        }

        // Unit (pcs, liters, etc.)
        public string Unit
        {
            get { return unit; }
            set { unit = value; }
        }

        // Storage Location
        public string Location
        {
            get { return location; }
            set { location = value; }
        }

        // Purchase Date
        public DateTime? Purchase_Date
        {
            get { return purchaseDate; }
            set { purchaseDate = value; }
        }

        // Purchase Cost
        public decimal Purchase_Cost
        {
            get { return purchaseCost; }
            set { purchaseCost = value; }
        }

        // Supplier / Vendor Name
        public string VendorName
        {
            get { return supplierName; }
            set { supplierName = value; }
        }
        public int VendorId
        {
            get { return supplierid; }
            set { supplierid = value; }
        }
        // Condition Status (New, Good, Needs Repair, etc.)
        public string Condition_Status
        {
            get { return conditionStatus; }
            set { conditionStatus = value; }
        }

        // Last Audit Date
        public DateTime? Last_Audit_Date
        {
            get { return lastAuditDate; }
            set { lastAuditDate = value; }
        }

        // Remarks / Notes
        public string Remarks
        {
            get { return remarks; }
            set { remarks = value; }
        }

        // Created At
        public DateTime Created_At
        {
            get { return createdAt; }
            set { createdAt = value; }
        }

        // Updated At
        public DateTime Updated_At
        {
            get { return updatedAt; }
            set { updatedAt = value; }
        }

        // For society reference
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }

        public int Warranty
        {
            get { return warranty; }
            set { warranty = value; }
        }
        // Operation name for stored procedure
        public string Sql_Operation
        {
            get { return operation; }
            set { operation = value; }
        }
        public string Result
        {
            get { return result; }
            set { result = value; }
        }
        public DateTime? Warranty_last_date
        {
            get { return warranty_last_date; }
            set { warranty_last_date = value; }
        }

    }
}