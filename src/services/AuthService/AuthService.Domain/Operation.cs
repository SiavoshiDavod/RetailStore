    public class Operation : Entity<Guid>
{
    public string Code { get; private set; } = null!; // order.manage, product.manage
    public string Name { get; private set; } = null!;
    public string? MenuPath { get; private set; }
    public string? Icon { get; private set; }
    public int SortOrder { get; private set; }
}