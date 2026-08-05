using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace DataAccessLayer.MasterDA
{
    public class DA_Servent_Maid_Master
    {
        stored st = new stored();
        public DataTable getServentDetails(Servent_Made servent)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", servent.Sql_Operation));
            data_item.Add(st.create_array("society_id", servent.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_servent_maid_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }
        public Servent_Made updateServentDetails(Servent_Made servent)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", servent.Sql_Operation));
            data_item.Add(st.create_array("servent_id", servent.servent_id));
            if (servent.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", servent.Society_Id));
                data_item.Add(st.create_array("s_name", servent.S_Name));
                data_item.Add(st.create_array("s_address_1", servent.S_Address_1));
                data_item.Add(st.create_array("s_address_2", servent.S_Address_2));
                data_item.Add(st.create_array("mobile_no1", servent.Mobile_No1));
                data_item.Add(st.create_array("mobile_no2", servent.Mobile_No2));
                data_item.Add(st.create_array("remark", servent.Remark));
                data_item.Add(st.create_array("cloth_wash", servent.Cloth_Wash));
                data_item.Add(st.create_array("cloth_wash_charge",servent.Cloth_Wash_Charge));
                data_item.Add(st.create_array("b_wash", servent.B_Wash));
                data_item.Add(st.create_array("b_wash_charge", servent.B_Wash_Charge));
                data_item.Add(st.create_array("f_wash", servent.F_Wash));
                data_item.Add(st.create_array("f_wash_charge", servent.F_Wash_Charge));
                data_item.Add(st.create_array("baby_set",servent.Baby_Set));
                data_item.Add(st.create_array("b_set_charge", servent.B_Set_Charge));
                data_item.Add(st.create_array("meal",servent.Meal));
                data_item.Add(st.create_array("meal_charge", servent.Meal_Charge));

            }
            status1 = st.run_query(data_item, "Select" , "sp_servent_maid_master", ref sdr);
            servent.Sql_Result = status1;
            if (status1 == "Done")
            {
                if (servent.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                                servent.Society_Id = sdr["society_id"].ToString();
                                servent.S_Name = sdr["s_name"].ToString();
                                servent.S_Address_1 = sdr["s_address_1"].ToString();
                                servent.S_Address_2 = sdr["s_address_2"].ToString();
                                servent.Mobile_No1 = sdr["mobile_no1"].ToString();
                                servent.Mobile_No2 = sdr["mobile_no2"].ToString();
                                servent.Remark = sdr["remark"].ToString();
                                servent.Cloth_Wash = Convert.ToInt32(sdr["cloth_wash"].ToString());

                                if (float.TryParse(sdr["cloth_wash_charge"].ToString(), out float clothWashCharge))
                                {
                                    servent.Cloth_Wash_Charge = clothWashCharge;
                                }

                                servent.B_Wash = Convert.ToInt32(sdr["b_wash"].ToString());

                                if (float.TryParse(sdr["b_wash_charge"].ToString(), out float bWashCharge))
                                {
                                    servent.B_Wash_Charge = bWashCharge;
                                }

                                servent.F_Wash = Convert.ToInt32(sdr["f_wash"].ToString());

                                if (float.TryParse(sdr["f_wash_charge"].ToString(), out float fWashCharge))
                                {
                                    servent.F_Wash_Charge = fWashCharge;
                                }

                                servent.Baby_Set = Convert.ToInt32(sdr["baby_set"].ToString());

                                if (float.TryParse(sdr["b_set_charge"].ToString(), out float bSetCharge))
                                {
                                    servent.B_Set_Charge = bSetCharge;
                                }

                                servent.Meal = Convert.ToInt32(sdr["meal"].ToString());

                                if (float.TryParse(sdr["meal_charge"].ToString(), out float mealCharge))
                                {
                                    servent.Meal_Charge = mealCharge;
                                }
                    }
                }

            }
            return servent;
        }

        public object servent_search(Servent_Made servent)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("Operation", servent.Sql_Operation));
            data_item.Add(st.create_array("search", servent.S_Name));
            data_item.Add(st.create_array("society_id", servent.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_servent_maid_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

       
        public Servent_Made serventdelete(Servent_Made servent)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", servent.Sql_Operation));
            data_item.Add(st.create_array("servent_id", servent.servent_id));

            status = st.run_query(data_item, "Delete", "sp_servent_maid_master", ref sdr);
            if (status == "Done")
            {
                servent.Sql_Result = status;
            }
            return servent;
        }

        public Servent_Made Mobile_No_TextChanged(Servent_Made servent)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", servent.Sql_Operation));
            data_item.Add(st.create_array("servent_id", servent.servent_id));
            data_item.Add(st.create_array("mobile_no1", servent.Mobile_No1));
           
            status = st.run_query(data_item, "Select", "sp_servent_maid_master", ref sdr);

            if (status == "Done")
                if (sdr.Read())
                    servent.Sql_Result = "Already exist";
                else
                    servent.Sql_Result = "";
            return servent;


        }


    }
}
