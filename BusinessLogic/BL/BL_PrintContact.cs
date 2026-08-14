using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_PrintContact
    {
        DA_PrintContact DA_Print = new DA_PrintContact();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            DA_Print.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable button_click(usefull_Contact printContact )
        {
            return DA_Print.Get_Report(printContact);
        }
    }
}