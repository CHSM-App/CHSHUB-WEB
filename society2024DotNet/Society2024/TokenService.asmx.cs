using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using Utility.DataClass;

namespace Society2024
{
    /// <summary>
    /// Summary description for TokenService
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    [ScriptService]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 

    public class TokenService : System.Web.Services.WebService
    {
        BL_User_Login bl = new BL_User_Login();
        Login_Details login = new Login_Details();
        BL_User_Login BL_Login = new BL_User_Login();
        Login_Details details = new Login_Details();
        [WebMethod(EnableSession = true)]
        public string SaveToken(string token)
        {
            try
            {
                if (HttpContext.Current.Session["name"] == null)
                    return "User not authenticated.";


                login.UserLoginId = Convert.ToInt32(Session["UserId"]);
                login.Web_Token = token;
                login.Sql_Operation = "Insert_Token";
                bl.Generate_Token(login);

                HttpContext.Current.Session["UserToken"] = token;

                return "Token saved successfully: " + token;
            }
            catch (Exception ex)
            {
                // Log the exception for debugging
                System.Diagnostics.Debug.WriteLine("Error in SaveToken: " + ex.Message);
                return "Error: " + ex.Message;
            }
        }


        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public string getJson(int a)
        {

            details.Sql_Operation = "ExpenseChart";
            details.Society_Id = Session["society_id"].ToString();
            details.ExpenseType = a;
            var dt = BL_Login.get_expense_chart(details);

            string strJson = JsonConvert.SerializeObject(dt, Formatting.Indented);
            return strJson;
        }
    }
}
