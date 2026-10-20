import 'package:flutter_test/flutter_test.dart';

import 'package:pe_na_areia/data/mappers/courier_mapper.dart';
import 'package:pe_na_areia/data/mappers/geo_json_mapper.dart';
import 'package:pe_na_areia/data/mappers/kiosk_mapper.dart';
import 'package:pe_na_areia/data/mappers/order_location_mapper.dart';
import 'package:pe_na_areia/data/mappers/order_mapper.dart';
import 'package:pe_na_areia/data/mappers/reference_point_mapper.dart';
import 'package:pe_na_areia/data/mappers/user_mapper.dart';
import 'package:pe_na_areia/domain/models/courier.dart';
import 'package:pe_na_areia/domain/models/order.dart';
import 'package:pe_na_areia/domain/models/order_location.dart';
import 'package:pe_na_areia/domain/models/order_status.dart';
import 'package:pe_na_areia/domain/models/payment_method.dart';

void main() {
  group('GeoJsonMapper', () {
    test('le GeoJSON Point no formato [lng, lat]', () {
      final ponto = GeoJsonMapper.geoPointFromJson(const {
        'type': 'Point',
        'coordinates': [-46.3285, -23.9720],
      });
      expect(ponto, isNotNull);
      expect(ponto!.latitude, -23.9720);
      expect(ponto.longitude, -46.3285);
    });

    test('le objeto plano {latitude, longitude}', () {
      final ponto = GeoJsonMapper.geoPointFromJson(const {
        'latitude': -23.9722,
        'longitude': -46.3280,
      });
      expect(ponto!.latitude, -23.9722);
      expect(ponto.longitude, -46.3280);
    });

    test('formato desconhecido vira null sem quebrar', () {
      expect(GeoJsonMapper.geoPointFromJson(null), isNull);
      expect(GeoJsonMapper.geoPointFromJson('nao e um ponto'), isNull);
      expect(GeoJsonMapper.geoPointFromJson(const {'x': 1}), isNull);
      expect(
        GeoJsonMapper.geoPointFromJson(const {
          'coordinates': ['a', 'b'],
        }),
        isNull,
      );
    });
  });

  group('ReferencePointMapper', () {
    test('le o payload de GET /reference-points com GeoJSON', () {
      final posto = ReferencePointMapper.fromJson(const {
        'id': 'posto-6',
        'numero': 6,
        'nome': 'Posto 6',
        'localizacao': {
          'type': 'Point',
          'coordinates': [-46.3285, -23.9720],
        },
        'trecho': 'Gonzaga',
        'ativo': true,
      });
      expect(posto.id, 'posto-6');
      expect(posto.numero, 6);
      expect(posto.nome, 'Posto 6');
      expect(posto.latitude, -23.9720);
      expect(posto.longitude, -46.3285);
      expect(posto.trecho, 'Gonzaga');
      expect(posto.ativo, isTrue);
    });

    test('campos opcionais usam defaults seguros', () {
      final posto = ReferencePointMapper.fromJson(const {
        'id': 'posto-8',
        'nome': 'Posto 8',
      });
      expect(posto.numero, 0);
      expect(posto.trecho, '');
      expect(posto.ativo, isTrue);
      expect(posto.latitude, 0);
      expect(posto.longitude, 0);
    });
  });

  group('KioskMapper', () {
    test('le quiosque com cardapio e localizacao', () {
      final kiosk = KioskMapper.fromJson(const {
        'id': 'k1',
        'nome': 'Quiosque Sol',
        'pontoReferenciaId': 'posto-6',
        'localizacao': {
          'type': 'Point',
          'coordinates': [-46.3281, -23.9723],
        },
        'cardapio': [
          {
            'id': 'm1',
            'nome': 'Agua de coco',
            'descricao': 'Gelada',
            'preco': 8.5,
            'disponivel': true,
          },
          {'id': 'm2', 'nome': 'Cerveja', 'preco': 10, 'disponivel': false},
        ],
        'aceitaEmbalagemSustentavel': true,
        'ativo': true,
      });
      expect(kiosk.id, 'k1');
      expect(kiosk.nome, 'Quiosque Sol');
      expect(kiosk.pontoReferenciaId, 'posto-6');
      expect(kiosk.localizacao!.latitude, -23.9723);
      expect(kiosk.localizacao!.longitude, -46.3281);
      expect(kiosk.cardapio, hasLength(2));
      expect(kiosk.cardapio.first.nome, 'Agua de coco');
      expect(kiosk.cardapio.first.descricao, 'Gelada');
      expect(kiosk.cardapio.first.preco, 8.5);
      expect(kiosk.cardapio.first.disponivel, isTrue);
      expect(kiosk.cardapio[1].descricao, '');
      expect(kiosk.cardapio[1].preco, 10.0);
      expect(kiosk.cardapio[1].disponivel, isFalse);
      expect(kiosk.aceitaEmbalagemSustentavel, isTrue);
      expect(kiosk.ativo, isTrue);
    });

    test('campos opcionais usam defaults seguros', () {
      final kiosk = KioskMapper.fromJson(const {
        'id': 'k2',
        'nome': 'Quiosque Mar',
      });
      expect(kiosk.pontoReferenciaId, '');
      expect(kiosk.localizacao, isNull);
      expect(kiosk.cardapio, isEmpty);
      expect(kiosk.aceitaEmbalagemSustentavel, isTrue);
      expect(kiosk.ativo, isTrue);
    });
  });

  group('UserMapper', () {
    test('le o payload do backend com criadoEm', () {
      final user = UserMapper.fromJson(const {
        'id': 'u1',
        'nome': 'Ana Praia',
        'email': 'ana@example.com',
        'telefone': '+55 13 99999-0000',
        'criadoEm': '2026-10-13T10:00:00Z',
      });
      expect(user.id, 'u1');
      expect(user.nome, 'Ana Praia');
      expect(user.email, 'ana@example.com');
      expect(user.telefone, '+55 13 99999-0000');
      expect(user.criadoEm, DateTime.utc(2026, 10, 13, 10));
    });

    test('campos opcionais ausentes viram defaults', () {
      final user = UserMapper.fromJson(const {'id': 'u2', 'nome': 'Ze'});
      expect(user.email, '');
      expect(user.telefone, isNull);
      expect(user.criadoEm, isNull);
    });

    test('criadoEm invalido vira null sem quebrar', () {
      final user = UserMapper.fromJson(const {
        'id': 'u3',
        'nome': 'Bia',
        'criadoEm': 'nao e data',
      });
      expect(user.criadoEm, isNull);
    });
  });

  group('CourierMapper', () {
    test('le veiculo, status e localizacao', () {
      final courier = CourierMapper.fromJson(const {
        'id': 'c1',
        'nome': 'Ze Entregador',
        'email': 'ze@example.com',
        'veiculo': 'BICICLETA',
        'status': 'EM_ROTA',
        'localizacao': {
          'type': 'Point',
          'coordinates': [-46.3280, -23.9722],
        },
      });
      expect(courier.id, 'c1');
      expect(courier.veiculo, VehicleType.bicicleta);
      expect(courier.status, CourierStatus.emRota);
      expect(courier.localizacao!.latitude, -23.9722);
      expect(courier.localizacao!.longitude, -46.3280);
    });

    test('sem veiculo/status/localizacao usa defaults', () {
      final courier = CourierMapper.fromJson(const {
        'id': 'c2',
        'nome': 'Sol',
      });
      expect(courier.veiculo, isNull);
      expect(courier.status, CourierStatus.offline);
      expect(courier.localizacao, isNull);
    });
  });

  group('OrderLocationMapper', () {
    test('tryFromOrderJson aceita pinCliente GeoJSON (formato do Mongo)', () {
      final local = OrderLocationMapper.tryFromOrderJson(const {
        'pinCliente': {
          'type': 'Point',
          'coordinates': [-46.3280, -23.9722],
        },
        'pontoReferenciaId': 'posto-6',
        'descricaoLocal': 'Guarda-sol azul',
        'fotoLocalUrl': 'https://cdn.example.com/foto.jpg',
      });
      expect(local, isNotNull);
      expect(local!.latitude, -23.9722);
      expect(local.longitude, -46.3280);
      expect(local.pontoReferenciaId, 'posto-6');
      expect(local.descricaoLocal, 'Guarda-sol azul');
      expect(local.fotoLocalUrl, 'https://cdn.example.com/foto.jpg');
    });

    test('tryFromOrderJson aceita pinCliente {latitude, longitude}', () {
      final local = OrderLocationMapper.tryFromOrderJson(const {
        'pinCliente': {'latitude': -23.9722, 'longitude': -46.3280},
        'pontoReferenciaId': 'posto-6',
      });
      expect(local!.latitude, -23.9722);
      expect(local.descricaoLocal, '');
      expect(local.fotoLocalUrl, isNull);
    });

    test('sem pinCliente devolve null', () {
      expect(
        OrderLocationMapper.tryFromOrderJson(const {'id': 'o1'}),
        isNull,
      );
    });

    test('toOrderFields gera pinCliente e omite foto nula', () {
      const local = OrderLocation(
        latitude: -23.9722,
        longitude: -46.3280,
        pontoReferenciaId: 'posto-6',
        descricaoLocal: 'Guarda-sol azul',
      );
      final fields = OrderLocationMapper.toOrderFields(local);
      expect(fields, {
        'pinCliente': {'latitude': -23.9722, 'longitude': -46.3280},
        'pontoReferenciaId': 'posto-6',
        'descricaoLocal': 'Guarda-sol azul',
      });
      expect(fields.containsKey('fotoLocalUrl'), isFalse);
    });

    test('toOrderFields inclui foto quando presente', () {
      const local = OrderLocation(
        latitude: -23.9722,
        longitude: -46.3280,
        pontoReferenciaId: 'posto-6',
        descricaoLocal: 'Guarda-sol azul',
        fotoLocalUrl: 'https://cdn.example.com/foto.jpg',
      );
      final fields = OrderLocationMapper.toOrderFields(local);
      expect(fields['fotoLocalUrl'], 'https://cdn.example.com/foto.jpg');
    });
  });

  group('OrderMapper', () {
    test('le a resposta 201 completa de POST /orders', () {
      final order = OrderMapper.fromJson(const {
        'id': 'pedido-123',
        'userId': 'u1',
        'kioskId': 'k1',
        'courierId': 'c9',
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
        'pago': true,
        'pinCliente': {'latitude': -23.9722, 'longitude': -46.3280},
        'pontoReferenciaId': 'posto-6',
        'descricaoLocal': 'Guarda-sol azul',
        'fotoLocalUrl': 'https://cdn.example.com/foto.jpg',
        'status': 'PAGO',
        'timeline': {
          'criadoEm': '2026-10-13T10:00:00Z',
          'pagoEm': '2026-10-13T10:02:00Z',
        },
      });
      expect(order.id, 'pedido-123');
      expect(order.userId, 'u1');
      expect(order.kioskId, 'k1');
      expect(order.courierId, 'c9');
      expect(order.itens, hasLength(1));
      expect(order.itens.first.menuItemId, 'm1');
      expect(order.itens.first.nome, 'Agua de coco');
      expect(order.itens.first.quantidade, 2);
      expect(order.itens.first.precoUnitario, 8.5);
      expect(order.valorTotal, 17.0);
      expect(order.embalagemSustentavel, isTrue);
      expect(order.formaPagamento, PaymentMethod.pix);
      expect(order.pago, isTrue);
      expect(order.localizacao!.pontoReferenciaId, 'posto-6');
      expect(order.localizacao!.fotoLocalUrl, 'https://cdn.example.com/foto.jpg');
      expect(order.status, OrderStatus.pago);
      expect(order.timeline.criadoEm, DateTime.utc(2026, 10, 13, 10));
      expect(order.timeline.pagoEm, DateTime.utc(2026, 10, 13, 10, 2));
      expect(order.timeline.entregueEm, isNull);
    });

    test('campos opcionais ausentes usam defaults seguros', () {
      final order = OrderMapper.fromJson(const {'id': 'pedido-9'});
      expect(order.userId, '');
      expect(order.kioskId, '');
      expect(order.courierId, isNull);
      expect(order.itens, isEmpty);
      expect(order.valorTotal, 0);
      expect(order.embalagemSustentavel, isFalse);
      expect(order.formaPagamento, PaymentMethod.pix);
      expect(order.pago, isFalse);
      expect(order.localizacao, isNull);
      expect(order.status, OrderStatus.criado);
      expect(order.timeline.criadoEm, isNull);
    });

    test('status desconhecido cai no fallback sem quebrar', () {
      final order = OrderMapper.fromJson(const {
        'id': 'pedido-10',
        'status': 'STATUS_NOVO_DO_BACKEND',
      });
      expect(order.status, OrderStatus.desconhecido);
    });

    test('timeline ausente vira timeline vazia', () {
      final order = OrderMapper.fromJson(const {
        'id': 'pedido-11',
        'timeline': 'formato inesperado',
      });
      expect(order.timeline.criadoEm, isNull);
      expect(order.timeline.entregueEm, isNull);
    });

    test('toCreateOrderJson monta o corpo exato do contrato', () {
      const localizacao = OrderLocation(
        latitude: -23.9722,
        longitude: -46.3280,
        pontoReferenciaId: 'posto-6',
        descricaoLocal: 'Guarda-sol azul',
      );
      final body = OrderMapper.toCreateOrderJson(
        userId: 'u1',
        kioskId: 'k1',
        itens: const [
          OrderItemRequest(menuItemId: 'm1', quantidade: 2),
          OrderItemRequest(menuItemId: 'm2', quantidade: 1),
        ],
        formaPagamento: PaymentMethod.cartao,
        localizacao: localizacao,
        embalagemSustentavel: true,
      );
      expect(body, {
        'userId': 'u1',
        'kioskId': 'k1',
        'itens': [
          {'menuItemId': 'm1', 'quantidade': 2},
          {'menuItemId': 'm2', 'quantidade': 1},
        ],
        'formaPagamento': 'CARTAO',
        'pinCliente': {'latitude': -23.9722, 'longitude': -46.3280},
        'pontoReferenciaId': 'posto-6',
        'descricaoLocal': 'Guarda-sol azul',
        'embalagemSustentavel': true,
      });
      expect(body.containsKey('fotoLocalUrl'), isFalse);
    });

    test('toCreateOrderJson inclui foto quando enviada', () {
      const localizacao = OrderLocation(
        latitude: -23.9722,
        longitude: -46.3280,
        pontoReferenciaId: 'posto-6',
        descricaoLocal: 'Guarda-sol azul',
        fotoLocalUrl: 'https://cdn.example.com/foto.jpg',
      );
      final body = OrderMapper.toCreateOrderJson(
        userId: 'u1',
        kioskId: 'k1',
        itens: const [OrderItemRequest(menuItemId: 'm1', quantidade: 1)],
        formaPagamento: PaymentMethod.pix,
        localizacao: localizacao,
      );
      expect(body['fotoLocalUrl'], 'https://cdn.example.com/foto.jpg');
      expect(body['embalagemSustentavel'], isFalse);
    });
  });
}
