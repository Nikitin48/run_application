import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/notifications_api.dart';
import '../data/notifications_repository.dart';
import '../domain/last_notification.dart';
import '../domain/repositories/notifications_repository.dart';
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

final lastNotificationProvider = FutureProvider<LastNotification?>((ref) async {
  return ref.watch(getLastNotificationUseCaseProvider)();
});


