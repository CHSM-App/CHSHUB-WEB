using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Society2024
{
    public partial class landing_page : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnDownload_Click(object sender, EventArgs e)
        {
            string relativePath = "~/apk/CHShub.apk";
            string filePath = Server.MapPath(relativePath);
            string fileName = "CHShhub.apk";

            if (!System.IO.File.Exists(filePath))
            {
                Response.Write("File not found on server.");
                return;
            }

            Response.Clear();
            Response.ContentType = "application/vnd.android.package-archive";
            Response.AppendHeader("Content-Disposition", "attachment; filename=" + fileName);
            Response.TransmitFile(filePath);
            Response.End();
        }

    }
}