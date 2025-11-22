app.MapPost("/api/notifications/send", async (SendNotification.Command cmd, IMediator m) =>
{
    var result = await m.Send(cmd);
    return result.Match(Results.Ok, Results.BadRequest);
});