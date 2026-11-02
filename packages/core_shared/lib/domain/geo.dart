import 'dart:math' as math;

import 'models/geo_point.dart';

const double _earthRadiusMeters = 6371000;

/// Distancia em metros entre dois pontos, pela formula de Haversine.
/// Suficiente e precisa o bastante para as distancias curtas da orla.
double distanceMeters(GeoPoint a, GeoPoint b) {
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLng = _toRadians(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_toRadians(a.latitude)) *
          math.cos(_toRadians(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
}

double _toRadians(double degrees) => degrees * math.pi / 180;
