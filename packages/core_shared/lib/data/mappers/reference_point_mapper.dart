import '../../domain/models/geo_point.dart';
import '../../domain/models/reference_point.dart';
import 'geo_json_mapper.dart';

/// Mapeamento JSON explicito de [ReferencePoint] (contrato de
/// `GET /reference-points`, com `localizacao` em GeoJSON [lng, lat]).
abstract final class ReferencePointMapper {
  static ReferencePoint fromJson(Map<String, dynamic> json) {
    final localizacao = GeoJsonMapper.geoPointFromJson(json['localizacao']) ??
        const GeoPoint(latitude: 0, longitude: 0);

    return ReferencePoint(
      id: json['id'] as String,
      numero: (json['numero'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String,
      latitude: localizacao.latitude,
      longitude: localizacao.longitude,
      trecho: json['trecho'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}
