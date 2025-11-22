// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthDomain()
    .AddApplication()
    .AddInfrastructure(builder.Configuration)
    .AddApiBehavior();

var app = builder.Build();

app.MapCarter(); // تمام endpointها در Features
app.UseAuthentication();
app.UseAuthorization();
app.Run();

