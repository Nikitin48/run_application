import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../notifications/application/last_notification_provider.dart';
import '../../profile/application/profile_controller.dart';
import '../application/territories_controller.dart';
import '../domain/territory.dart';
import '../../runs/application/run_tracker_controller.dart';
import 'widgets/run_controls_card.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/formatters.dart';
import '../domain/value_objects/bbox.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _MapPageBody();
  }
}

class _MapPageBody extends ConsumerStatefulWidget {
  const _MapPageBody();

  @override
  ConsumerState<_MapPageBody> createState() => _MapPageBodyState();
}

class _MapPageBodyState extends ConsumerState<_MapPageBody> {
  final _mapController = MapController();
  Timer? _debounce;
  Bbox? _bbox;
  DateTime? _dismissedAt;
  bool _followMe = true;
  bool _testMode = false;
  bool _mapReady = false;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _mapPosSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCurrentLocation();
      await _startLocationWatch();
    });
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever)
        return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _currentLocation = ll);

      if (_followMe && _mapReady) {
        _mapController.move(ll, _mapController.camera.zoom);
      }
    } catch (_) {
      // ignore for MVP; keep fallback center
    }
  }

  Future<void> _startLocationWatch() async {
    // Keep map location updated even when user is not recording a run.
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      await _mapPosSub?.cancel();
      _mapPosSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 5,
            ),
          ).listen((pos) {
            if (!mounted) return;

            // If a run is in progress, map marker follows the run's last point anyway.
            final runPhase = ref.read(runTrackerProvider).phase;
            if (runPhase == RunPhase.running || runPhase == RunPhase.paused)
              return;

            final ll = LatLng(pos.latitude, pos.longitude);
            setState(() => _currentLocation = ll);
            if (_followMe && _mapReady) {
              _mapController.move(ll, _mapController.camera.zoom);
            }
          });
    } catch (_) {
      // ignore for MVP
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapPosSub?.cancel();
    super.dispose();
  }

  void _scheduleBboxUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final bounds = _mapController.camera.visibleBounds;
      setState(() {
        _bbox = Bbox(
          minLng: bounds.southWest.longitude,
          minLat: bounds.southWest.latitude,
          maxLng: bounds.northEast.longitude,
          maxLat: bounds.northEast.latitude,
        );
      });
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  LatLng _moveByMeters(
    LatLng from, {
    required double northM,
    required double eastM,
  }) {
    // Very small-step approximation: good enough for emulator/test mode.
    final metersPerDegLat = 111320.0;
    final dLat = northM / metersPerDegLat;
    final cosLat = math.cos(from.latitude * (math.pi / 180.0));
    final metersPerDegLng =
        metersPerDegLat * (cosLat.abs() < 0.000001 ? 0.000001 : cosLat.abs());
    final dLng = eastM / metersPerDegLng;
    return LatLng(from.latitude + dLat, from.longitude + dLng);
  }

  void _simulateStep({required double northM, required double eastM}) {
    final base = _currentLocation;
    if (base == null) {
      _showSnack(AppLocalizations.of(context)!.noLocationYet);
      return;
    }
    final next = _moveByMeters(base, northM: northM, eastM: eastM);
    setState(() => _currentLocation = next);

    if (_followMe && _mapReady) {
      _mapController.move(next, _mapController.camera.zoom);
    }

    // If a run is started, also push the simulated point into the run track.
    ref
        .read(runTrackerProvider.notifier)
        .addSimulatedPoint(lat: next.latitude, lng: next.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bbox = _bbox;
    final territoriesAsync = bbox == null
        ? const AsyncValue<List<Territory>>.data([])
        : ref.watch(territoriesForBboxProvider(bbox));

    final meProfileAsync = ref.watch(meProfileProvider);
    final lastNotifAsync = ref.watch(lastNotificationProvider);
    final runState = ref.watch(runTrackerProvider);
    final bottomBarInset = 58.0 + 10.0;
    final myTrackColor = meProfileAsync.maybeWhen(
      data: (profile) => colorFromHexOrDefault(profile.territoryColor),
      orElse: () => Theme.of(context).colorScheme.primary,
    );

    final trackPoints = runState.points
        .map((p) => LatLng(p.lat, p.lng))
        .toList(growable: false);
    final lastPoint = trackPoints.isNotEmpty
        ? trackPoints.last
        : _currentLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            tooltip: _testMode ? l10n.testModeOn : l10n.testModeOff,
            onPressed: () async {
              if (!_testMode && _currentLocation == null) {
                await _loadCurrentLocation();
              }
              if (!mounted) return;
              if (_currentLocation == null) {
                _showSnack(l10n.enableLocationFirst);
                return;
              }
              setState(() => _testMode = !_testMode);
            },
            icon: Icon(_testMode ? Icons.gamepad : Icons.gamepad_outlined),
          ),
          IconButton(
            tooltip: _followMe ? l10n.followOn : l10n.followOff,
            onPressed: () {
              setState(() => _followMe = !_followMe);
              if (_followMe) {
                // Re-fetch current location (useful for emulator when you change mock location).
                _loadCurrentLocation();
              }
              if (_followMe && lastPoint != null) {
                _mapController.move(lastPoint, _mapController.camera.zoom);
              }
            },
            icon: Icon(_followMe ? Icons.gps_fixed : Icons.gps_not_fixed),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Fallback: Moscow. We replace it with current GPS location when available.
              initialCenter:
                  _currentLocation ?? const LatLng(55.75396, 37.620393),
              initialZoom: 15,
              onMapReady: () {
                _mapReady = true;
                _scheduleBboxUpdate();
                final ll = _currentLocation;
                if (_followMe && ll != null) {
                  _mapController.move(ll, _mapController.camera.zoom);
                }
              },
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _followMe) {
                  setState(() => _followMe = false);
                }
                _scheduleBboxUpdate();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'run_application',
              ),
              if (trackPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackPoints,
                      strokeWidth: 4,
                      color: myTrackColor.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              if (lastPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: lastPoint,
                      width: 18,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: myTrackColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              territoriesAsync.when(
                data: (territories) {
                  final polygons = <Polygon>[];
                  for (final t in territories) {
                    final baseColor = colorFromHexOrDefault(
                      t.territoryColorHex,
                    );
                    final fill = baseColor.withValues(alpha: 0.25);
                    final border = baseColor.withValues(alpha: 0.9);
                    for (final ring in t.polygons) {
                      polygons.add(
                        Polygon(
                          points: ring,
                          color: fill,
                          borderColor: border,
                          borderStrokeWidth: 2,
                        ),
                      );
                    }
                  }
                  return PolygonLayer(polygons: polygons);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: lastNotifAsync.when(
              data: (notif) {
                if (notif == null) return const SizedBox.shrink();
                if (_dismissedAt != null &&
                    !_dismissedAt!.isBefore(notif.createdAt)) {
                  return const SizedBox.shrink();
                }

                final area = formatAreaM2(notif.stolenAreaM2);
                return _NotificationBanner(
                  title: l10n.territoryStolenTitle,
                  message: l10n.territoryStolenMessage(area),
                  onClose: () => setState(() => _dismissedAt = DateTime.now()),
                  onRefresh: () => ref.invalidate(lastNotificationProvider),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12 + bottomBarInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RunControlsCard(
                  runState: runState,
                  onStart: () => ref.read(runTrackerProvider.notifier).start(),
                  onPause: () =>
                      ref.read(runTrackerProvider.notifier).pauseManual(),
                  onResume: () =>
                      ref.read(runTrackerProvider.notifier).resume(),
                  onFinish: () async {
                    await ref.read(runTrackerProvider.notifier).finish();
                    // refresh UI data after capture
                    if (_bbox != null) {
                      ref.invalidate(territoriesForBboxProvider(_bbox!));
                    }
                    ref.invalidate(lastNotificationProvider);

                    final finish = ref.read(runTrackerProvider).lastFinish;
                    if (finish != null && mounted) {
                      context.push('/run-summary');
                    } else {
                      _showSnack(l10n.runFinished);
                    }
                  },
                ),
              ],
            ),
          ),
          if (_testMode)
            Positioned(
              right: 12,
              bottom: 170 + bottomBarInset,
              child: _TestPad(
                onUp: () => _simulateStep(northM: 5, eastM: 0),
                onDown: () => _simulateStep(northM: -5, eastM: 0),
                onLeft: () => _simulateStep(northM: 0, eastM: -5),
                onRight: () => _simulateStep(northM: 0, eastM: 5),
              ),
            ),
          if (runState.phase == RunPhase.finishing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

// _InfoPill removed (territories pill hidden for now)

// moved to widgets/run_controls_card.dart

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({
    required this.title,
    required this.message,
    required this.onClose,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.refresh,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.close,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestPad extends StatelessWidget {
  const _TestPad({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
  });

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface.withValues(alpha: 0.9);
    final border = Theme.of(context).colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onUp,
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onLeft,
                  icon: const Icon(Icons.keyboard_arrow_left),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onRight,
                  icon: const Icon(Icons.keyboard_arrow_right),
                ),
              ],
            ),
            IconButton(
              onPressed: onDown,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            const SizedBox(height: 2),
            Text('5m', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
