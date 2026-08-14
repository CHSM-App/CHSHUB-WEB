using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Society_Member_Master
    {
        DA_Society_Member_Master dA_Society_Member = new DA_Society_Member_Master();
        public DataTable getSocietyMemberDetails(Society_Member member)
        {
           
            DataTable society_member_master = dA_Society_Member.getSocietyMemberDetails(member);
            return society_member_master;
        }


        public Society_Member CheckDuplicateEmail(Society_Member member)
        {
            return dA_Society_Member.CheckDuplicateEmail(member);
        }

        public DataTable add_approver(Society_Member member)
        {

             return dA_Society_Member.Add_Approver(member);
            
        }
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Society_Member.fill_drop(drp_down, sqlstring, text, value);
        }
        public Society_Member updateSocietyMemberDetails(Society_Member member)
        {
           
             return dA_Society_Member.updateSocietyMemberDetails(member);
         
        }

        public Society_Member UpdateProfile(Society_Member member)
        {

            return dA_Society_Member.UpdateProfile(member);

        }


        public DataTable fill_list(string operation, string society)
        {
            return dA_Society_Member.fill_list(operation, society);
        }

       
        public Society_Member delete(Society_Member member)
        {
           
            return dA_Society_Member.delete(member);


        }

        public Society_Member SocietyMemberTextChange(Society_Member member)
        {
            
            return dA_Society_Member.SocietyMemberTextChange(member);
        }

        public object search_member(Society_Member member)
        {
           
            return dA_Society_Member.search_member(member);
        }

        public Society_Member getPass(int user_id, String operation)
        {
            return dA_Society_Member.getPassword(user_id,operation);
        }

        public DataTable get_items(Society_Member member)
        {
            return dA_Society_Member.get_items(member);
        }
    }
}