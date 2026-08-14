using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.BL
{
    public class BL_Ledger
    {
        DA_Ledger dA_Ledger = new DA_Ledger();
        public DataTable getLedgerDetails(Ledger GetLedger)
        {
            return dA_Ledger.Get_Ledger(GetLedger);

        }

        public Ledger updateLedgerDetails(Ledger GetLedger)
        {
          
            return dA_Ledger.updateLedgerDetails(GetLedger);

        }
        public Ledger delete(Ledger GetLedger)
        {

            return dA_Ledger.delete_ledger(GetLedger);

        }

        public DataTable search_ledger(Ledger GetLedger)
        {
            return dA_Ledger.ledger_search(GetLedger);
        }

        public DataTable get_print_Ledger(Ledger getLedger)
        {
            return dA_Ledger.Get_Print_Ledger(getLedger);
        }
    }
}