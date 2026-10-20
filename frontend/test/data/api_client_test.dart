import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pe_na_areia/data/http/api_client.dart';
import 'package:pe_na_areia/data/http/api_exception.dart';

void main() {
  ApiClient buildClient(
    MockClient mock, {
    Duration timeout = const Duration(seconds: 15),
    BearerTokenProvider? bearerTokenProvider,
  }) =>
      ApiClient(
        baseUrl: 'http://api.test',
        httpClient: mock,
        timeout: timeout,
        bearerTokenProvider: bearerTokenProvider,
      );

  group('resolve', () {
    test('monta a URI absoluta com query', () {
      final client = buildClient(MockClient((_) async => http.Response('[]', 200)));
      final uri = client.resolve('/reference-points/nearby', const {
        'lat': '-23.97',
        'lng': '-46.32',
      });
      expect(uri.toString(),
          'http://api.test/reference-points/nearby?lat=-23.97&lng=-46.32');
    });

    test('tolera baseUrl com barra no final', () {
      final client = ApiClient(
        baseUrl: 'http://api.test/',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(client.resolve('/orders').toString(), 'http://api.test/orders');
    });
  });

  group('getJsonList', () {
    test('devolve a lista e envia a query configurada', () async {
      late Uri captured;
      final client = buildClient(MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode([
            {'id': 'posto-6'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }));

      final data = await client.getJsonList('/reference-points/nearby', query: {
        'lat': '-23.97',
        'lng': '-46.32',
        'raioKm': '1.5',
      });

      expect(data, hasLength(1));
      expect(data.first, {'id': 'posto-6'});
      expect(captured.queryParameters, {
        'lat': '-23.97',
        'lng': '-46.32',
        'raioKm': '1.5',
      });
    });

    test('status inesperado vira ApiHttpException', () async {
      final client = buildClient(
        MockClient((_) async => http.Response('erro interno', 500)),
      );
      await expectLater(
        client.getJsonList('/reference-points'),
        throwsA(
          isA<ApiHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.body, 'body', 'erro interno'),
        ),
      );
    });

    test('corpo nao-JSON vira ApiParsingException', () async {
      final client = buildClient(
        MockClient((_) async => http.Response('<html>erro</html>', 200)),
      );
      await expectLater(
        client.getJsonList('/reference-points'),
        throwsA(isA<ApiParsingException>()),
      );
    });

    test('objeto JSON no lugar de array vira ApiParsingException', () async {
      final client = buildClient(
        MockClient((_) async => http.Response('{"a": 1}', 200)),
      );
      await expectLater(
        client.getJsonList('/reference-points'),
        throwsA(isA<ApiParsingException>()),
      );
    });
  });

  group('postJson', () {
    test('envia JSON com content-type e devolve o mapa', () async {
      late http.Request captured;
      final client = buildClient(MockClient((request) async {
        captured = request;
        return http.Response('{"id": "pedido-1"}', 201);
      }));

      final json = await client.postJson(
        '/orders',
        const {'userId': 'u1'},
        expectedStatuses: const {201},
      );

      expect(json, {'id': 'pedido-1'});
      expect(captured.headers['content-type'],
          startsWith('application/json'));
      expect(jsonDecode(captured.body), {'userId': 'u1'});
    });

    test('status fora do esperado vira ApiHttpException', () async {
      final client = buildClient(
        MockClient((_) async => http.Response('{"erro": true}', 200)),
      );
      await expectLater(
        client.postJson('/orders', const {}, expectedStatuses: const {201}),
        throwsA(isA<ApiHttpException>()
            .having((e) => e.statusCode, 'statusCode', 200)),
      );
    });
  });

  group('postMultipart', () {
    test('envia multipart com campo file e filename', () async {
      late http.Request captured;
      final client = buildClient(MockClient((request) async {
        captured = request;
        return http.Response('{"secureUrl": "https://cdn.example.com/f.jpg"}',
            201);
      }));

      final json = await client.postMultipart(
        '/uploads/location-photo',
        field: 'file',
        bytes: const [1, 2, 3],
        filename: 'foto.jpg',
        expectedStatuses: const {200, 201},
      );

      expect(json['secureUrl'], 'https://cdn.example.com/f.jpg');
      expect(captured.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      final body = latin1.decode(captured.bodyBytes);
      expect(body, contains('name="file"'));
      expect(body, contains('filename="foto.jpg"'));
    });
  });

  group('erros tipados', () {
    test('timeout vira ApiTimeoutException', () async {
      final client = buildClient(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return http.Response('[]', 200);
        }),
        timeout: const Duration(milliseconds: 50),
      );
      await expectLater(
        client.getJsonList('/reference-points'),
        throwsA(isA<ApiTimeoutException>()
            .having((e) => e.timeout, 'timeout', const Duration(milliseconds: 50))),
      );
    });

    test('falha de transporte vira ApiNetworkException', () async {
      final client = buildClient(
        MockClient((_) async => throw http.ClientException('sem rede')),
      );
      await expectLater(
        client.getJsonList('/reference-points'),
        throwsA(isA<ApiNetworkException>()),
      );
    });
  });

  group('bearer token (extensao futura)', () {
    test('envia Authorization quando o provider devolve token', () async {
      Map<String, String>? capturedHeaders;
      final client = buildClient(
        MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response('[]', 200);
        }),
        bearerTokenProvider: () async => 'token-123',
      );

      await client.getJsonList('/reference-points');

      expect(capturedHeaders!['authorization'], 'Bearer token-123');
    });

    test('nao envia Authorization sem provider configurado', () async {
      Map<String, String>? capturedHeaders;
      final client = buildClient(MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response('[]', 200);
      }));

      await client.getJsonList('/reference-points');

      expect(capturedHeaders!.containsKey('authorization'), isFalse);
    });

    test('provider nulo/vazio nao envia header', () async {
      Map<String, String>? capturedHeaders;
      final client = buildClient(
        MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response('[]', 200);
        }),
        bearerTokenProvider: () async => null,
      );

      await client.getJsonList('/reference-points');

      expect(capturedHeaders!.containsKey('authorization'), isFalse);
    });
  });
}
