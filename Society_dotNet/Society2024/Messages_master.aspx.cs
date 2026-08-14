using BusinessLogic.MasterBL;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Data;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class Messages_master : System.Web.UI.Page
    {

        BL_Owner_Master bL_Owner = new BL_Owner_Master();
        Messages message = new Messages();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (Session["name"] == null)
                {
                    Response.Redirect("login1.aspx");
                }
                //hfFilter.Value = "All";
                LoadMessages();
            }
        }

        // Replace this with real DB calls. For now this returns sample data.
        private DataTable GetMessagesTable()
        {
            message.Operation = "GetMessages";
            message.SocietyID = (Session["society_id"]).ToString();
            DataTable dt = bL_Owner.get_Messages(message);

            return dt;
        }

        private void LoadMessages()
        {
            message.Operation = "GetMessages";
            message.SocietyID = (Session["society_id"]).ToString();
            DataTable dt = bL_Owner.get_Messages(message);

            GridView1.DataSource = dt;
            GridView1.DataBind();
        }

        //protected void btnAll_Click(object sender, EventArgs e)
        //{
        //    hfFilter.Value = "All";
        //    btnAll.CssClass = "nav-link active";
        //    btnResidents.CssClass = "nav-link";
        //    btnStaff.CssClass = "nav-link";
        //    LoadMessages();
        //}

        //protected void btnResidents_Click(object sender, EventArgs e)
        //{
        //    hfFilter.Value = "Residents";
        //    btnAll.CssClass = "nav-link";
        //    btnResidents.CssClass = "nav-link active";
        //    btnStaff.CssClass = "nav-link";
        //    LoadMessages();
        //}

        //protected void btnStaff_Click(object sender, EventArgs e)
        //{
        //    hfFilter.Value = "Staff";
        //    btnAll.CssClass = "nav-link";
        //    btnResidents.CssClass = "nav-link";
        //    btnStaff.CssClass = "nav-link active";
        //    LoadMessages();
        //}

        protected void btn_search_Click(object sender, EventArgs e)
        {
            // Keep current tab filter, just rebind with search term
            LoadMessages();
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            LoadMessages();
        }

        protected void GridView1_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "ViewMsg")
            {   
                int messageId = Convert.ToInt32(e.CommandArgument);
                DataTable dt = GetMessagesTable();
                var row = dt.AsEnumerable().FirstOrDefault(r => r.Field<int>("r_id") == messageId);

                if (row != null)
                {
                    lblSenderName.Text = row.Field<string>("owner_name");
                    //lblSenderRole.Text = row.Field<string>("owner_type");
                    lblDate.Text = row.Field<DateTime>("date").ToString("dd/MM/yyyy");
                    lblSubject.Text = row.Field<string>("message_sub");
                    txtMessageBody.Text = row.Field<string>("message");

                        message.Operation = "updateViewStatus";
                        message.OwnerID = messageId;
                        bL_Owner.update_view_status(message);

                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal", "$('#viewModal').modal('show');", true);
                }


            }
            else if (e.CommandName == "DeleteMsg")
            {
                int messageId = Convert.ToInt32(e.CommandArgument);
                try
                {
                    // TODO: replace with actual DB delete logic
                    // e.g. DeleteMessageFromDB(messageId);

                    // Show success alert and reload grid
                    ScriptManager.RegisterStartupScript(this, GetType(), "Popup", "SuccessDelete();", true);
                    LoadMessages();
                }
                catch
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "Popup", "FailedEntry();", true);
                }
            }
        }
    }
}
