import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_application/l10n/app_localizations.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/run_models.dart';

class RunStatsCard extends StatelessWidget {
  const RunStatsCard({
    super.key,
    this.startedAt,
    this.endedAt,
    this.capturePolygons = const [],
    this.trackPoints = const [],
    required this.previewAccent,
    required this.distanceM,
    required this.elapsedS,
    required this.pausedS,
    required this.movingS,
    required this.captureAreaM2,
    required this.victimsCount,
  });

  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<List<RunGeoPoint>> capturePolygons;
  final List<RunGeoPoint> trackPoints;
  final Color previewAccent;
  final double distanceM;
  final int elapsedS;
  final int pausedS;
  final int movingS;
  final double captureAreaM2;
  final int victimsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startedLabel = _formatDateTime(startedAt) ?? '—';
    final endedLabel = _formatDateTime(endedAt) ?? '—';
    final colorScheme = Theme.of(context).colorScheme;
    final cardRadius = BorderRadius.circular(24);
    final hasHeader = startedAt != null || endedAt != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: cardRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader) ...[
              _HeaderInfoRow(
                icon: Icons.calendar_today_rounded,
                label: l10n.historiesStartedAt,
                value: startedLabel,
              ),
              const SizedBox(height: 10),
              _HeaderInfoRow(
                icon: Icons.flag_outlined,
                label: l10n.historiesEndedAt,
                value: endedLabel,
              ),
            ],
            if (capturePolygons.isNotEmpty || trackPoints.length >= 2) ...[
              if (hasHeader) const SizedBox(height: 14),
              _RunCapturePreview(
                polygons: capturePolygons,
                trackPoints: trackPoints,
                accent: previewAccent,
              ),
            ],
            const SizedBox(height: 14),
            _MetricTileRow(
              icon: Icons.location_on_outlined,
              label: l10n.distance,
              value: formatMeters(distanceM),
            ),
            _MetricTileRow(
              icon: Icons.schedule_rounded,
              label: l10n.elapsed,
              value: formatDurationMmSs(elapsedS),
            ),
            _MetricTileRow(
              icon: Icons.pause_circle_outline_rounded,
              label: l10n.paused,
              value: formatDurationMmSs(pausedS),
            ),
            _MetricTileRow(
              icon: Icons.directions_run_rounded,
              label: l10n.avgPaceMoving,
              value: formatPace(distanceM: distanceM, movingS: movingS),
            ),
            _MetricTileRow(
              icon: Icons.speed_rounded,
              label: l10n.avgSpeedOverall,
              value: formatSpeedKmh(distanceM: distanceM, seconds: elapsedS),
            ),
            _MetricTileRow(
              icon: Icons.square_outlined,
              label: l10n.capturedArea,
              value: formatAreaM2(captureAreaM2),
            ),
            _MetricTileRow(
              icon: Icons.person_outline_rounded,
              label: l10n.victims,
              value: '$victimsCount',
              isLast: true,
            ),
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
  static const double _previewMinZoom = 9;
  static const double _previewMaxZoom = 14;
  static const int _previewNativeMaxZoom = 16;
  static const _urlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';

  List<List<LatLng>> get _latLngPolygons => widget.polygons
      .map(
        (ring) => ring.map((p) => LatLng(p.lat, p.lng)).toList(growable: false),
      )
      .toList(growable: false);

  List<LatLng> get _latLngTrackPoints => widget.trackPoints
      .map((p) => LatLng(p.lat, p.lng))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final polygons = _latLngPolygons;
    final track = _latLngTrackPoints;
    final points = <LatLng>[
      for (final ring in polygons) ...ring,
      ...track,
    ];
    if (points.isEmpty) return const SizedBox.shrink();

    final bounds = _expandedBounds(_boundsFromPoints(points));
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
              if (track.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: track,
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

class _HeaderInfoRow extends StatelessWidget {
  const _HeaderInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 1),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTileRow extends StatelessWidget {
  const _MetricTileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

String? _formatDateTime(DateTime? dt) {
  if (dt == null) return null;
  return DateFormat('dd.MM.yyyy HH:mm').format(dt);
}
