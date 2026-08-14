using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;

namespace Utility.DataClass
{
    public class Login_Details
    {
        private double amount;
        private string paymode;
        private int userloginid;
        private int depid;
        private int usertypeid;
        private int notice_id;
        private int s_id;
        private int eventid;
        private string name;
        private string shortname;
        private string username;
        private string password;
        private string address;
        private string mobile;
        private int status;
        private string telno;
        private string emailid;
        private DateTime joindt;
        private DateTime lastdt;
        private int branchid;
        private int compid;
        private int areaid;
        private int designation;
        private int manager;
        private DateTime otpdate;
        private string otpno;
        private string societyid;
        private string societyName;
        private DateTime establish_date;
        private string registration_no;
        private string off_address1;
        private string off_address2;
        private string contact_no1;
        private string email;
        private string city;
        private string web_token;
        private int state_id;
        private int open;
        private string village_id;
        private string UserTypeName;
        private string type;
        private int id;
        private int expense_type;
      

        private int resolve;
        private string pincode;
        private int due_bal;
        private int homeno;
        private string division;
        private int district;
        private string Operation;
        private string Result;

        private string fromDate;
        private string toDate;
        private string Recent_type;
        private string min_Price;
        private string max_Price;
        private string search;
        private string Society_id;

        private string _terms_conditions;
        private string _office_address1;
        private string _office_address2;
        private string _contact_no;
        private string _state_name;
        private string _district_name;
        private int _division_id;
        private string _division_name;
        private string _street_home_no;
        private decimal _per_sqft_rate;
        private decimal _two_wheeler_rate;
        private decimal _four_wheeler_rate;
        private int _generation_day;
        private int _due_period_days;
        private bool _auto_generation;
        private DateTime _created_date;
        private DateTime _modified_date;
        private bool _is_active;



        public DateTime Created_Date
        {
            get { return _created_date; }
            set { _created_date = value; }
        }

        // Modified Date
        public DateTime Modified_Date
        {
            get { return _modified_date; }
            set { _modified_date = value; }
        }

        // Is Active Flag
        public bool Is_Active
        {
            get { return _is_active; }
            set { _is_active = value; }
        }

        // Generation Day (1-31)
        public int Generation_Day
        {
            get { return _generation_day; }
            set
            {
                if (value >= 1 && value <= 31)
                    _generation_day = value;
                else
                    _generation_day = 1;
            }
        }

        // Due Period Days
        public int Due_Period_Days
        {
            get { return _due_period_days; }
            set { _due_period_days = value > 0 ? value : 15; }
        }

        // Auto Generation Flag
        public bool Auto_Generation
        {
            get { return _auto_generation; }
            set { _auto_generation = value; }
        }

        // Two Wheeler Rate
        public decimal Two_Wheeler_Rate
        {
            get { return _two_wheeler_rate; }
            set { _two_wheeler_rate = value >= 0 ? value : 0; }
        }

        // Four Wheeler Rate
        public decimal Four_Wheeler_Rate
        {
            get { return _four_wheeler_rate; }
            set { _four_wheeler_rate = value >= 0 ? value : 0; }
        }

        public decimal Per_Sqft_Rate
        {
            get { return _per_sqft_rate; }
            set { _per_sqft_rate = value >= 0 ? value : 0; }
        }
        public string Street_Home_No
        {
            get { return _street_home_no; }
            set { _street_home_no = value?.Trim() ?? string.Empty; }
        }


        public int Division_Id
        {
            get { return _division_id; }
            set { _division_id = value > 0 ? value : 0; }
        }

        // Division Name
        public string Division_Name
        {
            get { return _division_name; }
            set { _division_name = value?.Trim() ?? string.Empty; }
        }

        // District Name
        public string District_Name
        {
            get { return _district_name; }
            set { _district_name = value?.Trim() ?? string.Empty; }
        }
        public string State_Name
        {
            get { return _state_name; }
            set { _state_name = value?.Trim(); }
        }

        public string Contact_No
        {
            get { return _contact_no; }
            set
            {
                _contact_no = value;
            }
        }
        public string Terms_Conditions
        {
            get { return _terms_conditions; }
            set { _terms_conditions = value; }
        }

        // Office Address 1
        public string Office_Address1
        {
            get { return _office_address1; }
            set { _office_address1 = value; }
        }

        // Office Address 2
        public string Office_Address2
        {
            get { return _office_address2; }
            set { _office_address2 = value?.Trim() ?? string.Empty; }
        }

        public double Amount
        {
            get { return amount; }
            set { amount = value; }
        }
        public string Paymode
        {
            get { return paymode; }
            set { paymode = value; }
        }
        public string User_Type_Name
        {
            get { return UserTypeName; }
            set { UserTypeName = value; }
        }
        public int UserLoginId
        {
            get { return userloginid; }
            set { userloginid = value; }
        }
        public int DepId
        {
            get { return depid; }
            set { depid = value; }
        }
        public int UserTypeId
        {
            get { return usertypeid; }
            set { usertypeid = value; }
        }
        public int NoticeId
        {
            get { return notice_id; }
            set { notice_id = value; }
        }
        public int event_id
        {
            get { return eventid; }
            set { eventid = value; }
        }
        public int Open
        {
            get { return open; }
            set { open = value; }
        }
        public int Resolve
        {
            get { return resolve; }
            set { resolve = value; }
        }
        public string Type
        {
            get { return type; }
            set { type = value; }
        }
        public int Id
        {
            get { return id; }
            set { id = value; }
        }
        public string Village_Id
        {
            get { return village_id; }
            set { village_id = value; }
        }
        public int society_master_id
        {
            get { return s_id; }
            set { s_id = value; }
        }
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        public string Short_Name
        {
            get { return shortname; }
            set { shortname = value; }
        }
        public string UserName
        {
            get { return username; }
            set { username = value; }
        }
        public string Password
        {
            get { return password; }
            set { password = value; }
        }
        public string Address
        {
            get { return address; }
            set { address = value; }
        }
        public string Mobile
        {
            get { return mobile; }
            set { mobile = value; }
        }
        public int Status
        {
            get { return status; }
            set { status = value; }
        }
        public string TelNo
        {
            get { return telno; }
            set { telno = value; }
        }
        public string Emailid
        {
            get { return emailid; }
            set { emailid = value; }
        }
        public DateTime Join_Dt
        {
            get { return joindt; }
            set { joindt = value; }
        }
        public DateTime Last_Dt
        {
            get { return lastdt; }
            set { lastdt = value; }
        }
        public int Branch_Id
        {
            get { return branchid; }
            set { branchid = value; }
        }
        public int Comp_Id
        {
            get { return compid; }
            set { compid = value; }
        }
        public int Area_Id
        {
            get { return areaid; }
            set { areaid = value; }
        }
        public int Designation
        {
            get { return designation; }
            set { designation = value; }
        }
        public int Manager
        {
            get { return manager; }
            set { manager = value; }
        }
        public DateTime Otp_Date
        {
            get { return otpdate; }
            set { otpdate = value; }
        }
        public string Otp_No
        {
            get { return otpno; }
            set { otpno = value; }
        }
        public string Society_Id
        {
            get { return societyid; }
            set { societyid = value; }
        }
        public string Society_Name
        {
            get { return societyName; }
            set { societyName = value; }
        }

        public DateTime Establish_Date
        {
            get { return establish_date; }
            set { establish_date = value; }
        }
        public string Registration_No
        {
            get { return registration_no; }
            set { registration_no = value; }
        }
        public string Off_Address1
        {
            get { return off_address1; }
            set { off_address1 = value; }
        }
        public string Off_Address2
        {
            get { return off_address2; }
            set { off_address2 = value; }
        }
        public string Contact_No1
        {
            get { return contact_no1; }
            set { contact_no1 = value; }
        }
        public string Email
        {
            get { return email; }
            set { email = value; }
        }
        public string City
        {
            get { return city; }
            set { city = value; }
        }
        public int State_Id
        {
            get { return state_id; }
            set { state_id = value; }
        }
        public string Pincode
        {
            get { return pincode; }
            set { pincode = value; }
        }

        public int Due_Bal
        {
            get { return due_bal; }
            set { due_bal = value; }
        }
        public int Home_No
        {
            get { return homeno; }
            set { homeno = value; }
        }
        public string Division
        {
            get { return division; }
            set { division = value; }
        }
        public int District_Id
        {
            get { return district; }
            set { district = value; }
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
        public string Web_Token
        {
            get { return web_token; }
            set { web_token = value; }
        }

        public int ExpenseType
        {
            get { return expense_type; }
            set { expense_type = value; }
        }

        public string From_date
        {
            get { return fromDate; }
            set { fromDate = value; }
        }

        public string To_date
        {
            get { return toDate; }
            set { toDate = value; }
        }

        public string Recent_Type
        {
            get { return Recent_type; }
            set { Recent_type = value; }
        }
        public string Min_Price
        {
            get { return min_Price; }
            set { min_Price = value; }
        }
        public string Max_Price
        {
            get { return max_Price; }
            set { max_Price = value; }
        }


        public string Search
        {
            get { return search; }
            set { search = value; }
        }
        public string society_id
        {
            get { return Society_id; }
            set { Society_id = value; }
        }

        

    }
}