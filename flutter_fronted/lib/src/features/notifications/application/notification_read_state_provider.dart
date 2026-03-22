import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'last_notification_provider.dart';

const _lastReadNotificationIdKey = 'notifications_last_read_id';

final notificationsReadStateProvider =
    NotifierProvider<NotificationsReadState, String?>(
      NotificationsReadState.new,
    );

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final lastReadId = ref.watch(notificationsReadStateProvider);
  final history = ref.watch(notificationsHistoryProvider);
  return history.maybeWhen(
    data: (items) {
      if (items.isEmpty) return false;
      if (lastReadId == null || lastReadId.isEmpty) return true;
      return items.first.id != lastReadId;
    },
    orElse: () => false,
  );
});

class NotificationsReadState extends Notifier<String?> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _loaded = false;

  @override
  String? build() {
    if (!_loaded) {
      _loaded = true;
      _load();
    }
    return null;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _lastReadNotificationIdKey);
    state = value;
  }

  Future<void> markAsRead(String id) async {
    if (id.isEmpty) return;
    await _storage.write(key: _lastReadNotificationIdKey, value: id);
    state = id;
  }
}

