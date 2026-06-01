import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Boosts saturation (and slightly lightness) so user colors read as "neon" on dark tiles.
Color neonAccent(Color base) {
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withSaturation((hsl.saturation * 1.28).clamp(0.0, 1.0))
      .withLightness((hsl.lightness * 1.06 + 0.02).clamp(0.0, 1.0))
      .toColor();
}

List<Polyline> buildNeonTrackPolylines({
  required List<LatLng> points,
  required Color baseColor,
}) {
  final accent = neonAccent(baseColor);
  final core = Color.lerp(accent, Colors.white, 0.22)!;
  return [
    Polyline(
      points: points,
      strokeWidth: 17,
      color: accent.withValues(alpha: 0.14),
    ),
    Polyline(
      points: points,
      strokeWidth: 9,
      color: accent.withValues(alpha: 0.38),
    ),
    Polyline(
      points: points,
      strokeWidth: 3.5,
      color: core.withValues(alpha: 0.96),
    ),
  ];
}

/// Appends glow outline then filled polygon so each ring stays visually grouped.
void appendNeonTerritoryRing(
  List<Polygon> out, {
  required List<LatLng> ring,
  required Color baseColor,
}) {
  final accent = neonAccent(baseColor);
  final rim = Color.lerp(accent, Colors.white, 0.32)!;
  out.add(
    Polygon(
      points: ring,
      color: Colors.transparent,
      borderColor: accent.withValues(alpha: 0.42),
      borderStrokeWidth: 9,
    ),
  );
  out.add(
    Polygon(
      points: ring,
      color: accent.withValues(alpha: 0.18),
      borderColor: rim.withValues(alpha: 0.92),
      borderStrokeWidth: 2.5,
    ),
  );
}

void appendContestedTerritoryRing(
  List<Polygon> out, {
  required List<LatLng> ring,
  required List<Color> participantColors,
}) {
  final colors = participantColors.isEmpty ? [Colors.white] : participantColors;
  final fillAlpha = (0.34 / colors.length).clamp(0.14, 0.28);

  for (final color in colors) {
    final accent = neonAccent(color);
    out.add(
      Polygon(
        points: ring,
        color: accent.withValues(alpha: fillAlpha),
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      ),
    );
  }

  for (var i = 0; i < colors.length; i++) {
    final accent = neonAccent(colors[i]);
    out.add(
      Polygon(
        points: ring,
        color: Colors.transparent,
        borderColor: accent.withValues(alpha: 0.88),
        borderStrokeWidth: (7.0 - i * 1.4).clamp(2.8, 7.0),
      ),
    );
  }

  out.add(
    Polygon(
      points: ring,
      color: Colors.transparent,
      borderColor: Colors.white.withValues(alpha: 0.55),
      borderStrokeWidth: 1.6,
    ),
  );
}

/// Ground-aligned grid clipped to the contested polygon (drawn above fills).
void appendContestedTerritoryGrid(
  List<Polyline> out, {
  required List<LatLng> ring,
  double spacingM = 22,
}) {
  out.addAll(
    buildContestedTerritoryGridPolylines(ring: ring, spacingM: spacingM),
  );
}

List<Polyline> buildContestedTerritoryGridPolylines({
  required List<LatLng> ring,
  double spacingM = 22,
}) {
  final openRing = _openPolygonRing(ring);
  if (openRing.length < 3) return const [];

  const distance = Distance();
  final anchor = _ringCentroid(openRing);
  final enRing = openRing
      .map((p) => _En(_eastM(distance, anchor, p), _northM(distance, anchor, p)))
      .toList(growable: false);

  var minE = enRing.first.east;
  var maxE = minE;
  var minN = enRing.first.north;
  var maxN = minN;
  for (final p in enRing) {
    minE = math.min(minE, p.east);
    maxE = math.max(maxE, p.east);
    minN = math.min(minN, p.north);
    maxN = math.max(maxN, p.north);
  }

  final spanE = maxE - minE;
  final spanN = maxN - minN;
  final maxSpan = math.max(spanE, spanN);
  if (maxSpan < 1) return const [];

  var step = spacingM;
  const maxLinesPerAxis = 72;
  final lineCountE = (spanE / step).ceil() + 1;
  final lineCountN = (spanN / step).ceil() + 1;
  if (lineCountE > maxLinesPerAxis || lineCountN > maxLinesPerAxis) {
    step = math.max(spanE, spanN) / maxLinesPerAxis;
  }

  final gridColor = Colors.white.withValues(alpha: 0.42);
  const strokeWidth = 1.15;
  final segments = <List<LatLng>>[];

  for (var e = minE; e <= maxE + step * 0.5; e += step) {
    _appendClippedGridSegments(
      segments,
      anchor: anchor,
      distance: distance,
      enRing: enRing,
      a: _En(e, minN),
      b: _En(e, maxN),
    );
  }
  for (var n = minN; n <= maxN + step * 0.5; n += step) {
    _appendClippedGridSegments(
      segments,
      anchor: anchor,
      distance: distance,
      enRing: enRing,
      a: _En(minE, n),
      b: _En(maxE, n),
    );
  }

  return [
    for (final pts in segments)
      if (pts.length >= 2)
        Polyline(
          points: pts,
          strokeWidth: strokeWidth,
          color: gridColor,
          strokeCap: StrokeCap.butt,
        ),
  ];
}

void _appendClippedGridSegments(
  List<List<LatLng>> out, {
  required LatLng anchor,
  required Distance distance,
  required List<_En> enRing,
  required _En a,
  required _En b,
}) {
  for (final segment in _clipSegmentToPolygon(a, b, enRing)) {
    out.add([
      _enToLatLng(distance, anchor, segment.$1),
      _enToLatLng(distance, anchor, segment.$2),
    ]);
  }
}

List<(_En, _En)> _clipSegmentToPolygon(_En a, _En b, List<_En> ring) {
  final params = <double>{0, 1};
  for (var i = 0; i < ring.length; i++) {
    final c = ring[i];
    final d = ring[(i + 1) % ring.length];
    final t = _segmentIntersectionParam(a, b, c, d);
    if (t != null) params.add(t);
  }

  final sorted = params.toList()..sort();
  final inside = <(_En, _En)>[];
  for (var i = 0; i < sorted.length - 1; i++) {
    final t0 = sorted[i];
    final t1 = sorted[i + 1];
    if (t1 - t0 < 1e-9) continue;
    final mid = _En(
      a.east + (b.east - a.east) * (t0 + t1) / 2,
      a.north + (b.north - a.north) * (t0 + t1) / 2,
    );
    if (_pointInPolygon(mid, ring)) {
      inside.add((
        _En(
          a.east + (b.east - a.east) * t0,
          a.north + (b.north - a.north) * t0,
        ),
        _En(
          a.east + (b.east - a.east) * t1,
          a.north + (b.north - a.north) * t1,
        ),
      ));
    }
  }
  return inside;
}

double? _segmentIntersectionParam(_En a, _En b, _En c, _En d) {
  final rxe = b.east - a.east;
  final ryn = b.north - a.north;
  final sxe = d.east - c.east;
  final syn = d.north - c.north;
  final denom = rxe * syn - ryn * sxe;
  if (denom.abs() < 1e-12) return null;

  final qpx = c.east - a.east;
  final qpy = c.north - a.north;
  final t = (qpx * syn - qpy * sxe) / denom;
  final u = (qpx * ryn - qpy * rxe) / denom;
  if (t < 0 || t > 1 || u < 0 || u > 1) return null;
  return t;
}

bool _pointInPolygon(_En p, List<_En> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].east;
    final yi = ring[i].north;
    final xj = ring[j].east;
    final yj = ring[j].north;
    final intersects = ((yi > p.north) != (yj > p.north)) &&
        (p.east <
            (xj - xi) * (p.north - yi) / (yj - yi + 1e-15) + xi);
    if (intersects) inside = !inside;
  }
  return inside;
}

List<LatLng> _openPolygonRing(List<LatLng> ring) {
  if (ring.isEmpty) return const [];
  final closed =
      ring.length > 1 &&
      ring.first.latitude == ring.last.latitude &&
      ring.first.longitude == ring.last.longitude;
  return closed ? ring.sublist(0, ring.length - 1) : List<LatLng>.from(ring);
}

LatLng _ringCentroid(List<LatLng> ring) {
  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final p in ring) {
    sumLat += p.latitude;
    sumLng += p.longitude;
  }
  final n = ring.length;
  return LatLng(sumLat / n, sumLng / n);
}

double _eastM(Distance distance, LatLng anchor, LatLng point) {
  final bearing = distance.bearing(anchor, point);
  final meters = distance.distance(anchor, point);
  return meters * math.sin(bearing * math.pi / 180);
}

double _northM(Distance distance, LatLng anchor, LatLng point) {
  final bearing = distance.bearing(anchor, point);
  final meters = distance.distance(anchor, point);
  return meters * math.cos(bearing * math.pi / 180);
}

LatLng _enToLatLng(Distance distance, LatLng anchor, _En p) {
  final meters = math.sqrt(p.east * p.east + p.north * p.north);
  if (meters < 1e-3) return anchor;
  final bearing = math.atan2(p.east, p.north) * 180 / math.pi;
  return distance.offset(anchor, meters, bearing);
}

class _En {
  const _En(this.east, this.north);

  final double east;
  final double north;
}
