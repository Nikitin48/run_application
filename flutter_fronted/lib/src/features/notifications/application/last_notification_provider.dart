import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../data/notifications_api.dart';
import '../data/notifications_repository.dart';
import '../domain/last_notification.dart';
import '../domain/repositories/notifications_repository.dart';
import '../domain/usecases/get_notifications_history.dart';
import '../domain/usecases/get_last_notification.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(dioProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsApiProvider));
});

final getLastNotificationUseCaseProvider = Provider<GetLastNotificationUseCase>((ref) {
  return GetLastNotificationUseCase(ref.watch(notificationsRepositoryProvider));
});

final getNotificationsHistoryUseCaseProvider =
    Provider<GetNotificationsHistoryUseCase>((ref) {
      return GetNotificationsHistoryUseCase(
        ref.watch(notificationsRepositoryProvider),
      );
    });

final lastNotificationProvider = FutureProvider<LastNotification?>((ref) async {
  return ref.watch(getLastNotificationUseCaseProvider)();
});

final notificationsHistoryProvider = FutureProvider<List<LastNotification>>((
  ref,
) async {
  return ref.watch(getNotificationsHistoryUseCaseProvider)(limit: 10);
});

final notificationsPollingControllerProvider =
    NotifierProvider<NotificationsPollingController, void>(
      NotificationsPollingController.new,
    );

class NotificationsPollingController extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    final status = ref.watch(authControllerProvider).status;
    if (status != AuthStatus.authenticated) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _ensureStarted();
  }

  void _ensureStarted() {
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      _poll();
    });
    _poll();
  }

  Future<void> _poll() async {
    try {
      await ref.read(getNotificationsHistoryUseCaseProvider)(limit: 10);
      ref.invalidate(notificationsHistoryProvider);
    } catch (_) {
      // Keep polling; network errors are expected occasionally.
    }
  }
}

