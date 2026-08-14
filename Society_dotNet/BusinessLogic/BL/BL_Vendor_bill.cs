using DataAccessLayer.DA;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_Vendor_bill
    {
        DA_Vendor_Bills bills = new DA_Vendor_Bills();

        public DataTable fill_bills(string operation, int vendor_id)
        {
            return bills.fill_Bills(operation, vendor_id);
        }

        public Vendor createBill(Vendor vendor)
        {
           return bills.create_Bill(vendor);
        }


        public DataTable getBillItems_ApprovalList(Vendor vendor)
        {
            return bills.getBillItems_ApprovalList(vendor);
        }

        public DataTable getVendorBill(Vendor vendor)
        {
            return bills.getVendorBills(vendor);
        }

        public Vendor getVendorBillDetails(Vendor vendor)
        {
            return bills.Select_vendor_bill(vendor);
        }

        public Vendor saveVendorBill(Vendor vendor)
        {
            return bills.saveVendorBill(vendor);
        }

        public void Update_status(Society_Member member)
        {
            bills.Update_status(member);
        }

        public DataTable grid_show(Vendor vendor)
        {
            return bills.grid_show(vendor);
        }

        public DataTable view_bill(receipt billReceipt)
        {
            return bills.view_bill(billReceipt);
        }

       
    }
}