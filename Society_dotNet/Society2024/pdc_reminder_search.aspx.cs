using System;
using System.Data;
using System.Web.UI.WebControls;
using System.Web.UI;
using Society;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web.Services.Description;
using System.Web.Configuration;
using System.Configuration;
using DBCode.DataClass;
using BusinessLogic.BL;
using DocumentFormat.OpenXml.Wordprocessing;

namespace Society
{
    partial class pdc_reminder_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        pdc_reminder Reminder = new pdc_reminder();
        BL_Pdc_Reminder BL_Pdc = new BL_Pdc_Reminder();

        protected void Page_Load(object sender, System.EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();

            if (!IsPostBack)
            {
                pdc_reminder_Gridbind();
                Allbound();



                btn_delete.Visible = false;
            }

        }

        protected void Allbound()
        {
            DataTable dt = new DataTable();
            dt = BL_Pdc.fill_list("fill_owner", society_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = BL_Pdc.fill_list("fill_wing", society_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();

        }
        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                owner_name_id.Value = e.CommandArgument.ToString();
                Reminder.owner_id = Convert.ToInt32(owner_name_id.Value);
                Reminder.Sql_Operation = "owner_select";

                var result = BL_Pdc.owner_selectedindexchanged(Reminder);

                txt_pre_addr1.Text = result.Pre_Addr1;
                txt_pre_addr2.Text = result.Pre_Addr2;
                txt_pre_mob.Text = result.Pre_Mob.ToString();
                building_name_id.Value = result.wing_id.ToString();
                txt_email.Text = result.Email;
                txt_add_mob.Text = result.Alter_Mob.ToString();
                txt_pre_addr1.Enabled = false;
                txt_pre_addr2.Enabled = false;
                txt_pre_mob.Enabled = false;
                txt_add_mob.Enabled = false;
                txt_email.Enabled = false;
               var dt = BL_Pdc.fill_list("fill_wing", society_id.Value);
                Repeater2.DataSource = dt;
                Repeater2.DataBind();
            
            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                building_name_id.Value = e.CommandArgument.ToString();

            }
        }


        public void pdc_reminder_Gridbind()
        {
            DataTable dt = new DataTable();
            Reminder.Sql_Operation = "Grid_Show";
            Reminder.Society_Id = society_id.Value;
            dt = BL_Pdc.getPdcReminder(Reminder);
            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();
            GridView3.DataSource = dt;
            GridView3.DataBind();

        }

        protected void GridView1_Sorting(object sender, GridViewSortEventArgs e)
        {
            DataTable dtrslt = (DataTable)ViewState["dirState"];
            if (dtrslt.Rows.Count > 0)
            {
                if (Convert.ToString(ViewState["sortdr"]) == "Asc")
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Desc";
                    ViewState["sortdr"] = "Desc";
                }
                else
                {
                    dtrslt.DefaultView.Sort = e.SortExpression + " Asc";
                    ViewState["sortdr"] = "Asc";
                }
                GridView1.DataSource = dtrslt;
                GridView1.DataBind();


            }

        }
        protected void txt_chq_no_TextChanged(object sender, EventArgs e)
        {
            if (txt_chq_no.Text.Trim() != "")
            {
                if (pdc_rem_id.Value != "")
                    Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value);
                Reminder.Sql_Operation = "check_chq_no_exists";
                Reminder.Chq_No = Convert.ToInt32(txt_chq_no.Text);
                var result = BL_Pdc.chqno_textchanged(Reminder);
                Label2.Text = result.Sql_Result;
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
            }
        }
        protected void btn_search_Click(object sender, EventArgs e)
        {

            Reminder.Search = txt_search.Text.Trim(); 
            Reminder.Sql_Operation = "search";
            Reminder.Society_Id = society_id.Value;
            var result = BL_Pdc.search_reminder(Reminder);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            GridView3.DataSource = result;
            GridView3.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }



        public string runproc_save(string operation1)
        {
            if (pdc_rem_id.Value != "")
                Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value.ToString());
            Reminder.Sql_Operation = operation1;
            Reminder.Society_Id = society_id.Value;
            Reminder.owner_id = Convert.ToInt32(owner_name_id.Value);
            Reminder.O_Name = TextBox1.Text;
            Reminder.wing_id = Convert.ToInt32(building_name_id.Value);
            Reminder.Chq_No = Convert.ToInt32(txt_chq_no.Text);
            Reminder.Che_Date = Convert.ToDateTime(txt_chq_date.Text);
            Reminder.Che_Amount = float.Parse(txt_chq_amount.Text);
            //Reminder.Che_Dep = deposite_chk.Checked == true ? 1 : 0;
            //Reminder.Che_Can = bounce_chk.Checked == true ? 1 : 0;
            //Reminder.Che_Ret = return_chk.Checked == true ? 1 : 0;
            var result = BL_Pdc.updatePdcReminder(Reminder);
            return result.Sql_Result;

        }

        public void runproc(string operation)
        {
            if (pdc_rem_id.Value != "")
                Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value);
            Reminder.Sql_Operation = operation;

            var result = BL_Pdc.updatePdcReminder(Reminder);

            (pdc_rem_id.Value) = result.pdc_rem_id.ToString();
            society_id.Value = result.Society_Id;
            owner_name_id.Value = result.owner_id.ToString();

            building_name_id.Value = result.wing_id.ToString();
            txt_chq_no.Text = result.Chq_No.ToString();
            txt_chq_date.Text = result.Che_Date.ToString("yyyy-MM-dd");
            txt_chq_amount.Text = result.Che_Amount.ToString();

            //if (result.Che_Dep != 0)
            //{
            //    deposite_chk.Checked = true;
            //}

            //if (result.Che_Can != 0)
            //{
            //    bounce_chk.Checked = true;
            //}

            //if (result.Che_Ret != 0)
            //{
            //    return_chk.Checked = true;
            //}
            Allbound();
        }

        protected void ddl_owner_SelectedIndexChanged(object sender, EventArgs e)
        {
            Reminder.owner_id = Convert.ToInt32(owner_name_id.Value);
            Reminder.Sql_Operation = "owner_select";

            var result = BL_Pdc.owner_selectedindexchanged(Reminder);

            txt_pre_addr1.Text = result.Pre_Addr1;
            txt_pre_addr2.Text = result.Pre_Addr2;
            txt_pre_mob.Text = result.Pre_Mob.ToString();
            building_name_id.Value = result.wing_id.ToString();
            txt_email.Text = result.Email;
            txt_add_mob.Text = result.Alter_Mob.ToString();
            txt_pre_addr1.Enabled = false;
            txt_pre_addr2.Enabled = false;
            txt_pre_mob.Enabled = false;
            txt_add_mob.Enabled = false;
            txt_email.Enabled = false;

        }


        public void save_change()
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;

            Label acc_no = new Label(), chq_no = new Label(), pdc_id = new Label(), che_date = new Label(), che_amt = new Label();
            System.Web.UI.WebControls.CheckBox depo_chk = new System.Web.UI.WebControls.CheckBox(), ret_chk = new System.Web.UI.WebControls.CheckBox(), bou_chk = new System.Web.UI.WebControls.CheckBox();

            foreach (GridViewRow row in GridView1.Rows)
            {

                data_item.Clear();

                if (pdc_rem_id.Value != "")
                    Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value.ToString());
                Reminder.Sql_Operation = "save_change_rem";
                Reminder.Che_Date = Convert.ToDateTime(txt_chq_date.Text);
                Reminder.Che_Amount = float.Parse(txt_chq_amount.Text);
                //Reminder.Che_Dep = deposite_chk.Checked == true ? 1 : 0;
                //Reminder.Che_Can = bounce_chk.Checked == true ? 1 : 0;
                //Reminder.Che_Ret = return_chk.Checked == true ? 1 : 0;
                BL_Pdc.save_changes(Reminder);

            }
        }


        public void grid_show()
        {
            DataTable dt = new DataTable();
            Reminder.Sql_Operation = "ownerwise_cheq";
            //Reminder.owner_id = Convert.ToInt32(ddl_owner.SelectedValue);
            dt = BL_Pdc.ownergrid(Reminder);
            GridView2.DataSource = dt;
            GridView2.DataBind();
        }
        public void clear()
        {
            txt_chq_no.Text = "";
            txt_chq_date.Text = "";
            txt_chq_amount.Text = "";
            //deposite_chk.Checked = false;
            //return_chk.Checked = false;
            //bounce_chk.Checked = false;
        }


        protected void btn_delete_Click(object sender, System.EventArgs e)
        {
            SqlDataReader sdr = null;
            string status = "";
            if (pdc_rem_id.Value != "")
                Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value);
            Reminder.Sql_Operation = "Delete";
            BL_Pdc.delete(Reminder);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Record Is In Use. Cant Delete!!!');", true);
                    return;
                }
                else
                {
                    runproc_save("Delete");
                    Response.Redirect("pdc_reminder_search.aspx");
                }
            }

            else

                Response.Write(status);

        }

        protected void btn_close_Click(object sender, System.EventArgs e)
        {
            Response.Redirect("pdc_reminder_search.aspx");
        }


        protected void btn_next_Click(object sender, EventArgs e)
        {
            if (txt_chq_no.Text.Trim() == "")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Please Enter Cheque No !!!');", true);
                return;
            }
            if (txt_chq_date.Text == "")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Please Enter Cheque Date !!!');", true);
                return;
            }
            if (txt_chq_amount.Text.Trim() == "")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Please Enter Cheque Amount!!!');", true);
                return;
            }

            if (pdc_rem_id.Value != "")
                Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value);
            Reminder.Chq_No = Convert.ToInt32(txt_chq_no.Text);
            Reminder.Sql_Operation = "chq_no_exist";

            var result = BL_Pdc.next_click(Reminder);

            if (result.Sql_Result == "Exist")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Cheque No Already Exists !!!');", true);
                return;
            }
            else
                runproc_save("Update");
            clear();
            grid_show();

        }



        protected void btn_save_Click(object sender, EventArgs e)
        {
            //string str = runproc_save("Update");

            //if (str == "Done")
            //    ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            //else
            //{
            //    ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "FailedEntry();", true);

            //}

            if (txt_chq_no.Text.Trim() == "")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Please Enter Cheque No !!!');", true);
                return;
            }
            if (txt_chq_date.Text == "")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Please Enter Cheque Date !!!');", true);
                return;
            }
            if (txt_chq_amount.Text.Trim() == "")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Please Enter Cheque Amount!!!');", true);
                return;
            }

            if (pdc_rem_id.Value != "")
                Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Value);
            Reminder.Chq_No = Convert.ToInt32(txt_chq_no.Text);
            Reminder.Sql_Operation = "chq_no_exist";

            var result = BL_Pdc.next_click(Reminder);

            if (result.Sql_Result == "Exist")
            {
                ScriptManager.RegisterStartupScript(this, GetType(), "showalert", "alert('Cheque No Already Exists !!!');", true);
                return;
            }
            else
                runproc_save("Update");
            clear();
            grid_show();
        }


        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            pdc_rem_id.Value = id;
            runproc("Select");
            ddl_owner_SelectedIndexChanged(sender, e);
            grid_show();
           
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }


        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }


        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            Label pdc_rem_id = (Label)row.FindControl("pdc_rem_id");
            Reminder.Sql_Operation = "Delete";

            Reminder.pdc_rem_id = Convert.ToInt32(pdc_rem_id.Text);
            BL_Pdc.delete(Reminder);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
            pdc_reminder_Gridbind();
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            pdc_reminder_Gridbind();
        }


        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)

            {

                if (building_name_id.Value != "")

                {

                    var link = (LinkButton)e.Item.FindControl("lnkCategory");

                    if (link.CommandArgument == owner_name_id.Value)
                    {
                        TextBox2.Text = link.Text;
                        Reminder.owner_id = Convert.ToInt32(owner_name_id.Value);
                        Reminder.Sql_Operation = "owner_select";

                        var result = BL_Pdc.owner_selectedindexchanged(Reminder);

                        txt_pre_addr1.Text = result.Pre_Addr1;
                        txt_pre_addr2.Text = result.Pre_Addr2;
                        txt_pre_mob.Text = result.Pre_Mob.ToString();
                        building_name_id.Value = result.wing_id.ToString();
                        txt_email.Text = result.Email;
                        txt_add_mob.Text = result.Alter_Mob.ToString();
                        txt_pre_addr1.Enabled = false;
                        txt_pre_addr2.Enabled = false;
                        txt_pre_mob.Enabled = false;
                        txt_add_mob.Enabled = false;
                        txt_email.Enabled = false;
                   
                    }
                }

            }

        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)

            {

                if (owner_name_id.Value != "")

                {

                    var link = (LinkButton)e.Item.FindControl("lnkCategory");

                    if (link.CommandArgument == owner_name_id.Value)

                        TextBox1.Text = link.Text;

                }

            }
        }

        protected void btn_close_Click1(object sender, EventArgs e)
        {
            Response.Redirect("pdc_reminder_search.aspx");
        }
    }
}
