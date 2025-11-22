namespace DeliveryService.Domain.Entities;

public class DeliveryEvent : Entity<Guid>
{
    public Guid DeliveryId { get; set; }
    public DeliveryEventType Type { get; set; }
    public string? Description { get; set; }
    public DateTime OccurredAt { get; set; }
}

public enum DeliveryEventType
{
    Created,
    DriverAssigned,
    PickedUp,
    OnTheWay,
    Delivered,
    Failed,
    StatusChanged
}