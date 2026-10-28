import 'dart:math' as math;

/// Utilitários geodésicos para navegação pedestre na faixa de areia (Modo Bússola/Radar).
abstract final class BeachCompass {
  static const double _earthRadiusMeters = 6371000.0;

  /// Calcula a distância em linha reta (Haversine) em metros entre dois pontos.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Calcula o azimute inicial (bearing) em graus (0° = Norte, 90° = Leste, 180° = Sul, 270° = Oeste).
  static double bearingDegrees(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final deltaLambda = _toRadians(lng2 - lng1);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final theta = math.atan2(y, x);
    return (_toDegrees(theta) + 360.0) % 360.0;
  }

  /// Retorna a direção cardeal/colateral em português para o azimute informado.
  static String cardinalDirectionPtBr(double bearing) {
    final normalized = ((bearing % 360.0) + 360.0) % 360.0;
    const directions = [
      'Norte',
      'Nordeste',
      'Leste',
      'Sudeste',
      'Sul',
      'Sudoeste',
      'Oeste',
      'Noroeste',
    ];
    final index = ((normalized + 22.5) ~/ 45.0) % 8;
    return directions[index];
  }

  /// Formata a instrução de radar pedestre para o entregador na praia.
  static String formatRadarInstruction({
    required double courierLat,
    required double courierLng,
    required double pinLat,
    required double pinLng,
    String? referenceLabel,
  }) {
    final dist = distanceMeters(courierLat, courierLng, pinLat, pinLng).round();
    final bearing = bearingDegrees(courierLat, courierLng, pinLat, pinLng);
    final cardinal = cardinalDirectionPtBr(bearing);
    final deg = bearing.round();
    final refSuffix = (referenceLabel != null && referenceLabel.trim().isNotEmpty)
        ? ' (${referenceLabel.trim()})'
        : '';
    return 'A $dist m a $cardinal ($deg°)$refSuffix';
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
  static double _toDegrees(double radians) => radians * (180.0 / math.pi);
}

