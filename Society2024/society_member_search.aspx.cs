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
using DBCode.DataClass.Master_Dataclass;
using BusinessLogic.MasterBL;
using System.Windows.Forms;
using BusinessLogic.BL;
using Society2024;
using DBCode.DataClass;
using System.Security.Cryptography;

namespace Society
{


    public partial class society_member_search : System.Web.UI.Page
    {
        BL_FillRepeater repeater = new BL_FillRepeater();
        Owner owner = new Owner();
        BL_Owner_Master bl_owner = new BL_Owner_Master();
        Society_Member member = new Society_Member();
        BL_Society_Member_Master bL_Society = new BL_Society_Member_Master();

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
             
              
                Society_Member_Gridbind();
                Allbound();

            }

        }

        protected void Allbound()
        {
            DataTable dt = new DataTable();
            dt = bL_Society.fill_list("fill_owner", society_id.Value);
            categoryRepeater1.DataSource = dt;
            categoryRepeater1.DataBind();
            dt = bL_Society.fill_list("fill_type", society_id.Value);
            categoryRepeater2.DataSource = dt;
            categoryRepeater2.DataBind();

        }
        protected void CategoryRepeater_ItemCommand1(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                name_id.Value = e.CommandArgument.ToString();
                owner.owner_id = Convert.ToInt32(e.CommandArgument);
                owner.Sql_Operation = "Select";
                var result = bl_owner.runproc(owner);
                txt_contact_no.Text = result.Pre_Mob;
                txt_email.Text = result.Email;
                txt_username.Text = result.Email;

            }
        }

        protected void CategoryRepeater_ItemCommand2(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "SelectCategory")
            {
                Designation_id.Value = e.CommandArgument.ToString();



            }
        }


        protected void Society_Member_Gridbind()
        {
            DataTable dt = new DataTable();
            member.Sql_Operation = "Grid_Show";
            member.Society_Id = society_id.Value;
            dt = bL_Society.getSocietyMemberDetails(member);
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


        protected void btn_new_Click(object sender, EventArgs e)
        {
            Response.Redirect("society_member_search.aspx");
        }

        protected void btn_search_Click(object sender, EventArgs e)
        {
            member.Name = txt_search.Text;
            member.Sql_Operation = "Search";
            member.Society_Id = society_id.Value;
            var result = bL_Society.search_member(member);
            GridView1.DataSource = result;
            ViewState["dirState"] = result;
            GridView1.DataBind();
            ScriptManager.RegisterStartupScript(this, this.GetType(), "Refocus", "refocusAfterPostback();", true);
        }

        public string runproc_save(string operation)
        {

            if (user_id.Value != "")
                member.UserId = Convert.ToInt32(user_id.Value);
            member.Sql_Operation = operation;
            member.Society_Id = society_id.Value;
            member.Name = TextBox1.Text;
            member.Designation = Convert.ToInt32(Designation_id.Value);
            member.UserName = txt_username.Text;
            string plainPassword = txt_password.Text;
            string hashedPassword = HashPassword(plainPassword);
            member.Password = hashedPassword;
            member.Email = txt_email.Text;
            member.Contact_No = txt_contact_no.Text;
            member.Status = 0;
            member.Owner_id = Convert.ToInt32(name_id.Value);
            
            var result = bL_Society.updateSocietyMemberDetails(member);
            return result.Sql_Result;
        }


        public void runproc_edit_society_member(String operation)
        {
            if (user_id.Value != "")
                member.UserId = Convert.ToInt32(user_id.Value);
            member.Sql_Operation = operation;

            var result = bL_Society.updateSocietyMemberDetails(member);


            (user_id.Value) = result.UserId.ToString();
            society_id.Value = result.Society_Id;
            TextBox1.Text = result.Name.ToString();
            Designation_id.Value = result.Designation.ToString();
            TextBox1.Text = result.Name;
            //txt_address1.Text = result.Address1.ToString();
            //txt_address2.Text = result.Address2.ToString();
            txt_contact_no.Text = result.Contact_No.ToString();
            txt_email.Text = result.Email.ToString();
            txt_username.Text = result.UserName.ToString();
            txt_password.Text = result.Password.ToString();
            name_id.Value = result.Owner_id.ToString();

            String str = "Select *  from UserType where type = 1";
            repeater.fill_list(categoryRepeater2, str);

        }


        protected void btn_save_Click(object sender, EventArgs e)
        {
            member.UserName = txt_username.Text.Trim();
            member.Email = txt_email.Text.Trim();
            member.UserId = string.IsNullOrEmpty(user_id.Value) ? 0 : Convert.ToInt32(user_id.Value);

          

            // 🔍 Check email
            var emailResult = bL_Society.CheckDuplicateEmail(member);
            if (emailResult.Sql_Result == "Exist")
            {
                Label7.Text = "This Email is already registered.";
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "openModal();", true);
                return;
            }

            // All good, proceed to save
            string str = runproc_save("Update");
            if (str == "Done")
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "SuccessEntry();", true);
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "Pop", "FailedEntry();", true);
                ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            }
        }


        protected void btn_delete_Click(object sender, EventArgs e)
        {

            if (user_id.Value != "")
                member.UserId = Convert.ToInt32(user_id.Value);
            member.Sql_Operation = "Delete";
            member.Name = TextBox1.Text;
            member.Designation = Convert.ToInt32(Designation_id.Value);
            //member.Address1 = txt_address1.Text;
            //member.Address2 = txt_address2.Text;
            //member.Contact_No = txt_contact_no.Text;
            //member.Email = txt_email.Text;
            member.UserName = txt_username.Text;
            member.Password = txt_password.Text;
            member.Status = 0;
            bL_Society.delete(member);

            Response.Redirect("society_member_search.aspx");

        }

        protected void btn_close_Click(object sender, EventArgs e)
        {


            Response.Redirect("society_member_search.aspx");
        }

        protected void edit_Command(object sender, CommandEventArgs e)
        {
            string id = e.CommandArgument.ToString();
            user_id.Value = id;
            runproc_edit_society_member("Select");
            passPanel.Visible = false;
            ScriptManager.RegisterStartupScript(this, this.GetType(), "ShowModalScript", "openModal();", true);
            //ScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "OpenModal()", "<script>$('#mymodal').modal('show');</script>", true);
        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {

            GridViewRow row = (GridViewRow)GridView1.Rows[e.RowIndex];
            System.Web.UI.WebControls.Label user_id = (System.Web.UI.WebControls.Label)row.FindControl("user_id");
            member.Sql_Operation = "Delete";

            member.UserId = Convert.ToInt32(user_id.Text);
            bL_Society.delete(member);
            //ClientScript.RegisterStartupScript(this.GetType(), "Pop", "alert('" + result.Sql_Result + "')", true);

            Society_Member_Gridbind();


        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {

        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {

        }

        protected void txt_contact_no_TextChanged(object sender, EventArgs e)
        {
            if (txt_contact_no.Text.Trim() != "")
            {
                if (user_id.Value != "")
                    member.UserId = Convert.ToInt32(user_id.Value);
                member.Contact_No = txt_contact_no.Text;
                member.Society_Id = society_id.Value;
                member.Sql_Operation = "chk_name";
                var result = bL_Society.SocietyMemberTextChange(member);
                Label25.Text = result.Sql_Result;
            }
        }

        protected void txt_email_TextChanged(object sender, EventArgs e)
        {

            txt_username.Text = txt_email.Text;
        }

        protected void GridView1_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            GridView1.PageIndex = e.NewPageIndex;
            Society_Member_Gridbind();
        }


        protected void categoryRepeater1_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (name_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == name_id.Value)
                        TextBox1.Text = link.Text;
                }
            }
        }

        protected void categoryRepeater2_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                if (Designation_id.Value != "")
                {
                    var link = (LinkButton)e.Item.FindControl("lnkCategory");
                    if (link.CommandArgument == Designation_id.Value)
                        Textbox2.Text = link.Text;

                }
            }
        }

        protected void showPass(object sender, EventArgs e)
        {
            passPanel.Visible = true;
        }

        private static string HashPassword(string password)
        {
            byte[] salt;
            new RNGCryptoServiceProvider().GetBytes(salt = new byte[16]);

            var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000);
            byte[] hash = pbkdf2.GetBytes(20);

            byte[] hashBytes = new byte[36];
            Array.Copy(salt, 0, hashBytes, 0, 16);
            Array.Copy(hash, 0, hashBytes, 16, 20);

            return Convert.ToBase64String(hashBytes);
        }
    }
}

