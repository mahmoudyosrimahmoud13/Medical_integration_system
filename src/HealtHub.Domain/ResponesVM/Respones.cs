
namespace HealtHub.Domain.ResponesVM;

public record Respones<T>(T data,string?message,bool isSucss = true, Dictionary<string, string[]> ?errors=null);
