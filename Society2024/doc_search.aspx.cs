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
using System.Drawing.Drawing2D;
using Page = System.Web.UI.Page;
using DBCode.DataClass;
using BusinessLogic.MasterBL;
using System.Windows.Forms;
//using System.IdentityModel.Metadata;;

namespace Society
{
    public partial class doc_search : System.Web.UI.Page
    {
        Doc doc = new Doc();
        BL_Doc_Master bL_Doc = new BL_Doc_Master();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }else
                society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                Doc_Gridbind();
            }

        }

        public void Doc_Gridbind()
        {
            DataTable dt = new DataTable();
            doc.Sql_Operation = "Grid_Show";
            doc.Society_Id = society_id.Value;
            dt = bL_Doc.getDocDetails(doc);
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
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("Select * from doc_master where active_status=0 and society_id='" + society_id.Value + "'");
           if (!string.IsNullOrEmpty(txt_search.Text))
            {
                sb.Append(" and doc_name LIKE '" + txt_search.Text + "%'");
            }
            doc.Sql_Operation = sb.ToString();
            var result = bL_Doc.search_doc(doc);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);

        }
        public void runproc_save(string operation)
        {
            if (doc_id.Value != "")
                doc.doc_id = Convert.ToInt32(doc_id.Value);
            doc.Sql_Operation = operation;
            doc.Society_Id = society_id.Value;
            doc.Doc_Name = txt_doc_name.Text;
            bL_Doc.updatedocdetails(doc);
        }
        public void runproc_doc_search(String operation)
        {
            if (doc_id.Value != "")
                doc.doc_id = Convert.ToInt32(doc_id.Value);
            doc.Sql_Operation = operation;
            var result = bL_Doc.updatedocdetails(doc);

            (doc_id.Value) = result.doc_id.ToString();
            society_id.Value = result.Society_Id;
            txt_doc_name.Text = result.Doc_Name;
        
        }

        protected void btn_save_Click(object sender, EventArgs e)
        {

            if (Label1.Text == "")
            {
                runproc_save("Update");
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);

            }

        }

        protected void btn_delete_Click(object sender, EventArgs e)
        {
                if (doc_id.Value != "")
                    doc.doc_id = Convert.ToInt32(doc_id.Value);
                doc.Sql_Operation = "Delete";
                bL_Doc.delete(doc);
          
            Response.Redirect("doc_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {
            Response.Redirect("doc_search.aspx");
        }

        protected void txt_doc_name_TextChanged(object sender, EventArgs e)
        {
            if (txt_doc_name.Text.Trim() != "")
            {
                if (doc_id.Value != "")
                    doc.doc_id = Convert.ToInt32(doc_id.Value);
                doc.Sql_Operation = "check_name";
                doc.Society_Id = society_id.Value;
                doc.Doc_Name = txt_doc_name.Text;
                var result = bL_Doc.docnametextchanged(doc);
                //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);
                Label1.Text = result.Sql_Result;
            }
        }
        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            doc_id.Value = id;
            runproc_doc_search("Select");
            

            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
                GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
                System.Web.UI.WebControls.Label d_id = (System.Web.UI.WebControls.Label)row.FindControl("doc_id");
                doc.Sql_Operation = "Delete";

                doc.doc_id = Convert.ToInt32(d_id.Text);
                bL_Doc.delete(doc);
                Doc_Gridbind();
        }

      
        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Doc_Gridbind();
        }

    }

}



