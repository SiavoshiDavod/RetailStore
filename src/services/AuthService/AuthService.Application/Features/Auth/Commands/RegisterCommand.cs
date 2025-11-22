// Features/Authentication/Commands/RegisterCommand.cs
public static class RegisterUser
{
    public record Command(
        string FullName,
        string Mobile,
        string? Email,
        string Password,
        UserType UserType) : IRequest<Result<Response>>;

    public record Response(Guid UserId, string Mobile);

    public class Handler : IRequestHandler<Command, Result<Response>>
    {
        private readonly IUserRepository _userRepo;
        private readonly IPasswordHasher _hasher;
        private readonly IEventBus _eventBus;

        public async Task<Result<Response>> Handle(Command request, CancellationToken ct)
        {
            if (await _userRepo.ExistsByMobile(request.Mobile, ct))
                return Result.Failure<Response>("MOBILE_EXISTS");

            var user = User.Create(
                request.FullName,
                Mobile.From(request.Mobile),
                request.Email,
                _hasher.Hash(request.Password),
                request.UserType);

            // اختصاص گروه پیش‌فرض
            var defaultGroup = await _userRepo.GetDefaultGroupForType(request.UserType, ct);
            user.AssignToGroup(defaultGroup);

            await _userRepo.AddAsync(user, ct);
            await _eventBus.Publish(new UserRegisteredEvent(user.Id, user.Mobile), ct);

            return new Response(user.Id, user.Mobile);
        }
    }
}