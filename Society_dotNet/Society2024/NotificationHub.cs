using BusinessLogic.BL;
using Microsoft.AspNet.SignalR;
using Society;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society2024
{
    public partial class society1 : System.Web.UI.Page
    {


        //protected void Page_Load(object sender, EventArgs e)
        //{
        //    if (Session["Society_name"] == null)
        //    {
        //        Response.Redirect("login1.aspx");
        //    }
        //    society_id.Value = Session["society_id"].ToString();
        //    if (!IsPostBack)
        //    {


        //        txt_name.Text = Session["Society_name"].ToString();
        //    }

        //}

        public class NotificationHub : Hub
        {
            public static void SendNotification(string message)
            {
                var context = GlobalHost.ConnectionManager.GetHubContext<NotificationHub>();
                context.Clients.All.displayNotification(message);
                NotificationHub.SendNotification("New data has been added!");
            }
        }
       
    }
}

