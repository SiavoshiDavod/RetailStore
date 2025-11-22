public class AuthWriteDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();
    public DbSet<UserGroup> UserGroups => Set<UserGroup>();
    public DbSet<Operation> Operations => Set<Operation>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AuthWriteDbContext).Assembly);
        
        // User → UserGroup (Many-to-Many)
        modelBuilder.Entity<User>()
            .HasMany(u => u.Groups)
            .WithMany()
            .UsingEntity(j => j.ToTable("UserGroupMembers"));
    }
}