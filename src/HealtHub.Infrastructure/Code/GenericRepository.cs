using HealtHub.Application.Code;
using HealtHub.Application.Helpers;
using HealtHub.Domain.Entitiy;
using Microsoft.EntityFrameworkCore;

namespace HealtHub.Infrastructure.Code
{
    internal class GenericRepository<TEntity>(ApplicationDataBaseContext context)
         : IGenericRepository<TEntity> where TEntity : BaseEntity
    {
        public void Add(TEntity model)
        {
            context.Add(model);
            DbSet.Add(model);
        }

        public DbSet<TEntity> DbSet => context.Set<TEntity>();

        public void Delete(TEntity model) => DbSet.Remove(model);

        public bool Exists(Guid id) => DbSet.Any(e => e.Id == id);

        public async Task<TEntity> GetAsync(Guid id, CancellationToken cancellationToken=default(CancellationToken) ) => await Query().FirstOrErrorAsync(id,cancellationToken: cancellationToken);

        public virtual IQueryable<TEntity> Query() => DbSet.AsQueryable();

        public void Update(TEntity model) => context.Update(model);

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken) => await context.SaveChangesAsync(cancellationToken);

      
    }
}
