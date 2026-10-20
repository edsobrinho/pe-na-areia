import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Origem opcional do token JWT da sessao atual.
typedef BearerTokenProvider = Future<String?> Function();

/// Cliente HTTP injetavel e tipado usado por todos os repositorios.
///
/// - recebe um [http.Client] no construtor (trocavel por fakes em testes);
/// - aplica timeout configuravel em todas as chamadas;
/// - traduz falhas para [ApiException] (timeout, rede, status, parsing);
/// - resolve a base URL por `--dart-define=API_BASE_URL=...`;
/// - envia o token da sessao no header Bearer quando configurado.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
    BearerTokenProvider? bearerTokenProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _bearerTokenProvider = bearerTokenProvider;

  /// Base URL do backend, configuravel por dart-define:
  ///
  /// - Emulador Android: `http://10.0.2.2:8080` (default, aponta para o
  ///   localhost da maquina de desenvolvimento);
  /// - Simulador iOS: `http://localhost:8080`;
  /// - Dispositivo fisico: `http://<IP-da-sua-maquina-na-LAN>:8080`
  ///   (ex.: `flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080`).
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final String baseUrl;
  final Duration timeout;
  final http.Client _httpClient;
  final BearerTokenProvider? _bearerTokenProvider;

  /// Resolve a URI absoluta de um path da API (util tambem para testes).
  Uri resolve(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  /// GET que espera um array JSON na resposta.
  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? query,
    Set<int> expectedStatuses = const {200},
  }) async {
    final uri = resolve(path, query);
    final headers = await _resolveHeaders(json: false);
    final response =
        await _guard(uri, () => _httpClient.get(uri, headers: headers));
    final decoded = _decodeBody(response, uri, expectedStatuses);
    if (decoded is! List) {
      throw ApiParsingException(
        uri,
        FormatException('Esperado array JSON, veio ${decoded.runtimeType}.'),
      );
    }
    return decoded;
  }

  /// GET que espera um objeto JSON na resposta.
  Future<Map<String, dynamic>> getJsonMap(
    String path, {
    Set<int> expectedStatuses = const {200},
  }) async {
    final uri = resolve(path);
    final headers = await _resolveHeaders(json: false);
    final response =
        await _guard(uri, () => _httpClient.get(uri, headers: headers));
    return _decodeMap(response, uri, expectedStatuses);
  }

  /// POST com corpo JSON que espera um objeto JSON na resposta.
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Set<int> expectedStatuses = const {200},
  }) async {
    final uri = resolve(path);
    final headers = await _resolveHeaders(json: true);
    final response = await _guard(
      uri,
      () => _httpClient.post(uri, headers: headers, body: jsonEncode(body)),
    );
    return _decodeMap(response, uri, expectedStatuses);
  }

  /// PATCH com corpo JSON que espera um objeto JSON na resposta.
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    Set<int> expectedStatuses = const {200},
  }) async {
    final uri = resolve(path);
    final headers = await _resolveHeaders(json: true);
    final response = await _guard(
      uri,
      () => _httpClient.patch(uri, headers: headers, body: jsonEncode(body)),
    );
    return _decodeMap(response, uri, expectedStatuses);
  }

  /// POST multipart/form-data com um unico arquivo no campo [field],
  /// que espera um objeto JSON na resposta.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Set<int> expectedStatuses = const {200},
  }) async {
    final uri = resolve(path);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    final token = await _bearerTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await _guard(uri, () async {
      final streamed = await _httpClient.send(request);
      return http.Response.fromStream(streamed);
    });
    return _decodeMap(response, uri, expectedStatuses);
  }

  /// Fecha o client HTTP subjacente.
  void close() => _httpClient.close();

  Future<Map<String, String>> _resolveHeaders({required bool json}) async {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    final token = await _bearerTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _guard(
    Uri uri,
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send().timeout(timeout);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiTimeoutException(uri, timeout);
    } on http.ClientException catch (error) {
      throw ApiNetworkException(uri, error);
    } catch (error) {
      throw ApiNetworkException(uri, error);
    }
  }

  Object? _decodeBody(
    http.Response response,
    Uri uri,
    Set<int> expectedStatuses,
  ) {
    if (!expectedStatuses.contains(response.statusCode)) {
      throw ApiHttpException(uri, response.statusCode, response.body);
    }
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw ApiParsingException(uri, error);
    }
  }

  Map<String, dynamic> _decodeMap(
    http.Response response,
    Uri uri,
    Set<int> expectedStatuses,
  ) {
    final decoded = _decodeBody(response, uri, expectedStatuses);
    if (decoded is! Map<String, dynamic>) {
      throw ApiParsingException(
        uri,
        FormatException('Esperado objeto JSON, veio ${decoded.runtimeType}.'),
      );
    }
    return decoded;
  }
}
