
using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_Staff
    {
        DA_Staff dA_Staff = new DA_Staff();
        public void fill_drop(DropDownList drp_down, string sql, string text, string value)
        {
            dA_Staff.fill_drop(drp_down, sql, text, value);
        }

        public staff update_staff(staff Staff)
        {

            return dA_Staff.Update_Staff(Staff);
        }

        public DataTable getstaffdetails(staff Staff)
        {
            return dA_Staff.GetStaff_Details(Staff);
        }
        public DataTable getstaffdata(staff Staff)
        {
            return dA_Staff.GetStaff_Data(Staff);
        }


        public staff delete(staff Staff)
        {
            return dA_Staff.Delete_Staff(Staff);
        }

        public DataTable search_staff(staff Staff)
        {
            return dA_Staff.Staff_Search(Staff);
        }

        public staff contact_textchanged(staff Staff)
        {
            return dA_Staff.Contact_TextChanged(Staff);
        }

        public staff role_update(staff getstaff)
        {
            return dA_Staff.Role_Update(getstaff);
        }

        public DataTable getrole(staff getstaff)
        {
            return dA_Staff.Get_Role(getstaff);
        }

        public staff role_delete(staff getstaff)
        {
            return dA_Staff.Role_Delete(getstaff);
        }

        public staff RoleTextChanged(staff getstaff)
        {
            return dA_Staff.Role_Change(getstaff);
        }

        public bool StaffExist(string staffName, string soceityID, string operation)
        {
            return dA_Staff.StaffExist(staffName, soceityID, operation);

        }

        public DataTable getAttendance(int staff_id, string society_id)
        {
            return dA_Staff.getAtteandance(staff_id, society_id);
        }
    }
}
