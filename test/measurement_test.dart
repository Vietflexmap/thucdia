import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:vietflex_thucdia/services/measurement_service.dart';

void main() {
  test('distance measurement returns a positive value', () {
    final service = MeasurementService();
    final distance = service.distanceMeters(const [
      LatLng(10.0, 106.0),
      LatLng(10.001, 106.001),
    ]);
    expect(distance, greaterThan(0));
  });
}
