import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pe_na_areia/data/auth/token_storage.dart';
import 'package:pe_na_areia/data/http/api_client.dart';
import 'package:pe_na_areia/data/http/api_exception.dart';
import 'package:pe_na_areia/data/repositories/auth_repository.dart';
import 'package:pe_na_areia/domain/models/auth_session.dart';

class _MemorySessionStorage implements AuthSessionStorage {
  AuthSession? session;

  @override
  Future<void> save(AuthSession session) async => this.session = session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<String?> readToken() async => session?.token;

  @override
  Future<void> clear() async => session = null;
}

void main() {
  test('login envia credenciais e persiste a sessão', () async {
    late http.Request captured;
    final storage = _MemorySessionStorage();
    final repository = AuthRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'token': 'jwt-token',
              'userId': 'client-1',
              'name': 'Ana',
              'role': 'CLIENT',
            }),
            200,
          );
        }),
      ),
      storage,
    );

    final session = await repository.login(
      email: 'ana@example.com',
      password: 'secret1',
    );

    expect(captured.url.path, '/auth/login');
    expect(jsonDecode(captured.body), {
      'email': 'ana@example.com',
      'password': 'secret1',
    });
    expect(session.userId, 'client-1');
    expect(storage.session?.token, 'jwt-token');
  });

  test('registro de entregador envia perfil e veículo', () async {
    late http.Request captured;
    final repository = AuthRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            '{"token":"jwt","userId":"courier-1","name":"Leo","role":"COURIER"}',
            201,
          );
        }),
      ),
      _MemorySessionStorage(),
    );

    final session = await repository.register(
      name: 'Leo',
      email: 'leo@example.com',
      phone: '13999990000',
      password: 'secret1',
      role: 'COURIER',
      vehicle: 'PE',
    );

    expect(captured.url.path, '/auth/register');
    expect(captured.method, 'POST');
    expect(jsonDecode(captured.body), {
      'name': 'Leo',
      'email': 'leo@example.com',
      'phone': '13999990000',
      'password': 'secret1',
      'role': 'COURIER',
      'vehicle': 'PE',
    });
    expect(session.isCourier, isTrue);
  });

  test('resposta de autenticação inválida vira erro de parsing tipado',
      () async {
    final repository = AuthRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient:
            MockClient((_) async => http.Response('{"token": 12}', 200)),
      ),
      _MemorySessionStorage(),
    );

    await expectLater(
      repository.login(email: 'ana@example.com', password: 'secret1'),
      throwsA(
        isA<ApiParsingException>()
            .having((error) => error.uri.path, 'path', '/auth/login')
            .having((error) => error.cause, 'cause', isA<FormatException>()),
      ),
    );
  });

  test('currentSession devolve a sessão armazenada', () async {
    const session = AuthSession(
      token: 'jwt',
      userId: 'client-1',
      name: 'Ana',
      role: 'CLIENT',
    );
    final storage = _MemorySessionStorage()..session = session;
    final repository = AuthRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      ),
      storage,
    );

    expect(await repository.currentSession(), session);
  });

  test('logout limpa a sessão armazenada', () async {
    final storage = _MemorySessionStorage()
      ..session = const AuthSession(
        token: 'jwt',
        userId: 'client-1',
        name: 'Ana',
        role: 'CLIENT',
      );
    final repository = AuthRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      ),
      storage,
    );

    await repository.logout();

    expect(storage.session, isNull);
  });
}
