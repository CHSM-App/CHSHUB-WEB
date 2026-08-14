using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_FillRepeater
    {
        stored st = new stored();
        stored st2 = new stored();
        public void fill_list(Repeater list_box, string sqlstring)
        {
            st.fill_list(list_box, sqlstring);
        }

        public void fill_list_maintanace(Repeater list_box, string sqlstring)
        {
            st2.fill_list_maintanace(list_box, sqlstring);
        }
    }
}