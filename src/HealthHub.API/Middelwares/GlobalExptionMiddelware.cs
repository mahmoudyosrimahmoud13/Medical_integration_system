using HealthHub.Share.ResponesVM;
using Microsoft.AspNetCore.Diagnostics;
using System.Net;
namespace HealthHub.API.Middelwares
{
    public class GlobalExptionMiddelware : IExceptionHandler
    {
        public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
        {
            httpContext.Response.ContentType = "application/json";
            httpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            var response = new Respones<object>(null, exception.Message, false, 500);
            await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);
            return true;
        }

    }
}
