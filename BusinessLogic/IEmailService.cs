using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BusinessLogic
{
   public interface IEmailService
    {
        Task SendEmailAsync( 
    List<(string Email, string Name)> recipients,

    string subject,
    string plainTextContent,
    string htmlContent);
    }
}
