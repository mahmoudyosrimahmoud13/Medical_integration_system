using Microsoft.EntityFrameworkCore;


namespace HealthHub.Application.Abstraction
{
    public interface IGenericRepository<TEntity> where TEntity : BaseEntity
    {
        DbSet<TEntity> DbSet { get; }
        IQueryable<TEntity> Query();
        Task<TEntity> GetAsync(Guid id);
        void Update(TEntity model);
        void Add(TEntity model);
        void Delete(TEntity id);
        bool Exists(Guid id);
        Task<int> SaveChangesAsync(CancellationToken cancellationToken);
    }
}
