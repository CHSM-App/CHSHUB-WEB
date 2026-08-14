using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace BusinessLogic.MasterBL
{
    public class BL_User_Login
    {
        DA_User_Login dA_User = new DA_User_Login();
        public Login_Details GetLoginByUsername(string username)
        {
            return dA_User.GetLoginByUsername(username);
        }


        public Society_Member CheckDuplicateUsername(Society_Member member)
        {
            return dA_User.CheckDuplicateUsername(member);
        }
        public Login_Details UpdateLoginDetails(Login_Details login)
        {
           
            return dA_User.UpdateLoginDetails(login);
        
        }

        public DataTable get_single_receipt(Login_Details details)
        {
            // Implement DB call logic using ADO.NET or your DAL
            return dA_User.single_receipt(details);
        }


        public Login_Details Generate_Token(Login_Details details)
        {

            return dA_User.generate_token(details);
        }
        public DataTable getEventDetails(Login_Details details)
        {
            
            return dA_User.Event_Details(details);
        }

        public DataTable getmeeting(Login_Details details)
        {
           
            return dA_User.Meeting_Details(details);
        }

        public DataTable getnotice(Login_Details details)
        {
            
            return dA_User.Notice_Details(details);
        }

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_User.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable getmaintenance(Login_Details details)
        {
           
            return dA_User.Maintenance_Details(details);
        }

        public DataTable getreceipt(Login_Details details)
        {
           
            return dA_User.Receipt_Details(details);
        }

        public Login_Details getmail(Login_Details details)
        {
           
            return dA_User.Get_Mail(details);
        }

        public DataTable get_expense_chart(Login_Details details)
        {
           
            return dA_User.Get_Expense_Chart(details);
        }

        public DataTable get_recent_chart(Login_Details details)
        {

            return dA_User.Get_Recent_Chart(details);
        }

        public DataTable get_recent_Search(Login_Details details)
        {

            return dA_User.Get_Recent_Search(details);
        }

        public Login_Details InsertPayment(Login_Details details)
        {
            return dA_User.InsertPayment(details);
        }

        public DataTable Get_Pdc_Clearing(Login_Details details)
        {
           
            return dA_User.Pdc_Clear(details);
        }

        public DataTable income_chart(Login_Details details)
        {
           
            return dA_User.Income_Chart(details);
        }

        public Login_Details getticket(Login_Details details)
        {
           
            return dA_User.GetTicket(details);
        }

        public DataTable search_admin(Login_Details details)
        {
            return dA_User.Search_Admin(details);
        }

        public DataTable society_receipt(Login_Details details)
        {
            return dA_User.Search_receipt(details);
        }


            public DataTable show_receipt(Login_Details details)
            {
                return dA_User.show_receipt(details);
            }

            public DataTable get_notification(Login_Details details)
        {
            return dA_User.get_notification(details);
        }

        public Login_Details UpdateNotifyStatus(Login_Details login)
        {
            return dA_User.UpdateNotifyStatus(login);
        }

        public Login_Details getResidents(Login_Details details)
        {
            return dA_User.getResidents(details);
        }

        public DataTable getmonth(Login_Details details)
        {
            
            return dA_User.GetMonth(details);
        }

        public DataTable getdefaulter(Login_Details details)
        {
           
            return dA_User.GetDefaulter(details);
        }
        public DataTable dashUpdates(Login_Details details)
        {

            return dA_User.dashUpdates(details);
        }
        public DataTable search_defaulter(Login_Details details)
        {
            
            return dA_User.SearchDefaulter(details);
        }

        public int get_messages_count(Login_Details details)
        {
            return dA_User.get_messages_count(details);
        }

        public DataTable getOwnerDues(Login_Details details)
        {
           return dA_User.getOwnerDues(details);
        }
    }
}

