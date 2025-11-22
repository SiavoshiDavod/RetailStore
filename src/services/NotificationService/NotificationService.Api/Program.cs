var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCarter();
builder.Services.AddSwaggerGen();
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// Quartz برای Worker
builder.Services.AddQuartz(q =>
{
    q.UseMicrosoftDependencyInjectionJobFactory();
    var jobKey = new JobKey("NotificationWorker");
    q.AddJob<NotificationWorker>(jobKey)
     .AddTrigger(t => t.ForJob(jobKey).WithSimpleSchedule(x => x.WithIntervalInSeconds(10).RepeatForever()));
});
builder.Services.AddQuartzHostedService();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.MapCarter();
app.Run();