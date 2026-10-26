import '../../domain/models/kiosk.dart';
import '../../domain/models/partnership.dart';
import '../http/api_client.dart';
import '../mappers/json_helpers.dart';
import '../mappers/kiosk_mapper.dart';

/// Acesso ao catalogo de quiosques/restaurantes parceiros.
class CatalogRepository {
  CatalogRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/kiosks';

  /// Lista os canais ativos (`GET /partnerships`).
  Future<List<Partnership>> fetchPartnerships() async {
    const path = '/partnerships';
    final uri = _apiClient.resolve(path);
    final data = await _apiClient.getJsonList(path);
    return mapJsonObjectList(data, Partnership.fromJson, uri);
  }

  /// Lista todos os quiosques ativos (`GET /kiosks`).
  Future<List<Kiosk>> fetchKiosks({String? partnershipId}) async {
    final path = partnershipId == null
        ? _basePath
        : '$_basePath?partnershipId=${Uri.encodeQueryComponent(partnershipId)}';
    final uri = _apiClient.resolve(path);
    final data = await _apiClient.getJsonList(path);
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
