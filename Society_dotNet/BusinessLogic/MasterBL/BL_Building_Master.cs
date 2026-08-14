using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using DataAccessLayer.MasterDA;
using DBCode.DataClass;

namespace BusinessLogic.MasterBL
{
    public class BL_Building_Master
    {
        public DataTable getBuildingDetails(Building build)
        {
            DA_Building_Master DAB = new DA_Building_Master();
            DataTable building_data = DAB.getBuildingDetails(build);
            return building_data;
        }
        public Building updateBuildingDetails(Building building)
        {
            DA_Building_Master DAB = new DA_Building_Master();
            return DAB.updateBuildingDetails(building);
        

        }
        public Building GridViewDelete1(Building building)
        {
            DA_Building_Master DAB = new DA_Building_Master();
            return DAB.GridViewDelete1(building);

        }


        public Building BuildingTextchange(Building building)
        {
            DA_Building_Master DAB = new DA_Building_Master();
            return DAB.BuildingTextChange(building);

        }
        public Building delete(Building building)
        {
            DA_Building_Master DAB = new DA_Building_Master();
            return DAB.delete_building(building);


        }

        public object search_building(Building building)
        {
            DA_Building_Master DAB = new DA_Building_Master();
            return DAB.search_building(building);

        }
    }

    }
