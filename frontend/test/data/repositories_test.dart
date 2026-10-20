import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pe_na_areia/data/http/api_client.dart';
import 'package:pe_na_areia/data/http/api_exception.dart';
import 'package:pe_na_areia/data/repositories/catalog_repository.dart';
import 'package:pe_na_areia/data/repositories/order_repository.dart';
import 'package:pe_na_areia/data/repositories/reference_point_repository.dart';
import 'package:pe_na_areia/data/repositories/upload_repository.dart';
import 'package:pe_na_areia/domain/models/order.dart';
import 'package:pe_na_areia/domain/models/order_location.dart';
import 'package:pe_na_areia/domain/models/order_status.dart';
import 'package:pe_na_areia/domain/models/payment_method.dart';

ApiClient buildClient(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(baseUrl: 'http://api.test', httpClient: MockClient(handler));

const _postoJson = {
  'id': 'posto-6',
  'numero': 6,
  'nome': 'Posto 6',
  'localizacao': {
    'type': 'Point',
    'coordinates': [-46.3285, -23.9720],
  },
  'trecho': 'Gonzaga',
  'ativo': true,
};

const _orderCreatedJson = {
  'id': 'pedido-123',
  'userId': 'u1',
  'kioskId': 'k1',
  'courierId': null,
  'itens': [
    {
      'menuItemId': 'm1',
      'nome': 'Agua de coco',
      'quantidade': 2,
      'precoUnitario': 8.5,
    },
  ],
  'valorTotal': 17.0,
  'embalagemSustentavel': true,
  'formaPagamento': 'PIX',
  'pago': false,
  'pinCliente': {'latitude': -23.9722, 'longitude': -46.3280},
  'pontoReferenciaId': 'posto-6',
  'descricaoLocal': 'Guarda-sol azul',
  'fotoLocalUrl': null,
  'status': 'CRIADO',
  'timeline': {
    'criadoEm': '2026-10-13T10:00:00Z',
  },
};

const _localizacao = OrderLocation(
  latitude: -23.9722,
  longitude: -46.3280,
  pontoReferenciaId: 'posto-6',
  descricaoLocal: 'Guarda-sol azul',
);

void main() {
  group('ReferencePointRepository', () {
    test('fetchAll le GET /reference-points', () async {
      final repo = ReferencePointRepository(buildClient((request) async {
        expect(request.url.path, '/reference-points');
        return http.Response(jsonEncode([_postoJson]), 200);
      }));

      final postos = await repo.fetchAll();

      expect(postos, hasLength(1));
      expect(postos.first.id, 'posto-6');
      expect(postos.first.nome, 'Posto 6');
      expect(postos.first.latitude, -23.9720);
      expect(postos.first.trecho, 'Gonzaga');
    });

    test('fetchNearby envia lat/lng/raioKm na query', () async {
      late Uri captured;
      final repo = ReferencePointRepository(buildClient((request) async {
        captured = request.url;
        return http.Response(jsonEncode([_postoJson]), 200);
      }));

      final postos = await repo.fetchNearby(
        lat: -23.9722,
        lng: -46.3280,
        raioKm: 1.5,
      );

      expect(captured.path, '/reference-points/nearby');
      expect(captured.queryParameters, {
        'lat': '-23.9722',
        'lng': '-46.328',
        'raioKm': '1.5',
      });
      expect(postos, hasLength(1));
    });

    test('item malformado na lista vira ApiParsingException', () async {
      final repo = ReferencePointRepository(
        buildClient((_) async => http.Response('[1, 2]', 200)),
      );
      await expectLater(
        repo.fetchAll(),
        throwsA(isA<ApiParsingException>()),
      );
    });
  });

  group('CatalogRepository', () {
    test('fetchKiosks le GET /kiosks com cardapio', () async {
      final repo = CatalogRepository(buildClient((request) async {
        expect(request.url.path, '/kiosks');
        return http.Response(
          jsonEncode([
            {
              'id': 'k1',
              'nome': 'Quiosque Sol',
              'pontoReferenciaId': 'posto-6',
              'cardapio': [
                {'id': 'm1', 'nome': 'Agua de coco', 'preco': 8.5},
              ],
            },
          ]),
          200,
        );
      }));

      final kiosks = await repo.fetchKiosks();

      expect(kiosks, hasLength(1));
      expect(kiosks.first.nome, 'Quiosque Sol');
      expect(kiosks.first.cardapio.first.nome, 'Agua de coco');
    });

    test('fetchKiosksByReferencePoint monta o path do posto', () async {
      late Uri captured;
      final repo = CatalogRepository(buildClient((request) async {
        captured = request.url;
        return http.Response('[]', 200);
      }));

      final kiosks = await repo.fetchKiosksByReferencePoint('posto-6');

      expect(captured.path, '/kiosks/by-reference-point/posto-6');
      expect(kiosks, isEmpty);
    });
  });

  group('OrderRepository', () {
    test('fetchOrderById busca a versão atual do pedido', () async {
      late Uri captured;
      final repo = OrderRepository(buildClient((request) async {
        captured = request.url;
        return http.Response(jsonEncode(_orderCreatedJson), 200);
      }));

      final order = await repo.fetchOrderById('pedido-123');

      expect(captured.path, '/orders/pedido-123');
      expect(order.id, 'pedido-123');
      expect(order.localizacao!.latitude, -23.9722);
    });

    test('createOrder envia o corpo do contrato e le a resposta 201', () async {
      late http.Request captured;
      final repo = OrderRepository(buildClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_orderCreatedJson), 201);
      }));

      final order = await repo.createOrder(
        userId: 'u1',
        kioskId: 'k1',
        itens: const [OrderItemRequest(menuItemId: 'm1', quantidade: 2)],
        formaPagamento: PaymentMethod.pix,
        localizacao: _localizacao,
        embalagemSustentavel: true,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/orders');
      expect(jsonDecode(captured.body), {
        'userId': 'u1',
        'kioskId': 'k1',
        'itens': [
          {'menuItemId': 'm1', 'quantidade': 2},
        ],
        'formaPagamento': 'PIX',
        'pinCliente': {'latitude': -23.9722, 'longitude': -46.3280},
        'pontoReferenciaId': 'posto-6',
        'descricaoLocal': 'Guarda-sol azul',
        'embalagemSustentavel': true,
      });

      expect(order.id, 'pedido-123');
      expect(order.status, OrderStatus.criado);
      expect(order.valorTotal, 17.0);
      expect(order.localizacao!.pontoReferenciaId, 'posto-6');
      expect(order.timeline.criadoEm, DateTime.utc(2026, 10, 13, 10));
    });

    test('createOrder rejeita status 200 (espera 201)', () async {
      final repo = OrderRepository(
        buildClient(
            (_) async => http.Response(jsonEncode(_orderCreatedJson), 200)),
      );
      await expectLater(
        repo.createOrder(
          userId: 'u1',
          kioskId: 'k1',
          itens: const [OrderItemRequest(menuItemId: 'm1', quantidade: 1)],
          formaPagamento: PaymentMethod.pix,
          localizacao: _localizacao,
        ),
        throwsA(isA<ApiHttpException>()
            .having((e) => e.statusCode, 'statusCode', 200)),
      );
    });

    test('resposta 201 sem id vira ApiParsingException', () async {
      final repo = OrderRepository(
        buildClient((_) async => http.Response('{"status": "CRIADO"}', 201)),
      );
      await expectLater(
        repo.createOrder(
          userId: 'u1',
          kioskId: 'k1',
          itens: const [OrderItemRequest(menuItemId: 'm1', quantidade: 1)],
          formaPagamento: PaymentMethod.pix,
          localizacao: _localizacao,
        ),
        throwsA(isA<ApiParsingException>()),
      );
    });

    test('updateStatus envia PATCH com status e converte a resposta', () async {
      late http.Request captured;
      final response = {..._orderCreatedJson, 'status': 'EM_PREPARO'};
      final repo = OrderRepository(buildClient((request) async {
        captured = request;
        return http.Response(jsonEncode(response), 200);
      }));

      final order =
          await repo.updateStatus('pedido-123', OrderStatus.emPreparo);

      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/orders/pedido-123/status');
      expect(jsonDecode(captured.body), {'status': 'EM_PREPARO'});
      expect(order.status, OrderStatus.emPreparo);
    });

    test('confirmDelivery envia a localização do courier', () async {
      late http.Request captured;
      final response = {..._orderCreatedJson, 'status': 'ENTREGUE'};
      final repo = OrderRepository(buildClient((request) async {
        captured = request;
        return http.Response(jsonEncode(response), 200);
      }));

      final order = await repo.confirmDelivery(
        orderId: 'pedido-123',
        courierId: 'courier-1',
        latitude: -23.972,
        longitude: -46.328,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/orders/pedido-123/confirm-delivery');
      expect(jsonDecode(captured.body), {
        'courierId': 'courier-1',
        'courierLocation': {'lat': -23.972, 'lng': -46.328},
      });
      expect(order.status, OrderStatus.entregue);
    });

    test('nao envia status desconhecido para a API', () async {
      final repo = OrderRepository(
        buildClient((_) async => http.Response('', 200)),
      );
      await expectLater(
        repo.updateStatus('pedido-123', OrderStatus.desconhecido),
        throwsArgumentError,
      );
    });

    test('fetchAvailableOrders solicita a lista e converte os pedidos',
        () async {
      late http.Request captured;
      final repo = OrderRepository(buildClient((request) async {
        captured = request;
        return http.Response(jsonEncode([_orderCreatedJson]), 200);
      }));

      final orders = await repo.fetchAvailableOrders();

      expect(captured.method, 'GET');
      expect(captured.url.path, '/orders/available');
      expect(orders, hasLength(1));
      expect(orders.single.id, 'pedido-123');
    });

    test('fetchActiveCourierOrders solicita pedidos em rota', () async {
      late http.Request captured;
      final repo = OrderRepository(buildClient((request) async {
        captured = request;
        return http.Response('[]', 200);
      }));

      final orders = await repo.fetchActiveCourierOrders();

      expect(captured.url.path, '/orders/courier/active');
      expect(orders, isEmpty);
    });
  });

  group('UploadRepository', () {
    test('uploadLocationPhoto envia multipart no campo file e le secureUrl',
        () async {
      late http.Request captured;
      final repo = UploadRepository(buildClient((request) async {
        captured = request;
        return http.Response(
          '{"secureUrl": "https://cdn.example.com/foto.jpg"}',
          201,
        );
      }));

      final url = await repo.uploadLocationPhoto(
        bytes: const [1, 2, 3],
        filename: 'local.jpg',
      );

      expect(url, 'https://cdn.example.com/foto.jpg');
      expect(captured.method, 'POST');
      expect(captured.url.path, '/uploads/location-photo');
      expect(captured.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      final body = latin1.decode(captured.bodyBytes);
      expect(body, contains('name="file"'));
      expect(body, contains('filename="local.jpg"'));
    });

    test('secureUrl ausente vira ApiParsingException', () async {
      final repo = UploadRepository(
        buildClient((_) async => http.Response('{"url": "x"}', 201)),
      );
      await expectLater(
        repo.uploadLocationPhoto(bytes: const [1], filename: 'f.jpg'),
        throwsA(isA<ApiParsingException>()),
      );
    });

    test('secureUrl vazia vira ApiParsingException', () async {
      final repo = UploadRepository(
        buildClient((_) async => http.Response('{"secureUrl": ""}', 201)),
      );
      await expectLater(
        repo.uploadLocationPhoto(bytes: const [1], filename: 'f.jpg'),
        throwsA(isA<ApiParsingException>()),
      );
    });

    test('erro do servidor no upload vira ApiHttpException', () async {
      final repo = UploadRepository(
        buildClient((_) async => http.Response('erro', 500)),
      );
      await expectLater(
        repo.uploadLocationPhoto(bytes: const [1], filename: 'f.jpg'),
        throwsA(isA<ApiHttpException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}
