using HealtHub.Application.Code;
using HealtHub.Infrastructure.Code;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;


namespace HealtHub.Infrastructure.Commun
{
    public static class InfrastructureConfigration
    {
        extension(IServiceCollection Service)
        {
            public void AddInfrastructureServices(IConfiguration configure)
            {
                Service.AddDbContext<ApplicationDataBaseContext>(option => option.UseNpgsql(connectionString: configure.GetConnectionString("Postgre-main")));
                Service.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
            }
        }
    }
}
