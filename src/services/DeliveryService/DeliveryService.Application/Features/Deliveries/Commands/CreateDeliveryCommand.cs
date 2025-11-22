using FluentResults;
using MediatR;

namespace DeliveryService.Application.Features.Deliveries.Commands;

public static class CreateDelivery
{
    public record Command(
        Guid OrderId,
        string PickupAddress,
        double PickupLat,
        double PickupLng,
        string DeliveryAddress,
        double DeliveryLat,
        double DeliveryLng) : IRequest<Result<Response>>;

    public record Response(Guid DeliveryId, string TrackingNumber);

    public class Handler : IRequestHandler<Command, Result<Response>>
    {
        private readonly IDeliveryRepository _repo;
        private readonly IUnitOfWork _uow;
        private readonly IDeliveryProviderService _provider;

        public Handler(IDeliveryRepository repo, IUnitOfWork uow, IDeliveryProviderService provider)
        {
            _repo = repo;
            _uow = uow;
            _provider = provider;
        }

        public async Task<Result<Response>> Handle(Command request, CancellationToken ct)
        {
            var delivery = Delivery.Create(
                request.OrderId,
                request.PickupAddress, request.PickupLat, request.PickupLng,
                request.DeliveryAddress, request.DeliveryLat, request.DeliveryLng);

            // محاسبه هزینه و زمان از طریق اسنپ‌باکس یا ناوگان داخلی
            var quote = await _provider.GetQuoteAsync(delivery, ct);
            delivery.DeliveryFee = quote.Fee;
            delivery.EstimatedDeliveryAt = quote.EstimatedAt;

            await _repo.AddAsync(delivery, ct);
            await _uow.SaveChangesAsync(ct);

            // ارسال به Kafka برای OrderService
            await _publisher.Publish(new DeliveryCreatedEvent(delivery.Id, delivery.OrderId, delivery.TrackingNumber), ct);

            return new Response(delivery.Id, delivery.TrackingNumber);
        }
    }
}