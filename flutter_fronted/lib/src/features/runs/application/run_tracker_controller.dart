import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/dio_provider.dart';
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
    String? error,
  }) {
    return RunTrackerState(
      phase: phase ?? this.phase,
      startedAt: startedAt ?? this.startedAt,
      points: points ?? this.points,
      pauses: pauses ?? this.pauses,
      countdownSeconds: countdownSeconds,
      lastFinish: lastFinish ?? this.lastFinish,
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
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  RunTrackerState build() {
    ref.onDispose(_dispose);
    return const RunTrackerState.idle();
  }

  Future<void> start() async {
    if (state.phase != RunPhase.idle) return;

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

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online && state.phase == RunPhase.running) {
        _openPause(PauseReason.internetLost);
      } else if (online &&
          state.phase == RunPhase.paused &&
          state.openPause?.reason == PauseReason.internetLost) {
        _closePause();
      }
    });

    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen(
          (pos) {
            // Auto pause if accuracy is too poor (MVP heuristic).
            final accuracy = pos.accuracy;
            if (accuracy.isFinite && accuracy > 35) {
              _openPause(PauseReason.gpsLost);
              return;
            }

            // If we were auto-paused by GPS loss, resume automatically on good fix.
            if (state.phase == RunPhase.paused &&
                state.openPause?.reason == PauseReason.gpsLost) {
              _closePause();
            }

            if (state.phase != RunPhase.running) return;

            // Basic throttle: don't record points too frequently.
            final last = state.points.isEmpty ? null : state.points.last;
            if (last != null) {
              final dt = pos.timestamp.difference(last.ts).inMilliseconds.abs();
              if (dt < 800) return;
            }

            final p = RunPoint(
              lat: pos.latitude,
              lng: pos.longitude,
              ts: DateTime.fromMillisecondsSinceEpoch(
                pos.timestamp.millisecondsSinceEpoch,
                isUtc: true,
              ),
              accuracyM: pos.accuracy,
              speedMps: pos.speed,
              altitudeM: pos.altitude,
            );

            state = state.copyWith(points: [...state.points, p]);
          },
          onError: (_) {
            if (state.phase == RunPhase.running)
              _openPause(PauseReason.gpsLost);
          },
        );
  }

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
    if (state.phase != RunPhase.running && state.phase != RunPhase.paused)
      return;
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

    state = state.copyWith(phase: RunPhase.finishing, error: null);
    try {
      final res = await ref.read(finishRunUseCaseProvider)(req);
      state = const RunTrackerState.idle().copyWith(lastFinish: res);
    } catch (e) {
      state = state.copyWith(phase: RunPhase.running, error: e.toString());
    } finally {
      await _dispose();
    }
  }

  void clearLastFinish() {
    state = state.copyWith(lastFinish: null);
  }

  /// Adds a simulated point (for emulator / test mode).
  /// Works when run is running or paused.
  void addSimulatedPoint({required double lat, required double lng}) {
    if (state.phase != RunPhase.running && state.phase != RunPhase.paused)
      return;
    final p = RunPoint(lat: lat, lng: lng, ts: DateTime.now().toUtc());
    state = state.copyWith(points: [...state.points, p]);
  }

  Future<void> _dispose() async {
    await _posSub?.cancel();
    await _connSub?.cancel();
    _posSub = null;
    _connSub = null;
  }
}
