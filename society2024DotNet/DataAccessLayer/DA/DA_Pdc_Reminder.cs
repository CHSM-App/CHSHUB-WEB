using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web; 
using System.Web.UI;
using System.Web.UI.WebControls;

namespace DataAccessLayer.DA
{
    public class DA_Pdc_Reminder
    {
        stored st = new stored();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getpdcreminder(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("society_id", Reminder.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public pdc_reminder Chqno_Textchanged(pdc_reminder reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1;

            data_item.Add(st.create_array("operation", reminder.Sql_Operation));
            data_item.Add(st.create_array("pdc_rem_id", reminder.pdc_rem_id));
            data_item.Add(st.create_array("chqno", reminder.Chq_No));
            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    reminder.Sql_Result = "Already exist";
                else
                    reminder.Sql_Result = "";
            return reminder;
        }

        public DataTable fill_list(string operation, string society_id)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", operation));

            data_item.Add(st.create_array("society_id", society_id));

            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Owner_Grid(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("owner_id", Reminder.owner_id));

            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public pdc_reminder Update_Pdc_Reminder(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("pdc_rem_id", Reminder.pdc_rem_id));
            if (Reminder.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", Reminder.Society_Id));
                data_item.Add(st.create_array("owner_id", Reminder.owner_id));
                data_item.Add(st.create_array("o_name", Reminder.O_Name));
                data_item.Add(st.create_array("wing_id", Reminder.wing_id));
                data_item.Add(st.create_array("chqno", Reminder.Chq_No));
                data_item.Add(st.create_array("che_date", Reminder.Che_Date));
                data_item.Add(st.create_array("che_amount", Reminder.Che_Amount));
                data_item.Add(st.create_array("che_dep", Reminder.Che_Dep));
                data_item.Add(st.create_array("che_can", Reminder.Che_Can));
                data_item.Add(st.create_array("che_ret", Reminder.Che_Ret));

            }
            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);
            Reminder.Sql_Result = status1;

            if (status1 == "Done")
            {
                if (Reminder.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        Reminder.Society_Id = sdr["society_id"].ToString();
                        Reminder.owner_id = Convert.ToInt32(sdr["owner_id"].ToString());
                       
                        Reminder.wing_id = Convert.ToInt32(sdr["wing_id"].ToString());
                        Reminder.Chq_No = Convert.ToInt32(sdr["chqno"].ToString());
                        Reminder.Che_Date = Convert.ToDateTime(sdr["che_date"].ToString());
                        Reminder.Che_Amount = float.Parse(sdr["che_amount"].ToString());

                        Reminder.Che_Dep = Convert.ToInt32(sdr["che_dep"].ToString());
                        if (int.TryParse(sdr["che_dep"].ToString(), out int chedep))
                        {
                            Reminder.Che_Dep = chedep;
                        }

                        Reminder.Che_Can = Convert.ToInt32(sdr["che_can"].ToString());

                        if (int.TryParse(sdr["che_can"].ToString(), out int checan))
                        {
                            Reminder.Che_Can = checan;
                        }

                        Reminder.Che_Ret = Convert.ToInt32(sdr["che_ret"].ToString());

                        if (int.TryParse(sdr["che_ret"].ToString(), out int cheret))
                        {
                            Reminder.Che_Ret = cheret;
                        }

                    }
                }

            }
            return Reminder;



            //ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            //string status = "";
            //data_item.Add(st.create_array("operation", operation));
            //data_item.Add(st.create_array("p_id", p_id.Value == null ? (object)DBNull.Value : p_id.Value));
            //if (operation == "Update")
            //{
            //    data_item.Add(st.create_array("society_id", society_id.Value == null ? (object)DBNull.Value : society_id.Value));
            //      data_item.Add(st.create_array("owner_id", string.IsNullOrWhiteSpace(ddl_owner.SelectedValue) ? (object)DBNull.Value : ddl_owner.SelectedValue));
            //    data_item.Add(st.create_array("o_name", string.IsNullOrWhiteSpace(ddl_owner.SelectedItem.Text) ? (object)DBNull.Value : ddl_owner.SelectedItem.Text));
            //    data_item.Add(st.create_array("wing_id", string.IsNullOrWhiteSpace(ddl_build_wing.SelectedValue) ? (object)DBNull.Value : ddl_build_wing.SelectedValue));
            //    data_item.Add(st.create_array("chqno", string.IsNullOrWhiteSpace(txt_chq_no.Text) ? (object)DBNull.Value : txt_chq_no.Text));
            //    data_item.Add(st.create_array("che_date", string.IsNullOrWhiteSpace(txt_chq_date.Text) ? (object)DBNull.Value : txt_chq_date.Text));
            //    data_item.Add(st.create_array("che_amount", string.IsNullOrWhiteSpace(txt_chq_amount.Text) ? (object)DBNull.Value : txt_chq_amount.Text));
            //    data_item.Add(st.create_array("che_dep", deposite_chk.Checked == true ? 1 : 0));
            //    data_item.Add(st.create_array("che_can", bounce_chk.Checked == true ? 1 : 0));
            //    data_item.Add(st.create_array("che_ret", return_chk.Checked == true ? 1 : 0));
            //}
            //status = st.run_query(data_item, operation, "sp_pdc_reminder", ref sdr);
            //if (status == "Done")
            //{

            //    if (operation == "Select")
            //    {
            //        if (sdr.Read())
            //        {


            //            ddl_build_wing.SelectedValue = sdr["wing_id"].ToString();
            //            ddl_owner.SelectedValue = sdr["owner_id"].ToString();
            //            txt_chq_no.Text = sdr["chqno"].ToString();
            //            txt_chq_date.Text = Convert.ToDateTime(sdr["che_date"]).ToString("yyyy-MM-dd");
            //            txt_chq_amount.Text = sdr["che_amount"].ToString();
            //            string che_dep = sdr["che_dep"].ToString();
            //            deposite_chk.Checked = int.Parse(che_dep) == 1 ? true : false;
            //            string che_ret = sdr["che_ret"].ToString();
            //            return_chk.Checked = int.Parse(che_ret) == 1 ? true : false; 
            //            string che_can = sdr["che_can"].ToString();
            //            bounce_chk.Checked = int.Parse(che_can) == 1 ? true : false;
            //        }

            //    }
            //}



        }

        public DataTable reminder_search(pdc_reminder reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", reminder.Sql_Operation));
            data_item.Add(st.create_array("search", reminder.Search));
            data_item.Add(st.create_array("society_id", reminder.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Update_Pdc_Clearing(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("startdate", Reminder.Start_Date));
            data_item.Add(st.create_array("enddate", Reminder.End_Date));
            data_item.Add(st.create_array("society_id", Reminder.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);
            if (status1 == "Done")
                if (sdr.HasRows)
                {
                dt.Load(sdr);

            }
            return dt;
        }








        public pdc_reminder Delete_Pdc_Reminder(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("pdc_rem_id", Reminder.pdc_rem_id));

            status = st.run_query(data_item, "Delete", "sp_pdc_reminder", ref sdr);
            if (status == "Done")
            {
                Reminder.Sql_Result = status;
            }
            return Reminder;
        }

        public pdc_reminder Owner_SelectdIndexChanged(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("owner_id", Reminder.owner_id));
            status = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);
            if (status == "Done")
            {
                //dt.Load(sdr);
                if (sdr.Read())
                {
                    Reminder.Pre_Mob = sdr["pre_mob"].ToString();
                    Reminder.wing_id = Convert.ToInt32(sdr["wing_id"].ToString());
                    Reminder.Email = sdr["email"].ToString();
                    Reminder.Alter_Mob = sdr["alter_mob"].ToString();
                    Reminder.Pre_Addr1 = sdr["pre_addr1"].ToString();
                    Reminder.Pre_Addr2 = sdr["pre_add2"].ToString();

                }

            }
            return Reminder;
        }

        public pdc_reminder Save_Change(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            Label acc_no = new Label(), chq_no = new Label(), pdc_id = new Label(), che_date = new Label(), che_amt = new Label();
            CheckBox depo_chk = new CheckBox(), ret_chk = new CheckBox(), bou_chk = new CheckBox();

            //foreach (GridViewRow row in GridView1.Rows)
            //{

            //    data_item.Clear();

            //    data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            //    data_item.Add(st.create_array("p_id", Reminder.pdc_rem_id));
            //    data_item.Add(st.create_array("che_date", Reminder.Che_Date));
            //    data_item.Add(st.create_array("che_amount", Reminder.Che_Amount));
            //    data_item.Add(st.create_array("che_dep", Reminder.Che_Dep));
            //    data_item.Add(st.create_array("che_can", Reminder.Che_Can));
            //    data_item.Add(st.create_array("che_ret", Reminder.Che_Ret));
            //    status = st.run_query(data_item, "Update", "sp_pdc_reminder", ref sdr);

            //}
            return Reminder;
        }


        public pdc_reminder Next_Click(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status;
            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            data_item.Add(st.create_array("pdc_rem_id", Reminder.pdc_rem_id));
            data_item.Add(st.create_array("chqno", Reminder.Chq_No));


            status = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);
            if (status == "Done")
            {
                if (sdr.Read())
                {
                    
                    Reminder.Sql_Result = "Exist";

                }
            }
            return Reminder;
        }
        public pdc_reminder Save_Changes(pdc_reminder Reminder)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            //string status1;

            data_item.Add(st.create_array("operation", Reminder.Sql_Operation));
            
                data_item.Add(st.create_array("pdc_rem_id", Reminder.pdc_rem_id));
                data_item.Add(st.create_array("che_dep", Reminder.Che_Dep));
                data_item.Add(st.create_array("che_ret", Reminder.Che_Ret));
                data_item.Add(st.create_array("che_can", Reminder.Che_Can));


               string status1 = st.run_query(data_item, "Select", "sp_pdc_reminder", ref sdr);
                
            
            return Reminder;
        }
    }
}

    