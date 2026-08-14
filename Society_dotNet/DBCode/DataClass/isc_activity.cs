using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace DBCode.DataClass
{
    public class isc_activity
    {
        private int activityid;
        private string activityname;
        private string othername;
        private string menutype;
        private string showhide;
        private string navigatelink;
        private int srno;
        private int headid;
        private string iconclass;
        private string submenu;
        private string angelclass;
        private string menucat;
        private string itembackcolor;
        private string chartid;
        private string operation;
        private string colclass;
        private int colcount;
        private int adminright;
        private int userright;
        private int securityright;
        private string Operation;
        private string Result;


        public int Activity_Id
        {
            get { return activityid; }
            set { activityid = value; }
        }
        public string Activity_Name
        {
            get { return activityname; }
            set { activityname = value; }
        }
        public string Other_Name
        {
            get { return othername; }
            set { othername = value; }
        }
        public string Menu_Type
        {
            get { return menutype; }
            set { menutype = value; }
        }
        public string Show_Hide
        {
            get { return showhide; }
            set { showhide = value; }
        }
        public string Navigate_Link
        {
            get { return navigatelink; }
            set { navigatelink = value; }
        }
        public int Sr_No
        {
            get { return srno; }
            set { srno = value; }
        }
        public int Head_Id
        {
            get { return headid; }
            set { headid = value; }
        }
        public string Icon_Class
        {
            get { return iconclass; }
            set { iconclass = value; }
        }
        public string Sub_Menu
        {
            get { return submenu; }
            set { submenu = value; }
        }
        public string Angel_Class
        {
            get { return angelclass; }
            set { angelclass = value; }
        }
        public string Menu_Cat
        {
            get { return menucat; }
            set { menucat = value; }
        }
        public string Item_Back_color
        {
            get { return itembackcolor; }
            set { itembackcolor = value; }
        }
        public string Chart_Id
        {
            get { return chartid; }
            set { chartid = value; }
        }
        //public string Operation
        //{
        //    get { return operation; }
        //    set { operation = value; }
        //}
        public string Col_Class
        {
            get { return colclass; }
            set { colclass = value; }
        }
        public int Col_Count
        {
            get { return colcount; }
            set { colcount = value; }
        }
        public int Admin_Right
        {
            get { return adminright; }
            set { adminright = value; }
        }
        public int User_Right
        {
            get { return userright; }
            set { userright = value; }
        }
        public int Security_Right
        {
            get { return securityright; }
            set { securityright = value; }
        }

        public string Sql_Operation
        {
            get { return Operation; }
            set { Operation = value; }
        }
        public string Sql_Result
        {
            get { return Result; }
            set { Result = value; }
        }
    }
}