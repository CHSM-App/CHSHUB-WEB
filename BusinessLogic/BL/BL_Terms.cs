using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_Terms
    {
        DA_Terms dA_terms = new DA_Terms();
        public terms_condition getupdate_details(terms_condition terms)
        {
            return dA_terms.Get_Update_Details(terms);  
        }

        public terms_condition delete(terms_condition terms)
        {
            return dA_terms.Delete_Term(terms);
        }

        public DataTable getTermsDetails(terms_condition terms)
        {
            return dA_terms.Term_Show(terms);
        }
    }
}