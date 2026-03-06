using HealtHub.Domain.Entitiy;
using Microsoft.EntityFrameworkCore;
namespace HealtHub.Application.Code;
public interface IGenericRepository<TEntity> where TEntity : BaseEntity
{
    DbSet<TEntity> DbSet { get; }
    IQueryable<TEntity> Query();
    Task<TEntity> GetAsync(Guid id, CancellationToken CancellationToken);
    void Update(TEntity model);
    void Add(TEntity model);
    void Delete(TEntity id);
    bool Exists(Guid id);
    Task<int> SaveChangesAsync(CancellationToken CancellationToken);
}

