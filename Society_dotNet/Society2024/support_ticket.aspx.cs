using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society2024;
using System;
using System.Collections.Generic;
using System.Data; // Needed for DataTable
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class support_ticket : Page
    {
        Search_Society support = new Search_Society();
        BL_Society_Master bl_support = new BL_Society_Master();
        Notice notice = new Notice();
        BL_Notice_Master bL_Notice = new BL_Notice_Master();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
            {
                society_id.Value = Session["society_id"].ToString();
            }

            if (!IsPostBack)
            {
                getTicket();
            }
        }

        protected async void GetPath(int id)
        {
            pnlCarousel.Controls.Clear();

            List<string> paths = bl_support.getImagePath("getImage", id);

            if (paths == null || paths.Count == 0)
            {
                Label lblNoImage = new Label
                {
                    Text = "No images found.",
                    CssClass = "text-muted"
                };
                pnlCarousel.Controls.Add(lblNoImage);
                return;
            }

            // Create carousel container
            StringBuilder carouselHtml = new StringBuilder();
            carouselHtml.Append("<div id='helpdeskCarousel' class='carousel slide' data-ride='carousel'>");

            // Indicators
            carouselHtml.Append("<ol class='carousel-indicators'>");
            for (int i = 0; i < paths.Count; i++)
            {
                string activeClass = i == 0 ? "active" : "";
                carouselHtml.Append($"<li data-target='#helpdeskCarousel' data-slide-to='{i}' class='{activeClass}'></li>");
            }
            carouselHtml.Append("</ol>");

            // Carousel items
            carouselHtml.Append("<div class='carousel-inner text-center'>");

            int index = 0;
            foreach (var path in paths)
            {
                int idx = path.IndexOf("upload/", StringComparison.OrdinalIgnoreCase);
                if (idx >= 0)
                {
                    string fileName = path.Substring(idx + "upload/".Length);

                    string base64 = await GetBase64ImageAsync(fileName);
                    if (string.IsNullOrEmpty(base64))
                        continue;

                    string activeClass = index == 0 ? "active" : "";
                    carouselHtml.Append($@"
                <div class='carousel-item {activeClass}'>
                    <img src='data:image/jpeg;base64,{base64}' class='d-block mx-auto img-fluid rounded' style='max-height:500px;' />
                </div>");
                    index++;
                }
            }

            carouselHtml.Append("</div>");

            // Controls
            carouselHtml.Append(@"
        <a class='carousel-control-prev' href='#helpdeskCarousel' role='button' data-slide='prev'>
            <span class='carousel-control-prev-icon' aria-hidden='true'></span>
            <span class='sr-only'>Previous</span>
        </a>
        <a class='carousel-control-next' href='#helpdeskCarousel' role='button' data-slide='next'>
            <span class='carousel-control-next-icon' aria-hidden='true'></span>
            <span class='sr-only'>Next</span>
        </a>
    </div>");

            // Add carousel HTML to panel
            pnlCarousel.Controls.Add(new LiteralControl(carouselHtml.ToString()));

            // Show modal after images load
            ScriptManager.RegisterStartupScript(this, this.GetType(), "showImageModal", "$('#imageModal').modal('show');", true);
        }

        private async Task<string> GetBase64ImageAsync(string fileName)
        {
            try
            {
                using (var client = new HttpClient())
                {
                    var url = $"https://app.chshub.co.in/file/{fileName}";
                    var response = await client.GetAsync(url);
                    response.EnsureSuccessStatusCode();

                    var imageBytes = await response.Content.ReadAsByteArrayAsync();
                    return Convert.ToBase64String(imageBytes);
                }
            }
            catch
            {
                return null;
            }
        }


        //protected async void GetPath(int id)
        //{
        //    List<string> paths = bl_support.getImagePath("getImage", id);
        //    // Return substring after "upload/"
        //    foreach (var path in paths)
        //    {


        //        int idx = path.IndexOf("upload/", StringComparison.OrdinalIgnoreCase);
        //        if (idx >= 0)
        //        {

        //            await LoadImageFromNodeAsync(path.Substring(idx + "upload/".Length));
        //            //return path.Substring(idx + "upload/".Length);
        //        }
        //    }

        //}

        //private async Task LoadImageFromNodeAsync(string fileName)
        //{
        //    try
        //    {
        //        using (var client = new HttpClient())
        //        {
        //            // URL of your Node.js API
        //            var url = $"https://society.vengurlatech.com/file/{fileName}";

        //            //https://society.vengurlatech.com/file/1760506486894scaled_1000153609.jpg
        //            // Fetch image bytes
        //            var response = await client.GetAsync(url);
        //            response.EnsureSuccessStatusCode();
        //            var imageBytes = await response.Content.ReadAsByteArrayAsync();

        //            // Convert bytes to Base64 string
        //            string base64 = Convert.ToBase64String(imageBytes);

        //            // Detect MIME type (optional improvement)
        //            string mimeType = response.Content.Headers.ContentType?.MediaType ?? "image/jpeg";

        //            // Set the ImageUrl property dynamically
        //            imgHelpdesk.ImageUrl = $"data:{mimeType};base64,{base64}";
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        // Handle errors
        //        //lblError.Text = "Error loading image: " + ex.Message;
        //    }
        //}

        protected void GridView1_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "ShowComments")
            {

                string[] args = e.CommandArgument.ToString().Split('|');

                int helpdeskId = Convert.ToInt32(args[0]);
                flat_id.Text = args[1];

                // Fetch and bind comments
                BindComments(helpdeskId);

                // Show modal
                ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "$('#commentsModal').modal('show');", true);

            }

            if (e.CommandName == "ShowImage")
            {
                string helpdeskId = e.CommandArgument.ToString();

                // Example: Fetch image path from your database using helpdeskId
                GetPath(Convert.ToInt32(helpdeskId));

                // Open modal via script
                ScriptManager.RegisterStartupScript(this, this.GetType(), "openImageModal", "$('#imageModal').modal('show');", true);
            }
        }

        private void BindComments(int helpdeskId)
        {
            DataTable dt = bl_support.get_comment(helpdeskId);

            lblNoComments.Visible = dt.Rows.Count == 0;

            hfHelpdeskId.Value = helpdeskId.ToString();

            // Set name/unit only once from first row
            if (dt.Rows.Count > 0)
            {
                string name = dt.Rows[0]["name"].ToString();
                string unit = dt.Rows[0]["unit"].ToString();
                //lblUserNameUnit.Text = $"{name} - {unit}";
            }

            rptComments.DataSource = dt;
            rptComments.DataBind();
            temp.Update();
        }


        protected void btnReply_Click(object sender, EventArgs e)
        {
            string replyText = txtReply.Text.Trim();
            int helpdeskId = int.Parse(hfHelpdeskId.Value);

            if (!string.IsNullOrEmpty(replyText))
            {
                // Store reply via your BLL method
                support.Sql_Operation = "InsertComments";
                support.helpdeskId = helpdeskId;
                support.Comment = replyText;
                support.ownerId = Convert.ToInt32(Session["OwnerId"].ToString()); // Or user_id
                support.Society_Id = society_id.Value;
                support.Type = Session["user_role"].ToString();

                bl_support.post_comment(support); // You must implement this
                var temp = flat_id.Text;
                DataTable dt = bl_support.get_tokens("getFlatTokens", Convert.ToInt32(flat_id.Text));

                foreach (DataRow row in dt.Rows)
                {
                    string token = row["token"].ToString();
                    notice.User_Id = Convert.ToInt32(row["owner_id"]);
                    notice.UserType = row["type"].ToString();
                    notice.Notification_id = Convert.ToInt32(helpdeskId);
                    notice.Society_Id = Session["society_id"].ToString();
                    notice.Notification_Type = "Helpdesk Comment";
                    notice.Body = "comment added";
                    bL_Notice.send_notification(notice);
                    // Example: send notification
                    generate_notification(token, "Message : " + replyText);
                }

                //generate_notification(, "New Message");
                // Rebind updated comments and clear reply
                txtReply.Text = "";


                BindComments(helpdeskId);
            }

        }
        protected void GridView1_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                // Find the DropDownList in the current row
                DropDownList ddlStatus = (DropDownList)e.Row.FindControl("ddlStatus");

                if (ddlStatus != null)
                {
                    // Get the value from your data source
                    // Assume your data item has a property "Status" that corresponds to the selected value (e.g., "1", "2", etc.)
                    string statusValue = DataBinder.Eval(e.Row.DataItem, "Status").ToString();

                    // Set the selected value
                    if (ddlStatus.Items.FindByText(statusValue) != null)
                    {
                        ddlStatus.SelectedItem.Text = statusValue;
                    }
                }
            }
        }


        protected async void ddlStatus_SelectedIndexChanged(object sender, EventArgs e)
        {
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "$('#commentsModal').modal('show');", true);

            DropDownList ddl = (DropDownList)sender;
            GridViewRow row = (GridViewRow)ddl.NamingContainer;

            Label hfHelpdeskId = (Label)row.FindControl("lblHelpdeskId");
            string helpdeskId = hfHelpdeskId.Text;
            string newStatus = ddl.SelectedValue;

            Label lblownerId = (Label)row.FindControl("lblownerId");
            int ownerId = Convert.ToInt32(lblownerId.Text);
            // Update in database
            support.Sql_Operation = "UpdateStatus";
            support.helpdeskId = Convert.ToInt32(helpdeskId);
            support.Status = Convert.ToInt32(newStatus);
            support.Society_Id = society_id.Value;

            bl_support.update_status(support);
            var result = bl_support.get_token("getOwnerToken", ownerId);

            notice.User_Id = result.ownerId;
            notice.UserType = result.Type;
            notice.Notification_id = Convert.ToInt32(helpdeskId);
            notice.Society_Id = Session["society_id"].ToString();
            notice.Notification_Type = "Helpdesk";
            notice.Body = "Helpdesk Status updated";
            bL_Notice.send_notification(notice);
            Label lblFlat = (Label)row.FindControl("lblFlatId");
            flat_id.Text = lblFlat.Text;

            getTicket();
            generate_notification(result.token, "Helpdesk Status is " + ddl.SelectedItem.ToString());
            // Show comment modal if you want
            BindComments(Convert.ToInt32(helpdeskId));

        }


        protected async void generate_notification(string token, string update)
        {
            var Fcm = new FirebaseCloudMessaging();
            string result1 = await Fcm.SendNotificationAsync(token, "Helpdesk Update", update);
        }

        // TODO: Update the status in DB or take desired action
        // Example:
        //UpdateHelpdeskStatus(helpdeskId, newStatus);

        // Rebind GridView or show message or load details
        //LoadHelpdeskData(); // Your method to rebind data


        protected void rptComments_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "Reply")
            {
                int helpdeskId = Convert.ToInt32(e.CommandArgument);
                TextBox txtReply = (TextBox)e.Item.FindControl("txtReply");
                string replyText = txtReply.Text.Trim();

                if (!string.IsNullOrEmpty(replyText))
                {
                    // Save the reply to DB (you need to have this method in BLL)
                    support.Sql_Operation = "AddReply";
                    //support.Helpdesk_id = helpdeskId;
                    //support.Description = replyText;
                    //support.Created_By = Session["name"].ToString(); // Or user_id
                    support.Society_Id = society_id.Value;

                    /*   bl_support.add_reply(support);*/ // You must have this BLL method

                    // Re-bind updated comments
                    BindComments(helpdeskId);
                }
            }
        }



        protected void btn_search_Click(object sender, EventArgs e)
        {
            getTicket();
        }

        protected void getTicket()
        {
            support.Sql_Operation = "SupportTicket";
            support.Society_Id = society_id.Value;
            var dt = bl_support.support_ticket(support);
            GridView1.DataSource = dt;
            GridView1.DataBind();
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            getTicket();
        }



    }


}
