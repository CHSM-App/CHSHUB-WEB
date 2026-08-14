using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Vendor_Master
    {
        DA_Vendor_Master dA_Vendor = new DA_Vendor_Master();
        public DataTable getvendorDetails(Vendor vendor)
        {
           return dA_Vendor.Get_Vendor_Details(vendor);
           
        }
        public Vendor updatevendorDetails(Vendor vendor)
        {
           
            return dA_Vendor.updateVendorDetails(vendor);

        }
        public Vendor delete(Vendor vendor)
        {

            return dA_Vendor.Delete_Vendor(vendor);

        }

        public Vendor mobile_no_textchanged(Vendor vendor)
        {

            return dA_Vendor.Mobile_No_TextChanged(vendor);

        }
        public Vendor email_textchanged(Vendor vendor)
        {

            return dA_Vendor.Email_TextChanged(vendor);

        }

        public object search_vendor(Vendor vendor)
        {
            return dA_Vendor.vendor_serach(vendor);
        }
    }
}