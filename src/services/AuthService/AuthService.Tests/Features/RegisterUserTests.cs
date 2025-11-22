// AuthService.UnitTests/Features/RegisterUserTests.cs
public class RegisterUserTests
{
    [Fact]
    public async Task Should_Create_User_And_Assign_Customer_Group()
    {
        var repo = new Mock<IUserRepository>();
        repo.Setup(r => r.ExistsByMobile(It.IsAny<Mobile>(), default))
            .ReturnsAsync(false);

        var handler = new RegisterUser.Handler(repo.Object, new PasswordHasher.Default, new Mock<IEventBus>().Object);

        var command = new RegisterUser.Command("علی احمدی", "+989123456789", null, "Pass123!", UserType.Customer);
        var result = await handler.Handle(command, default);

        result.IsSuccess.Should().BeTrue();
        repo.Verify(r => r.AddAsync(It.Is<User>(u => u.Groups.Any(g => g.Code == "Customer")), default));
    }
}