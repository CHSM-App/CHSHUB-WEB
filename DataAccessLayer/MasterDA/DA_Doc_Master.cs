using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace DataAccessLayer.MasterDA
{
     
    public class DA_Doc_Master
    {
        stored st = new stored();
        public DataTable getDocDetails(Doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("society_id", doc.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_doc_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }
        public Doc updateDocDetails(Doc doc)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("doc_id", doc.doc_id));
            if (doc.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", doc.Society_Id));
                data_item.Add(st.create_array("doc_name", doc.Doc_Name));



            }
            status1 = st.run_query(data_item, "Select", "sp_doc_master", ref sdr);

            if (status1 == "Done")
            {
                if (doc.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  facility_id.Value = sdr["facility_id"].ToString();
                        doc.Doc_Name = sdr["doc_name"].ToString();

                    }
                }
                else
                {
                    doc.Sql_Result = status1;
                }
            }
            return doc;
        }

        public object doc_search(Doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", doc.Sql_Operation));
            data_item.Add(st.create_array("society_id", doc.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Doc delete_Doc(Doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("doc_id", doc.doc_id));

            status = st.run_query(data_item, "Delete", "sp_doc_master", ref sdr);
            if (status == "Done")
            {
                doc.Sql_Result = status;
            }
            return doc;

        }
        public Doc Doc_Name_Textchanged(Doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 = "";

            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("society_id", doc.Society_Id));
            data_item.Add(st.create_array("doc_id", doc.doc_id));
            data_item.Add(st.create_array("doc_name", doc.Doc_Name));
            status1 = st.run_query(data_item, "Select", "sp_doc_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    doc.Sql_Result = "Already exist";
                else
                    doc.Sql_Result = "";
            return doc;


            //ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            //string status1 = "";

            //data_item.Add(st.create_array("operation", "check_name"));
            //data_item.Add(st.create_array("doc_id", doc_id.Value == null ? (object)DBNull.Value : doc_id.Value));
            //data_item.Add(st.create_array("doc_name", string.IsNullOrWhiteSpace(txt_doc_name.Text) ? (object)DBNull.Value : txt_doc_name.Text));
            //status1 = st.run_query(data_item, "Select", "sp_doc_master", ref sdr);
            //if (status1 == "Done")
            //{
            //    if (sdr.Read())
            //    {
            //        Label1.Text = ("Already exist");
            //    }
            //    else
            //        Label1.Text = "";


            //}


        }
    }
}