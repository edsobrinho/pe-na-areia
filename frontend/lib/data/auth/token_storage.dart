import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/auth_session.dart';

abstract interface class AuthSessionStorage {
  Future<void> save(AuthSession session);
  Future<AuthSession?> read();
  Future<String?> readToken();
  Future<void> clear();
}

class TokenStorage implements AuthSessionStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'auth_session';
  final FlutterSecureStorage _storage;

  @override
  Future<void> save(AuthSession session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  @override
  Future<AuthSession?> read() async {
    final value = await _storage.read(key: _sessionKey);
    if (value == null) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Sessão salva em formato inválido.');
    }
    return AuthSession.fromJson(decoded);
  }

  @override
  Future<String?> readToken() async => (await read())?.token;

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
}
