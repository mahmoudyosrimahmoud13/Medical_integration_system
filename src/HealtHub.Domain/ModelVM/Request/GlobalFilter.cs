using HealtHub.Domain.Entitiy;
using HealtHub.Domain.Enums;

namespace HealtHub.Domain.ModelVM.Request
{
    public class GlobalFilter<T> where T : QueryBase
    {
        public IEnumerable<T> Items { get; set; } = [];
        public Pagination Pagination { get; set; } = new();
        public string? SortField { get; set; }
        public SortTypeEnum SortApproach { get; set; } = SortTypeEnum.Desc;

        public void GetPagination<TEntity>(IQueryable<TEntity> query)
            where TEntity : BaseEntity
        {
            int count = query.Count();
            while ((Pagination.PageNo * Pagination.RowsCount) > count) Pagination.PageNo--;
            Pagination = new Pagination
            {
                PageNo = Pagination.PageNo,
                CurrentPage = Pagination.PageNo,
                RowsCount = Pagination.RowsCount,
                PagesCount = (int)Math.Ceiling((decimal)count / Pagination.RowsCount)
            };
        }
    }
}
