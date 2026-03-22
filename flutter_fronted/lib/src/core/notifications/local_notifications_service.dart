import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final localNotificationsServiceProvider = Provider<LocalNotificationsService>((
  ref,
) {
  return LocalNotificationsService(ref.watch(flutterLocalNotificationsPluginProvider));
});

class LocalNotificationsService {
  LocalNotificationsService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
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
}

