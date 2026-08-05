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
    public class BL_FillRepeater
    {
        DA_FillRepeater repeater = new DA_FillRepeater();

        public void fill_list(Repeater drp_down, string sqlstring)
        {
            repeater.fill_list(drp_down, sqlstring);
        }

        public void fill_list_maintanace(Repeater drp_down, string sqlstring)
        {
            repeater.fill_list_maintanace(drp_down, sqlstring);
        }
    }
}  