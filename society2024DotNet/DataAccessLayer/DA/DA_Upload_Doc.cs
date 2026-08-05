using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Upload_Doc
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable get_upload_doc(upload_doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("society_id", doc.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable get_doc(int flat_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "get_doc"));
            data_item.Add(st.create_array("society_id", flat_id));

            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public upload_doc Flat_No_SelectedIndexChanged(upload_doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 = "";

            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("society_id", doc.Society_Id));
            data_item.Add(st.create_array("file_id", doc.File_Id));
            data_item.Add(st.create_array("doc_id", doc.doc_id));
            data_item.Add(st.create_array("flat_id", doc.flat_id));
          
            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    doc.Sql_Result = "Already exist";
                else
                    doc.Sql_Result = "";
            return doc;

        }

        public DataTable Fill_list(string society, string operation, string build_id, string wing_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("society_id", society));
            data_item.Add(st.create_array("build_id", build_id));
            data_item.Add(st.create_array("wing_id", wing_id));



            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }

        public upload_doc doc_search_update(upload_doc doc)
        {


            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("file_id", doc.File_Id));
            if (doc.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", doc.Society_Id));
                data_item.Add(st.create_array("file_save_path", doc.File_Save_Path));
                data_item.Add(st.create_array("doc_id", doc.doc_id));
                data_item.Add(st.create_array("build_id", doc.build_id));
                data_item.Add(st.create_array("wing_id", doc.wing_id));
                data_item.Add(st.create_array("flat_id", doc.flat_id));

                data_item.Add(st.create_array("date", doc.Date));

            }
            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);
            doc.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (doc.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  facility_id.Value = sdr["facility_id"].ToString();
                        doc.Society_Id = sdr["society_id"].ToString();
                        doc.File_Save_Path = sdr["file_save_path"].ToString();
                        doc.doc_id = Convert.ToInt32(sdr["doc_id"]);
                        doc.build_id = Convert.ToInt32(sdr["build_id"]);
                        doc.wing_id = Convert.ToInt32(sdr["wing_id"]);
                        doc.flat_id = Convert.ToInt32(sdr["flat_id"]);

                        doc.Date = Convert.ToDateTime(sdr["date"]);

                    }
                }
                else
                {
                    doc.Sql_Result = status1;
                }
            }
            return doc;

        }

            public upload_doc doc_master_update(upload_doc doc)
            {
                ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
                SqlDataReader sdr = null;
                string status1 = "";
                data_item.Add(st.create_array("operation", doc.Sql_Operation));
                data_item.Add(st.create_array("file_id", doc.File_Id));
                if (doc.Sql_Operation == "Update")
                {
                    data_item.Add(st.create_array("society_id", doc.Society_Id));
                    data_item.Add(st.create_array("Tag", doc.Tag));
                    data_item.Add(st.create_array("Description", doc.Description));
                    data_item.Add(st.create_array("file_save_path", doc.File_Save_Path));
                data_item.Add(st.create_array("doc_name", doc.Doc_Name));
                }
                status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);
                doc.Sql_Result = status1;

                if (status1 == "Done")
                {
                    if (doc.Sql_Operation == "Select")
                    {
                        while (sdr.Read())
                        {
                            //  facility_id.Value = sdr["facility_id"].ToString();
                            doc.Society_Id = sdr["society_id"].ToString();
                            doc.File_Save_Path = sdr["file_save_path"].ToString();
                            doc.Tag = sdr["Tag"].ToString();
                            doc.Description = sdr["Description"].ToString();
                        }
                    }
                    else
                    {
                        doc.Sql_Result = status1;
                    }
                }
                return doc;



                //ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
                //SqlDataReader sdr = null;
                //string status = "";
                //data_item.Add(st.create_array("operation", operation));
                //data_item.Add(st.create_array("file_id", file_id.Value == null ? (object)DBNull.Value : file_id.Value));
                //if (operation == "Update")
                //{
                //    data_item.Add(st.create_array("society_id", society_id.Value == null ? (object)DBNull.Value : society_id.Value));
                //    data_item.Add(st.create_array("file_save_path", string.IsNullOrWhiteSpace(path) ? (object)DBNull.Value : path));
                //    data_item.Add(st.create_array("doc_id", string.IsNullOrWhiteSpace(ddl_doc_type.SelectedValue) ? (object)DBNull.Value : ddl_doc_type.SelectedValue));
                //    data_item.Add(st.create_array("build_id", string.IsNullOrWhiteSpace(ddl_build.SelectedValue) ? (object)DBNull.Value : ddl_build.SelectedValue));
                //    data_item.Add(st.create_array("wing_id", string.IsNullOrWhiteSpace(ddl_wing.SelectedValue) ? (object)DBNull.Value : ddl_wing.SelectedValue));
                //    data_item.Add(st.create_array("facility_id", string.IsNullOrWhiteSpace(ddl_type.SelectedValue) ? (object)DBNull.Value : ddl_type.SelectedValue));
                //    data_item.Add(st.create_array("fnowner_id", string.IsNullOrWhiteSpace(ddl_flatno.SelectedValue) ? (object)DBNull.Value : ddl_flatno.SelectedValue));
                //    data_item.Add(st.create_array("date", string.IsNullOrWhiteSpace(txt_date.Text) ? (object)DBNull.Value : txt_date.Text));
                //}
                //status = st.run_query(data_item, operation, "sp_upload_doc", ref sdr);
                //if (status == "Done")
                //{
                //    Label2.Text = string.Format("Files Uploaded Successfully");
                //    Label2.ForeColor = System.Drawing.Color.Green;
                //    if (operation == "Select")
                //    {
                //        while (sdr.Read())
                //        {
                //            txt_date.Text = Convert.ToDateTime(sdr["date"]).ToString("yyyy-MM-dd");
                //            ddl_build.SelectedValue = sdr["build_id"].ToString();
                //            txt_wing.Text = sdr["w_name"].ToString();
                //            txt_no.Text = sdr["flat_no"].ToString();
                //            txt_type.Text = sdr["bed"].ToString();

                //            ddl_doc_type.SelectedValue = sdr["doc_id"].ToString();
                //            Label15.Text = sdr["file_save_path"].ToString();

                //        }
                //    }
                //}
            }

        public upload_doc delete_upload_doc(upload_doc doc)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", doc.Sql_Operation));
            data_item.Add(st.create_array("file_id", doc.File_Id));

            status = st.run_query(data_item, "Delete", "sp_upload_doc", ref sdr);
            if (status == "Done")
            {
                doc.Sql_Result = status;
            }
            return doc;
        }

        public DataTable upload_doc_serach(upload_doc doc)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", doc.Sql_Operation));
            data_item.Add(st.create_array("search", doc.Doc_Name));
            data_item.Add(st.create_array("society_id", doc.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public void delete_File(int file_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", "Delete"));
            data_item.Add(st.create_array("file_id", file_id));

            status1 = st.run_query(data_item, "Select", "sp_upload_doc", ref sdr);
        }
    }
}