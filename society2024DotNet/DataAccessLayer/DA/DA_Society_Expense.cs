using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Society_Expense
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable getExpenseDetails(Society_Expense society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("society_id", society.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable get_approver(Society_Expense expense)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
           
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", expense.Sql_Operation));
            data_item.Add(st.create_array("expense_id", expense.expense_id));

            status1 = st.run_query(data_item, "Select", "sp_approvar", ref sdr);

            if (status1 == "Done")
                if(sdr.HasRows)
                    dt.Load(sdr);
           
            return dt;
        }

        public DataTable get_expense_report(Society_Expense expense)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();

            data_item.Add(st.create_array("operation", expense.Sql_Operation));
            data_item.Add(st.create_array("search", expense.Ex_Name));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt; 
        }

        public DataTable fill_list(string operation, string society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));

            data_item.Add(st.create_array("society_id", society));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Society_Expense Update_Status(Society_Expense society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", society.Sql_Operation));
      
                data_item.Add(st.create_array("expense_id", society.expense_id));
                data_item.Add(st.create_array("user_id", society.User_Id));
   
            status = st.run_query(data_item, "Select", "sp_approvar", ref sdr);
            if (status == "Done")
            {
                society.Sql_Result = status;
            }
            return society;
        }

        public Society_Expense Select_expense(Society_Expense society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("expense_id", society.expense_id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (society.Sql_Operation == "Select")
            {
                while (sdr.Read())
                {
                    society.Invoice_No = sdr["invoice_no"].ToString();
                    society.Date = Convert.ToDateTime(sdr["date"].ToString());
                    society.Ex_Type = sdr["ex_type"].ToString();
                    society.Ex_Name = sdr["ex_name"].ToString();
                    society.Ex_Details = sdr["ex_details"].ToString();
                    society.Comments = sdr["comments"].ToString();
                    society.Amount = float.Parse(sdr["amount"].ToString());
                    society.Tax = float.Parse(sdr["tax"].ToString());
                    society.Tds = float.Parse(sdr["tds"].ToString());
                    society.F_Amount = float.Parse(sdr["f_amount"].ToString());
                    society.Regular = Convert.ToBoolean(sdr["regular"]);
                    society.Ex_Details = sdr["ex_details"].ToString();
                    society.Status = Convert.ToBoolean(sdr["status"]);
                }
            }
            return society;

        }

        public Society_Expense Update_Approver(Society_Expense society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("approver_id", society.Approvar_Id));
            if (society.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("bill_id", society.expense_id));
                data_item.Add(st.create_array("user_id", society.User_Id));
                //data_item.Add(st.create_array("date", society.Date));

            }


            status1 = st.run_query(data_item, "Select", "sp_approvar", ref sdr);

            if (status1 == "Done")
            {
                if (society.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        society.Invoice_No = sdr["expense_id"].ToString();
                        society.Ex_Type = sdr["user_id"].ToString();
                        //society.Date = Convert.ToDateTime(sdr["date"].ToString());

                    }
                }
            }

            return society;
        }

        public Society_Expense expense_fetch(Society_Expense society)
        {
            string status = "", str = "";
            int val = 0;
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("society_id", society.Society_Id));
            status = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    str = sdr["invoice_no"].ToString();
                    val = int.Parse(Regex.Match(str, @"\d+").ToString()) + 1;
                    society.Invoice_No = str.Replace((val - 1).ToString(), (val).ToString());
                }
                else
                {
                    society.Invoice_No = "EXP0001";
                }
            }
            return society;
        }

        public DataTable Chk_Reg_Exp(Society_Expense society)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("society_id", society.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable society_expense_search(Society_Expense expense)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", expense.Sql_Operation));
            data_item.Add(st.create_array("search", expense.Ex_Name));
            data_item.Add(st.create_array("society_id", expense.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_vendor_bills", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                    if (status1 == "Done")
                dt.Load(sdr);
            return dt;
        }

        public Society_Expense update_expense(Society_Expense society)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            int sdr = 0;
            string status1 = "";
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("expense_id", society.expense_id));
            if (society.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", society.Society_Id));
                data_item.Add(st.create_array("invoice_no", society.Invoice_No));
                data_item.Add(st.create_array("date", society.Date));
                //data_item.Add(st.create_array("build_id", society.build_id));

                data_item.Add(st.create_array("ex_name", society.Ex_Name));

                data_item.Add(st.create_array("ex_type", society.Ex_Type));

                data_item.Add(st.create_array("ex_details", society.Ex_Details));
                data_item.Add(st.create_array("comments", society.Comments));
                data_item.Add(st.create_array("add_maintanance", society.Add_Maintanance));
                data_item.Add(st.create_array("amount", society.Amount));
                data_item.Add(st.create_array("tax", society.Tax));
                data_item.Add(st.create_array("tds", society.Tds));
                data_item.Add(st.create_array("regular", society.Regular));
                data_item.Add(st.create_array("f_amount", society.F_Amount));


            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_vendor_bills", ref sdr);
            society.Sql_Result = status1;
            if (status1 == "Done")
            {
                society.Sql_Result = "Done";
                if (sdr != 0)
                    society.expense_id = sdr;
            }
            else
                society.Sql_Result="Error";
            return society;

            
        }
        public Society_Expense Delete_Expense(Society_Expense society)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", society.Sql_Operation));
            data_item.Add(st.create_array("expense_id", society.expense_id));

            status = st.run_query(data_item, "Delete", "sp_vendor_bills", ref sdr);
            if (status == "Done")
            {
                society.Sql_Result = status;
            }
            return society;
        }
    }
}









