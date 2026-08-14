using DataAccessLayer.MasterDA;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace BusinessLogic.MasterBL
{
    public class BL_Asset_Master
    {
        public DataTable getAssetDetails(int a_id, string society_id)
        {
            DA_Asset_Master dA_Asset = new DA_Asset_Master();
            DataTable asset_data =dA_Asset.getAssetDetails(a_id, society_id);
            return asset_data;
        }
        public void updateAssetDetails(DataTable assetmaster)
        {
            DA_Asset_Master dA_Asset = new DA_Asset_Master();
           dA_Asset.updateAssetDetails(assetmaster);


        }
    }
}