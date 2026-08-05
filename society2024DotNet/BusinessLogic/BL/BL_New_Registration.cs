
using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    
    public class BL_New_Registration
    {
        DA_New_Registration dA_New_Registration = new DA_New_Registration();
        public Login_Details Save_Registration(Login_Details details)
        {
            return dA_New_Registration.update_registration(details);
        }

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_New_Registration.fill_drop(drp_down, sqlstring, text, value);
        }

        public Login_Details new_society(Login_Details details)
        {
            return dA_New_Registration.New_Society(details);
        }

        public Login_Details Update_Society(Login_Details details)
        {
            return dA_New_Registration.Update_Society(details);
        }

        //public object Select_Society(Login_Details details)
        //{
        //    return dA_New_Registration.select_society(details);
        //}

        public Login_Details delete(Login_Details details)
        {
            return dA_New_Registration.Delete_Registration(details);
        }

        public Login_Details Reg_Textchanged(Login_Details details)
        {
            return dA_New_Registration.reg_textchanged(details);
        }

        public Login_Details select_society(Login_Details details)
        {
            return dA_New_Registration.select_society(details);
        }

        public Login_Details reg_textchanged(Login_Details details)
        {
            return dA_New_Registration.Textchanged_Reg(details);
        }

        public Login_Details delete_village(Login_Details details)
        {
            return dA_New_Registration.Delete_Village(details);
        }

        public Login_Details Email_Check(Login_Details details)
        {
            return dA_New_Registration.email_check(details);
        }
        public Login_Details update_village(Login_Details details)
        {
            return dA_New_Registration.Update_Village(details);
        }

        public Login_Details select_village(Login_Details details)
        {
            return dA_New_Registration.Select_Village(details);
        }
    }
}