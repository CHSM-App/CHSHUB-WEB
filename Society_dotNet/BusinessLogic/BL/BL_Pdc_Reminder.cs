using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace BusinessLogic.BL
{
    public class BL_Pdc_Reminder
    {
        DA_Pdc_Reminder Pdc_Reminder = new DA_Pdc_Reminder();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            Pdc_Reminder.fill_drop(drp_down, sqlstring, text, value);
        }
        public DataTable getPdcReminder(pdc_reminder Reminder)
        {

            return Pdc_Reminder.getpdcreminder(Reminder);
            
        }
        public pdc_reminder chqno_textchanged(pdc_reminder reminder)
        {
            return Pdc_Reminder.Chqno_Textchanged(reminder);
        }
        public DataTable ownergrid(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Owner_Grid(Reminder);

        }
        public pdc_reminder updatePdcReminder(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Update_Pdc_Reminder(Reminder);

        }
        public DataTable updatePdcClearing(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Update_Pdc_Clearing(Reminder);

        }

        public DataTable fill_list(string operation, string society_id)
        {
            return Pdc_Reminder.fill_list(operation, society_id);
        }

        public pdc_reminder delete(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Delete_Pdc_Reminder(Reminder);

        }
        public pdc_reminder owner_selectedindexchanged(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Owner_SelectdIndexChanged(Reminder);

        }
        public pdc_reminder save_changes(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Save_Change(Reminder);

        }

        public pdc_reminder save_change(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Save_Changes(Reminder);

        }
        public pdc_reminder next_click(pdc_reminder Reminder)
        {

            return Pdc_Reminder.Next_Click(Reminder);

        }

        public DataTable search_reminder(pdc_reminder reminder)
        {
            return Pdc_Reminder.reminder_search(reminder);

        }
    }
}