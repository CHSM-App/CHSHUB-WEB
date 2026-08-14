using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Mail;
using System.Threading.Tasks;

using SendGrid;
using SendGrid.Helpers.Mail;

using System.Web;

namespace BusinessLogic
{
    public class SendGridEmailService : IEmailService
    {
        private readonly string _apiKey;
        private readonly EmailAddress _from;

        public SendGridEmailService()
        {
            _apiKey = ConfigurationManager.AppSettings["SendGridApiKey"];
            if (string.IsNullOrEmpty(_apiKey))
                throw new InvalidOperationException("SendGrid API key is not configured.");

            _from = new EmailAddress("pundalik.salunkhe@codepath.in", "VengurlaTech");
        }

        public async Task SendEmailAsync(
             List<(string Email, string Name)> recipients,
             string subject,
             string plainTextContent,
             string htmlContent)
        {
            var client = new SendGridClient(_apiKey);

            // Create the sender
            var from = _from;

            // Map recipients into SendGrid EmailAddress list
            var toAddresses = recipients.Select(r => new EmailAddress(r.Email, r.Name)).ToList();

            // Create message with multiple recipients
            var msg = MailHelper.CreateSingleEmailToMultipleRecipients(
                from,
                toAddresses,
                subject,
                plainTextContent,
                htmlContent
            );

            var response = await client.SendEmailAsync(msg);

            if (response.StatusCode >= System.Net.HttpStatusCode.BadRequest)
            {
                var errorBody = await response.Body.ReadAsStringAsync();
                throw new ApplicationException(
                    $"SendGrid failed ({response.StatusCode}): {errorBody}");
            }
        }


        // Optional synchronous wrapper for pages not marked Async="true"
        public void SendEmail(
            List<(string Email, string Name)> recipients,
       
            string subject,
            string plainTextContent,
            string htmlContent)
        {
            SendEmailAsync(recipients, subject, plainTextContent, htmlContent)
                .GetAwaiter()
                .GetResult();
        }
    }
}