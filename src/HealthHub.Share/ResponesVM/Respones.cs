namespace HealthHub.Share.ResponesVM
{
    public record Respones<T>(T? Data, string? message = null, bool isSucss = true, int? status = 200, IDictionary<string, string[]>? errors = null);
}
