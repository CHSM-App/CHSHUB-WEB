using BusinessLogic.BL;
using BusinessLogic.MasterBL;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society2024;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society
{
    public partial class Vote : Page
    {

        Polls polls = new Polls();
        BL_poll bL_Poll = new BL_poll();
        BL_Notice_Master bL_Notice = new BL_Notice_Master();
        Notice notice = new Notice();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }

            // Optional: add logic if needed

            rptPolls.ItemDataBound += rptPolls_ItemDataBound;
            pollBind();


        }

        protected void rptPolls_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                var rptOptions = (Repeater)e.Item.FindControl("rptOptions");
                rptOptions.ItemDataBound += rptOptions_ItemDataBound;
            }
        }


        protected async void btnStartPoll_Click(object sender, EventArgs e)
        {
            polls.Topic = txtTopic.Text.Trim();
            polls.Desc = txtDescription.Text.Trim();
            polls.ExpireDate = Convert.ToDateTime(txtExpiryDate.Text.ToString());
            polls.AllowMultiple = chkMultipleVotes.Checked ? 1 : 0;
            polls.VotePerUnit = chkOneVotePerUnit.Checked ? 1 : 0;
            polls.Audience = ddlAudience.SelectedValue;
            polls.sql_operation = "Insert";
            polls.UserId = Convert.ToInt32(Session["OwnerId"]);
            polls.society_id = Session["Society_id"].ToString();

            // Get all dynamic options from the form
            var optionInputs = Request.Form.GetValues("option");

            List<string> optionsList = new List<string>();

            if (optionInputs != null)
            {
                foreach (var option in optionInputs)
                {
                    if (!string.IsNullOrWhiteSpace(option))
                    {
                        optionsList.Add(option.Trim());
                    }
                }
            }

            if (optionsList.Count < 2)
            {
                Response.Write("<script>alert('Please provide at least two options for the poll.');</script>");
                return;
            }

            var result = bL_Poll.addPolls(polls);

            polls.Poll_id = result.Poll_id;

            int recipients_id = ddlAudience.SelectedValue == "1" ? 5 :        //all members
                               ddlAudience.SelectedValue == "2" ? 4 :         //Associate Committee
                               ddlAudience.SelectedValue == "3" ? 1 :         //Owners only
                               ddlAudience.SelectedValue == "4" ? 2 :         //Tenants only
                               0;


            polls.Option = string.Join(",", optionsList);         

            var resultPoll = bL_Poll.addOptions(polls);

            DataTable dt = bL_Poll.getTokens(recipients_id, Session["society_id"].ToString());

            foreach (DataRow row in dt.Rows)
            {
                notice.User_Id = Convert.ToInt32(row["user_id"].ToString());
                notice.UserType = row["type"].ToString();
                notice.Notification_id = resultPoll.Poll_id;
                notice.Notification_Type = "Poll";
                notice.Body = "New Poll";
                notice.Society_Id = Session["society_id"].ToString();
                bL_Notice.send_notification(notice);
                generate_notification(row["token"].ToString());
            }

            pollBind();
            ScriptManager.RegisterStartupScript(this, GetType(), "hideVoteModal", "$('#createPollModal').modal('hide');", true);

        }

        protected async void generate_notification(string token)

        {
            var Fcm = new FirebaseCloudMessaging();
            await Fcm.SendNotificationAsync(token, "New Poll", "Your Vote is Valuable");
        }

        public void pollBind()
        {
            polls.UserId = Convert.ToInt32(Session["OwnerId"]);
            polls.society_id = Session["society_Id"].ToString();
            polls.sql_operation = "selectAll";
            polls.user_type = Session["user_type"].ToString();

            DataTable dt = bL_Poll.getPolls(polls);

            Repeater1.DataSource = dt;
            Repeater1.DataBind();
        }

        //protected void gvPolls_RowDataBound(object sender, GridViewRowEventArgs e)
        //{
        //    if (e.Row.RowType == DataControlRowType.DataRow)
        //    {

        //        PlaceHolder optionContainer = (PlaceHolder)e.Row.FindControl("optionContainer");
        //        DataRowView drv = (DataRowView)e.Row.DataItem;
        //        HiddenField hfPollId = (HiddenField)e.Row.FindControl("PollId");

        //----------To hide Delete button for other users-----------------------------
        //int pollOwnerId = Convert.ToInt32(drv["user_id"]);
        //int currentUserId = Convert.ToInt32(Session["OwnerId"]);

        //        LinkButton btnDelete = (LinkButton)e.Row.FindControl("btnDelete");

        //        if (pollOwnerId != currentUserId)
        //        {
        //            btnDelete.Visible = false; // Hide delete button if not owner
        //        }
        //        //-----------------------------------------------------------------------------

        //        int optionIndex = 0;
        //        int AllowMultipleVotes = 0;
        //        foreach (DataColumn col in drv.DataView.Table.Columns)
        //        {
        //            if (col.ColumnName.Equals("AllowMultipleVotes"))
        //            {
        //                AllowMultipleVotes = Convert.ToInt32(drv[col.ColumnName]);
        //            }
        //            if (col.ColumnName.StartsWith("Option") && !string.IsNullOrEmpty(drv[col.ColumnName].ToString()))
        //            {
        //                //string optionText = drv[col.ColumnName].ToString();

        //                string[] parts = drv[col.ColumnName].ToString().Split('`');
        //                string optionText = parts[0];
        //                string optionId = parts.Length > 1 ? parts[1] : "0";
        //                string count = parts.Length > 1 ? parts[2] : "0";
        //                // Wrap the option in clickable div
        //                string html = $@"
        //                    <div class='option' data-option-id='{optionId.Trim()}'
        //                         data-index='{optionIndex}' 
        //                         data-votes='{count}' 
        //                         onclick=""vote({AllowMultipleVotes},{hfPollId.Value}, {optionId}, {optionIndex}, {Session["UserId"]}, '{Session["Society_id"]}','{Session["user_role"]}', this.closest('.poll-card'))"">
        //                        <div>{optionText}</div>
        //                        <div class='result-row'>
        //                            <div class='bar-container'><div class='bar'></div></div>
        //                            <div class='percentage'>0%</div>
        //                        </div>
        //                    </div>";

        //                optionContainer.Controls.Add(new LiteralControl(html));
        //                optionIndex++;
        //            }
        //        }

        //    }
        //}

        //protected void gvPolls_RowCommand(object sender, GridViewCommandEventArgs e)
        //{
        //    int pollId = Convert.ToInt32(e.CommandArgument);

        //    if (e.CommandName == "DeletePoll")
        //    {
        //        DeletePollFromDatabase(pollId);
        //    }

        //    if (e.CommandName == "ShowVotes")
        //    {
        //        GetList(pollId);

        //        // Show modal after binding data
        //        ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowVoteModal", "$('#voteDetailModal').modal('show');", true);
        //    }
        //}


        private void DeletePollFromDatabase(int pollId)
        {
            polls.Poll_id = pollId;
            polls.UserId = Convert.ToInt32(Session["OwnerId"]);
            polls.society_id = Session["society_Id"].ToString();
            polls.sql_operation = "deleteall";

            bL_Poll.deletePoll(polls);

            pollBind();
        }


        protected void rptOptions_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                var optionData = e.Item.DataItem as dynamic; // or use a strongly typed object if you have one
                var usersRepeater = (Repeater)e.Item.FindControl("rptUsers");

                var users = optionData.Users as List<string> ?? new List<string>();
                usersRepeater.DataSource = users;
                usersRepeater.DataBind();
            }
        }



        private void GetList(int pollId)
        {
            polls.Poll_id = pollId;
            //polls.UserId = Convert.ToInt32(Session["UserId"]);
            polls.society_id = Session["society_Id"].ToString();
            polls.sql_operation = "VOTEDUSERS";
            DataTable dt = bL_Poll.getVotedNames(polls);

            var poll = dt.AsEnumerable()
    .GroupBy(r => new { PollId = r["Poll_id"], Topic = r["Topic"] })
    .Select(p => new
    {
        PollId = p.Key.PollId,
        Topic = p.Key.Topic,
        Options = p.GroupBy(o => o["Options"])
                   .Select(o => new
                   {
                       Option = o.Key,
                       Users = o.Select(x => x["display_name"].ToString()).ToList()
                   }).ToList()
    }).ToList();

            rptPolls.DataSource = poll;
            rptPolls.DataBind();
        }

        protected void Repeater1_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int pollId = Convert.ToInt32(e.CommandArgument);

            if (e.CommandName == "DeletePoll")
            {
                DeletePollFromDatabase(pollId);
            }

            if (e.CommandName == "ShowVotes")
            {
                GetList(pollId);
                ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowVoteModal", "$('#voteDetailModal').modal('show');", true);
            }
        }


        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                DataRowView drv = (DataRowView)e.Item.DataItem;

                PlaceHolder optionContainer = (PlaceHolder)e.Item.FindControl("optionContainer");
                HiddenField hfPollId = (HiddenField)e.Item.FindControl("PollId");
                LinkButton btnDelete = (LinkButton)e.Item.FindControl("btnDelete");



                int pollOwnerId = Convert.ToInt32(drv["user_id"]);
                int currentUserId = Convert.ToInt32(Session["OwnerId"]);


                if (pollOwnerId != currentUserId)
                {
                    btnDelete.Visible = false;
                }

                int optionIndex = 0;
                int AllowMultipleVotes = 0;
                int OneVotePerUnit = 0;
                int hasVoted = 0;


                foreach (DataColumn col in drv.DataView.Table.Columns)
                {
                    if (col.ColumnName.Equals("HasVoted"))
                    {
                        hasVoted = Convert.ToInt32(drv[col.ColumnName]);
                    }
                    if (col.ColumnName.Equals("AllowMultipleVotes"))
                    {
                        AllowMultipleVotes = Convert.ToInt32(drv[col.ColumnName]);
                    }
                    if (col.ColumnName.Equals("OneVotePerUnit"))
                    {
                        OneVotePerUnit = Convert.ToInt32(drv[col.ColumnName]);
                    }

                    if (col.ColumnName.StartsWith("Option") && !string.IsNullOrEmpty(drv[col.ColumnName].ToString()))
                    {
                        string[] parts = drv[col.ColumnName].ToString().Split('`');
                        string optionText = parts[0];
                        string optionId = parts.Length > 1 ? parts[1] : "0";
                        string count = parts.Length > 2 ? parts[2] : "0";

                        string html = $@"
                    <div class='option' data-option-id='{optionId.Trim()}'
                         data-index='{optionIndex}' 
                         data-votes='{count}' 
                        onclick=""vote({hasVoted},{OneVotePerUnit},{AllowMultipleVotes},{hfPollId.Value}, {optionId}, {optionIndex}, {Session["OwnerId"]}, '{Session["Society_id"]}','{Session["user_role"]}', this.closest('.poll-card'))""> <div>{optionText}</div>
                        <div class='result-row'>
                            <div class='bar-container'><div class='bar'></div></div>
                            <div class='percentage'>0%</div>
                        </div>
                    </div>";

                        optionContainer.Controls.Add(new LiteralControl(html));
                        optionIndex++;
                        //upPolls.Update();
                    }
                }
            }
        }

    }
}
