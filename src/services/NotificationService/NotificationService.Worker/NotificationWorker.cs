using Quartz;

[DisallowConcurrentExecution]
public class NotificationWorker : IJob
{
    private readonly IQueueService _queue;
    private readonly INotificationSender _sender;
    private readonly INotificationRepository _repo;
    private readonly IUnitOfWork _uow;

    public NotificationWorker(IQueueService queue, INotificationSender sender, 
                               INotificationRepository repo, IUnitOfWork uow)
    {
        _queue = queue;
        _sender = sender;
        _repo = repo;
        _uow = uow;
    }

    public async Task Execute(IJobExecutionContext context)
    {
        var notifications = await _queue.DequeueBatchAsync(50);

        foreach (var notification in notifications)
        {
            try
            {
                var result = await _sender.SendAsync(notification);
                if (result.IsSuccess)
                    notification.MarkAsSent(result.Value);
                else
                    notification.MarkAsFailed(result.Errors.First().Message);
            }
            catch (Exception ex)
            {
                notification.MarkAsFailed(ex.Message);
            }

            await _uow.SaveChangesAsync();
        }
    }
}