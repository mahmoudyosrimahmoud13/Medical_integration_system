using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
namespace HealthHub.Infrastructure.Commun
{
    public static class InfrastructureConfigration
    {
        extension(IServiceCollection Service)
        {
            public IServiceCollection AddInfrastructureServices(IConfiguration configure)
            {
                Service.AddDbContext<ApplicationDataBaseContext>(option => option.UseSqlServer(connectionString: configure.GetConnectionString("defult")));
                Service.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
                Service.AddScoped<IDapperRepository, DapperRepository>();
                return Service;

            }
        }
    }
}
