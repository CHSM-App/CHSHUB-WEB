using Google.Apis.Auth.OAuth2;
using Newtonsoft.Json;
using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Policy;
using System.Text;
using System.Threading.Tasks;


namespace Society2024
{
    
    public class FirebaseCloudMessaging
    {
        private const string FcmUrl = "https://fcm.googleapis.com/fcm/send";
        private readonly string projectId ; // Get this from Firebase Console

        public FirebaseCloudMessaging()
        {
            // Load the service account JSON to extract the server key
            var json = File.ReadAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data", "serviceAccountKey.json"));
            dynamic serviceAccount = JsonConvert.DeserializeObject(json);

            projectId = serviceAccount.project_id;
        }

        public async Task<String> SendNotificationAsync(string token, string title, string message)
        {
            var credential = GoogleCredential.FromFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data", "serviceAccountKey.json"))
           .CreateScoped("https://www.googleapis.com/auth/firebase.messaging"); 

            var accessToken = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();

            // FCM HTTP v1 endpoint
            var url = $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

            using (var httpClient = new HttpClient())
            {
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

                var payload = new
                {
                    message = new
                    {
                        token = token,
                        notification = new
                        {
                            title = title,
                            body = message

                        }

                    }
                    
                };

                var json = JsonConvert.SerializeObject(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await httpClient.PostAsync(url, content);
                var result = await response.Content.ReadAsStringAsync();


                if (!response.IsSuccessStatusCode)
                {
                    // Log or handle the error
                    System.Diagnostics.Debug.WriteLine($"Error sending FCM: {result}");
                }

                return $"Status: {response.StatusCode}\nResponse: {result}";
            }
        }
    }






    public class FirebaseServiceAccount
    {
        [JsonProperty("project_id")]
        public string ProjectId { get; set; }

        [JsonProperty("private_key_id")]
        public string PrivateKeyId { get; set; }

        [JsonProperty("private_key")]
        public string PrivateKey { get; set; }

        [JsonProperty("client_email")]
        public string ClientEmail { get; set; }

        [JsonProperty("client_id")]
        public string ClientId { get; set; }

        [JsonProperty("auth_uri")]
        public string AuthUri { get; set; }

        [JsonProperty("token_uri")]
        public string TokenUri { get; set; }

        [JsonProperty("auth_provider_x509_cert_url")]
        public string AuthProviderX509CertUrl { get; set; }

        [JsonProperty("client_x509_cert_url")]
        public string ClientX509CertUrl { get; set; }

        [JsonProperty("project_credentials")]
        public ProjectCredentials ProjectCredentials { get; set; }
    }

    public class ProjectCredentials
    {
        [JsonProperty("server_key")]
        public string ServerKey { get; set; }
    }

}




