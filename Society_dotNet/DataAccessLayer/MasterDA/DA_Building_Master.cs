using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using Society;
using System.Data.SqlClient;
using DBCode.DataClass;

namespace DataAccessLayer.MasterDA
{
    public class DA_Building_Master
    {
        stored st = new stored();
        public DataTable getBuildingDetails(Building build)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation",build.Sql_Operation));
            data_item.Add(st.create_array("society_id", build.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_building_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;

        }
        public Building updateBuildingDetails(Building building)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", building.Sql_Operation));
            data_item.Add(st.create_array("build_id", building.build_id));
            if (building.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", building.Society_Id));
                data_item.Add(st.create_array("name", building.Name));
                data_item.Add(st.create_array("address1", building.Address1));
                data_item.Add(st.create_array("address2", building.Address2));
                data_item.Add(st.create_array("registration_no", building.Registration_No));
                data_item.Add(st.create_array("no_of_floore", building.No_Of_Floore));
                data_item.Add(st.create_array("print_name", building.Print_Name));
                data_item.Add(st.create_array("bank_name", building.Bank_Name));
                data_item.Add(st.create_array("bank_add", building.Bank_Add));
                data_item.Add(st.create_array("branch", building.Branch));
                data_item.Add(st.create_array("ifsc_code", building.Ifsc_Code));
                data_item.Add(st.create_array("acc_no", building.Acc_No));
                data_item.Add(st.create_array("email", building.Email));

            }
            status1 = st.run_query(data_item, "Select", "sp_building_master", ref sdr);
            //data_item.Clear();

            if (status1 == "Done")
            {
                if (building.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        building.Society_Id = sdr["society_id"].ToString();
                        building.Name = sdr["name"].ToString();
                        building.Address1 = sdr["address1"].ToString();
                        building.Address2 = sdr["address2"].ToString();
                        building.Registration_No = sdr["registration_no"].ToString();
                        building.No_Of_Floore = Convert.ToInt32(sdr["no_of_floore"].ToString());
                        building.Print_Name = sdr["print_name"].ToString();
                        building.Bank_Name = sdr["bank_name"].ToString();
                        building.Bank_Add = sdr["bank_add"].ToString();
                        building.Branch = sdr["branch"].ToString();
                        building.Ifsc_Code = sdr["ifsc_code"].ToString();
                        building.Acc_No = sdr["acc_no"].ToString();
                        building.Email = sdr["email"].ToString();

                    }
                }

                else
                {
                    building.Sql_Result = status1;
                }
               
            }
            else
            {
                building.Sql_Result = status1;
            }
            return building;
        }

        public object search_building(Building building)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("search", building.Name));
            data_item.Add(st.create_array("operation", building.Sql_Operation));
            data_item.Add(st.create_array("society_id", building.Society_Id));


            status1 = st.run_query(data_item, "Select", "sp_building_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Building GridViewDelete1(Building building)
        {

                ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
                SqlDataReader sdr = null;
                string status1 = "";

                data_item.Add(st.create_array("operation", "Delete"));
                data_item.Add(st.create_array("build_id", building.build_id));
                status1 = st.run_query(data_item, "Select", "sp_building_master", ref sdr);

            if (status1 == "Done")
            {
                building.Sql_Result = status1;
            }
            return building;

        }

            public Building BuildingTextChange(Building building)
            {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 = "";

            data_item.Add(st.create_array("operation", building.Sql_Operation));
            data_item.Add(st.create_array("build_id", building.build_id));
            data_item.Add(st.create_array("registration_no", building.Registration_No));
            status1 = st.run_query(data_item, "Select", "sp_building_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    building.Sql_Result = "Already exist";
                else
                    building.Sql_Result = "";
            return building;

        }

        public Building delete_building(Building building)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status = "";
            data_item.Add(st.create_array("operation", building.Sql_Operation));
            data_item.Add(st.create_array("build_id", building.build_id));

            status = st.run_query(data_item, "Delete", "sp_building_master", ref sdr);
            if (status == "Done")
            {
                building.Sql_Result = status;
            }
            return building;
        }


    }

}