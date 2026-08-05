using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.MasterBL
{
    public class BL_Notice_Master
    {
        DA_Notice_Master dA_Notice = new DA_Notice_Master();
        public DataTable getNotice( Notice notice)
        {
           
           return dA_Notice.getNotice(notice);
           
        }

        public DataTable updateNoticeDetails(Notice notice)
        {
          
            return dA_Notice.Notice_Save(notice);

        }
        public Notice getNoticeDetails(Notice notice)
        {

            return dA_Notice.getnoticedetails(notice);

        }
        public Notice delete(Notice notice)
        {
           
            return dA_Notice.Delete_Notice(notice);

        }
        //public Notice numbertextchanged(Notice notice)
        //{
           
        //    return dA_Notice.Number_TextChanged(notice);

        //}

        public DataTable search_notice(Notice notice)
        {
            return dA_Notice.notice_search(notice);
        }

        public DataTable list_Fill(Notice notice)
        {
            return dA_Notice.List_Fill(notice);
        }

        public void fill_drop(DropDownList drp_down, string sqlstring , string text, string value)
        {
            dA_Notice.fill_drop(drp_down, sqlstring, text, value);
        }

        public Notice send_notification(Notice notice)
        {
            return dA_Notice.Send_Notification(notice);
        }
    }
}