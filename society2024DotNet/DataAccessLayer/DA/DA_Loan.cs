using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace DataAccessLayer.DA
{
    public class DA_Loan
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getloan(Loan l_Loan)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", l_Loan.Sql_Operation));
            data_item.Add(st.create_array("society_id", l_Loan.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_loan", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable fill_list(string operation, string society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));

            data_item.Add(st.create_array("society_id", society_id));

            status1 = st.run_query(data_item, "Select", "sp_loan", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public object loan_search(Loan getLoan)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", getLoan.Sql_Operation));
            data_item.Add(st.create_array("search", getLoan.Name));
            data_item.Add(st.create_array("society_id", getLoan.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_loan", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Loan updateloan(Loan l_Loan)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", l_Loan.Sql_Operation));
            data_item.Add(st.create_array("loan_id", l_Loan.loan_id));
            if (l_Loan.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", l_Loan.Society_Id));
                data_item.Add(st.create_array("flat_id", l_Loan.flat_id));
                data_item.Add(st.create_array("bank", l_Loan.Bank));
                data_item.Add(st.create_array("type_id", l_Loan.Type_Id));
                data_item.Add(st.create_array("noc_issued", l_Loan.Noc_Issued));
                data_item.Add(st.create_array("cert_id", l_Loan.cert_id));
                data_item.Add(st.create_array("society_noc", l_Loan.Society_Noc));
                if(l_Loan.Loan_Clearance != DateTime.MinValue)
                data_item.Add(st.create_array("loan_clearance", l_Loan.Loan_Clearance));
            }
            status1 = st.run_query(data_item, "Select", "sp_loan", ref sdr);

            if (status1 == "Done")
            {
                if (l_Loan.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  flat_id.Value = sdr["flat_id"].ToString();
                        l_Loan.Society_Id = sdr["society_id"].ToString();
                        l_Loan.flat_id = Convert.ToInt32(sdr["flat_id"].ToString());
                        l_Loan.Bank = sdr["bank"].ToString();
                        l_Loan.Type_Id = Convert.ToInt32(sdr["type_id"].ToString());
                        l_Loan.Noc_Issued = sdr["noc_issued"].ToString();
                        l_Loan.cert_id = Convert.ToInt32(sdr["cert_id"].ToString());
                        l_Loan.Society_Noc = Convert.ToDateTime(sdr["society_noc"].ToString());
                        if (sdr["loan_clearance"].ToString()!= "")
                        {
                            l_Loan.Loan_Clearance = Convert.ToDateTime(sdr["loan_clearance"].ToString());
                        }
                    }
                }
                else
                {
                    l_Loan.Sql_Result = status1;
                }
            }
            return l_Loan;
        }
        public Loan Loan_Delete(Loan loan)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            data_item.Add(st.create_array("operation", "Delete"));
            data_item.Add(st.create_array("loan_id", loan.loan_id));
            status1 = st.run_query(data_item, "Select", "sp_loan", ref sdr);

            if (status1 == "Done")
            {
                loan.Sql_Result = status1;
            }
            return loan;
        }
    }
}