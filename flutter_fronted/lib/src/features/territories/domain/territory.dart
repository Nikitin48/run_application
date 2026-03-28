import 'package:latlong2/latlong.dart';

class Territory {
  const Territory({
    required this.userId,
    required this.displayName,
    required this.areaM2,
    required this.territoryColorHex,
    required this.polygons,
  });

  final String userId;
  /// Shown on the map territory label.
  final String displayName;
  final double areaM2;
  final String territoryColorHex;

  /// Each item is a polygon ring (no holes for MVP).
  final List<List<LatLng>> polygons;
}
