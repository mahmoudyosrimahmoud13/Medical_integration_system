namespace HealthHub.Domain.Entity
{
    public class BaseEntity
    {
        public Guid Id { get; protected set; }
        public string? Note { get; protected set; }
        public string? CreatedBy { get; protected set; }
        public string? ModifyBy { get; protected set; }
        public string? DeletedBy { get; protected set; }
        public DateTime? CreatedOn { get; protected set; }
        public DateTime? ModifyOn { get; protected set; }
        public DateTime? DeletedOn { get; protected set; }
        public bool IsDeleted { get; protected set; }

        protected BaseEntity()
        { }
        public BaseEntity(string createdBy)
        {
            this.CreatedBy = createdBy;
            this.CreatedOn = DateTime.UtcNow;
            this.IsDeleted = false;
        }

        public virtual bool Update(string modifyBy)
        {
            if (string.IsNullOrWhiteSpace(modifyBy))
                return false;

            this.ModifyBy = modifyBy;
            this.ModifyOn = DateTime.UtcNow;
            return true;
        }

        public virtual bool ToggaleStatus(string deletedBy)
        {
            if (string.IsNullOrWhiteSpace(deletedBy))
                return false;

            this.DeletedBy = deletedBy;
            this.DeletedOn = DateTime.UtcNow;
            this.IsDeleted = !this.IsDeleted;
            return true;
        }
    }
}
