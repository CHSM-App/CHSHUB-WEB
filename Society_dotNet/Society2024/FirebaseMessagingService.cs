using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;

namespace Society2024
{
    public class FirebaseMessagingService
    {
        public static async Task<string> GenerateFirebaseToken(string uid)
        {
            // Initialize the Firebase App once
            if (FirebaseApp.DefaultInstance == null)
            {
                FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data", "serviceAccountKey.json"))
                });
            }

            // Optional: Add custom claims
            var additionalClaims = new Dictionary<string, object>()
        {
            { "premiumAccount", true }
        };

            string customToken = await FirebaseAuth.DefaultInstance
                .CreateCustomTokenAsync(uid, additionalClaims);

            return customToken;
        }
    }
}
