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
    public class BL_Receipt
    {
        DA_Receipt dA_Receipt = new DA_Receipt();
        public void fill_drop(DropDownList drp_down, string sqlstring, string text, string value)
        {
            dA_Receipt.fill_drop(drp_down, sqlstring, text, value);
        }

        public DataTable GetReceipt(receipt Receipt)
        {
            return dA_Receipt.getreceipt(Receipt);
        }
        public receipt UpdateReceipt(receipt Receipt)
        {
            return dA_Receipt.updatereceipt(Receipt);
        }
       
        public receipt fetch_receipt(receipt Receipt)
        {
            return dA_Receipt.receipt_exfetch(Receipt);
        }
       
        public receipt Advance_Pay_Settlement(receipt Receipt)
        {
            return dA_Receipt.advance_pay_settlement(Receipt);
        }
        public receipt Delete_Receipt(receipt Receipt)
        {
            return dA_Receipt.delete(Receipt);
        }
        public receipt Cheque_Select(receipt Receipt)
        {
            return dA_Receipt.Select_Cheque(Receipt);
        }

        public object get_printreceipt(receipt getReceipt)
        {
            return dA_Receipt.Print_Receipt(getReceipt);
        }

        public DataTable search_receipt(receipt Receipt)
        {
            return dA_Receipt.receipt_search(Receipt);
        }

        public DataTable Get_CashBook(Cashbook cash)
        {
            return dA_Receipt.get_cashbook(cash);
        }

        public DataTable fill_list(string operation, int flat, string society)
        {
            
                return dA_Receipt.fill_list(operation, flat, society);
            
        }


        public DataTable get_paid_amount(receipt getReceipt)
        {
            return dA_Receipt.Get_Paid_Amount(getReceipt);
        }

        public DataTable grid_show(receipt billReceipt)
        {
            return dA_Receipt.grid_show(billReceipt);
        }

        public DataTable view_bill(receipt billReceipt)
        {
            return dA_Receipt.view_bill(billReceipt);
        }



        //public receipt email_send(receipt receipt)
        //{
        //    return dA_Receipt.Email_Send(receipt);
        //}
    }
}