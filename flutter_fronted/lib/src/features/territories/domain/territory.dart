import 'package:latlong2/latlong.dart';

class Territory {
  const Territory({
    required this.userId,
    required this.areaM2,
    required this.territoryColorHex,
    required this.polygons,
  });

  final String userId;
  final double areaM2;
  final String territoryColorHex;

  /// Each item is a polygon ring (no holes for MVP).
  final List<List<LatLng>> polygons;
}
