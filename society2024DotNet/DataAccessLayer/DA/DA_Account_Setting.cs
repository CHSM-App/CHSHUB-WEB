using Society;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace DataAccessLayer.DA
{
    public class DA_Account_Setting
    {
        stored st = new stored();
        public Account_Setting Get_Code_Details(Account_Setting account)
        {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", account.Sql_Operation));
            data_item.Add(st.create_array("society_id", account.Society_Id));


            status1 = st.run_query(data_item, "Select", "sp_account_setting", ref sdr);

            if (status1 == "Done")

            {
                if (sdr.Read())
                {
                    account.Acc_Set_Id = Convert.ToInt32(sdr["acc_set_id"].ToString());
                }
            }

           
            return account;
        }

        public Account_Setting Update_Account_Setting(Account_Setting account)
                    {
            ICollection<System.Collections.ArrayList> data_item = new List<System.Collections.ArrayList>();
            SqlDataReader sdr = null;
            string status1 = "";
            data_item.Add(st.create_array("operation", account.Sql_Operation));

            data_item.Add(st.create_array("acc_set_id", account.Acc_Set_Id));

            if (account.Sql_Operation == "Update")
            {
                data_item.Add(st.create_array("society_id", account.Society_Id));
                data_item.Add(st.create_array("mem_open_bal", account.Mem_Open_Bal));
                data_item.Add(st.create_array("mem_charge_btn", account.Mem_Charge_Btn));
                data_item.Add(st.create_array("mem_charge_allocation", account.Mem_Charge_Allocation));
                data_item.Add(st.create_array("receipt_btn", account.Receipt_Btn));
                //data_item.Add(st.create_array("bill_gen_btn", account.Bill_Gen_Btn));
                data_item.Add(st.create_array("gst_round", account.Gst_Round));
                data_item.Add(st.create_array("charge_round", account.Charge_Round));
                data_item.Add(st.create_array("payment_voucher", account.Payment_Voucher));
                data_item.Add(st.create_array("debit_note_voucher", account.Debit_Note_Voucher));
                data_item.Add(st.create_array("credit_note_voucher", account.Credit_Note_Voucher));
                data_item.Add(st.create_array("general_voucher", account.General_Voucher));
                data_item.Add(st.create_array("receipt_voucher", account.Receipt_Voucher));
                data_item.Add(st.create_array("build_wise_payment", account.Build_Wise_Payment));
                data_item.Add(st.create_array("remainder_email_dues", account.Remainder_Email_Dues));
                data_item.Add(st.create_array("rate_per_sqf", account.ratePerSq));
                data_item.Add(st.create_array("two_w_rate", account.twoWRate));
                data_item.Add(st.create_array("four_w_rate", account.fourWRate));
                //rate_per_sqfeet,two_wheeler_rate,four_wheeler_rate
            }
            status1 = st.run_query(data_item, "Select", "sp_account_setting", ref sdr);
            if (status1 == "Done")
            {
                if (account.Sql_Operation == "Select")
                {
                    while (sdr.Read())
                    {
                        account.Society_Id = sdr["society_id"].ToString();
                        account.Mem_Open_Bal = Convert.ToInt32(sdr["mem_open_bal"].ToString()) ;
                        account.Mem_Charge_Btn = Convert.ToInt32(sdr["mem_charge_btn"].ToString());
                        account.Mem_Charge_Allocation = Convert.ToInt32(sdr["mem_charge_allocation"]);
                        account.Receipt_Btn = Convert.ToInt32(sdr["receipt_btn"]);
                        account.Bill_Gen_Btn = Convert.ToInt32(sdr["bill_gen_btn"]);
                        account.Gst_Round = Convert.ToInt32(sdr["gst_round"]);
                        account.Charge_Round = Convert.ToInt32(sdr["charge_round"]);
                        account.Payment_Voucher = Convert.ToInt32(sdr["payment_voucher"]);
                        account.Debit_Note_Voucher = Convert.ToInt32(sdr["debit_note_voucher"]);
                        account.Credit_Note_Voucher = Convert.ToInt32(sdr["credit_note_voucher"]);
                        account.General_Voucher = Convert.ToInt32(sdr["general_voucher"]);
                        account.Receipt_Voucher = Convert.ToInt32(sdr["receipt_voucher"]);
                        account.Build_Wise_Payment = Convert.ToInt32(sdr["build_wise_payment"]);
                        account.Remainder_Email_Dues = Convert.ToInt32(sdr["remainder_email_dues"]);

                        account.ratePerSq = Convert.ToInt32(sdr["rate_per_sqfeet"]);
                        account.twoWRate = Convert.ToInt32(sdr["two_wheeler_rate"]);
                        account.fourWRate = Convert.ToInt32(sdr["four_wheeler_rate"]);
                        
                    }
                }

            }
            return account;
        }
    }
}