namespace HealtHub.Domain.Entitiy;

public class BaseEntity
{
    public Guid Id { get; set; }
    public string? CreatedBy { get; set; }
    public string? ModifyBy{ get; set; }
    public string? DeletdBy { get; set; }
    public DateTime? CreatedOn { get; set; }
    public DateTime? ModifyOn{ get; set; }
    public DateTime? DeletedOn{ get; set; }
    public bool IsDeleted{ get; set; }
}
