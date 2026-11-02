import '../../domain/models/geo_point.dart';

/// Leitura explicita das representacoes geograficas usadas pelo backend.
///
/// O Mongo armazena campos GeoJSON (`{"type": "Point", "coordinates": [lng, lat]}`)
/// e o contrato de criacao de pedido usa `{"latitude": ..., "longitude": ...}`;
/// este mapper aceita as duas formas.
abstract final class GeoJsonMapper {
  static GeoPoint? geoPointFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final coordinates = value['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final longitude = coordinates[0];
      final latitude = coordinates[1];
      if (longitude is num && latitude is num) {
        return GeoPoint(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
        );
      }
    }

    final latitude = value['latitude'];
    final longitude = value['longitude'];
    if (latitude is num && longitude is num) {
      return GeoPoint(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      );
    }

    return null;
  }
}
