import 'dart:convert';

import 'package:flutter/services.dart';
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
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
            );

  static const _sessionKey = 'auth_session';
  final FlutterSecureStorage _storage;
  AuthSession? _cachedSession;

  @override
  Future<void> save(AuthSession session) async {
    _cachedSession = session;
    final encoded = jsonEncode(session.toJson());
    try {
      await _storage.write(key: _sessionKey, value: encoded);
    } on PlatformException {
      // Se a chave do Android Keystore ficou invalida apos reinstalacao do APK,
      // limpa o storage corrompido e tenta gravar novamente.
      await _safeResetStorage();
      try {
        await _storage.write(key: _sessionKey, value: encoded);
      } on PlatformException {
        // Mantem a sessao em memoria (_cachedSession) caso o Keystore do aparelho falhe.
      }
    }
  }

  @override
  Future<AuthSession?> read() async {
    try {
      final value = await _storage.read(key: _sessionKey);
      if (value == null) return _cachedSession;
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        await _safeResetStorage();
        return _cachedSession;
      }
      final session = AuthSession.fromJson(decoded);
      _cachedSession = session;
      return session;
    } on PlatformException {
      // Captura BadPaddingException (BAD_DECRYPT) quando o Android Auto-Backup
      // restaura dados criptografados com chave antiga do Keystore.
      await _safeResetStorage();
      return _cachedSession;
    } on FormatException {
      await _safeResetStorage();
      return _cachedSession;
    }
  }

  @override
  Future<String?> readToken() async => (await read())?.token;

  @override
  Future<void> clear() async {
    _cachedSession = null;
    await _safeResetStorage();
  }

  Future<void> _safeResetStorage() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }
}
