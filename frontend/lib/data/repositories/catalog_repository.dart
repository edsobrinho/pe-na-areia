import '../../domain/models/kiosk.dart';
import '../http/api_client.dart';
import '../mappers/json_helpers.dart';
import '../mappers/kiosk_mapper.dart';

/// Acesso ao catalogo de quiosques/restaurantes parceiros.
class CatalogRepository {
  CatalogRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/kiosks';

  /// Lista todos os quiosques ativos (`GET /kiosks`).
  Future<List<Kiosk>> fetchKiosks() async {
    final uri = _apiClient.resolve(_basePath);
    final data = await _apiClient.getJsonList(_basePath);
    return mapJsonObjectList(data, KioskMapper.fromJson, uri);
  }

  /// Lista quiosques vinculados a um posto de referencia
  /// (`GET /kiosks/by-reference-point/{pontoReferenciaId}`).
  Future<List<Kiosk>> fetchKiosksByReferencePoint(String pontoReferenciaId) async {
    final path = '$_basePath/by-reference-point/$pontoReferenciaId';
    final uri = _apiClient.resolve(path);
    final data = await _apiClient.getJsonList(path);
    return mapJsonObjectList(data, KioskMapper.fromJson, uri);
  }
}
