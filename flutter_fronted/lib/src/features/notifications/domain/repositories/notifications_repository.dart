import '../last_notification.dart';

abstract interface class NotificationsRepository {
  Future<LastNotification?> last();
  Future<List<LastNotification>> history({int limit = 10});
}


