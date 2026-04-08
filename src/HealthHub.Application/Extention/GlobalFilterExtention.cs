namespace HealthHub.Application.Extention
{
    internal static class GlobalFilterExtention
    {
        extension<T>(GlobalFilter<T> source) where T : new()
        {
            public void GetPagination<TEntity>(IQueryable<TEntity> query) where TEntity : BaseEntity
            {
                int count = query.Count();
                while ((source.Pagination.PageNo * source.Pagination.RowsCount) > count) source.Pagination.PageNo--;
                source.Pagination = new Pagination
                {
                    PageNo = source.Pagination.PageNo,
                    CurrentPage = source.Pagination.PageNo,
                    RowsCount = source.Pagination.RowsCount,
                    PagesCount = (int)Math.Ceiling((decimal)count / source.Pagination.RowsCount)
                };
            }
        }
    }
}
