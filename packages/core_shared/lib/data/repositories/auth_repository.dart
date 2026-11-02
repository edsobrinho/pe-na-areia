import '../../domain/models/auth_session.dart';
import '../http/api_client.dart';
import '../http/api_exception.dart';
import '../auth/token_storage.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final AuthSessionStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _apiClient.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    return _saveSession(json, '/auth/login');
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? vehicle,
  }) async {
    final json = await _apiClient.postJson(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'vehicle': vehicle,
      },
      expectedStatuses: const {201},
    );
    return _saveSession(json, '/auth/register');
  }

  Future<AuthSession?> currentSession() => _tokenStorage.read();

  Future<void> logout() => _tokenStorage.clear();

  Future<AuthSession> _saveSession(
    Map<String, dynamic> json,
    String path,
  ) async {
    try {
      final session = AuthSession.fromJson(json);
      await _tokenStorage.save(session);
      return session;
    } on FormatException catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    } on TypeError catch (error) {
      throw ApiParsingException(_apiClient.resolve(path), error);
    }
  }
}
