using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;

namespace Society2024
{
    /// <summary>
    /// Summary description for UploadImageHandler
    /// </summary>
    public class UploadImageHandler : IHttpHandler
    {
        public class UploadRequest
        {
            public string imageData { get; set; }
            public string ownerId { get; set; }
        }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";

            try
            { 
                using (var reader = new StreamReader(context.Request.InputStream))
                {
                    var json = reader.ReadToEnd();

                    JavaScriptSerializer serializer = new JavaScriptSerializer();
                    UploadRequest request = serializer.Deserialize<UploadRequest>(json);

                    if (string.IsNullOrEmpty(request.ownerId))
                    {
                        context.Response.Write("Missing owner ID.");
                        return;
                    }

                    string base64Data = request.imageData.Replace("data:image/png;base64,", "")
                                                         .Replace(" ", "+");

                    byte[] imageBytes = Convert.FromBase64String(base64Data);
                    string folderPath = context.Server.MapPath("~/img/ProfilePic/");

                    if (!Directory.Exists(folderPath))
                        Directory.CreateDirectory(folderPath);

                    string fileName = "owner_" + request.ownerId + ".png";
                    string filePath = Path.Combine(folderPath, fileName);
                    File.WriteAllBytes(filePath, imageBytes);

                    context.Response.Write("Image saved as " + fileName);
                }
            }
            catch (Exception ex)
            {
                context.Response.Write("Error: " + ex.Message);
            }
        }

        public bool IsReusable => false;
    }
}