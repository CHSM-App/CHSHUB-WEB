using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Maintenance_Master
    {
       
        DA_Maintenence_Master dA_Maintenence = new DA_Maintenence_Master();

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Maintenence.fill_drop(drp_down, sqlstring, text, value);
        }

        public void fill_drop_1(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Maintenence.fill_drop_1(drp_down, sqlstring, text, value);
        }
        public DataTable getMaintenanceDetails(maintenance Maintenance1)
        {
          
            return dA_Maintenence.get_maintenance_details(Maintenance1);
           
        }
        public maintenance updateMaintenanceDetails(maintenance Maintenance1)
        {
            return dA_Maintenence.Update_Maintenance_Details(Maintenance1);
        }

        public DataTable Add_Click(maintenance Maintenance1)
        {
            return dA_Maintenence.btn_add_click(Maintenance1);
        }

        public DataTable get_monthwise_charges(maintenance_cal maintenance1)
        {
            return dA_Maintenence.Get_Monthwise_Charges(maintenance1);
        }

        public maintenance getflat(maintenance Maintenance1)
        {
            return dA_Maintenence.getflats(Maintenance1);
        }

        public DataTable get_maintanance(maintenance Maintanance)
        {
            return dA_Maintenence.Print_maintanance(Maintanance);
        }

        public maintenance check_already(maintenance Maintenance1)
        {
            return dA_Maintenence.Check_Already(Maintenance1);
        }
        public maintenance delete(maintenance Maintenance1)
        {
            return dA_Maintenence.Maintenance_Delete(Maintenance1);
        }
        public maintenance select_maintenance_details(maintenance Maintenance1)
        {
            return dA_Maintenence.Select_Maintenance_Details(Maintenance1);
        }

        public DataTable Get_Maintanance_Report(maintenance getMaintenance)
        {
            return dA_Maintenence.get_maintenance_report(getMaintenance);
        }

        public maintenance check_date(maintenance Maintenance1)
        {
            return dA_Maintenence.Check_Date(Maintenance1);
        }
        public maintenance bill_exist(maintenance Maintenance1)
        {
            return dA_Maintenence.Bill_Exist(Maintenance1);
        }

        public maintenance_cal update_monthwise_charges_details(maintenance_cal Maintenance1)
        {
            return dA_Maintenence.Update_monthwise_charges(Maintenance1);
        }

        public DataTable genrate_bill(maintenance Maintenance1)
        {
            return dA_Maintenence.Genrate_Bill(Maintenance1);
        }

        public DataTable Get_Ownerwise_Maintenance(maintenance getMaintenance)
        {
            return dA_Maintenence.ownerwise_maintenance(getMaintenance);
        }

        public DataTable list_Fill(maintenance Maintenance1)
        {
            return dA_Maintenence.List_Fill(Maintenance1);
        }

        public object search_maintenance1(maintenance maintenance1)
        {
            return dA_Maintenence.search_maintenance(maintenance1);
        }

        public maintenance_cal Monthwise_Charges_delete(maintenance_cal maintenance1)
        {
            return dA_Maintenence.Delete_Monthwise_Charges(maintenance1);
        }

        public maintenance_cal due_remaining(maintenance_cal maintenance1)
        {
            return dA_Maintenence.Remaining_Due(maintenance1);
        }

        public void updateSettings(maintenance maintenance1)
        {
            dA_Maintenence.updateSettings(maintenance1);
        }

        public DataTable executeMaintanence(maintenance maintenance1)
        {
            return dA_Maintenence.executeMaintanence(maintenance1);
        }

        public maintenance select_settings(maintenance maintenance1)
        {
            return dA_Maintenence.selectSettings(maintenance1);
        }

        public void add_Charges(maintenance maintenance)
        {
            dA_Maintenence.add_charges(maintenance);
        }

        public DataTable getCharges(maintenance maintenance)
        {
            return dA_Maintenence.getCharges(maintenance);
        }

        public maintenance select_charges_details(maintenance maintenance)
        {
            return dA_Maintenence.selectCharges(maintenance);
        }

        public DataTable getTokens(int id, string society_id)
        {
            return dA_Maintenence.getToken(id, society_id);
        }
    }
}