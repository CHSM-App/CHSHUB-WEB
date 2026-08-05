using DataAccessLayer.MasterDA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using Utility.DataClass;

namespace BusinessLogic.MasterBL
{
    public class BL_Suggestion_Request_Master
    {
        DA_Suggestion_Request DA_Suggestion = new DA_Suggestion_Request();
        public DataTable getsuggestion(Request request)
        {

            return DA_Suggestion.Get_Suggestion(request);
         
        }

        public Request updateSuggestionRequestDetails(Request request)
        {
            return DA_Suggestion.Update_Suggestion(request);
        }

        public DataTable search_suggestion(Request request)
        {
            return DA_Suggestion.Suggestion_Search(request);
        }

        public Request delete_suggestion(Request request)
        {
            return DA_Suggestion.Suggestion_delete(request);
        }
    }
}