public class UserRegisteredProjector : IEventHandler<UserRegisteredEvent>
{
    private readonly AuthReadDbContext _readDb;
    public async Task Handle(UserRegisteredEvent @event, CancellationToken ct)
    {
        var readModel = new UserReadModel
        {
            UserId = @event.UserId,
            Mobile = @event.Mobile,
            Groups = new[] { "Customer" },
            Permissions = new[] { "order.create", "product.view" },
            MenuJson = await BuildDefaultCustomerMenu()
        };
        _readDb.Users.Add(readModel);
        await _readDb.SaveChangesAsync(ct);
    }
}