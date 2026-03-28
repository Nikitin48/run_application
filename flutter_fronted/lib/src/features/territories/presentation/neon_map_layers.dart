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
