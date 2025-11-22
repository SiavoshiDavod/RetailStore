public class UserGroup : Entity<Guid>
{
    public string Code { get; private set; } = null!; // Customer, VendorOwner, SystemAdmin
    public string Name { get; private set; } = null!;
    public bool IsSystem { get; private set; }

    public IReadOnlyCollection<Operation> Operations => _operations.AsReadOnly();
    private readonly List<Operation> _operations = new();

    private UserGroup() { }
    public static UserGroup CreateSystem(string code, string name) =>
        new() { Id = Guid.NewGuid(), Code = code, Name = name, IsSystem = true };
}