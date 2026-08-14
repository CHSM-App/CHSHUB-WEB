using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace DataAccessLayer.MasterDA
{
    public class DA_Owner_Master
    {
        stored st = new stored();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            st.fill_drop(drp_down, sqlstring, text, value);
        }

        public void fill_list(Repeater list_box, string sqlstring)
        {
            st.fill_list(list_box, sqlstring);
        }
        public DataTable getOwnerDetails(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
             DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation",owner.Sql_Operation));
            data_item.Add(st.create_array("society_id", owner.Society_Id));
            data_item.Add(st.create_array("type", owner.Type));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }


        public DataTable getFamilyDetails(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done") 
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Fill_list(string society_id, string operation, string building, string type)
        
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>(); 
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("society_id", society_id));
            data_item.Add(st.create_array("operation", operation));
            data_item.Add(st.create_array("build_id", building));
            data_item.Add(st.create_array("type_id", type));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

      

        public Owner updateOwnerDetails(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            int sdr = 0;
            string status1;
            //string type = "Owner";
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            if (owner.Sql_Operation == "Update")
            {

                data_item.Add(st.create_array("society_id", owner.Society_Id));
                data_item.Add(st.create_array("wing_id", owner.wing_id));
                //if (owner.Poss_Date != DateTime.MinValue)
                //    data_item.Add(st.create_array("poss_date", owner.Poss_Date));
                    data_item.Add(st.create_array("name", owner.Name));
                data_item.Add(st.create_array("pre_mob", owner.Pre_Mob));
                if(owner.Dob!= DateTime.MinValue)
                    data_item.Add(st.create_array("dob", owner.Dob));
                data_item.Add(st.create_array("married_id", owner.married_id));
                data_item.Add(st.create_array("occup", owner.Occup));
                data_item.Add(st.create_array("monthly_income", owner.Monthly_Income));
                data_item.Add(st.create_array("off_tel", owner.Off_Tel));
                data_item.Add(st.create_array("off_addr1", owner.Off_Addr1));
                data_item.Add(st.create_array("email", owner.Email));
                data_item.Add(st.create_array("alter_mob", owner.Alter_Mob));
                data_item.Add(st.create_array("flat_id", owner.flat_id));
                data_item.Add(st.create_array("flat_type_id", owner.Flat_type_Id));
                //data_item.Add(st.create_array("photo_name", owner.Photo_Name));
                data_item.Add(st.create_array("id_proof", owner.Id_Proof)); 
                data_item.Add(st.create_array("type", owner.Type));
                data_item.Add(st.create_array("doc_id", owner.Doc_Id));
            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_owner_master", ref sdr);
            owner.Sql_Result = status1;
            if (status1 == "Done")
                if(sdr!=0)
                owner.owner_id = sdr;
            return owner;

        }

        public DataTable Fill_list(Owner owner)
        {
            throw new NotImplementedException();
        }

        public DataTable Get_Printunitwise_Maintenance(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            DataTable dt = new DataTable();

            data_item.Add(st.create_array("query", owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Owner GetFlat(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
           
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("society_id", owner.Society_Id));
            data_item.Add(st.create_array("wing_id", owner.wing_id));
            data_item.Add(st.create_array("flat_type_id", owner.Flat_type_Id));
            data_item.Add(st.create_array("flat", owner.Flat_No));


            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    owner.flat_id = Convert.ToInt32(sdr["flat_id"].ToString());
                else
                    owner.flat_id = 0;

            return owner;
        }

        public DataTable Get_PrintOwner(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable Get_PrintRental(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            DataTable dt = new DataTable();
            data_item.Add(st.create_array("query", owner.Sql_Operation));

            status1 = st.run_query(data_item, "Select", "sp_search", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public DataTable search_rental(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            DataTable dt = new DataTable();

            data_item.Add(st.create_array("Operation", owner.Sql_Operation));
            data_item.Add(st.create_array("search", owner.Name));
            data_item.Add(st.create_array("society_id", owner.Society_Id));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

       
        public Owner runproc(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            //data_item.Add(st.create_array("o_ex_id", owner.O_Ex_Id));

            status1 = st.run_query(data_item, owner.Sql_Operation, "sp_owner_master", ref sdr);
            if (status1 == "Done")
            {
                if (owner.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {

                        owner.Society_Id = sdr["society_id"].ToString();
                        owner.Poss_Date = Convert.ToDateTime(sdr["poss_date"]);
                        owner.Name = sdr["name"].ToString();
                        owner.Pre_Mob = sdr["pre_mob"].ToString();
                        owner.Alter_Mob = sdr["alter_mob"].ToString();
                        owner.Dob = sdr["dob"] == DBNull.Value? (DateTime?)null: Convert.ToDateTime(sdr["dob"]);
                        owner.married_id = Convert.ToInt32(sdr["married_id"].ToString());
                        owner.Flat_No = sdr["_flat"].ToString();
                        owner.Occup = sdr["job_title"].ToString();
                        owner.Off_Addr1 = sdr["off_addr1"].ToString();
                        owner.Off_Tel = sdr["off_tel"].ToString();
                        owner.Email = sdr["email"].ToString();
                        owner.Monthly_Income = sdr["monthly_income"].ToString();
                        owner.Flat_type_Id = Convert.ToInt32(sdr["flat_type_id"].ToString());
                        owner.flat_id = Convert.ToInt32(sdr["flat_id"].ToString());
                        owner.wing_id = Convert.ToInt32(sdr["wing_id"].ToString());
                        owner.Photo_Name = sdr["photo_name"].ToString();
                        owner.Id_Proof = sdr["id_proof"].ToString();
                        owner.Type = sdr["type"].ToString();
                        owner.Doc_Id = Convert.ToInt32(sdr["doc_id"].ToString());

                        if (owner.Type == "Rent")
                        {
                            if (owner.Aggrement_Date != DateTime.MinValue)
                                owner.Aggrement_Date = Convert.ToDateTime(sdr["aggrement_date"]);
                            if (owner.Aggrement_Period_From != DateTime.MinValue)
                                owner.Aggrement_Period_From = Convert.ToDateTime(sdr["aggrement_period_from"]);
                            if (owner.Aggrement_Period_To != DateTime.MinValue)
                                owner.Aggrement_Period_To = Convert.ToDateTime(sdr["aggrement_period_to"]);
                            if (owner.Police_Verification_Date != DateTime.MinValue)
                                owner.Police_Verification_Date = Convert.ToDateTime(sdr["police_verification_date"]);
                        }

                    }

                }
            }
            return owner;
        }


        public Owner runproc_family(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            

            status1 = st.run_query(data_item, owner.Sql_Operation, "sp_owner_master", ref sdr);
            if (status1 == "Done")
            {
                if (owner.Sql_Operation == "Select_Family")
                {
                    while (sdr.Read())
                    {


                        owner.F_Name = sdr["f_name"].ToString();
                        owner.Relation = sdr["relation"].ToString();
                        owner.F_Occu = sdr["f_occu"].ToString();
                        owner.F_Dob = sdr["f_dob"].ToString();

                    }

                }
            }
            return owner;
        }




        public DataTable getRentalDetails(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("society_id", owner.Society_Id));
            data_item.Add(st.create_array("type", owner.Type));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }


        public Owner updateRentalDetails(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            //SqlDataReader sdr = null;
            int sdr = 0;
            string status1 ;

            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            if (owner.Sql_Operation == "Update")
            {

                data_item.Add(st.create_array("society_id", owner.Society_Id));
                data_item.Add(st.create_array("wing_id", owner.wing_id));
                //data_item.Add(st.create_array("poss_date", owner.Poss_Date));
                data_item.Add(st.create_array("name", owner.Name));
                data_item.Add(st.create_array("pre_mob", owner.Pre_Mob));
                data_item.Add(st.create_array("dob", owner.Dob));
                data_item.Add(st.create_array("married_id", owner.married_id));
                data_item.Add(st.create_array("occup", owner.Occup));
                data_item.Add(st.create_array("monthly_income", owner.Monthly_Income));
                data_item.Add(st.create_array("off_addr1", owner.Off_Addr1));
                data_item.Add(st.create_array("off_tel", owner.Off_Tel));
                data_item.Add(st.create_array("email", owner.Email));
                data_item.Add(st.create_array("alter_mob", owner.Alter_Mob));
                data_item.Add(st.create_array("flat_id", owner.flat_id));
                data_item.Add(st.create_array("flat_type_id", owner.Flat_type_Id));
                data_item.Add(st.create_array("type", owner.Type));
                data_item.Add(st.create_array("aggrement_date", owner.Aggrement_Date));
                data_item.Add(st.create_array("aggrement_period_from", owner.Aggrement_Period_From));
                data_item.Add(st.create_array("aggrement_period_to", owner.Aggrement_Period_To));
                data_item.Add(st.create_array("police_verification_date", owner.Police_Verification_Date));

                data_item.Add(st.create_array("id_proof", owner.Id_Proof));
                data_item.Add(st.create_array("agreement_path", owner.Aggreement_path));
                data_item.Add(st.create_array("police_verification_path", owner.Police_ver_path));



            }
            status1 = st.run_query_scalar(data_item, "Select", "sp_owner_master", ref sdr);
            owner.Sql_Result = status1;
            if (status1 == "Done")
                if(sdr!=0)
                owner.owner_id = sdr;
            return owner;

        }

        public DataTable getFamily1Details(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            data_item.Add(st.create_array("type", "Rental"));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public Owner updateFamilyOwnerDetails(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
           
            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            data_item.Add(st.create_array("o_ex_id", owner.O_Ex_Id));

            if (owner.Sql_Operation == "D_Update")
            {
                data_item.Add(st.create_array("society_id", owner.Society_Id));
                data_item.Add(st.create_array("f_name", owner.F_Name));
                data_item.Add(st.create_array("relation", owner.Relation));
                data_item.Add(st.create_array("f_occu", owner.F_Occu));
                data_item.Add(st.create_array("f_dob", owner.F_Dob));


            }
            string status1= st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
            {
                owner.Sql_Result = status1;
            }
            return owner;
        }

        public Owner owner_delete(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
            {
                owner.Sql_Result = status1;
            }
            return owner;
        }
        public Owner family_delete(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 ;

            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("o_ex_id", owner.O_Ex_Id));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
            {
                owner.Sql_Result = status1;
            }
            return owner;
        }

        public Owner flattextchanged(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1;

            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            data_item.Add(st.create_array("wing_id", owner.wing_id));
            data_item.Add(st.create_array("flat_id", owner.flat_id));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    owner.Sql_Result = "Already exist";
                else
                    owner.Sql_Result = "";
            return owner;
        }
        public Owner typetextchanged(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1 ;

            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("owner_id", owner.owner_id));
            data_item.Add(st.create_array("flat_id", owner.flat_id));
            data_item.Add(st.create_array("wing_id", owner.wing_id));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    owner.Sql_Result = "Already exist";
                else
                    owner.Sql_Result = "";
            return owner;

        }

        public Owner mobiletextchanged(Owner owner)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;

            string status1;

            data_item.Add(st.create_array("operation", owner.Sql_Operation));
            data_item.Add(st.create_array("pre_mob", owner.Pre_Mob));
            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.Read())
                    owner.Sql_Result = "Already exist";
                else
                    owner.Sql_Result = "";
            return owner;

        }

        public DataTable get_Messages(Messages message)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation",message.Operation));
            data_item.Add(st.create_array("society_id", message.SocietyID));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

            if (status1 == "Done")
                if (sdr.HasRows)
                    dt.Load(sdr);
            return dt;
        }

        public void update_view_status(Messages message)
        {

            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1;
            DataTable dt = new DataTable();
            data_item.Add(st.create_array("operation", message.Operation));
            data_item.Add(st.create_array("r_id", message.OwnerID));

            status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

        }

        //public Owner telnotextchanged(Owner owner)
        //{
        //    ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
        //    SqlDataReader sdr = null;

        //    string status1 = "";

        //    data_item.Add(st.create_array("operation", owner.Sql_Operation));
        //    data_item.Add(st.create_array("owner_id", owner.owner_id));
        //    data_item.Add(st.create_array("off_tel", owner.Off_Tel));
        //    status1 = st.run_query(data_item, "Select", "sp_owner_master", ref sdr);

        //    if (status1 == "Done")
        //        if (sdr.Read())
        //            owner.Sql_Result = "Already exist";
        //        else
        //            owner.Sql_Result = "";
        //    return owner;

        //}



    }
}