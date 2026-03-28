import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/color_utils.dart';

/// Approximate center of the outer ring (mean of vertices). Fine for city-scale polygons.
LatLng? polygonRingCentroid(List<LatLng> ring) {
  if (ring.isEmpty) return null;
  final closed =
      ring.length > 1 && ring.first.latitude == ring.last.latitude &&
          ring.first.longitude == ring.last.longitude;
  final pts = closed ? ring.sublist(0, ring.length - 1) : ring;
  if (pts.isEmpty) return null;

  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final p in pts) {
    sumLat += p.latitude;
    sumLng += p.longitude;
  }
  final n = pts.length;
  return LatLng(sumLat / n, sumLng / n);
}

/// Plain text label for [MarkerLayer]; color from territory, shadows for contrast.
class TerritoryDisplayNameMapLabel extends StatelessWidget {
  const TerritoryDisplayNameMapLabel({
    super.key,
    required this.displayName,
    required this.territoryColorHex,
  });

  final String displayName;
  final String territoryColorHex;

  @override
  Widget build(BuildContext context) {
    final base = colorFromHexOrDefault(territoryColorHex);
    final hsl = HSLColor.fromColor(base);
    final textColor = hsl
        .withLightness((hsl.lightness + 0.38).clamp(0.0, 1.0))
        .toColor();

    return Center(
      child: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          height: 1.1,
          shadows: const [
            Shadow(color: Color(0xE6000000), blurRadius: 3, offset: Offset(0, 0)),
            Shadow(color: Color(0xB3000000), blurRadius: 8, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}
