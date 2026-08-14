using BusinessLogic.BL;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Windows.Forms;

namespace Society
{
    public partial class ledger : System.Web.UI.Page
    {
        Ledger GetLedger = new Ledger();
        BL_Ledger bL_Ledger = new BL_Ledger();

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
                Ledger_GridBind();
            }

        }
       
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            led_id.Value = id;
            runproc("Select");          
            btn_delete.Visible = true;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
        }

        public void Ledger_GridBind()
        {
            DataTable dt = new DataTable();
            GetLedger.Sql_Operation = "Grid_Show";
            GetLedger.Society_Id = society_id.Value;
            dt = bL_Ledger.getLedgerDetails(GetLedger);

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

            GetLedger.Search = txt_search.Text.Trim();
            GetLedger.Sql_Operation = "search";
            GetLedger.Society_Id = society_id.Value;
            var result = bL_Ledger.search_ledger(GetLedger);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }
        protected void btn_save_Click(object sender, EventArgs e)

        {
            string str = runproc_save("Update");

            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            else
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "Pop", "FailedEntry();", true);

            }
        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
            MessageBoxButtons buttons = MessageBoxButtons.YesNo;
            DialogResult result = MessageBox.Show("Are you sure want to delete", "delete", buttons);
            if (result == DialogResult.Yes)
            {
                runproc("delete");
            }
            Response.Redirect("ledger_form.aspx");
        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            
            Response.Redirect("ledger_form.aspx");
        }
        public string runproc_save(String operation)
        {
            if (led_id.Value != "")
               GetLedger.led_id = Convert.ToInt32(led_id.Value.ToString());
            GetLedger.Sql_Operation = operation;
            GetLedger.Society_Id = society_id.Value;
            GetLedger.Led_Description = txt_des.Text;
            GetLedger.Led_Status = radiobtn1.Checked == true ? "Active" : "Inactive";
            var result = bL_Ledger.updateLedgerDetails(GetLedger);
            return result.Sql_Result;

        }


        public void runproc(String operation)
        {
            if (led_id.Value != "")
                GetLedger.led_id = Convert.ToInt32(led_id.Value);
            GetLedger.Sql_Operation = operation;
            var result = bL_Ledger.updateLedgerDetails(GetLedger);

            led_id.Value = result.led_id.ToString();
            society_id.Value = result.Society_Id;
            txt_des.Text = result.Led_Description;
            if(result.Led_Status == "Active")
            {
                radiobtn1.Checked = true;
            }
           else if(result.Led_Status == "Inactive")
            {
                radiobtn2.Checked = true;
            }

           

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }
        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label led_id = (System.Web.UI.WebControls.Label)row.FindControl("led_id");
                GetLedger.Sql_Operation = "Delete";

                GetLedger.led_id = Convert.ToInt32(led_id.Text);
                bL_Ledger.delete(GetLedger);
                


            Ledger_GridBind();

        }

        protected void GridView1_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            //if(e.Row.RowType==DataControlRowType.DataRow)
            //{
            //    ((System.Web.UI.WebControls.Button)e.Row.Cells[7].Controls[0]).OnClientClick = "return confirm('Are you sure you want to log out?');";
            //}
        }



        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Ledger_GridBind();
        }
    }    
}