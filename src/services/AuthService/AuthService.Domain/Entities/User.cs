public class User : AggregateRoot<Guid>
{
    public string FullName { get; private set; } = null!;
    public string Mobile { get; private set; } = null!;
    public string? Email { get; private set; }
    public string PasswordHash { get; private set; } = null!;
    public UserType UserType { get; private set; }
    public UserStatus Status { get; private set; } = UserStatus.Pending;

    public IReadOnlyCollection<UserGroup> Groups => _groups.AsReadOnly();
    private readonly List<UserGroup> _groups = new();

    // رفتارهای دامنه
    public void AssignToGroup(UserGroup group) => _groups.Add(group);
    public void RemoveFromGroup(UserGroup group) => _groups.Remove(group);
    public void Activate() => Status = UserStatus.Active;
    public void Suspend() => Status = UserStatus.Suspended;
}