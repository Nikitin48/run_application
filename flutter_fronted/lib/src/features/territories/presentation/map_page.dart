import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../notifications/application/notification_read_state_provider.dart';
import '../../profile/application/profile_controller.dart';
import '../application/territories_controller.dart';
import '../domain/territory.dart';
import '../../runs/application/run_tracker_controller.dart';
import '../../../core/utils/color_utils.dart';
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
  static const _tileStyles = <_TileStyle>[
    _TileStyle(
      id: 'osm',
      title: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    _TileStyle(
      id: 'carto_voyager',
      title: 'Carto Voyager',
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      supportsRetina: true,
    ),
    _TileStyle(
      id: 'esri_dark_gray',
      title: 'Esri Dark Gray',
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    ),
  ];

  final _mapController = MapController();
  Timer? _debounce;
  Timer? _testMoveTimer;
  Bbox? _bbox;
  bool _followMe = true;
  bool _testMode = false;
  bool _mapReady = false;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _mapPosSub;
  _TileStyle _selectedTileStyle = _tileStyles[2];

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
    _testMoveTimer?.cancel();
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

  void _startSimulatedMove({required double northM, required double eastM}) {
    _testMoveTimer?.cancel();
    _simulateStep(northM: northM, eastM: eastM);
    _testMoveTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      _simulateStep(northM: northM, eastM: eastM);
    });
  }

  void _stopSimulatedMove() {
    _testMoveTimer?.cancel();
    _testMoveTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bbox = _bbox;
    final territoriesAsync = bbox == null
        ? const AsyncValue<List<Territory>>.data([])
        : ref.watch(territoriesForBboxProvider(bbox));

    final meProfileAsync = ref.watch(meProfileProvider);
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);
    final runState = ref.watch(runTrackerProvider);
    final bottomBarInset = 52.0 + 10.0;
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
          PopupMenuButton<_TileStyle>(
            tooltip: 'Стиль карты',
            initialValue: _selectedTileStyle,
            onSelected: (style) => setState(() => _selectedTileStyle = style),
            itemBuilder: (context) {
              return _tileStyles
                  .map(
                    (style) => PopupMenuItem<_TileStyle>(
                      value: style,
                      child: Row(
                        children: [
                          if (style == _selectedTileStyle)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(style.title),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false);
            },
            icon: const Icon(Icons.layers_outlined),
          ),
          IconButton(
            tooltip: 'Уведомления',
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (hasUnread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                urlTemplate: _selectedTileStyle.urlTemplate,
                subdomains: _selectedTileStyle.subdomains,
                retinaMode:
                    _selectedTileStyle.supportsRetina &&
                    MediaQuery.devicePixelRatioOf(context) > 1.0,
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
                error: (_, stackTrace) => const SizedBox.shrink(),
              ),
            ],
          ),
          if (_testMode)
            Positioned(
              right: 12,
              bottom: 170 + bottomBarInset,
              child: _TestPad(
                onMoveStart: ({required northM, required eastM}) {
                  _startSimulatedMove(northM: northM, eastM: eastM);
                },
                onMoveStop: _stopSimulatedMove,
              ),
            ),
          if (runState.phase == RunPhase.finishing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          if (runState.countdownSeconds != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${runState.countdownSeconds}',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.runStartingSoon,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TestPad extends StatelessWidget {
  const _TestPad({
    required this.onMoveStart,
    required this.onMoveStop,
  });

  final void Function({required double northM, required double eastM})
  onMoveStart;
  final VoidCallback onMoveStop;

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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoldMoveButton(
                  icon: Icons.north_west,
                  onStart: () => onMoveStart(northM: 10, eastM: -10),
                  onStop: onMoveStop,
                ),
                _HoldMoveButton(
                  icon: Icons.keyboard_arrow_up,
                  onStart: () => onMoveStart(northM: 10, eastM: 0),
                  onStop: onMoveStop,
                ),
                _HoldMoveButton(
                  icon: Icons.north_east,
                  onStart: () => onMoveStart(northM: 10, eastM: 10),
                  onStop: onMoveStop,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoldMoveButton(
                  icon: Icons.keyboard_arrow_left,
                  onStart: () => onMoveStart(northM: 0, eastM: -10),
                  onStop: onMoveStop,
                ),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text('10m', style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
                _HoldMoveButton(
                  icon: Icons.keyboard_arrow_right,
                  onStart: () => onMoveStart(northM: 0, eastM: 10),
                  onStop: onMoveStop,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HoldMoveButton(
                  icon: Icons.south_west,
                  onStart: () => onMoveStart(northM: -10, eastM: -10),
                  onStop: onMoveStop,
                ),
                _HoldMoveButton(
                  icon: Icons.keyboard_arrow_down,
                  onStart: () => onMoveStart(northM: -10, eastM: 0),
                  onStop: onMoveStop,
                ),
                _HoldMoveButton(
                  icon: Icons.south_east,
                  onStart: () => onMoveStart(northM: -10, eastM: 10),
                  onStop: onMoveStop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldMoveButton extends StatelessWidget {
  const _HoldMoveButton({
    required this.icon,
    required this.onStart,
    required this.onStop,
  });

  final IconData icon;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onStart(),
      onTapUp: (_) => onStop(),
      onTapCancel: onStop,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon),
      ),
    );
  }
}

class _TileStyle {
  const _TileStyle({
    required this.id,
    required this.title,
    required this.urlTemplate,
    this.subdomains = const [],
    this.supportsRetina = false,
  });

  final String id;
  final String title;
  final String urlTemplate;
  final List<String> subdomains;
  final bool supportsRetina;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _TileStyle && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
