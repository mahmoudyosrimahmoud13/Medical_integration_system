using HealthHub.Application.Behaviors;
using Microsoft.Extensions.DependencyInjection;
namespace HealthHub.Application.Commun
{
    public static class ApplicationConfigration
    {
        extension(IServiceCollection services)
        {
            public IServiceCollection AddApplicaitonService()
            {
                services.AddMediatR(option => option.RegisterServicesFromAssembly(typeof(ApplicationConfigration).Assembly));
                services.AddValidatorsFromAssembly(typeof(ApplicationConfigration).Assembly);
                services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehaviors<,>));
                return services;
            }
        }
    }
}
