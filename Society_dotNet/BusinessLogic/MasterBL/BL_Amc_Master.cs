using DataAccessLayer.MasterDA;
using DBCode.DataClass;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Amc_Master
    {
            DA_Amc_Master dA_Amc = new DA_Amc_Master();

        public Amc audit_que(Amc audit)
        {
            return dA_Amc.audit_que(audit);
        }

        public DataTable bindIncome(Amc audit)
        {
            return dA_Amc.bindIncome(audit);
        }
        public DataTable latePayemnt(Amc audit)
        {
            return dA_Amc.latePayment(audit);
        }

        public DataTable getAmcDetails(int amc_id, string society_id)
        {
            DataTable amc_data = dA_Amc.geAmcDetails(amc_id, society_id);
            return amc_data;
        }

        public DataTable getAmcDetails(Amc agm)
        {
           return dA_Amc.GetAmcDetails(agm);
        }

        public DataTable getHeaders(string society_id, string operation)
        {
            return dA_Amc.getHeaders(society_id, operation);
        }

        public DataTable getQestions(string society_id, string operation)
        {
            return dA_Amc.getQuestions(society_id,operation);
        }

        public int InsertAuditMainPoint(Amc audit)
        {
            return dA_Amc.InsertAuditMainPoint(audit);
        }

        public void InsertAuditSubPoint(Amc audit)
        {
            dA_Amc.InsertAuditSubPoint(audit);
        }

        public void updateAmcDetails(DataTable amcmaster)
        {
            DA_Amc_Master dA_Amc = new DA_Amc_Master();
           dA_Amc.updateAmcDetails(amcmaster);
             

        }

        public string updateSeq(Amc audit)
        {
            return dA_Amc.updateSeq(audit);
        }

        public DataTable fetchSocietyData(string operation, string society_id)
        {
            return dA_Amc.fetchSocietyData(operation, society_id);
        }
    }
}