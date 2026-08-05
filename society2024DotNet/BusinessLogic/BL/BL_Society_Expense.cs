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
    public class BL_Society_Expense
    {
        DA_Society_Expense dA_Society = new DA_Society_Expense();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Society.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable GetExpense(Society_Expense expense)
        {
            return dA_Society.getExpenseDetails(expense);

        }
        public DataTable GetApprover(Society_Expense expense)
        {
            return dA_Society.get_approver(expense);

        }
        public Society_Expense UpdateExpense(Society_Expense expense)
        {
            return dA_Society.update_expense(expense);

        }
        public Society_Expense delete(Society_Expense expense)
        {
            return dA_Society.Delete_Expense(expense);

        }

        public DataTable search_society_expense(Society_Expense expense)
        {
            return dA_Society.society_expense_search(expense);
        }

        public DataTable Get_Expense_Report(Society_Expense expense)
        {
            return dA_Society.get_expense_report(expense);
        }

        public DataTable chk_reg_exp(Society_Expense society)
        {
            return dA_Society.Chk_Reg_Exp(society);
        }
        public Society_Expense Fetch_Expense(Society_Expense society)
        {
            return dA_Society.expense_fetch(society);
        }

        public Society_Expense updateApprover(Society_Expense society)
        {
            return dA_Society.Update_Approver(society);
        }

        public DataTable fill_list(string operation, string society)
        {
            return dA_Society.fill_list(operation, society);
        }

        public Society_Expense runproc_select(Society_Expense society)
        {
            return dA_Society.Select_expense(society);
        }

        public Society_Expense update_status(Society_Expense society)
        {
            return dA_Society.Update_Status(society);
        }
    }
}