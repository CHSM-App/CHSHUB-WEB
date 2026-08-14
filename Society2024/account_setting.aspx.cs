using BusinessLogic.BL;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace Society
{
    public partial class account_setting : System.Web.UI.Page
    {
        Account_Setting account = new Account_Setting();
        BL_Account_Setting BL_Account = new BL_Account_Setting();
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["name"] == null)
            {
                Response.Redirect("login1.aspx");
            }
            society_id.Value = Session["society_id"].ToString();
            if (!IsPostBack)
            {
                getcode();           
            runproc_account("Select");
            }
        }
        protected void getcode()
        {
           
            account.Sql_Operation = "getcode";
            account.Society_Id = society_id.Value;
           var result = BL_Account.GetCode(account);
            acc_set_id.Value = result.Acc_Set_Id.ToString();

        }
        public void runproc(string operation)
        {
            if (acc_set_id.Value != "")
            account.Acc_Set_Id = Convert.ToInt32(acc_set_id.Value);
            account.Sql_Operation = operation;
            account.Society_Id = society_id.Value;
            account.Mem_Open_Bal = Convert.ToInt32(DropDownList1.SelectedValue);
            account.Mem_Charge_Btn = Convert.ToInt32(DropDownList2.SelectedValue);
            account.Mem_Charge_Allocation = Convert.ToInt32(DropDownList3.SelectedValue);
            account.Receipt_Btn = Convert.ToInt32(DropDownList4.SelectedValue);
            account.Bill_Gen_Btn = Convert.ToInt32(DropDownList5.SelectedValue);
            account.Gst_Round = Convert.ToInt32(DropDownList6.SelectedValue);
            account.Charge_Round = Convert.ToInt32(DropDownList7.SelectedValue);
            account.Payment_Voucher = Convert.ToInt32(DropDownList8.SelectedValue);
            account.Debit_Note_Voucher = Convert.ToInt32(DropDownList9.SelectedValue);
            account.Credit_Note_Voucher = Convert.ToInt32(DropDownList10.SelectedValue);
            account.General_Voucher = Convert.ToInt32(DropDownList11.SelectedValue);
            account.Receipt_Voucher = Convert.ToInt32(DropDownList12.SelectedValue);
            account.Build_Wise_Payment = Convert.ToInt32(DropDownList13.SelectedValue);
            account.Remainder_Email_Dues = Convert.ToInt32(DropDownList14.SelectedValue);
            account.ratePerSq = Convert.ToDecimal(txtRatePerSqFeet.Text);
            account.twoWRate = Convert.ToDecimal(txtTwoWheelerRate.Text);
            account.fourWRate = Convert.ToDecimal(txtFourWheelerRate.Text);
            BL_Account.update_account_setting(account);


        }

        private void runproc_account(string operation)
        {
            if (acc_set_id.Value != "")
                account.Acc_Set_Id = Convert.ToInt32(acc_set_id.Value.ToString());

            account.Sql_Operation = operation;
            var result = BL_Account.update_account_setting(account);

            (acc_set_id.Value) = result.Acc_Set_Id.ToString();
            society_id.Value = result.Society_Id;
            DropDownList1.SelectedValue = result.Mem_Open_Bal.ToString();
            DropDownList2.SelectedValue = result.Mem_Charge_Btn.ToString();
            DropDownList3.SelectedValue = result.Mem_Charge_Allocation.ToString();
            DropDownList4.SelectedValue = result.Receipt_Btn.ToString();
            DropDownList5.SelectedValue = result.Bill_Gen_Btn.ToString();
            DropDownList6.SelectedValue = result.Gst_Round.ToString();
            DropDownList7.SelectedValue = result.Charge_Round.ToString();
            DropDownList8.SelectedValue = result.Payment_Voucher.ToString();
            DropDownList9.SelectedValue = result.Debit_Note_Voucher.ToString();
            DropDownList10.SelectedValue = result.Credit_Note_Voucher.ToString();
            DropDownList11.SelectedValue = result.General_Voucher.ToString();
            DropDownList12.SelectedValue = result.Receipt_Voucher.ToString();
            DropDownList13.SelectedValue = result.Build_Wise_Payment.ToString();
            DropDownList14.SelectedValue = result.Remainder_Email_Dues.ToString();

        }

        protected void btn_save_Click(object sender, EventArgs e)
        {
            runproc("Update");
            Response.Redirect("account_setting.aspx");


        }
    }
}