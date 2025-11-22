// Features/Authentication/RegisterEndpoint.cs
public class RegisterEndpoint : ICarterModule
{
    public void AddRoutes(IEndpointRouteBuilder app)
    {
        app.MapPost("/api/public/register", async (
            RegisterUser.Command command,
            IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.Match(
                success => Results.Created($"/api/users/{success.UserId}", success),
                error => Results.BadRequest(error));
        })
        .WithTags("Public")
        .Produces(201)
        .ProducesProblem(400);
    }
}