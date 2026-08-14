using DataAccessLayer.DA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Net.Sockets;
using System.Web;
using System.Web.Services.Description;
using System.Web.UI.WebControls; 
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class BL_Upload_Doc
    {
        DA_Upload_Doc dA_Upload = new DA_Upload_Doc();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Upload.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable GetUploadDoc(upload_doc doc)
        {
            return dA_Upload.get_upload_doc(doc);
        }
        public DataTable getdoc(int flat_id)
        {
            return dA_Upload.get_doc(flat_id);
        }

        public DataTable search_upload_doc(upload_doc doc)
        {
            return dA_Upload.upload_doc_serach(doc);
        }

        public upload_doc delete(upload_doc doc)
        {
            return dA_Upload.delete_upload_doc(doc);
        }

        public upload_doc updatedocsearch(upload_doc doc)
        {
            return dA_Upload.doc_master_update(doc);
        }

        public upload_doc doc_master_update(upload_doc doc)
        {
            return dA_Upload.doc_search_update(doc);
        }

        public upload_doc flat_no_selectedIndexChanged(upload_doc doc)
        {
            return dA_Upload.Flat_No_SelectedIndexChanged(doc);
        }


        public DataTable Fill_list(string society, string operation, string build_id, string wing_id)
        {
            return dA_Upload.Fill_list(society, operation, build_id, wing_id);
        }

        public void delete_file(int file_id)
        {
             dA_Upload.delete_File(file_id);
        }
    }
}