import '../last_notification.dart';
import '../repositories/notifications_repository.dart';

class GetLastNotificationUseCase {
  GetLastNotificationUseCase(this._repo);

  final NotificationsRepository _repo;

  Future<LastNotification?> call() => _repo.last();
}


