using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;
using System.Web.Configuration;
using DBCode.DataClass;
using BusinessLogic.BL;
using System.Windows.Forms;
using DocumentFormat.OpenXml.Bibliography;
using Label = System.Web.UI.WebControls.Label;

namespace Society
{
    public partial class facility_booking : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        facility party = new facility();
        BL_facility bL_Facility = new BL_facility();
        //stored st = new stored();


        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {

               
                Party_GridBind();

                Allbound();

                txt_from_date.Text = DateTime.Now.ToString("yyyy-MM-dd");
                txt_to_date.Text = DateTime.Now.ToString("yyyy-MM-dd");
                txt_to_date.Attributes["min"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_from_date.Attributes["min"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_from_date.Attributes["max"] = DateTime.Now.AddDays(30).ToString("yyyy-MM-dd");
                from_time.Text = DateTime.Now.ToLocalTime().ToString("hh:mm");
                to_time.Text = DateTime.Now.ToLocalTime().AddHours(1).ToString("hh:mm");
                txt_date.Text = DateTime.Now.ToString("yyyy-MM-dd");
                txt_date.Attributes["min"] = DateTime.Now.ToString("yyyy-MM-dd");
                txt_date.Attributes["max"] = DateTime.Now.AddDays(30).ToString("yyyy-MM-dd");
            }
            Panel2.Visible = true;
            Panel1.Visible = false;
        }

        protected void Allbound()
        {
            DataTable dt = new DataTable();
            dt = bL_Facility.Fill_list("fill_facilities", society_id.Value);
            Repeater1.DataSource = dt;
            Repeater1.DataBind();
            dt = bL_Facility.Fill_list("fill_owner", society_id.Value);
            Repeater2.DataSource = dt;
            Repeater2.DataBind();

        }


    
        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {

            facility_id.Value = e.CommandArgument.ToString();

            Panel3.Visible = false;
            Panel4.Visible = false;
            Label33.Visible = true;
            Label34.Visible = true;
            txt_date.Visible = true;
            GridView2.Visible = true;
            from_time.Text = DateTime.Now.ToLocalTime().ToString("hh:mm");
            to_time.Text = DateTime.Now.ToLocalTime().AddHours(1).ToString("hh:mm");
            if (facility_id.Value != "")
            {
                DataTable dt = new DataTable();
                party.Sql_Operation = "Get_Slot";
                party.Society_Id = society_id.Value;
                party.From_Date = Convert.ToDateTime(txt_date.Text.ToString());
                party.facility_id = Convert.ToInt32(facility_id.Value);
                dt = bL_Facility.getslot(party); 
                if (dt.Rows.Count > 0)
                {
                    GridView2.DataSource = dt;
                    ViewState["dirState"] = dt;
                    GridView2.DataBind();
                }
                else
                {
                    GridView2.Visible = false;
                    Panel3.Visible = false;
                    Panel4.Visible = true;
                    Label33.Visible = false;
                    Label34.Visible = false;
                    txt_date.Visible = false;
                }

                party.facility_id = Convert.ToInt32(facility_id.Value);
                party.Sql_Operation = "GetCharge";
                var result = bL_Facility.get_charges(party);
                if (result.Cost == 0)
                {
                    txt_amount.Text = "Free";
                }
                else
                {
                    txt_amount.Text = result.Cost.ToString() + "+ 18% GST(" + (result.Cost * 18 / 100) + ") \n=" + (result.Cost + (result.Cost * 18 / 100));
                }
                if (result.Slot == 1)
                {
                    GridView2.Visible = false;
                    Panel3.Visible = true;
                    Panel4.Visible = false;
                    Label33.Visible = false;
                    Label34.Visible = false;
                    txt_date.Visible = false;
                }
                else if (result.Slot == 2)
                {
                    GridView2.Visible = false;
                    Panel3.Visible = false;
                    //Panel4.Visible = false;
                    Label33.Visible = true;
                    Label34.Visible = true;
                    txt_date.Visible = true;
                }

            }

        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                name_id.Value = e.CommandArgument.ToString();

            }

            if (name_id.Value != "")
            {
                party.owner_id = Convert.ToInt32(name_id.Value);
                party.Sql_Operation = "GetFlat";
                var result = bL_Facility.getflatno(party);
                txt_flat.Text = result.Flat_No.ToString();
                flat_id.Value = result.Flat_id.ToString();
                ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
            }

        }
        public void filldrop()
        {
            //String sql_query1 = "Select * from facilities where active_status=0 and society_id='" + society_id.Value + "'";
            //bL_Facility.fill_drop(ddl_facility, sql_query1, "name", "facility_id");
            //String sql_query = "Select * from owner_master where active_status=0 and society_id='" + society_id.Value + "'";
            //bL_Facility.fill_drop(ddl_name, sql_query, "name", "owner_id");

        }
        public void Party_GridBind()
        {
            DataTable dt = new DataTable();
            party.Sql_Operation = "Grid_Show";
            party.Society_Id = society_id.Value;
            dt = bL_Facility.GetPartyDetails(party);

            GridView1.DataSource = dt;
            ViewState["dirState"] = dt;
            GridView1.DataBind();

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

        protected void btn_search_Click(object sender, EventArgs e)
        {
            party.Name = txt_search.Text.Trim();
            party.Sql_Operation = "search";
            party.Society_Id = society_id.Value;
            var result = bL_Facility.search_party(party);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            facility_book_id.Value = id;
            runproc("Select");
            ddl_facility_SelectedIndexChanged(sender, e);


            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        public string runproc_save(String operation)
        {
            if (facility_book_id.Value != "")
                party.facility_book_id = Convert.ToInt32(facility_book_id.Value.ToString());
            party.Sql_Operation = operation;
            party.Society_Id = society_id.Value;
            party.Note = txt_note.Text;
              party.From_Date = Convert.ToDateTime(txt_from_date.Text.ToString());
            if (txt_to_date.Text != "")
                party.To_Date = Convert.ToDateTime(txt_to_date.Text);
            //if (society_in.Checked == true)
            //{
            //    party.Name = name_id.Value.ToString();
                party.Flat_No = Convert.ToInt32(flat_id.Value);
            //}
            //else
            //{
                party.Name = TextBox2.Text;
            //    party.Address = txt_add.Text;
            //    party.Contact = txt_contact.Text;
            //}
            if (txt_amount.Text == "Free" && string.IsNullOrWhiteSpace(hidden_total_amount.Value))
            {
                party.Cost = 0;
            }
            else
            {

                party.Cost = Convert.ToDecimal(GetAmountAfterEquals());
            }

            party.facility_id = Convert.ToInt32(facility_id.Value);
            party.From_Time = Convert.ToDateTime(from_time.Text.ToString());
            party.To_Time = Convert.ToDateTime(to_time.Text.ToString());
            //party.Society_In = society_in.Checked == true ? 1 : 0;
            var result = bL_Facility.UpdateParty(party);
            return result.Sql_Result;


        }

        public void runproc(String operation)
        {
            if (facility_book_id.Value != "")
                party.facility_book_id = Convert.ToInt32(facility_book_id.Value);
            party.Sql_Operation = operation;
            var result = bL_Facility.UpdateParty(party);

            facility_book_id.Value = result.facility_book_id.ToString();
            society_id.Value = result.Society_Id;
            txt_note.Text = result.Note.ToString();
            txt_from_date.Text = result.From_Date.ToString("yyyy-MM-dd");
            txt_to_date.Text = result.To_Date.ToString("yyyy-MM-dd");
            txt_name.Text = result.Name;
            txt_flat.Text = result.Flat_No.ToString();
            txt_contact.Text = result.Contact;
            txt_add.Text = result.Address;
            from_time.Text = result.From_Time.ToString("hh:mm");
            to_time.Text = result.To_Time.ToString("hh:mm");
            txt_amount.Text = result.Cost.ToString();
            facility_id.Value = result.facility_id.ToString();
            name_id.Value = result.Name;
            if (result.Society_In == 1)
            {
                //society_in.Checked = true;
                Panel1.Visible = false;
                Panel2.Visible = true;
            }
            else
            {
                //society_in.Checked = false;
                Panel1.Visible = true;
                Panel2.Visible = false;
            }
            Allbound();
        }


        protected void btn_save_Click(object sender, EventArgs e)
        {
            var str = runproc_save("Update");
            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);

            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);

            }

        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {

            if (facility_book_id.Value != "")
                party.facility_book_id = Convert.ToInt32(facility_book_id.Value);
            party.Sql_Operation = "Delete";
            bL_Facility.Party_Delete(party);

            Response.Redirect("facility_booking.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("facility_booking.aspx");
        }

        protected void society_in_CheckedChanged(object sender, EventArgs e)
        {
            //if (society_in.Checked == false)
            //{
            //    Panel1.Visible = true;
            //    Panel2.Visible = false;
            //}
        }
        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }
        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label facility_book_id = (System.Web.UI.WebControls.Label)row.FindControl("facility_book_id");
            party.Sql_Operation = "Delete";

            party.facility_book_id = Convert.ToInt32(facility_book_id.Text);
            bL_Facility.Party_Delete(party);

            Party_GridBind();

        }

        protected void ddl_name_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (name_id.Value != "")
            {
                party.owner_id = Convert.ToInt32(name_id.Value);
                party.Sql_Operation = "GetFlat";
                var result = bL_Facility.getflatno(party);
                txt_flat.Text = result.Flat_No.ToString();
                ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
            }
        }



        protected void ddl_facility_SelectedIndexChanged(object sender, EventArgs e)
        {
            Panel3.Visible = false;
            Panel4.Visible = false;
            Label33.Visible = true;
            Label34.Visible = true;
            txt_date.Visible = true;
            GridView2.Visible = true;
            from_time.Text = DateTime.Now.ToLocalTime().ToString("hh:mm");
            to_time.Text = DateTime.Now.ToLocalTime().AddHours(1).ToString("hh:mm");
            if (facility_id.Value != "")
            {
                DataTable dt = new DataTable();
                party.Sql_Operation = "Get_Slot";
                party.Society_Id = society_id.Value;
                party.From_Date = Convert.ToDateTime(txt_date.Text.ToString());
                party.facility_id = Convert.ToInt32(facility_id.Value);
                dt = bL_Facility.getslot(party);
                if (dt.Rows.Count > 0)
                {
                    GridView2.DataSource = dt;
                    ViewState["dirState"] = dt;
                    GridView2.DataBind();
                }
                else
                {
                    GridView2.Visible = false;
                    Panel3.Visible = false;
                    Panel4.Visible = true;
                    Label33.Visible = false;
                    Label34.Visible = false;
                    txt_date.Visible = false;
                }

                party.facility_id = Convert.ToInt32(facility_id.Value);
                party.Sql_Operation = "GetCharge";
                var result = bL_Facility.get_charges(party);
                if (result.Cost == 0)
                {
                    txt_amount.Text = "Free";
                }
                else
                {
                    txt_amount.Text = result.Cost.ToString() + "+ 18% GST(" + (result.Cost * 18 / 100) + ") \n=" + (result.Cost + (result.Cost * 18 / 100));
                }
                if (result.Slot == 1)
                {
                    GridView2.Visible = false;
                    Panel3.Visible = true;
                    Panel4.Visible = false;
                    Label33.Visible = false;
                    Label34.Visible = false;
                    txt_date.Visible = false;
                }
                else if (result.Slot == 2)
                {
                    GridView2.Visible = false;
                    Panel3.Visible = false;
                    //Panel4.Visible = false;
                    Label33.Visible = true;
                    Label34.Visible = true;
                    txt_date.Visible = true;
                }

            }
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
        }

        protected void chk_CheckedChanged(object sender, EventArgs e)
        {
            System.Web.UI.WebControls.CheckBox activeCheckBox = sender as System.Web.UI.WebControls.CheckBox;
            GridViewRow Row = (GridViewRow)activeCheckBox.NamingContainer;
            string rowindex = GridView2.Rows[Row.RowIndex].Cells[1].Text;
            int abc = Row.RowIndex;
            foreach (GridViewRow row in GridView2.Rows)
            {

                System.Web.UI.WebControls.CheckBox chkBx = (System.Web.UI.WebControls.CheckBox)row.FindControl("chk");
                if (row.RowIndex == abc)
                {
                    chkBx.Checked = true;
                    System.Web.UI.WebControls.Label start_time = (System.Web.UI.WebControls.Label)row.FindControl("start_time");
                    System.Web.UI.WebControls.Label end_time = (System.Web.UI.WebControls.Label)row.FindControl("end_time");
                    System.Web.UI.WebControls.Label id = (System.Web.UI.WebControls.Label)row.FindControl("slot_id");
                    from_time.Text = Convert.ToDateTime(start_time.Text).ToString("hh:mm tt");
                    to_time.Text = Convert.ToDateTime(end_time.Text).ToString("hh:mm tt");
                    slot_id.Value = id.Text;
                }
                else
                {
                    chkBx.Checked = false;
                }
            }
        }

        protected void GridView2_RowDataBound(object sender, GridViewRowEventArgs e)
        {

            foreach (GridViewRow row in GridView2.Rows)
            {

                if (row.RowType == DataControlRowType.DataRow)
                {
                    System.Web.UI.WebControls.Label status = (System.Web.UI.WebControls.Label)row.FindControl("status");
                    System.Web.UI.WebControls.Label reason = (System.Web.UI.WebControls.Label)row.FindControl("reason");
                    System.Web.UI.WebControls.CheckBox chk = (System.Web.UI.WebControls.CheckBox)row.FindControl("chk");
                    if (status.Text == "1")
                    {
                        chk.Visible = false;
                        reason.Text = "Reason: This slot is Already Booked";

                    }

                }
            }
        }

        protected void txt_date_TextChanged(object sender, EventArgs e)
        {
            txt_from_date.Text = txt_date.Text;
            ddl_facility_SelectedIndexChanged(sender, e);
        }

        protected void txt_to_date_TextChanged(object sender, EventArgs e)
        {
            if (txt_to_date.Text != "")
                if (facility_id.Value != "")
                {

                    party.facility_id = Convert.ToInt32(facility_id.Value);
                    party.Sql_Operation = "GetCharge";
                    var result = bL_Facility.get_charges(party);


                    if (result.Cost == 0)
                    {
                        txt_amount.Text = "Free";
                    }
                    else
                    {
                        DateTime fromDate = Convert.ToDateTime(txt_from_date.Text);
                        DateTime toDate = Convert.ToDateTime(txt_to_date.Text);

                        int dayDifference = (toDate - fromDate).Days +1;

                        if (dayDifference < 0)
                        {
                            txt_amount.Text = "Invalid date range";
                            return;
                        }

                        float baseAmount = float.Parse(result.Cost.ToString()) * dayDifference;
                        float gst = baseAmount * 18 / 100;
                        float totalAmount = baseAmount + gst;

                        txt_amount.Text = baseAmount + "+ 18% GST (" + gst + ")\n=" + totalAmount;
                        hidden_total_amount.Value = totalAmount.ToString();
                        //ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);

                    }
                }   
        }

        protected void to_time_TextChanged(object sender, EventArgs e)
        {
            if (to_time.Text != "")
                if (facility_id.Value != "")
                {
                    party.facility_id = Convert.ToInt32(facility_id.Value);
                    party.Sql_Operation = "GetCharge";
                    var result = bL_Facility.get_charges(party);

                    if (result.Cost == 0)
                    {
                        txt_amount.Text = "Free";
                    }
                    else
                    {

                        TimeSpan fromTime, toTime;

                        bool isFromTimeValid = TimeSpan.TryParse(from_time.Text, out fromTime);
                        bool isToTimeValid = TimeSpan.TryParse(to_time.Text, out toTime);

                        if (!isFromTimeValid || !isToTimeValid)
                        {
                            txt_amount.Text = "Invalid time format";
                            return;
                        }


                        double hours = (toTime - fromTime).TotalHours;

                        if (hours <= 0)
                        {
                            txt_amount.Text = "Invalid time range";
                            return;
                        }


                        float baseAmount = (float)hours * float.Parse(result.Cost.ToString());
                        float gst = baseAmount * 18 / 100;
                        float totalAmount = baseAmount + gst;

                        txt_amount.Text = baseAmount + "+ 18% GST (" + gst + ")\n= " + totalAmount;
                        hidden_total_amount.Value = totalAmount.ToString();


                        ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModal", "$('#edit_model').modal('show');", true);
                    }
                }
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Party_GridBind();
        }

        protected void Repeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (facility_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == facility_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }

        protected void Repeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (name_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == name_id.Value)
                        TextBox2.Text = link.Text;
                }
            }
        }

        protected void GridView1_RowDataBound(object sender, GridViewRowEventArgs e)
            {
            if (e.Row.RowType == DataControlRowType.Footer)
            {
                decimal total = 0;

                // Calculate total from all data rows
                foreach (GridViewRow row in GridView1.Rows)
                {
                    if (row.RowType == DataControlRowType.DataRow)
                    {
                        Label lblCharges = (Label)row.FindControl("charges");
                        if (lblCharges != null && !string.IsNullOrEmpty(lblCharges.Text))
                        {
                            decimal amount;
                            if (decimal.TryParse(lblCharges.Text, out amount))
                            {
                                total += amount;
                            }
                        }
                    }
                }

                // Display total in footer
                Label lblTotal = (Label)e.Row.FindControl("lblTotal");
                if (lblTotal != null)
                {
                    lblTotal.Text = "Total: " + total.ToString("N2");
                }
            }
        }

        // Add this method to extract the value after '=' from txt_amount.Text
        private string GetAmountAfterEquals()
        {
            if (string.IsNullOrWhiteSpace(txt_amount.Text))
                return string.Empty;

            int index = txt_amount.Text.IndexOf('=');
            if (index == -1 || index == txt_amount.Text.Length - 1)
                return string.Empty;

            // Get substring after '=' and trim whitespace/newlines
            return txt_amount.Text.Substring(index + 1).Trim();
        }
    }
}

