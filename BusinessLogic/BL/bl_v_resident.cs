using DataAccessLayer.DA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace BusinessLogic.BL
{
    public class bl_v_resident
    {
        da_v_resident dA_v_resident = new da_v_resident();

        public DataTable getPoints(AmcBalanceSheet balanceEntry)
        {
            return dA_v_resident.getPoints(balanceEntry);
        }

        public receipt getReceiptData(int receipt_id, string operation)
        {
            return dA_v_resident.getReceiptData(receipt_id, operation);
        }

        public DataTable gridBind(string village_id, string operatoin)
        {
            return dA_v_resident.gridBind(village_id, operatoin);
        }

        public DataTable gridBindHistory(string operation, string village_id)
        {
            return dA_v_resident.gridBindHistory(village_id, operation);
        }

        public DataTable gridbind_pending(string village_id, string operation)
        {
            return dA_v_resident.gridbind_pending(village_id, operation);
        }

        public DataTable gridbind_pending_specific_tax(string operation, string village_id, int type, int house_id)
        {
            return dA_v_resident.gridbind_pending_specific_tax(operation,village_id, type, house_id);
        }

        public int InsertBalanceHeader(AmcBalanceSheet balanceEntry)
        {
            return dA_v_resident.InsertBalanceHeader(balanceEntry);
        }

        public AmcBalanceSheet InsertBalanceSubpoint(AmcBalanceSheet balanceEntry)
        {
            return dA_v_resident.InsertBalanceSubpoint(balanceEntry);
        }

        public int InsertHouse(homeModal house)
        {
           return dA_v_resident.InsertHouse(house);
        }

        public void InsertOwner(homeModal house)
        {
            dA_v_resident.insertOwner(house); 
        }

        public void makePayment(receipt payment)
        {
            dA_v_resident.makePayment(payment);
        }

        public string UpdateBalanceSequence(AmcBalanceSheet balanceEntry)
        {
            return dA_v_resident.UpdateBalanceSequence(balanceEntry);
        }
    }
}