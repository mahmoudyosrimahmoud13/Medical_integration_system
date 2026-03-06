
using Microsoft.EntityFrameworkCore;

namespace HealtHub.Infrastructure.DataBase;

internal class ApplicationDataBaseContext(DbContextOptions<ApplicationDataBaseContext> option) : DbContext(option)
{

    //public DbSet<Employee> Employees => Set<Employee>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
       // modelBuilder.ApplyConfigurationsFromAssembly(typeof(EmployeeConfiguration).Assembly);
    }

}
