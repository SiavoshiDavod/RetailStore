namespace NotificationService.Domain.Entities;

public class Notification : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public string TemplateCode { get; private set; } = null!;
    public NotificationChannel Channel { get; private set; }
    public NotificationPriority Priority { get; private set; } = NotificationPriority.Normal;
    
    public string? Subject { get; private set; }
    public string Body { get; private set; } = null!;
    public Dictionary<string, object> Data { get; private set; } = new();
    
    public NotificationStatus Status { get; private set; } = NotificationStatus.Pending;
    public int RetryCount { get; private set; } = 0;
    public DateTime? NextRetryAt { get; private set; }
    public DateTime? SentAt { get; private set; }
    public DateTime? DeliveredAt { get; private set; }
    public string? FailReason { get; private set; }

    private readonly List<NotificationLog> _logs = new();
    public IReadOnlyCollection<NotificationLog> Logs => _logs.AsReadOnly();

    public static Notification Create(
        Guid userId,
        string templateCode,
        NotificationChannel channel,
        Dictionary<string, object> data,
        NotificationPriority priority = NotificationPriority.Normal)
    {
        return new Notification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TemplateCode = templateCode,
            Channel = channel,
            Data = data,
            Priority = priority
        };
    }

    public void MarkAsSent(string providerMessageId)
    {
        Status = NotificationStatus.Sent;
        SentAt = DateTime.UtcNow;
        AddLog("SENT", providerMessageId);
    }

    public void MarkAsDelivered()
    {
        Status = NotificationStatus.Delivered;
        DeliveredAt = DateTime.UtcNow;
        AddLog("DELIVERED");
    }

    public void MarkAsFailed(string reason)
    {
        RetryCount++;
        Status = RetryCount >= 3 ? NotificationStatus.Failed : NotificationStatus.Pending;
        FailReason = reason;
        NextRetryAt = DateTime.UtcNow.AddMinutes(Math.Pow(2, RetryCount)); // Exponential backoff
        AddLog("FAILED", reason);
    }

    private void AddLog(string action, string? details = null)
    {
        _logs.Add(new NotificationLog
        {
            Id = Guid.NewGuid(),
            NotificationId = Id,
            Action = action,
            Details = details,
            Timestamp = DateTime.UtcNow
        });
    }
}

public enum NotificationChannel { SMS, Push, Email, InApp }
public enum NotificationPriority { Low, Normal, High, Critical }
public enum NotificationStatus { Pending, Sent, Delivered, Failed }