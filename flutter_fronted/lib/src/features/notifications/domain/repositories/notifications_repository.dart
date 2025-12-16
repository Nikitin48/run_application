import '../last_notification.dart';

abstract interface class NotificationsRepository {
  Future<LastNotification?> last();
}


