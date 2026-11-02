import '../http/api_client.dart';
import '../http/api_exception.dart';

/// Upload de arquivos para o storage do backend (MVP: foto do local).
class UploadRepository {
  UploadRepository(this._apiClient);

  final ApiClient _apiClient;

  static const String locationPhotoPath = '/uploads/location-photo';

  /// Envia a foto do local como multipart/form-data no campo `file` e devolve
  /// a `secureUrl` publica retornada pelo backend.
  Future<String> uploadLocationPhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final json = await _apiClient.postMultipart(
      locationPhotoPath,
      field: 'file',
      bytes: bytes,
      filename: filename,
      expectedStatuses: const {200, 201},
    );
    final secureUrl = json['secureUrl'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw ApiParsingException(
        _apiClient.resolve(locationPhotoPath),
        const FormatException('Campo secureUrl ausente na resposta do upload.'),
      );
    }
    return secureUrl;
  }
}
