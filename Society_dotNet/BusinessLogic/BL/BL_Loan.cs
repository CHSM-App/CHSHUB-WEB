using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.BL
{
    public class BL_Loan
    {
        DA_Loan A_Loan = new DA_Loan();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            A_Loan.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable GetLoan(Loan l_Loan)
        {
            return A_Loan.getloan(l_Loan);

        }
        public Loan Update_Loan(Loan l_Loan)
        {
            return A_Loan.updateloan(l_Loan);

        }
        public Loan delete(Loan l_Loan)
        {
            return A_Loan.Loan_Delete(l_Loan);

        }

        public object search_loan(Loan getLoan)
        {
            return A_Loan.loan_search(getLoan);
        }

        public DataTable fill_list(string operation, string society_id)
        {
            return A_Loan.fill_list(operation, society_id);
        }
    }
}