import '../../domain/models/reference_point.dart';
import '../http/api_client.dart';
import '../mappers/json_helpers.dart';
import '../mappers/reference_point_mapper.dart';

/// Acesso aos postos de salvamento (referencias) da orla.
class ReferencePointRepository {
  ReferencePointRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/reference-points';

  /// Lista todos os postos ativos (`GET /reference-points`).
  Future<List<ReferencePoint>> fetchAll() async {
    final uri = _apiClient.resolve(_basePath);
    final data = await _apiClient.getJsonList(_basePath);
    return mapJsonObjectList(data, ReferencePointMapper.fromJson, uri);
  }

  /// Sugere os postos mais proximos de um pin
  /// (`GET /reference-points/nearby?lat=&lng=&raioKm=`).
  Future<List<ReferencePoint>> fetchNearby({
    required double lat,
    required double lng,
    double raioKm = 1.5,
  }) async {
    final query = {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'raioKm': raioKm.toString(),
    };
    final uri = _apiClient.resolve('$_basePath/nearby', query);
    final data =
        await _apiClient.getJsonList('$_basePath/nearby', query: query);
    return mapJsonObjectList(data, ReferencePointMapper.fromJson, uri);
  }
}
