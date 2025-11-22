namespace DeliveryService.Domain.Entities;

public class Delivery : AggregateRoot<Guid>
{
    public Guid OrderId { get; private set; }
    public string TrackingNumber { get; private set; } = null!;
    public DeliveryProvider Provider { get; private set; }
    public DeliveryStatus Status { get; private set; } = DeliveryStatus.Pending;
    
    public Guid? DriverId { get; private set; }
    public string? DriverName { get; private set; }
    public string? DriverMobile { get; private set; }
    public string? DriverPlate { get; private set; }
    
    public decimal DeliveryFee { get; private set; }
    public DateTime? EstimatedDeliveryAt { get; private set; }
    public DateTime? PickedUpAt { get; private set; }
    public DateTime? DeliveredAt { get; private set; }

    public string PickupAddress { get; private set; } = null!;
    public string DeliveryAddress { get; private set; } = null!;
    public double PickupLat { get; private set; }
    public double PickupLng { get; private set; }
    public double DeliveryLat { get; private set; }
    public double DeliveryLng { get; private set; }

    private readonly List<DeliveryEvent> _events = new();
    public IReadOnlyCollection<DeliveryEvent> Events => _events.AsReadOnly();

    private Delivery() { }

    public static Delivery Create(
        Guid orderId,
        string pickupAddress, double pickupLat, double pickupLng,
        string deliveryAddress, double deliveryLat, double deliveryLng)
    {
        return new Delivery
        {
            Id = Guid.NewGuid(),
            OrderId = orderId,
            TrackingNumber = $"DLV-{DateTime.Now:yyyyMMddHHmmss}",
            Provider = DeliveryProvider.Internal,
            PickupAddress = pickupAddress,
            DeliveryAddress = deliveryAddress,
            PickupLat = pickupLat,
            PickupLng = pickupLng,
            DeliveryLat = deliveryLat,
            DeliveryLng = deliveryLng
        };
    }

    public void AssignDriver(Guid driverId, string name, string mobile, string plate)
    {
        DriverId = driverId;
        DriverName = name;
        DriverMobile = mobile;
        DriverPlate = plate;
        Status = DeliveryStatus.Assigned;
        AddEvent(DeliveryEventType.DriverAssigned, $"راننده {name} تخصیص یافت");
    }

    public void UpdateStatus(DeliveryStatus status, string? note = null)
    {
        Status = status;
        AddEvent(status switch
        {
            DeliveryStatus.PickedUp => DeliveryEventType.PickedUp,
            DeliveryStatus.OnTheWay => DeliveryEventType.OnTheWay,
            DeliveryStatus.Delivered => DeliveryEventType.Delivered,
            DeliveryStatus.Failed => DeliveryEventType.Failed,
            _ => DeliveryEventType.StatusChanged
        }, note);
    }

    private void AddEvent(DeliveryEventType type, string? description = null)
    {
        _events.Add(new DeliveryEvent
        {
            Id = Guid.NewGuid(),
            DeliveryId = Id,
            Type = type,
            Description = description,
            OccurredAt = DateTime.UtcNow
        });
    }
}

public enum DeliveryProvider { Internal, SnappBox, Alopeyk, Tipax }
public enum DeliveryStatus { Pending, Assigned, PickedUp, OnTheWay, Delivered, Failed, Cancelled }