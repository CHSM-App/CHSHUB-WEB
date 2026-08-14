using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace Society
{
    /// <summary>
    /// Summary description for getFiles
    /// </summary>
    public class getFiles : IHttpHandler
    {

        // Base directory that contains all your files
        // (change this to your actual root folder)
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                // Example: /uploads/user/photo.jpg
                string relativePath = context.Request.QueryString["path"];

                if (string.IsNullOrEmpty(relativePath))
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write("Missing 'path' parameter.");
                    return;
                }

                // Normalize path (block ../)
                if (relativePath.Contains(".."))
                {
                    context.Response.StatusCode = 403;
                    context.Response.Write("Invalid path.");
                    return;
                }

                // Map to physical root of website
                // This converts /uploads/file.jpg → C:\inetpub\wwwroot\YourSite\uploads\file.jpg
                string fullPath = context.Server.MapPath(relativePath);

                if (!File.Exists(fullPath))
                {
                    context.Response.StatusCode = 404;
                    context.Response.Write("File not found.");
                    return;
                }

                string mime = GetMimeType(fullPath);

                context.Response.ContentType = mime;
                context.Response.AddHeader("Content-Disposition", "inline; filename=" + Path.GetFileName(fullPath));

                context.Response.WriteFile(fullPath);
            }
            catch
            {
                context.Response.StatusCode = 500;
                context.Response.Write("Server error.");
            }
        }

        public bool IsReusable => false;

        private string GetMimeType(string path)
        {
            string ext = Path.GetExtension(path).ToLower();
            switch (ext)
            {
                case ".jpg":
                case ".jpeg": return "image/jpeg";
                case ".png": return "image/png";
                case ".gif": return "image/gif";
                case ".pdf": return "application/pdf";
                case ".txt": return "text/plain";
                default: return "application/octet-stream";
            }
        }
    }
}