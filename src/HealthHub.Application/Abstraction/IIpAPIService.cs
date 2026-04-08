using HealthHub.Share.IPVM;

namespace HealthHub.Application.Abstraction
{
    public interface IIpAPIService
    {
        Task<Respones<IpRespones?>> GetIpAsync();
        Task<DateTime> GetCurrentDateTimeAsync();
    }
}
