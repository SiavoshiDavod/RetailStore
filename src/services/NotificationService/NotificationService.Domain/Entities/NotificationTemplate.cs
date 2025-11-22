namespace NotificationService.Domain.Entities;

public class NotificationTemplate : Entity<Guid>
{
    public string Code { get; private set; } = null!;
    public NotificationChannel Channel { get; private set; }
    public string Title { get; private set; } = null!;
    public string? Subject { get; private set; }
    public string Body { get; private set; } = null!; // Handlebars template
    public bool IsActive { get; private set; } = true;
    public int Version { get; private set; } = 1;
}