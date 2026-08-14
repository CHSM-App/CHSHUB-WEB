using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using DBCode.DataClass.Master_Dataclass;
using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Owner_Master
    {

        DA_Owner_Master DA_Owner = new DA_Owner_Master();
        public DataTable getOwnerDetails(Owner owner)
        {
            return DA_Owner.getOwnerDetails(owner);
        }
           
        public DataTable getFamilyDetails(Owner owner)
        {
            
            return DA_Owner.getFamilyDetails(owner);
            
        }
        public Owner updateOwnerDetails(Owner owner)
        {
            
            return DA_Owner.updateOwnerDetails(owner);
        }

        public Owner updateFamilyOwnerDetails(Owner owner)
        {
            
            return DA_Owner.updateFamilyOwnerDetails(owner);
           
        }

        public Owner runproc(Owner owner)
        {
           
            return DA_Owner.runproc(owner);
        }

        public Owner runproc_family(Owner owner)
        {
           
            return DA_Owner.runproc_family(owner);
        }
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            DA_Owner.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable Fill_list(string society_id, string operation, string building, string type)
        {
            return DA_Owner.Fill_list(society_id, operation, building, type);
        }


        //public void fill_list(Repeater drp_down, string sqlstring)
        //{
        //    DA_Owner.fill_list(drp_down, sqlstring);
        //}

        public Owner OwnerDelete(Owner owner)
        {
            
            return DA_Owner.owner_delete(owner);

        }
        public Owner FamilyDelete(Owner owner)
        {
          
            return DA_Owner.family_delete(owner);

        }

        public Owner FlatTextChanged(Owner owner)
        {
           
            return DA_Owner.flattextchanged(owner);
        }
        public Owner TypeTextChanged(Owner owner)
        {

            return DA_Owner.typetextchanged(owner);
        }

        //public Owner TelNoTextchanged(Owner owner)
        //{
        //    DA_Owner_Master dA_Owner = new DA_Owner_Master();
        //    return dA_Owner.telnotextchanged(owner);
        //}
        public Owner MobileTextchanged(Owner owner)
        {
           
            return DA_Owner.mobiletextchanged(owner);
        }
       
        //rental_search 
        public DataTable getRentalDetails(Owner owner)
        {

            return DA_Owner.getRentalDetails(owner);

        }



        //public DataTable Fill_list(Owner owner)
        //{
        //    return DA_Owner.Fill_list(owner);
        //}

        public DataTable get_printowner(Owner owner)
        {
            return DA_Owner.Get_PrintOwner(owner);
        }

        public DataTable get_printunitwise_maintenance(Owner owner)
        {
            return DA_Owner.Get_Printunitwise_Maintenance(owner);
        }

        public DataTable get_printrental(Owner owner)
        {
            return DA_Owner.Get_PrintRental(owner);
        }

        public Owner UpdateRentalDetails(Owner owner)
        {

            return DA_Owner.updateRentalDetails(owner);

        }
        
        public DataTable search_rental(Owner owner)
        {
            return DA_Owner.search_rental(owner);
        }

        public Owner getFlat(Owner owner)
        {
            return DA_Owner.GetFlat(owner);
        }

        public DataTable get_Messages(Messages message)
        {
            return DA_Owner.get_Messages(message);
        }

        public void update_view_status(Messages message)
        {
            DA_Owner.update_view_status(message);
        }

        //house_tax

    }
}