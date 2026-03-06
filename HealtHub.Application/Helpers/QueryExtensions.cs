using HealtHub.Domain.Entitiy;
using HealtHub.Domain.ModelVM.Request;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace HealtHub.Application.Helpers;

public static class QueryExtensions
{
    extension<T>(DbSet<T> source) where T : BaseEntity
    {
        public async Task<T> FindOrErrorAsync(Guid id, Exception? exception = null)
            => await source.FindAsync(id) ?? throw exception ?? new KeyNotFoundException();

    }


    extension<T>(IQueryable<T> source) where T : BaseEntity
    {
        public async Task<T> FirstOrErrorAsync(Guid id, Exception? exception = null, CancellationToken cancellationToken=default(CancellationToken))
            => await source.FirstOrDefaultAsync(c => c.Id == id,cancellationToken: cancellationToken) ?? throw exception ?? new KeyNotFoundException();


        public IQueryable<T> WhereIf(bool Condition, Expression<Func<T, bool>> expression)
            => Condition ? source.Where(expression) : source;

        public IQueryable<T> Paginate<TDto>(GlobalFilter<TDto> filter) where TDto : QueryBase
            => source
                .Skip(filter.Pagination.PageNo * filter.Pagination.RowsCount)
                .Take(filter.Pagination.RowsCount);

        public IQueryable<T> OrderAndPaginate<TDto>(GlobalFilter<TDto> filter) where TDto : QueryBase
             => source.OrderWith(filter).Paginate(filter);


        public IQueryable<T> OrderWith<TDto>(GlobalFilter<TDto> filter) where TDto : QueryBase
        {
            if (string.IsNullOrEmpty(filter.SortField))
                filter.SortField = nameof(BaseEntity.CreatedOn);

            return
                filter.SortApproach == SortTypeEnum.Desc ?
                source.OrderByDescending(c => EF.Property<object>(c!, filter.SortField))
                :
                source.OrderBy(c => EF.Property<object>(c!, filter.SortField))
                ;
        }

    }


}