using Society;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class DA_New_Registration
    {
        stored st = new stored();
        public Login_Details update_registration(Login_Details details)
        {
            if (UserLoginId.Value != "")
                Details.UserLoginId = Convert.ToInt32(UserLoginId.Value.ToString());
            Details.Sql_Operation = operation;
            Details.UserLoginId = Convert.ToInt32(UserLoginId.Value);
            Details.Name = txt_Name.Text;
            Details.UserName = txt_user.Text;
            Details.Password = txt_new_pass.Text;
            Details.Address = txt_Address.Text;
            Details.Mobile = txt_Mobile.Text;
            Details.Emailid = txt_Emailid.Text;




            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", details.Sql_Operation));
            data_item.Add(st.create_array("UserLoginId", details.UserLoginId));
            if (details.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("Name", details.Name));
                data_item.Add(st.create_array("UserName", details.UserName));
                data_item.Add(st.create_array("Password", details.Password));
                data_item.Add(st.create_array("Address", details.Address));
                data_item.Add(st.create_array("Mobile", details.Mobile));
                data_item.Add(st.create_array("Emailid", details.Emailid));
               
            }
            status1 = st.run_query(data_item, "Select", "sp_party", ref sdr);

            if (status1 == "Done")
            {
                if (party.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        //  f_id.Value = sdr["f_id"].ToString();
                        party.Society_Id = sdr["society_id"].ToString();
                        party.Book_Date = Convert.ToDateTime(sdr["book_date"].ToString());
                        party.From_Date = Convert.ToDateTime(sdr["from_date"].ToString());
                        party.To_Date = Convert.ToDateTime(sdr["to_date"].ToString());
                        party.Name = sdr["name"].ToString();
                        party.Flat_No = Convert.ToInt32(sdr["flat_no"].ToString());
                        party.Address = sdr["address"].ToString();
                        party.Contact = sdr["contact"].ToString();
                        party.From_Time = Convert.ToDateTime(sdr["from_time"].ToString());
                        party.To_Time = Convert.ToDateTime(sdr["to_time"].ToString());
                        party.Society_In = Convert.ToInt32(sdr["society_in"].ToString());

                    }
                }
                else                {
                    party.Sql_Result = status1;
                }
            }
            return party;
        }
    }
}