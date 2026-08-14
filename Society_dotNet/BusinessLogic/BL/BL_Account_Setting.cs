using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_Account_Setting
    {
        DA_Account_Setting DA_Account = new DA_Account_Setting();

        public Account_Setting GetCode(Account_Setting account)
        {
            return DA_Account.Get_Code_Details(account); 
        }

        public Account_Setting update_account_setting(Account_Setting account)
        {
            return DA_Account.Update_Account_Setting(account);
        }
    }
}