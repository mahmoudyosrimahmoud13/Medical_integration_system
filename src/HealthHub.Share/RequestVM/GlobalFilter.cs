using HealthHub.Share.Enum;
namespace HealthHub.Share.RequestVM
{
    public class GlobalFilter<T> where T : new()
    {
        public IEnumerable<T> Items { get; set; } = [];
        public Pagination Pagination { get; set; } = new();
        public string? SortField { get; set; }
        public SortingTypeEnum SortApproach { get; set; } = SortingTypeEnum.Desc;


    }
}
