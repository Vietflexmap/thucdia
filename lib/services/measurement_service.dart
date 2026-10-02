import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class MeasurementService {
  static const _earthRadius = 6378137.0;

  double distanceMeters(List<LatLng> points) {
    if (points.length < 2) return 0;
    const distance = Distance();
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += distance.as(LengthUnit.Meter, points[i - 1], points[i]);
    }
    return total;
  }

  double areaSquareMeters(List<LatLng> points) {
    if (points.length < 3) return 0;
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final lon1 = _rad(p1.longitude);
      final lon2 = _rad(p2.longitude);
      final lat1 = _rad(p1.latitude);
      final lat2 = _rad(p2.latitude);
      sum += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    return (sum * _earthRadius * _earthRadius / 2).abs();
  }

  double bearingDegrees(LatLng from, LatLng to) {
    final phi1 = _rad(from.latitude);
    final phi2 = _rad(to.latitude);
    final dLon = _rad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String formatDistance(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(3)} km' : '${meters.toStringAsFixed(1)} m';

  String formatArea(double squareMeters) => squareMeters >= 10000
      ? '${(squareMeters / 10000).toStringAsFixed(3)} ha'
      : '${squareMeters.toStringAsFixed(1)} m²';

  double _rad(double value) => value * math.pi / 180;
}
