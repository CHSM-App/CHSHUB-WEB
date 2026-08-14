using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Configuration;
using System.Configuration;
using Microsoft.ApplicationBlocks.Data;
using System.Collections;
using static System.Net.Mime.MediaTypeNames;

namespace Society
{
    public partial class stored : System.Web.UI.Page
    {
        String sqlconn;

        public void fill_list(Repeater repeater, string sqlstring)
        {
            SqlConnection con = new SqlConnection(setsqlconnection());

            SqlDataReader sdr = SqlHelper.ExecuteReader(con, CommandType.Text, sqlstring);

            repeater.DataSource = sdr;
            repeater.DataBind();
        }

        public void fill_list_maintanace(Repeater repeater, string sqlstring)
        {
            using (SqlConnection con = new SqlConnection(setsqlconnection()))
            {
                con.Open();

              
                SqlDataAdapter da = new SqlDataAdapter(sqlstring, con);
                DataTable dt = new DataTable();
                da.Fill(dt);

                // Add hardcoded row
                DataRow extraRow = dt.NewRow();
                extraRow["wing_id"] = 0; 
                extraRow["w_name"] = "ALL"; 
                dt.Rows.InsertAt(extraRow,0);

                // Bind to repeater
                repeater.DataSource = dt;
                repeater.DataBind();
            }
        }
  
        public string setsqlconnection()
        {
            sqlconn =ConfigurationManager.ConnectionStrings["DBCS"].ConnectionString;

            return sqlconn;
        }

       
        public void fill_drop_1(DropDownList drp_down, string sqlstring, string text, string value)
        {
            SqlConnection con ;

            con = new SqlConnection(setsqlconnection());

            SqlDataReader sdr = SqlHelper.ExecuteReader(con, CommandType.Text, sqlstring);
            
            drp_down.DataSource = sdr; 
            drp_down.DataTextField = text;
            drp_down.DataValueField = value;
            drp_down.DataBind();
            drp_down.Items.Insert(0, new ListItem("ALL", "0"));

        }

        internal void fill_drop(object dpdwYear, string sql1, string v1, string v2)
        {
            throw new NotImplementedException();
        }

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            SqlConnection con = null;
           
                con = new SqlConnection(setsqlconnection());

                SqlDataReader sdr = SqlHelper.ExecuteReader(con, CommandType.Text, sqlstring);
            //DataTable dt = new DataTable();
            //dt.Load(sdr);
                drp_down.DataSource = sdr;
                drp_down.DataTextField = text;
                drp_down.DataValueField = value;
                drp_down.DataBind();
            //drp_down.Items.Add(0,new ListItem("Select1", "select1"));
            drp_down.Items.Insert(0, new ListItem("select" ,"0"));
        }

        public ArrayList create_array(string field_name,object field_value)
        {
            ArrayList data_aaray = new ArrayList();
            data_aaray.Add(field_name);
            data_aaray.Add(field_value);
            return data_aaray;
        }

        public string run_query(ICollection<ArrayList> data_item,string operation,string stored_proc,ref SqlDataReader sdr)
        {
            
            string status = "Error";
            SqlConnection con = null;
            try{
            con = new SqlConnection(setsqlconnection());

            List<SqlParameter> parameters = new List<SqlParameter>();
            foreach (ArrayList ar in data_item)
            {
                String field_name = (string)ar[0];
               
              //  Console.WriteLine(ar);
                parameters.Add(new SqlParameter(field_name, ar[1]));
                
            }
                int rowsAffected=0;
               switch (operation)  
                {  

                  case "Update":  
                    rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                  break;  
                  case "Insert":  
                   rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                  break;  
                  case "Delete":  
                  rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                  break;  
                  case "Select":
                   sdr = SqlHelper.ExecuteReader(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                 //       if(sdr.Read())
                 //       {
                            rowsAffected = 1;
                 //       }
                        
                  break;  
               }  
         //   int rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
           
            if (rowsAffected == 1)
            {
                status = "Done";
            }
            }
            catch(System.Data.SqlClient.SqlException ex)
            {
               status = ex.Message;
                  
            }
              return status;

        }

       

        public string run_query_scalar(ICollection<ArrayList> data_item, string operation, string stored_proc, ref int sdr)
        {

            string status = "Error";
            SqlConnection con = null;
            try
            {
                con = new SqlConnection(setsqlconnection());
                //  string sqlstring = "Select * from standard";
                // SqlCommand cmd = new SqlCommand(sqlstring, con);

                List<SqlParameter> parameters = new List<SqlParameter>();
                foreach (ArrayList ar in data_item)
                {
                    String field_name = (string)ar[0];

                    //  Console.WriteLine(ar);
                    parameters.Add(new SqlParameter(field_name, ar[1]));

                }
                int rowsAffected = 0;
                switch (operation)
                {

                    case "Update":
                        rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                        break;
                    case "Insert":
                        rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                        break;
                    case "Delete":
                        rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());
                        break;
                    case "Select":
                    object  obj =SqlHelper.ExecuteScalar(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());

                        rowsAffected = 1;
                        sdr = Convert.ToInt32(obj);
                        //       }

                        break;
                }
                //   int rowsAffected = SqlHelper.ExecuteNonQuery(con, CommandType.StoredProcedure, stored_proc, parameters.ToArray());

                if (rowsAffected == 1)
                {
                    status = "Done";
                }
            }
            catch (System.Data.SqlClient.SqlException ex)
            {
                status = ex.Message;

            }
            return status;

        }

       
    }


}