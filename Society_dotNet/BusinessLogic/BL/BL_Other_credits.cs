using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.BL
{
    public class BL_Other_credits
    {
        DA_Other_credits credits = new DA_Other_credits();

        public maintenance add_other_credits(maintenance maintenance)
        {
                return credits.add_other_credits(maintenance);
        }

        public DataTable Get_other_credits(maintenance maintenance)
        {
            return credits.Get_other_credits(maintenance);
        }

        public maintenance Get_other_credits_by_Id(maintenance maintenance)
        {
            return credits.Get_other_credits_by_Id(maintenance);
        }
    }
}