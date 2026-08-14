using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Utility.DataClass
{
    public class Account_Setting
    {
        private int acc_set_id;
        private string society_id;
        private int mem_open_bal;
        private int mem_change_allocation;
        private int receipt_btn;
        private int bill_gen_btn;
        private int gst_round;
        private int charge_round;
        private int payment_voucher;
        private int debit_note_voucher;
        private int credit_note_voucher;
        private int general_voucher;
        private int mem_charge_btn;
        private int receipt_voucher;
        private int build_wise_payment;
        private int remainder_email_dues;
        private string Operation;
        private string Result;
        private decimal rate_per_sqf;
        private decimal two_w_rate;
        private decimal four_w_rate;


        public int Acc_Set_Id
        {
            get { return acc_set_id; }
            set { acc_set_id = value; }
        }
        public decimal twoWRate
        {
            get { return two_w_rate; }
            set { two_w_rate = value; }
        }
        public decimal ratePerSq
        {
            get { return rate_per_sqf; }
            set { rate_per_sqf = value; }
        }
        public decimal fourWRate
        {
            get { return four_w_rate; }
            set { four_w_rate = value; }
        }
        public string Society_Id
        {
            get { return society_id; }
            set { society_id = value; }
        }
        public int Mem_Open_Bal
        {
            get { return mem_open_bal; }
            set { mem_open_bal = value; }
        }
        public int Mem_Charge_Btn
        {
            get { return mem_charge_btn; }
            set { mem_charge_btn = value; }
        }
        public int Mem_Charge_Allocation
        {
            get { return mem_change_allocation; }
            set { mem_change_allocation = value; }
        }
        public int Receipt_Btn
        {
            get { return receipt_btn; }
            set { receipt_btn = value; }
        }
        public int Bill_Gen_Btn
        {
            get { return bill_gen_btn; }
            set { bill_gen_btn = value; }
        }
        public int Gst_Round
        {
            get { return gst_round; }
            set { gst_round = value; }
        }
        public int Charge_Round
        {
            get { return charge_round; }
            set { charge_round = value; }
        }
        public int Payment_Voucher
        {
            get { return payment_voucher; }
            set { payment_voucher = value; }
        }
        public int Debit_Note_Voucher
        {
            get { return debit_note_voucher; }
            set { debit_note_voucher = value; }
        }
        public int Credit_Note_Voucher
        {
            get { return credit_note_voucher; }
            set { credit_note_voucher = value; }
        }
        public int General_Voucher
        {
            get { return general_voucher; }
            set { general_voucher = value; }
        }
        public int Receipt_Voucher
        {
            get { return receipt_voucher; }
            set { receipt_voucher = value; }
        }
        public int Build_Wise_Payment
        {
            get { return build_wise_payment; }
            set { build_wise_payment = value; }
        }
        public int Remainder_Email_Dues
        {
            get { return remainder_email_dues; }
            set { remainder_email_dues = value; }
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