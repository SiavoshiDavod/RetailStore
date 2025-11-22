using Carter;
using MediatR;

public class CreateDeliveryEndpoint : ICarterModule
{
    public void AddRoutes(IEndpointRouteBuilder app)
    {
        app.MapPost("/api/deliveries", async (
            CreateDelivery.Command cmd,
            IMediator mediator) =>
        {
            var result = await mediator.Send(cmd);
            return result.Match(
                success => Results.Created($"/api/deliveries/{success.DeliveryId}", success),
                error => Results.BadRequest(error));
        })
        .WithTags("Deliveries")
        .Produces(201)
        .ProducesProblem(400);
    }
}