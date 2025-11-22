using FluentResults;
using MediatR;

namespace NotificationService.Application.Features.Notifications.Commands;

public static class SendNotification
{
    public record Command(
        Guid UserId,
        string TemplateCode,
        Dictionary<string, object> Data,
        NotificationChannel? Channel = null,
        NotificationPriority Priority = NotificationPriority.Normal) : IRequest<Result<Guid>>;

    public class Handler : IRequestHandler<Command, Result<Guid>>
    {
        private readonly INotificationRepository _repo;
        private readonly ITemplateService _templateService;
        private readonly IQueueService _queue;
        private readonly IUnitOfWork _uow;

        public Handler(INotificationRepository repo, ITemplateService templateService, 
                       IQueueService queue, IUnitOfWork uow)
        {
            _repo = repo;
            _templateService = templateService;
            _queue = queue;
            _uow = uow;
        }

        public async Task<Result<Guid>> Handle(Command request, CancellationToken ct)
        {
            var template = await _templateService.GetTemplateAsync(request.TemplateCode, request.Channel, ct);
            if (template == null)
                return Result.Fail("TEMPLATE_NOT_FOUND");

            var rendered = _templateService.Render(template, request.Data);

            var notification = Notification.Create(
                request.UserId,
                request.TemplateCode,
                template.Channel,
                request.Data,
                request.Priority);

            notification.Subject = rendered.Subject;
            notification.Body = rendered.Body;

            await _repo.AddAsync(notification, ct);
            await _uow.SaveChangesAsync(ct);

            // ارسال به صف Redis
            await _queue.EnqueueAsync(notification, ct);

            return notification.Id;
        }
    }
}