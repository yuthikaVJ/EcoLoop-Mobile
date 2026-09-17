using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace EcoLoop.Api.Services;

public class NotificationService
{
    public NotificationService()
    {
        // FirebaseApp is initialized in Program.cs
    }

    public async Task SendPushNotificationAsync(List<string> deviceTokens, string title, string body, Dictionary<string, string>? data = null)
    {
        if (deviceTokens == null || deviceTokens.Count == 0) return;

        var message = new MulticastMessage()
        {
            Tokens = deviceTokens, // Note: Fids could be used instead based on newer SDK, but Tokens still works for now
            Notification = new Notification()
            {
                Title = title,
                Body = body
            },
            Data = data ?? new Dictionary<string, string>()
        };

        try
        {
            var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
            // We could handle response.Responses here to remove invalid tokens
            Console.WriteLine($"{response.SuccessCount} messages were sent successfully");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending FCM message: {ex.Message}");
        }
    }
}
