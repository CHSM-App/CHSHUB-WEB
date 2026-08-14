using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Doc_Master
    {
      
        public DataTable getDocDetails(Doc doc)
        {
            DA_Doc_Master dA_Doc = new DA_Doc_Master();
            return dA_Doc.getDocDetails(doc);
           
        }
        public Doc updatedocdetails(Doc doc)
        {
            DA_Doc_Master dA_Doc = new DA_Doc_Master();
            return dA_Doc.updateDocDetails(doc);
        }
        public Doc delete(Doc doc)
        {
            DA_Doc_Master dA_Doc = new DA_Doc_Master();
            return dA_Doc.delete_Doc(doc);
        }
        public Doc docnametextchanged(Doc doc)
        {
            DA_Doc_Master dA_Doc = new DA_Doc_Master();
            return dA_Doc.Doc_Name_Textchanged(doc);
        }

        public object search_doc(Doc doc)
        {
            DA_Doc_Master dA_Doc = new DA_Doc_Master();
            return dA_Doc.doc_search(doc);
        }
    }
}