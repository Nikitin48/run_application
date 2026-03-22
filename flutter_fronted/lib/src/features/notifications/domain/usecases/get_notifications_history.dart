import '../last_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsHistoryUseCase {
  GetNotificationsHistoryUseCase(this._repo);

  final NotificationsRepository _repo;

  Future<List<LastNotification>> call({int limit = 10}) {
    return _repo.history(limit: limit);
  }
}

