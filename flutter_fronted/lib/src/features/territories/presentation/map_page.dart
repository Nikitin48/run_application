import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

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
import '../../runs/domain/run_models.dart';
import '../../../app/home_shell_page.dart'
    show kShellBottomBarHeight, shellBottomSystemInset;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/formatters.dart';
import '../domain/value_objects/bbox.dart';
import 'neon_map_layers.dart';
import 'territory_map_label.dart';

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
  /// Starting zoom; [maxZoom] allows exactly one double-click step above this.
  static const double _mapInitialZoom = 15;
  static const double _mapMaxZoom = _mapInitialZoom + 1;

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
  List<Territory> _territoriesCache = const <Territory>[];
  bool _followMe = true;
  bool _testMode = false;
  bool _mapReady = false;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _mapPosSub;
  _TileStyle _selectedTileStyle = _tileStyles[2];
  static const double _bboxEpsilon = 0.00001;
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
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
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
            if (runPhase == RunPhase.running || runPhase == RunPhase.paused) {
              return;
            }

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
      final nextBbox = Bbox(
        minLng: bounds.southWest.longitude,
        minLat: bounds.southWest.latitude,
        maxLng: bounds.northEast.longitude,
        maxLat: bounds.northEast.latitude,
      );
      final currentBbox = _bbox;
      if (currentBbox != null && _isBboxAlmostEqual(currentBbox, nextBbox)) {
        return;
      }
      setState(() => _bbox = nextBbox);
    });
  }

  bool _isBboxAlmostEqual(Bbox a, Bbox b) {
    return (a.minLng - b.minLng).abs() < _bboxEpsilon &&
        (a.minLat - b.minLat).abs() < _bboxEpsilon &&
        (a.maxLng - b.maxLng).abs() < _bboxEpsilon &&
        (a.maxLat - b.maxLat).abs() < _bboxEpsilon;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleTerritoryTap(
    LatLng point,
    List<_TerritoryAreaTapTarget> targets,
  ) {
    for (final target in targets.reversed) {
      if (_containsPoint(point, target.ring)) {
        _showTerritoryDetails(target);
        return;
      }
    }
  }

  bool _containsPoint(LatLng point, List<LatLng> ring) {
    if (ring.length < 3) return false;
    final x = point.longitude;
    final y = point.latitude;
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].longitude;
      final yi = ring[i].latitude;
      final xj = ring[j].longitude;
      final yj = ring[j].latitude;
      final intersects =
          ((yi > y) != (yj > y)) &&
          (x <
              (xj - xi) *
                      (y - yi) /
                      ((yj - yi).abs() < 1e-12 ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  void _showTerritoryDetails(_TerritoryAreaTapTarget target) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _TerritoryOwnerBottomSheet(
          territory: target.territory,
          areaM2: target.areaM2,
        );
      },
    );
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
    final isAdmin = meProfileAsync.maybeWhen(
      data: (profile) => profile.isAdmin,
      orElse: () => false,
    );
    final latestTerritories = territoriesAsync.valueOrNull;
    if (latestTerritories != null) {
      _territoriesCache = latestTerritories;
    }
    final territories = latestTerritories ?? _territoriesCache;
    final tapTargets = <_TerritoryAreaTapTarget>[
      for (final t in territories)
        for (var i = 0; i < t.polygons.length; i++)
          _TerritoryAreaTapTarget(
            territory: t,
            polygonIndex: i,
            ring: t.polygons[i],
          ),
    ];
    // Reserve space for the shell's bottom bar (notch + tabs) plus the
    // system navigation bar so floating overlays (TestPad etc.) never sit
    // under the bar regardless of gesture vs 3-button mode.
    final bottomBarInset =
        kShellBottomBarHeight + 10.0 + shellBottomSystemInset(context);
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
          if (isAdmin)
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
                                color: Theme.of(context).colorScheme.secondary,
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
                        color: Theme.of(context).colorScheme.error,
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
          if (isAdmin)
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
              icon: Icon(
                _testMode ? Icons.gamepad : Icons.gamepad_outlined,
                color: _testMode ? AppColors.secondPrimary : AppColors.text,
              ),
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
            icon: Icon(
              _followMe ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _followMe ? AppColors.secondPrimary : AppColors.text,
            ),
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
              initialZoom: _mapInitialZoom,
              maxZoom: _mapMaxZoom,
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
              onTap: (_, point) => _handleTerritoryTap(point, tapTargets),
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
                  polylines: buildNeonTrackPolylines(
                    points: trackPoints,
                    baseColor: myTrackColor,
                  ),
                ),
              if (lastPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: lastPoint,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: _NeonUserMarker(color: myTrackColor),
                    ),
                  ],
                ),
              ...() {
                final polygons = <Polygon>[];
                final labelMarkers = <Marker>[];
                for (final t in territories) {
                  final baseColor = colorFromHexOrDefault(t.territoryColorHex);
                  for (var i = 0; i < t.polygons.length; i++) {
                    final ring = t.polygons[i];
                    appendNeonTerritoryRing(
                      polygons,
                      ring: ring,
                      baseColor: baseColor,
                    );
                    final anchor = polygonRingCentroid(ring);
                    if (anchor != null && t.displayName.isNotEmpty) {
                      labelMarkers.add(
                        Marker(
                          key: ValueKey('territory-label-${t.userId}-$i'),
                          point: anchor,
                          width: 132,
                          height: 28,
                          alignment: Alignment.center,
                          rotate: true,
                          child: TerritoryDisplayNameMapLabel(
                            displayName: t.displayName,
                            territoryColorHex: t.territoryColorHex,
                          ),
                        ),
                      );
                    }
                  }
                }
                return <Widget>[
                  PolygonLayer(polygons: polygons),
                  if (labelMarkers.isNotEmpty)
                    MarkerLayer(markers: labelMarkers),
                ];
              }(),
            ],
          ),
          if (_testMode && isAdmin)
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
          if (runState.phase == RunPhase.running ||
              runState.phase == RunPhase.paused)
            Positioned(
              top: 12,
              left: 12,
              child: _RunLiveStatsCard(runState: runState),
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
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.runStartingSoon,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.text),
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
  const _TestPad({required this.onMoveStart, required this.onMoveStop});

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
                    child: Text(
                      '10m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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

class _NeonUserMarker extends StatelessWidget {
  const _NeonUserMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final accent = neonAccent(color);
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: AppColors.text.withValues(alpha: 0.92),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.75),
              blurRadius: 14,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: 0,
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
      child: SizedBox(width: 40, height: 40, child: Icon(icon)),
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

class _RunLiveStatsCard extends StatelessWidget {
  const _RunLiveStatsCard({required this.runState});

  final RunTrackerState runState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.97),
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.82),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: StreamBuilder<int>(
                stream: Stream<int>.periodic(
                  const Duration(seconds: 1),
                  (x) => x,
                ),
                initialData: 0,
                builder: (context, _) {
                  final now = DateTime.now().toUtc();
                  final elapsedS = _elapsedSeconds(runState.startedAt, now);
                  final pausedS = _pausedSeconds(runState.pauses, now);
                  final movingS = (elapsedS - pausedS).clamp(0, elapsedS);
                  final distanceM = _distanceMeters(runState.points);
                  final pace = formatPace(
                    distanceM: distanceM,
                    movingS: movingS,
                  );
                  return Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _buildLiveMetricRow(
                        icon: Icons.directions_run_rounded,
                        label: l10n.avgPaceMoving,
                        value: pace,
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      _buildLiveMetricRow(
                        icon: Icons.straighten_rounded,
                        label: l10n.distance,
                        value: formatMeters(distanceM),
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                      _buildLiveMetricRow(
                        icon: Icons.timer_outlined,
                        label: l10n.elapsed,
                        value: formatDurationMmSs(elapsedS),
                        labelStyle: labelStyle,
                        valueStyle: valueStyle,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TableRow _buildLiveMetricRow({
  required IconData icon,
  required String label,
  required String value,
  required TextStyle? labelStyle,
  required TextStyle? valueStyle,
}) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 4, right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.88)),
            const SizedBox(width: 6),
            Text(label, style: labelStyle),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(value, style: valueStyle),
      ),
    ],
  );
}

int _elapsedSeconds(DateTime? startedAt, DateTime nowUtc) {
  if (startedAt == null) return 0;
  return nowUtc.difference(startedAt).inSeconds.clamp(0, 1 << 31);
}

int _pausedSeconds(List<RunPause> pauses, DateTime nowUtc) {
  var total = 0;
  for (final pause in pauses) {
    final endedAt = pause.endedAt ?? nowUtc;
    final part = endedAt.difference(pause.startedAt).inSeconds;
    if (part > 0) total += part;
  }
  return total;
}

double _distanceMeters(List<RunPoint> points) {
  if (points.length < 2) return 0;
  var sum = 0.0;
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final curr = points[i];
    sum += Geolocator.distanceBetween(prev.lat, prev.lng, curr.lat, curr.lng);
  }
  return sum;
}

class _TerritoryAreaTapTarget {
  const _TerritoryAreaTapTarget({
    required this.territory,
    required this.polygonIndex,
    required this.ring,
  });

  final Territory territory;
  final int polygonIndex;
  final List<LatLng> ring;

  double get areaM2 {
    if (polygonIndex < territory.polygonAreasM2.length) {
      return territory.polygonAreasM2[polygonIndex];
    }
    if (territory.polygons.length == 1) return territory.areaM2;
    return 0;
  }
}

class _TerritoryOwnerBottomSheet extends StatelessWidget {
  const _TerritoryOwnerBottomSheet({
    required this.territory,
    required this.areaM2,
  });

  final Territory territory;
  final double areaM2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final stats = territory.stats;
    final sharePercent = stats.ownedAreaM2 <= 0
        ? 0
        : ((areaM2 / stats.ownedAreaM2) * 100).clamp(0, 100);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + insets),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorFromHexOrDefault(
                      territory.territoryColorHex,
                    ).withValues(alpha: 0.2),
                    backgroundImage: territory.avatarUrl?.isNotEmpty == true
                        ? NetworkImage(territory.avatarUrl!)
                        : null,
                    child: territory.avatarUrl?.isNotEmpty == true
                        ? null
                        : Icon(
                            Icons.person,
                            color: colorFromHexOrDefault(
                              territory.territoryColorHex,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      territory.displayName.isEmpty
                          ? 'Игрок'
                          : territory.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StatsSectionCard(
                title: 'Статистика данной области',
                children: [
                  _MetricRow(
                    label: l10n.capturedArea,
                    value: formatAreaM2(areaM2),
                  ),
                  _MetricRow(
                    label: 'Доля от всей территории',
                    value: '${sharePercent.toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatsSectionCard(
                title: 'Общая статистика пользователя',
                children: [
                  _MetricRow(
                    label: l10n.profileRunsCount,
                    value: '${stats.runCount}',
                  ),
                  _MetricRow(
                    label: l10n.distance,
                    value: formatMeters(stats.totalDistanceM),
                  ),
                  _MetricRow(
                    label: l10n.elapsed,
                    value: formatDurationMmSs(stats.totalElapsedS),
                  ),
                  _MetricRow(
                    label: l10n.paused,
                    value: formatDurationMmSs(stats.totalPausedS),
                  ),
                  _MetricRow(
                    label: l10n.moving,
                    value: formatDurationMmSs(stats.totalMovingS),
                  ),
                  _MetricRow(
                    label: l10n.profileOwnedArea,
                    value: formatAreaM2(stats.ownedAreaM2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSectionCard extends StatelessWidget {
  const _StatsSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
