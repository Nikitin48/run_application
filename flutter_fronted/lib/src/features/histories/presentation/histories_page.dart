import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../profile/application/profile_controller.dart';
import '../../runs/domain/run_models.dart';
import '../application/run_history_provider.dart';

class HistoriesPage extends ConsumerStatefulWidget {
  const HistoriesPage({super.key});

  @override
  ConsumerState<HistoriesPage> createState() => _HistoriesPageState();
}

class _HistoriesPageState extends ConsumerState<HistoriesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 220) return;
    ref.read(runHistoryProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(runHistoryProvider);
    final meProfileAsync = ref.watch(meProfileProvider);
    final previewAccent = meProfileAsync.maybeWhen(
      data: (profile) => colorFromHexOrDefault(profile.territoryColor),
      orElse: () => Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historiesTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(runHistoryProvider.notifier).refreshList();
        },
        child: historyAsync.when(
          data: (data) {
            if (data.items.isEmpty) {
              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.historiesEmpty),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= data.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return _RunHistoryCard(
                  item: data.items[index],
                  previewAccent: previewAccent,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunHistoryCard extends StatelessWidget {
  const _RunHistoryCard({required this.item, required this.previewAccent});

  final RunHistoryItem item;
  final Color previewAccent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startedLabel = _formatDateTime(item.startedAt) ?? '—';
    final endedLabel = _formatDateTime(item.endedAt) ?? '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.historiesStartedAt}: $startedLabel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.historiesEndedAt}: $endedLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (item.capturePolygons.isNotEmpty || item.trackPoints.length >= 2) ...[
              const SizedBox(height: 12),
              _RunCapturePreview(
                polygons: item.capturePolygons,
                trackPoints: item.trackPoints,
                accent: previewAccent,
              ),
            ],
            const SizedBox(height: 10),
            _MetricRow(
              label: l10n.distance,
              value: formatMeters(item.distanceM),
            ),
            _MetricRow(
              label: l10n.elapsed,
              value: formatDurationMmSs(item.elapsedS),
            ),
            _MetricRow(
              label: l10n.paused,
              value: formatDurationMmSs(item.pausedS),
            ),
            _MetricRow(
              label: l10n.moving,
              value: formatDurationMmSs(item.movingS),
            ),
            _MetricRow(
              label: l10n.capturedArea,
              value: formatAreaM2(item.captureAreaM2),
            ),
            _MetricRow(label: l10n.victims, value: '${item.victimsCount}'),
          ],
        ),
      ),
    );
  }
}

class _RunCapturePreview extends StatefulWidget {
  const _RunCapturePreview({
    required this.polygons,
    required this.trackPoints,
    required this.accent,
  });

  final List<List<RunGeoPoint>> polygons;
  final List<RunGeoPoint> trackPoints;
  final Color accent;

  @override
  State<_RunCapturePreview> createState() => _RunCapturePreviewState();
}

class _RunCapturePreviewState extends State<_RunCapturePreview> {
  // Dark Gray Base has limited native zoom levels; clamp preview zoom to avoid
  // raster upscaling blur on tiny captured polygons.
  static const double _previewMinZoom = 9;
  static const double _previewMaxZoom = 14;
  static const int _previewNativeMaxZoom = 16;
  static const _urlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';

  List<List<LatLng>> get _latLngPolygons => widget.polygons
      .map(
        (ring) => ring
            .map((p) => LatLng(p.lat, p.lng))
            .toList(growable: false),
      )
      .toList(growable: false);

  List<LatLng> get _latLngTrackPoints => widget.trackPoints
      .map((p) => LatLng(p.lat, p.lng))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final polygons = _latLngPolygons;
    final trackPoints = _latLngTrackPoints;
    final previewPoints = <LatLng>[
      for (final ring in polygons) ...ring,
      ...trackPoints,
    ];
    if (previewPoints.isEmpty) return const SizedBox.shrink();
    final bounds = _expandedBounds(_boundsFromPoints(previewPoints));
    final initialCenter = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14,
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(16),
                maxZoom: _previewMaxZoom,
              ),
              minZoom: _previewMinZoom,
              maxZoom: _previewMaxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _urlTemplate,
                userAgentPackageName: 'run_application',
                minZoom: _previewMinZoom,
                maxZoom: _previewMaxZoom,
                maxNativeZoom: _previewNativeMaxZoom,
              ),
              if (polygons.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    for (final ring in polygons)
                      Polygon(
                        points: ring,
                        color: widget.accent.withValues(alpha: 0.26),
                        borderColor: widget.accent.withValues(alpha: 0.95),
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
              if (trackPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackPoints,
                      color: widget.accent.withValues(alpha: 0.95),
                      strokeWidth: 3.2,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLng = double.infinity;
    var maxLng = -double.infinity;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  LatLngBounds _expandedBounds(LatLngBounds bounds) {
    final latSpan = (bounds.north - bounds.south).abs();
    final lngSpan = (bounds.east - bounds.west).abs();
    final latPad = math.max(latSpan * 0.2, 0.0004);
    final lngPad = math.max(lngSpan * 0.2, 0.0004);
    return LatLngBounds(
      LatLng(bounds.south - latPad, bounds.west - lngPad),
      LatLng(bounds.north + latPad, bounds.east + lngPad),
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

String? _formatDateTime(DateTime? dt) {
  if (dt == null) return null;
  return DateFormat('dd.MM.yyyy HH:mm').format(dt);
}
