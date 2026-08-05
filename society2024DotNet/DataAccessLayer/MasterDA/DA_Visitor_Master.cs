using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.EnterpriseServices;
using System.Linq;
using System.Web;
using System.Web.Services.Description;
using System.Web.UI.WebControls;

namespace DataAccessLayer.MasterDA
{
    public class DA_Visitor_Master
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getVisitorDetails(Visitor visitor)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", visitor.Sql_Operation));
            data_item.Add(st.create_array("society_id", visitor.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_visitor", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Fill_list(string operation, string build_id, string society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("society_id", society_id));
            data_item.Add(st.create_array("build_id", build_id));

            status1 = st.run_query(data_item, "Select", "sp_visitor", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Visitor UpdateVisitorDetails(Visitor visitor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", visitor.Sql_Operation));
            data_item.Add(st.create_array("visitor_id", visitor.visitor_id));
            if (visitor.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", visitor.Society_Id));
                data_item.Add(st.create_array("v_name", visitor.V_Name));
                data_item.Add(st.create_array("type", visitor.V_Type));
                data_item.Add(st.create_array("contact_no", visitor.Contact_No));
                data_item.Add(st.create_array("flat_id", visitor.flat_id));
                data_item.Add(st.create_array("image", visitor.Image));
                data_item.Add(st.create_array("in_date", visitor.In_Date));
                if (visitor.Out_Date != DateTime.MinValue)
                    data_item.Add(st.create_array("out_date", visitor.Out_Date));
                data_item.Add(st.create_array("in_time", visitor.In_Time));
                if (visitor.Out_Time != DateTime.MinValue)
                    data_item.Add(st.create_array("out_time", visitor.Out_Time));
                data_item.Add(st.create_array("build_id", visitor.build_id));
                data_item.Add(st.create_array("vehicle_no", visitor.Vehical_No));
                data_item.Add(st.create_array("purpose", visitor.Visiting_Purpose));
            }
            status = st.run_query(data_item, "Select", "sp_Visitor", ref sdr);
            if (status == "Done")
            {
                if (visitor.Sql_Operation == "Select")
                {

                    if (sdr.Read())
                    {

                        visitor.V_Name = sdr["v_name"].ToString();
                        visitor.V_Type = sdr["type"].ToString();
                        visitor.Contact_No = sdr["contact_no"].ToString();
                        visitor.flat_id = Convert.ToInt32(sdr["flat_id"].ToString());
                        visitor.Vehical_No = sdr["vehicle_no"].ToString();
                        visitor.Visiting_Purpose = sdr["purpose"].ToString();
                        visitor.Image = sdr["image"].ToString();
                        visitor.company = sdr["company"].ToString();
                        visitor.location = sdr["location"].ToString();
                        visitor.imgpath = sdr["image"].ToString();


                        if (sdr["in_date"].ToString() != "")
                            visitor.In_Date = Convert.ToDateTime(sdr["in_date"].ToString());
                        if (sdr["out_date"].ToString() != "")
                            visitor.Out_Date = Convert.ToDateTime(sdr["out_date"].ToString());
                        if (sdr["in_time"].ToString() != "")
                            visitor.In_Time = Convert.ToDateTime(sdr["in_time"].ToString());
                        if (sdr["out_time"].ToString() != "")
                            visitor.Out_Time = Convert.ToDateTime(sdr["out_time"].ToString());

                        visitor.build_id = Convert.ToInt32(sdr["build_id"].ToString());

                    }
                }
                else
                {
                    visitor.Sql_Result = status;
                }

            }
            return visitor;
        }

        public DataTable Get_PrintVisitor(Visitor visitor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", visitor.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public object search_visitor(Visitor visitor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", visitor.Sql_Operation));
            data_item.Add(st.create_array("search", visitor.V_Name));
            data_item.Add(st.create_array("society_id", visitor.Society_Id));
            if (visitor.In_Date != DateTime.MinValue)
                data_item.Add(st.create_array("fromDate", visitor.In_Date));
            if (visitor.Out_Date != DateTime.MinValue)
                data_item.Add(st.create_array("toDate", visitor.Out_Date));

            status1 = st.run_query(data_item, "Select", "sp_visitor", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Visitor delete_visitor(Visitor visitor)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", visitor.Sql_Operation));
            data_item.Add(st.create_array("visitor_id", visitor.visitor_id));

            status = st.run_query(data_item, "Delete", "sp_visitor", ref sdr);
            if (status == "Done")
            {
                visitor.Sql_Result = status;
            }
            return visitor;
        }
    }
}