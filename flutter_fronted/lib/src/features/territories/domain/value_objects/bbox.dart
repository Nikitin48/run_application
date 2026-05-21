class Bbox {
  const Bbox({
    required this.minLng,
    required this.minLat,
    required this.maxLng,
    required this.maxLat,
  });

  final double minLng;
  final double minLat;
  final double maxLng;
  final double maxLat;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bbox &&
          other.minLng == minLng &&
          other.minLat == minLat &&
          other.maxLng == maxLng &&
          other.maxLat == maxLat);

  @override
  int get hashCode => Object.hash(minLng, minLat, maxLng, maxLat);
}
