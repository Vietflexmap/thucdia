import 'dart:math' as math;

/// Projection helper for field display.
///
/// VN-2000 is a national datum, while GNSS normally reports WGS84. This class
/// performs the Transverse Mercator projection step with configurable central
/// meridian and scale factor. For cadastral-grade transformation, configure an
/// approved WGS84 <-> VN-2000 datum transform before projection.
class Vn2000 {
  static const double _a = 6378137.0;
  static const double _invF = 298.257223563;

  static Vn2000Result projectWgs84({
    required double latitude,
    required double longitude,
    required double centralMeridian,
    double scaleFactor = 0.9999,
    double falseEasting = 500000.0,
    double falseNorthing = 0.0,
  }) {
    final f = 1.0 / _invF;
    final e2 = f * (2 - f);
    final ep2 = e2 / (1 - e2);
    final phi = _rad(latitude);
    final lambda = _rad(longitude);
    final lambda0 = _rad(centralMeridian);

    final sinPhi = math.sin(phi);
    final cosPhi = math.cos(phi);
    final tanPhi = math.tan(phi);
    final n = _a / math.sqrt(1 - e2 * sinPhi * sinPhi);
    final t = tanPhi * tanPhi;
    final c = ep2 * cosPhi * cosPhi;
    final aa = cosPhi * (lambda - lambda0);

    final m = _a *
        ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * math.pow(e2, 3) / 256) * phi -
            (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * math.pow(e2, 3) / 1024) *
                math.sin(2 * phi) +
            (15 * e2 * e2 / 256 + 45 * math.pow(e2, 3) / 1024) *
                math.sin(4 * phi) -
            (35 * math.pow(e2, 3) / 3072) * math.sin(6 * phi));

    final easting = falseEasting +
        scaleFactor *
            n *
            (aa +
                (1 - t + c) * math.pow(aa, 3) / 6 +
                (5 - 18 * t + t * t + 72 * c - 58 * ep2) *
                    math.pow(aa, 5) /
                    120);

    final northing = falseNorthing +
        scaleFactor *
            (m +
                n *
                    tanPhi *
                    (aa * aa / 2 +
                        (5 - t + 9 * c + 4 * c * c) * math.pow(aa, 4) / 24 +
                        (61 - 58 * t + t * t + 600 * c - 330 * ep2) *
                            math.pow(aa, 6) /
                            720));

    return Vn2000Result(
      xNorthing: northing,
      yEasting: easting,
      centralMeridian: centralMeridian,
      scaleFactor: scaleFactor,
      projectionOnly: true,
    );
  }

  static double _rad(double degree) => degree * math.pi / 180.0;
}

class Vn2000Result {
  final double xNorthing;
  final double yEasting;
  final double centralMeridian;
  final double scaleFactor;
  final bool projectionOnly;

  const Vn2000Result({
    required this.xNorthing,
    required this.yEasting,
    required this.centralMeridian,
    required this.scaleFactor,
    required this.projectionOnly,
  });
}
