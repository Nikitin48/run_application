import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/services/background_location_service.dart';
import '../../profile/application/profile_controller.dart';
import '../../runs/data/runs_api.dart';
import '../../runs/data/runs_repository.dart';
import '../domain/repositories/runs_repository.dart';
import '../domain/run_models.dart';
import '../domain/usecases/finish_run.dart';

enum RunPhase { idle, running, paused, finishing }

class RunTrackerState {
  const RunTrackerState({
    required this.phase,
    required this.startedAt,
    required this.points,
    required this.pauses,
    required this.countdownSeconds,
    this.lastFinish,
    this.error,
  });

  final RunPhase phase;
  final DateTime? startedAt;
  final List<RunPoint> points;
  final List<RunPause> pauses;
  final int? countdownSeconds;
  final FinishRunResponse? lastFinish;
  final String? error;

  RunPause? get openPause => pauses
      .where((p) => p.isOpen)
      .cast<RunPause?>()
      .firstWhere((p) => p != null, orElse: () => null);

  RunTrackerState copyWith({
    RunPhase? phase,
    DateTime? startedAt,
    List<RunPoint>? points,
    List<RunPause>? pauses,
    int? countdownSeconds,
    FinishRunResponse? lastFinish,
    bool clearLastFinish = false,
    String? error,
  }) {
    return RunTrackerState(
      phase: phase ?? this.phase,
      startedAt: startedAt ?? this.startedAt,
      points: points ?? this.points,
      pauses: pauses ?? this.pauses,
      countdownSeconds: countdownSeconds,
      lastFinish: clearLastFinish ? null : (lastFinish ?? this.lastFinish),
      error: error,
    );
  }

  const RunTrackerState.idle()
    : phase = RunPhase.idle,
      startedAt = null,
      points = const [],
      pauses = const [],
      countdownSeconds = null,
      lastFinish = null,
      error = null;
}

final runsApiProvider = Provider<RunsApi>(
  (ref) => RunsApi(ref.watch(dioProvider)),
);
final runsRepositoryProvider = Provider<RunsRepository>(
  (ref) => RunsRepositoryImpl(ref.watch(runsApiProvider)),
);
final finishRunUseCaseProvider = Provider<FinishRunUseCase>(
  (ref) => FinishRunUseCase(ref.watch(runsRepositoryProvider)),
);

final runTrackerProvider =
    NotifierProvider<RunTrackerController, RunTrackerState>(
      RunTrackerController.new,
    );

class RunTrackerController extends Notifier<RunTrackerState> {
  StreamSubscription<Position>? _posSub;
  StreamSubscription<BgLocationPoint>? _bgSub;
  StreamSubscription<RunNotificationAction>? _runActionSub;
  AppLifecycleListener? _lifecycleListener;
  bool _isUsingBackgroundForCurrentRun = false;
  int? _lastAcceptedPointTimestampMs;

  bool get _useBackgroundService =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  RunTrackerState build() {
    unawaited(_bootstrapNotifications());
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
    listenSelf((_, next) {
      unawaited(_syncRunTrackingNotification(next));
    });
    ref.onDispose(_dispose);
    return const RunTrackerState.idle();
  }

  // ── Notifications ────────────────────────────────────────────────────────

  Future<void> _bootstrapNotifications() async {
    final notifications = ref.read(localNotificationsServiceProvider);
    await notifications.ensureInitialized();
    await _runActionSub?.cancel();
    _runActionSub = notifications.runActions.listen(_onNotificationAction);
    for (final pendingAction in notifications.takePendingRunActions()) {
      _onNotificationAction(pendingAction);
    }
  }

  Future<void> _syncRunTrackingNotification(RunTrackerState nextState) async {
    final notifications = ref.read(localNotificationsServiceProvider);
    if (nextState.phase == RunPhase.running ||
        nextState.phase == RunPhase.paused) {
      await notifications.showRunTracking(
        paused: nextState.phase == RunPhase.paused,
      );
      return;
    }
    await notifications.cancelRunTrackingNotification();
  }

  void _onNotificationAction(RunNotificationAction action) {
    switch (action) {
      case RunNotificationAction.stop:
        pauseManual();
        return;
      case RunNotificationAction.finish:
        unawaited(finish());
        return;
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void _onAppResumed() {
    unawaited(_refreshAfterResume());
  }

  Future<void> _refreshAfterResume() async {
    if (state.phase != RunPhase.running && state.phase != RunPhase.paused) {
      return;
    }

    if (_isUsingBackgroundForCurrentRun) {
      BackgroundLocationService.instance.flushBuffer();
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      _appendPointIfNeeded(pos, allowWhenPaused: false);
    } catch (_) {}
  }

  // ── Start / Stop ─────────────────────────────────────────────────────────

  Future<void> start() async {
    if (state.phase != RunPhase.idle) return;
    if (_runActionSub == null) {
      await _bootstrapNotifications();
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(error: 'Location service disabled');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      state = state.copyWith(error: 'Location permission denied');
      return;
    }

    // Android background service needs "Allow all the time".
    final canUseBackgroundService =
        !_useBackgroundService || perm == LocationPermission.always;
    if (_useBackgroundService && !canUseBackgroundService) {
      state = state.copyWith(
        error:
            'Background GPS disabled: grant "Allow all the time" for location.',
      );
    }

    state = const RunTrackerState.idle().copyWith(
      countdownSeconds: 3,
      error: null,
    );

    for (var seconds = 3; seconds >= 1; seconds--) {
      state = state.copyWith(countdownSeconds: seconds, error: null);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (state.phase != RunPhase.idle) return;
    }

    final startedAt = DateTime.now().toUtc();
    state = RunTrackerState(
      phase: RunPhase.running,
      startedAt: startedAt,
      points: const [],
      pauses: const [],
      countdownSeconds: null,
      lastFinish: null,
      error: null,
    );

    await _posSub?.cancel();
    await _bgSub?.cancel();
    _lastAcceptedPointTimestampMs = null;

    _isUsingBackgroundForCurrentRun = canUseBackgroundService;
    if (_isUsingBackgroundForCurrentRun) {
      await _startAndroidBackgroundTracking();
    } else {
      _startDirectTracking();
    }
  }

  /// Android: GPS runs in a background-isolate foreground service so that
  /// points keep recording when the app is minimised or the screen is off.
  Future<void> _startAndroidBackgroundTracking() async {
    final bg = BackgroundLocationService.instance;
    await bg.startTracking();
    _bgSub = bg.points.listen(
      _onBackgroundPoint,
      onError: (e) {
        state = state.copyWith(error: 'Background location error: $e');
      },
    );
  }

  /// iOS / Web: geolocator stream in the main isolate.
  /// On iOS `allowBackgroundLocationUpdates: true` keeps the stream alive.
  void _startDirectTracking() {
    _posSub =
        Geolocator.getPositionStream(
          locationSettings: _buildLocationSettings(),
        ).listen(
          (pos) => _appendPointIfNeeded(pos),
          onError: (error) {
            state = state.copyWith(error: 'Location stream error: $error');
          },
        );
  }

  LocationSettings _buildLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );
  }

  // ── Point processing ─────────────────────────────────────────────────────

  void _onBackgroundPoint(BgLocationPoint pt) {
    if (state.phase != RunPhase.running) return;

    final accuracy = pt.accuracy;
    if (accuracy.isFinite && accuracy > 65) return;

    final ts = DateTime.fromMillisecondsSinceEpoch(pt.timestampMs, isUtc: true);
    if (!_isPointTimestampNew(ts)) return;
    final last = state.points.isEmpty ? null : state.points.last;
    if (last != null) {
      final dtMs = ts.difference(last.ts).inMilliseconds.abs();
      if (dtMs < 800) return;
      final distanceM = Geolocator.distanceBetween(
        last.lat,
        last.lng,
        pt.lat,
        pt.lng,
      );
      if (distanceM < 1.5 && accuracy > 25) return;
    }

    final point = RunPoint(
      lat: pt.lat,
      lng: pt.lng,
      ts: ts,
      accuracyM: pt.accuracy,
      speedMps: pt.speed,
      altitudeM: pt.altitude,
    );
    _rememberPointTimestamp(ts);
    state = state.copyWith(points: [...state.points, point], error: null);
  }

  void _appendPointIfNeeded(Position pos, {bool allowWhenPaused = false}) {
    if (state.phase != RunPhase.running &&
        (!allowWhenPaused || state.phase != RunPhase.paused)) {
      return;
    }
    final accuracy = pos.accuracy;
    if (accuracy.isFinite && accuracy > 65) return;

    final ts = DateTime.fromMillisecondsSinceEpoch(
      pos.timestamp.millisecondsSinceEpoch,
      isUtc: true,
    );
    if (!_isPointTimestampNew(ts)) return;
    final last = state.points.isEmpty ? null : state.points.last;
    if (last != null) {
      final dtMs = ts.difference(last.ts).inMilliseconds.abs();
      if (dtMs < 800) return;
      final distanceM = Geolocator.distanceBetween(
        last.lat,
        last.lng,
        pos.latitude,
        pos.longitude,
      );
      if (distanceM < 1.5 && accuracy > 25) return;
    }

    final point = RunPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      ts: ts,
      accuracyM: pos.accuracy,
      speedMps: pos.speed,
      altitudeM: pos.altitude,
    );
    _rememberPointTimestamp(ts);
    state = state.copyWith(points: [...state.points, point], error: null);
  }

  // ── Pause / Resume / Finish ──────────────────────────────────────────────

  void pauseManual() {
    if (state.phase == RunPhase.running) _openPause(PauseReason.manual);
  }

  void resume() {
    if (state.phase == RunPhase.paused) _closePause();
  }

  void _openPause(PauseReason reason) {
    if (state.openPause != null) return;
    state = state.copyWith(
      phase: RunPhase.paused,
      pauses: [
        ...state.pauses,
        RunPause(startedAt: DateTime.now().toUtc(), reason: reason),
      ],
    );
  }

  void _closePause() {
    final open = state.openPause;
    if (open == null) {
      state = state.copyWith(phase: RunPhase.running);
      return;
    }
    final closed = open.close(DateTime.now().toUtc());
    final pauses = state.pauses.map((p) => p == open ? closed : p).toList();
    state = state.copyWith(phase: RunPhase.running, pauses: pauses);
  }

  Future<void> finish() async {
    if (state.phase != RunPhase.running && state.phase != RunPhase.paused) {
      return;
    }
    if (state.startedAt == null) return;

    if (state.phase == RunPhase.paused) {
      _closePause();
    }

    final startedAt = state.startedAt!;
    final endedAt = DateTime.now().toUtc();
    final req = FinishRunRequest(
      startedAt: startedAt,
      endedAt: endedAt,
      points: state.points,
      pauses: state.pauses.map((p) => p.isOpen ? p.close(endedAt) : p).toList(),
    );

    var completed = false;
    state = state.copyWith(phase: RunPhase.finishing, error: null);
    try {
      final res = await ref.read(finishRunUseCaseProvider)(req);
      ref.invalidate(meProfileProvider);
      ref.invalidate(myAchievementsProvider);
      state = const RunTrackerState.idle().copyWith(lastFinish: res);
      completed = true;
    } catch (e) {
      state = state.copyWith(phase: RunPhase.running, error: e.toString());
    } finally {
      if (completed) {
        await _stopRunSession();
      }
    }
  }

  void clearLastFinish() {
    state = state.copyWith(clearLastFinish: true);
  }

  /// Adds a simulated point (for emulator / test mode).
  void addSimulatedPoint({required double lat, required double lng}) {
    if (state.phase != RunPhase.running && state.phase != RunPhase.paused) {
      return;
    }
    final p = RunPoint(lat: lat, lng: lng, ts: DateTime.now().toUtc());
    state = state.copyWith(points: [...state.points, p]);
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────

  Future<void> _stopRunSession() async {
    await _posSub?.cancel();
    await _bgSub?.cancel();
    _posSub = null;
    _bgSub = null;

    if (_isUsingBackgroundForCurrentRun) {
      await BackgroundLocationService.instance.stopTracking();
    }
    _isUsingBackgroundForCurrentRun = false;
    _lastAcceptedPointTimestampMs = null;

    await ref
        .read(localNotificationsServiceProvider)
        .cancelRunTrackingNotification();
  }

  Future<void> _dispose() async {
    await _stopRunSession();
    await _runActionSub?.cancel();
    _lifecycleListener?.dispose();
    _runActionSub = null;
    _lifecycleListener = null;
  }

  bool _isPointTimestampNew(DateTime ts) {
    final tsMs = ts.millisecondsSinceEpoch;
    final lastTsMs = _lastAcceptedPointTimestampMs;
    if (lastTsMs != null && tsMs <= lastTsMs) {
      return false;
    }
    return true;
  }

  void _rememberPointTimestamp(DateTime ts) {
    _lastAcceptedPointTimestampMs = ts.millisecondsSinceEpoch;
  }
}
