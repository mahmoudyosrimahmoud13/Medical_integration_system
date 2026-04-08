using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
namespace HealthHub.Infrastructure.Context
{
    internal class ApplicationDataBaseContext(DbContextOptions<ApplicationDataBaseContext> option) : IdentityDbContext(option)
    {
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            //modelBuilder.ApplyConfigurationsFromAssembly(typeof().Assembly);
        }
    }
}
