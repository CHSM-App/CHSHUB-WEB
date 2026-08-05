using DataAccessLayer.MasterDA;
using DBCode.DataClass.Master_Dataclass;
using System;
using System.Collections.Generic;
using System.Data;
using System.EnterpriseServices;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Visitor_Master
    {

        DA_Visitor_Master dA_Visitor = new DA_Visitor_Master();
        public DataTable getVisitorDetails(Visitor visitor)
        {
            
            DataTable visitor_data = dA_Visitor.getVisitorDetails(visitor);
            return visitor_data;

        }
        public Visitor updateVisitorDetails(Visitor visitor)
        {
            
            return dA_Visitor.UpdateVisitorDetails(visitor);

        }
        public Visitor deletevisitor(Visitor visitor)
        {
            
            return dA_Visitor.delete_visitor(visitor);

        }
         

        public DataTable Fill_list(string operation, string build_id, string society_id)
        {
            return dA_Visitor.Fill_list(operation, build_id, society_id);
        }

        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Visitor.fill_drop(drp_down, sqlstring, text, value);
        }

        public object search_visitor(Visitor visitor)
        {
            
            return dA_Visitor.search_visitor(visitor);
        }

        public DataTable get_printvisitor(Visitor visitor)
        {
            
            return dA_Visitor.Get_PrintVisitor(visitor);
        }
    }
}