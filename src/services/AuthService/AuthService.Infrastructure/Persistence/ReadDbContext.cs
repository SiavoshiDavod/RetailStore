//(PostgreSQL)
public class AuthReadDbContext : DbContext
{
    public DbSet<UserReadModel> Users { get; set; }
    public DbSet<UserMenuReadModel> UserMenus { get; set; }
}