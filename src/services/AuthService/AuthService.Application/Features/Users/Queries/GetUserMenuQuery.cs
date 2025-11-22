public static class GetUserMenu
{
    public record Query(Guid UserId) : IRequest<List<MenuItemDto>>;

    public class Handler : IRequestHandler<Query, List<MenuItemDto>>
    {
        private readonly IUserReadRepository _readRepo;
        public async Task<List<MenuItemDto>> Handle(Query request, CancellationToken ct) =>
            await _readRepo.GetUserMenuTreeAsync(request.UserId, ct);
    }
}