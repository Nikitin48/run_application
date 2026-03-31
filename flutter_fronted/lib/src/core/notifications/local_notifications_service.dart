import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _runActionPortName = 'run_notification_actions_port';
const _runTrackingNotificationId = 2001;
const _runTrackingChannelId = 'run_tracking';
const _runTrackingChannelName = 'Run tracking';
const _runTrackingCategoryId = 'run_tracking_actions';
const _runActionStopId = 'run_action_stop';
const _runActionFinishId = 'run_action_finish';

enum RunNotificationAction { stop, finish }

RunNotificationAction? _parseRunAction(String? actionId) {
  return switch (actionId) {
    _runActionStopId => RunNotificationAction.stop,
    _runActionFinishId => RunNotificationAction.finish,
    _ => null,
  };
}

@pragma('vm:entry-point')
void onBackgroundNotificationTap(NotificationResponse response) {
  final action = _parseRunAction(response.actionId);
  if (action == null) return;
  final port = IsolateNameServer.lookupPortByName(_runActionPortName);
  port?.send(action.name);
}

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final localNotificationsServiceProvider = Provider<LocalNotificationsService>((
  ref,
) {
  return LocalNotificationsService(
    ref.watch(flutterLocalNotificationsPluginProvider),
  );
});

class LocalNotificationsService {
  LocalNotificationsService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  final _runActionController =
      StreamController<RunNotificationAction>.broadcast();
  final List<RunNotificationAction> _pendingRunActions =
      <RunNotificationAction>[];
  final _runActionPort = ReceivePort();
  bool _initialized = false;

  Stream<RunNotificationAction> get runActions => _runActionController.stream;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    IsolateNameServer.removePortNameMapping(_runActionPortName);
    IsolateNameServer.registerPortWithName(
      _runActionPort.sendPort,
      _runActionPortName,
    );
    _runActionPort.listen((message) {
      if (message is! String) return;
      final action = RunNotificationAction.values.firstWhere(
        (item) => item.name == message,
        orElse: () => RunNotificationAction.stop,
      );
      _emitRunAction(action);
    });

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _runTrackingCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              _runActionStopId,
              'Остановить',
              options: {DarwinNotificationActionOption.authenticationRequired},
            ),
            DarwinNotificationAction.plain(
              _runActionFinishId,
              'Завершить',
              options: {
                DarwinNotificationActionOption.authenticationRequired,
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
          options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
        ),
      ],
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final action = _parseRunAction(response.actionId);
        if (action != null) _emitRunAction(action);
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  Future<void> showTerritoryAttacked({required String attackerName}) async {
    await ensureInitialized();
    const androidDetails = AndroidNotificationDetails(
      'territory_attacked',
      'Territory attacks',
      channelDescription: 'Notifications about captured territory',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      1001,
      'Ваша территория была атакована',
      '$attackerName захватил вашу территорию',
      details,
    );
  }

  Future<void> showRunTracking({required bool paused}) async {
    await ensureInitialized();
    const androidDetails = AndroidNotificationDetails(
      _runTrackingChannelId,
      _runTrackingChannelName,
      channelDescription: 'Ongoing notification for active run tracking',
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.service,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      actions: [
        AndroidNotificationAction(
          _runActionStopId,
          'Остановить',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          _runActionFinishId,
          'Завершить',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      categoryIdentifier: _runTrackingCategoryId,
      interruptionLevel: InterruptionLevel.passive,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      _runTrackingNotificationId,
      paused ? 'Пробежка на паузе' : 'Идет пробежка',
      paused
          ? 'Нажмите «Завершить», чтобы отправить маршрут'
          : 'Маршрут записывается в фоне',
      details,
    );
  }

  Future<void> cancelRunTrackingNotification() async {
    await _plugin.cancel(_runTrackingNotificationId);
  }

  List<RunNotificationAction> takePendingRunActions() {
    if (_pendingRunActions.isEmpty) return const <RunNotificationAction>[];
    final actions = List<RunNotificationAction>.from(_pendingRunActions);
    _pendingRunActions.clear();
    return actions;
  }

  void _emitRunAction(RunNotificationAction action) {
    if (_runActionController.hasListener) {
      _runActionController.add(action);
      return;
    }
    _pendingRunActions.add(action);
  }

  Future<void> dispose() async {
    IsolateNameServer.removePortNameMapping(_runActionPortName);
    _runActionPort.close();
    await _runActionController.close();
  }
}
