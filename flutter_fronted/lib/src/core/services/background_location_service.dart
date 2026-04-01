import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Lightweight DTO for GPS points exchanged between isolates.
class BgLocationPoint {
  final double lat;
  final double lng;
  final int timestampMs;
  final double accuracy;
  final double speed;
  final double altitude;

  const BgLocationPoint({
    required this.lat,
    required this.lng,
    required this.timestampMs,
    required this.accuracy,
    required this.speed,
    required this.altitude,
  });

  factory BgLocationPoint.fromMap(Map<String, dynamic> m) => BgLocationPoint(
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    timestampMs: (m['ts'] as num).toInt(),
    accuracy: (m['acc'] as num?)?.toDouble() ?? 0,
    speed: (m['spd'] as num?)?.toDouble() ?? 0,
    altitude: (m['alt'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'ts': timestampMs,
    'acc': accuracy,
    'spd': speed,
    'alt': altitude,
  };
}

/// Reuse the same channel that [LocalNotificationsService] creates for
/// run-tracking so the channel already exists by the time we start.
const _bgChannelId = 'run_tracking';
const _bgChannelName = 'Run tracking';

/// Manages a background-isolate GPS stream on Android.
///
/// On iOS the native CLLocationManager background mode is sufficient,
/// so this service is only used on Android to keep a Dart isolate alive
/// inside a foreground service.
class BackgroundLocationService {
  BackgroundLocationService._();
  static final instance = BackgroundLocationService._();

  final _service = FlutterBackgroundService();
  bool _configured = false;

  StreamSubscription<Map<String, dynamic>?>? _locSub;
  StreamSubscription<Map<String, dynamic>?>? _bufSub;

  final _pointsCtrl = StreamController<BgLocationPoint>.broadcast();

  /// Points received from the background isolate (real-time + buffered).
  Stream<BgLocationPoint> get points => _pointsCtrl.stream;

  /// Ensures the notification channel exists and the service is configured.
  Future<void> _ensureReady() async {
    if (_configured) return;

    // Guarantee the notification channel exists before the service starts.
    final flnPlugin = FlutterLocalNotificationsPlugin();
    final androidImpl = flnPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _bgChannelId,
          _bgChannelName,
          description: 'Background location tracking during runs',
          importance: Importance.low,
        ),
      );
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: bgOnStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _bgChannelId,
        initialNotificationTitle: 'Идёт пробежка',
        initialNotificationContent: 'Маршрут записывается в фоне',
        foregroundServiceNotificationId: 901,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: bgOnStart,
        onBackground: bgOnIosBackground,
      ),
    );

    _configured = true;
  }

  Future<void> startTracking() async {
    await _ensureReady();

    // Kill any zombie service left from a previous crash.
    final alreadyRunning = await _service.isRunning();
    if (alreadyRunning) {
      _service.invoke('stopGps');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await _service.startService();

    _locSub?.cancel();
    _bufSub?.cancel();

    _locSub = _service.on('loc').listen((data) {
      if (data == null) return;
      _pointsCtrl.add(BgLocationPoint.fromMap(data));
    });

    _bufSub = _service.on('buf').listen((data) {
      if (data == null) return;
      final list = data['pts'] as List<dynamic>?;
      if (list == null) return;
      for (final raw in list) {
        _pointsCtrl.add(
          BgLocationPoint.fromMap(Map<String, dynamic>.from(raw as Map)),
        );
      }
    });

    _service.invoke('startGps');
  }

  /// Ask the background isolate to flush its point buffer.
  /// Responses arrive via the [points] stream.
  void flushBuffer() {
    _service.invoke('flush');
  }

  Future<void> stopTracking() async {
    _locSub?.cancel();
    _bufSub?.cancel();
    _locSub = null;
    _bufSub = null;
    _service.invoke('stopGps');
  }

  void dispose() {
    _locSub?.cancel();
    _bufSub?.cancel();
    _pointsCtrl.close();
  }
}

// ─── Background isolate entry points ────────────────────────────────────────

@pragma('vm:entry-point')
void bgOnStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  StreamSubscription<Position>? posSub;
  final buffer = <Map<String, dynamic>>[];

  service.on('startGps').listen((_) async {
    await posSub?.cancel();
    buffer.clear();

    posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      final data = <String, dynamic>{
        'lat': pos.latitude,
        'lng': pos.longitude,
        'ts': pos.timestamp.millisecondsSinceEpoch,
        'acc': pos.accuracy,
        'spd': pos.speed,
        'alt': pos.altitude,
      };
      buffer.add(data);
      service.invoke('loc', data);
    });
  });

  service.on('flush').listen((_) {
    final snapshot = List<Map<String, dynamic>>.from(buffer);
    buffer.clear();
    service.invoke('buf', {'pts': snapshot});
  });

  service.on('stopGps').listen((_) async {
    await posSub?.cancel();
    posSub = null;
    buffer.clear();
    await service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> bgOnIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
