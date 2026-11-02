import '../../domain/models/courier.dart';
import 'geo_json_mapper.dart';

/// Mapeamento JSON explicito de [Courier] (formato do backend Spring Boot).
abstract final class CourierMapper {
  static Courier fromJson(Map<String, dynamic> json) => Courier(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String? ?? '',
        veiculo: json['veiculo'] == null
            ? null
            : VehicleType.fromWire(json['veiculo'] as String),
        status: json['status'] == null
            ? CourierStatus.offline
            : CourierStatus.fromWire(json['status'] as String),
        localizacao: GeoJsonMapper.geoPointFromJson(json['localizacao']),
      );
}
