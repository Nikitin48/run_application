import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Territory {
  const Territory({
    required this.userId,
    required this.areaM2,
    required this.polygons,
  });

  final String userId;
  final double areaM2;

  /// Each item is a polygon ring (no holes for MVP).
  final List<List<LatLng>> polygons;
}

Color territoryColor(String userId) {
  // Stable-ish color from user id.
  final h = userId.hashCode;
  final r = 80 + (h & 0x7F);
  final g = 80 + ((h >> 8) & 0x7F);
  final b = 80 + ((h >> 16) & 0x7F);
  return Color.fromARGB(255, r, g, b);
}


