using HealthHub.Share.IPVM;
using HealthHub.Share.ResponesVM;
using Microsoft.AspNetCore.Http;
using RestSharp;
using System.Text.Json;

namespace HealthHub.Infrastructure.Implementation
{
    internal class IpAPIService(IHttpContextAccessor context) : IIpAPIService
    {
        public async Task<Respones<IpRespones?>> GetIpAsync()
        {

            try
            {
                string ipAddress = context?.HttpContext?.Request?.Headers["X-Forwarded-For"].FirstOrDefault() ?? context.HttpContext.Connection.RemoteIpAddress?.ToString();
                ipAddress = ipAddress?.Split(':')[0];
                var url = $"https://ip-api.com/json/{ipAddress}";

                var request = new RestRequest(url, Method.Get);
                RestResponse response = new RestClient().Execute(request);

                var Ip = JsonSerializer.Deserialize<IpRespones>(response.Content);



                if (!string.IsNullOrEmpty(Ip.timezone))
                {
                    TimeZoneInfo targetTimeZone = TimeZoneInfo.FindSystemTimeZoneById(Ip.timezone);
                    DateTime targetTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, targetTimeZone);
                    Ip.time_date = targetTime.ToString("yyyy-MM-dd  HH:mm:ss");
                    Ip.time_date = $"{Ip.time_date} ({Ip.country})";
                }
                return new(Ip);

            }
            catch (HttpRequestException ex)
            {
                return new(null, ex.Message, false, (int)ex.StatusCode);

            }
            catch (Exception ex)
            {
                return new(null, ex.Message, false, 500);
            }
        }

        public async Task<DateTime> GetCurrentDateTimeAsync()
        {
            var currentUser = await GetIpAsync();
            if (currentUser.isSucss)
            {
                TimeZoneInfo timeZone = TimeZoneInfo.FindSystemTimeZoneById(currentUser.Data?.timezone);
                DateTimeOffset specificTime = TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, timeZone);
                return specificTime.DateTime;
            }
            else
            {
                return DateTime.UtcNow;
            }

        }
    }
}