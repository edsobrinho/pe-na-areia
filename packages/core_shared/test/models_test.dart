import 'package:flutter_test/flutter_test.dart';

import 'package:core_shared/domain/geo.dart';
import 'package:core_shared/domain/models/auth_session.dart';
import 'package:core_shared/domain/models/courier.dart';
import 'package:core_shared/domain/models/geo_point.dart';
import 'package:core_shared/domain/models/order.dart';
import 'package:core_shared/domain/models/order_location.dart';
import 'package:core_shared/domain/models/order_status.dart';
import 'package:core_shared/domain/models/payment_method.dart';

void main() {
  group('AuthSession', () {
    test('serializa e valida os dados de autenticação', () {
      const session = AuthSession(
        token: 'jwt',
        userId: 'user-1',
        name: 'Ana',
        role: 'COURIER',
      );

      expect(AuthSession.fromJson(session.toJson()).isCourier, isTrue);
    });

    test('rejeita campos ausentes ou com tipo inválido', () {
      expect(
        () => AuthSession.fromJson({'token': 'jwt'}),
        throwsFormatException,
      );
      expect(
        () => AuthSession.fromJson({
          'token': 'jwt',
          'userId': 1,
          'name': 'Ana',
          'role': 'CLIENT',
        }),
        throwsFormatException,
      );
    });
  });

  group('GeoPoint', () {
    test('e imutavel e expoe latitude/longitude', () {
      const ponto = GeoPoint(latitude: -23.9722, longitude: -46.3280);
      expect(ponto.latitude, -23.9722);
      expect(ponto.longitude, -46.3280);
    });
  });

  group('OrderLocation', () {
    test('aceita descricao no limite de 140 caracteres e foto opcional', () {
      final location = OrderLocation(
        latitude: -23.9722,
        longitude: -46.3280,
        pontoReferenciaId: 'posto-6',
        descricaoLocal: 'a' * OrderLocation.maxDescricaoLength,
        fotoLocalUrl: 'https://cdn.example.com/foto.jpg',
      );
      expect(location.fotoLocalUrl, 'https://cdn.example.com/foto.jpg');
    });

    test('rejeita descricao com mais de 140 caracteres', () {
      expect(
        () => OrderLocation(
          latitude: 0,
          longitude: 0,
          pontoReferenciaId: 'posto-6',
          descricaoLocal: 'a' * (OrderLocation.maxDescricaoLength + 1),
        ),
        throwsAssertionError,
      );
    });
  });

  group('OrderItemRequest', () {
    test('aceita quantidade positiva', () {
      const item = OrderItemRequest(menuItemId: 'm1', quantidade: 2);
      expect(item.quantidade, 2);
    });

    test('rejeita quantidade zero ou negativa', () {
      expect(
        () => OrderItemRequest(menuItemId: 'm1', quantidade: 0),
        throwsAssertionError,
      );
      expect(
        () => OrderItemRequest(menuItemId: 'm1', quantidade: -1),
        throwsAssertionError,
      );
    });
  });

  group('OrderStatus', () {
    test('mapeia todos os valores do contrato com o backend', () {
      expect(OrderStatus.fromWire('CRIADO'), OrderStatus.criado);
      expect(OrderStatus.fromWire('PAGO'), OrderStatus.pago);
      expect(OrderStatus.fromWire('EM_PREPARO'), OrderStatus.emPreparo);
      expect(OrderStatus.fromWire('A_CAMINHO'), OrderStatus.aCaminho);
      expect(
          OrderStatus.fromWire('CHEGOU_NO_LOCAL'), OrderStatus.chegouNoLocal);
      expect(OrderStatus.fromWire('ENTREGUE'), OrderStatus.entregue);
      expect(OrderStatus.fromWire('CANCELADO'), OrderStatus.cancelado);
      expect(
          OrderStatus.fromWire('NAO_ENCONTRADO'), OrderStatus.naoEncontrado);
    });

    test('valor desconhecido cai no fallback sem quebrar', () {
      expect(OrderStatus.fromWire('SEI_LA'), OrderStatus.desconhecido);
    });
  });

  group('PaymentMethod', () {
    test('mapeia PIX e CARTAO', () {
      expect(PaymentMethod.fromWire('PIX'), PaymentMethod.pix);
      expect(PaymentMethod.fromWire('CARTAO'), PaymentMethod.cartao);
    });

    test('forma desconhecida lanca ArgumentError', () {
      expect(() => PaymentMethod.fromWire('BOLETO'), throwsArgumentError);
    });
  });

  group('Courier', () {
    test('defaults: offline, sem veiculo e sem localizacao', () {
      const courier = Courier(id: 'c1', nome: 'Ze Entregador');
      expect(courier.status, CourierStatus.offline);
      expect(courier.veiculo, isNull);
      expect(courier.localizacao, isNull);
    });

    test('enums de wire do entregador', () {
      expect(VehicleType.fromWire('A_PE'), VehicleType.aPe);
      expect(VehicleType.fromWire('BICICLETA'), VehicleType.bicicleta);
      expect(CourierStatus.fromWire('DISPONIVEL'), CourierStatus.disponivel);
      expect(CourierStatus.fromWire('EM_ROTA'), CourierStatus.emRota);
      expect(() => VehicleType.fromWire('CARRO'), throwsArgumentError);
      expect(() => CourierStatus.fromWire('FÉRIAS'), throwsArgumentError);
    });
  });

  group('Order', () {
    test('defaults: CRIADO, nao pago, timeline vazia e sem entregador', () {
      const order = Order(
        id: 'o1',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 17.0,
        formaPagamento: PaymentMethod.pix,
      );
      expect(order.status, OrderStatus.criado);
      expect(order.pago, isFalse);
      expect(order.courierId, isNull);
      expect(order.itens, isEmpty);
      expect(order.localizacao, isNull);
      expect(order.timeline.criadoEm, isNull);
      expect(order.timeline.entregueEm, isNull);
    });

    test('codigoCurtoPedido remove cerquilha e NUNCA utiliza codigoEntrega', () {
      const orderWithCode = Order(
        id: 'o1',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 20.0,
        formaPagamento: PaymentMethod.pix,
        codigoPedido: '#0042',
        codigoEntrega: '9999',
      );
      expect(orderWithCode.codigoCurtoPedido, '0042');
      expect(orderWithCode.codigoFormatado, '#0042');
      expect(orderWithCode.codigoCurtoPedido, isNot(contains('9999')));

      // Normalização caso codigoPedido venha sem cerquilha
      const orderWithoutHash = Order(
        id: 'o2',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 20.0,
        formaPagamento: PaymentMethod.pix,
        codigoPedido: '0042',
      );
      expect(orderWithoutHash.codigoCurtoPedido, '0042');
      expect(orderWithoutHash.codigoFormatado, '#0042');

      const orderFallback = Order(
        id: 'pedido-xyz-123',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 20.0,
        formaPagamento: PaymentMethod.pix,
        codigoEntrega: '1234',
      );
      // Fallback determinístico derivado do hash do id; NUNCA deve ser '1234'
      expect(orderFallback.codigoCurtoPedido, isNot('1234'));
      expect(orderFallback.codigoFormatado, '#${orderFallback.codigoCurtoPedido}');
    });

    test('isChatActive e isChatExpired refletem ciclo de vida do pedido', () {
      const orderPronto = Order(
        id: 'o1',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 20.0,
        formaPagamento: PaymentMethod.pix,
        status: OrderStatus.prontoEntrega,
      );
      expect(orderPronto.isChatActive, isTrue);
      expect(orderPronto.isChatExpired, isFalse);

      final orderACaminho = orderPronto.copyWith(status: OrderStatus.aCaminho);
      expect(orderACaminho.isChatActive, isTrue);
      expect(orderACaminho.isChatExpired, isFalse);

      final orderChegou = orderPronto.copyWith(status: OrderStatus.chegouNoLocal);
      expect(orderChegou.isChatActive, isTrue);
      expect(orderChegou.isChatExpired, isFalse);

      final orderEntregue = orderPronto.copyWith(status: OrderStatus.entregue);
      expect(orderEntregue.isChatActive, isFalse);
      expect(orderEntregue.isChatExpired, isTrue);

      final orderCancelado = orderPronto.copyWith(status: OrderStatus.cancelado);
      expect(orderCancelado.isChatActive, isFalse);
      expect(orderCancelado.isChatExpired, isTrue);

      final orderNaoEncontrado = orderPronto.copyWith(status: OrderStatus.naoEncontrado);
      expect(orderNaoEncontrado.isChatActive, isFalse);
      expect(orderNaoEncontrado.isChatExpired, isTrue);

      final orderCriado = orderPronto.copyWith(status: OrderStatus.criado);
      expect(orderCriado.isChatActive, isFalse);
      expect(orderCriado.isChatExpired, isFalse);
    });
  });

  group('distanceMeters', () {
    test('mesmo ponto devolve zero', () {
      const ponto = GeoPoint(latitude: -23.9722, longitude: -46.3280);
      expect(distanceMeters(ponto, ponto), 0);
    });

    test('um grau de latitude na linha do equador equivale a ~111 km', () {
      final metros = distanceMeters(
        const GeoPoint(latitude: 0, longitude: 0),
        const GeoPoint(latitude: 1, longitude: 0),
      );
      expect(metros, closeTo(111195, 100));
    });

    test('e simetrica', () {
      const a = GeoPoint(latitude: -23.9722, longitude: -46.3280);
      const b = GeoPoint(latitude: -23.9760, longitude: -46.3190);
      expect(distanceMeters(a, b), closeTo(distanceMeters(b, a), 0.001));
      expect(distanceMeters(a, b), greaterThan(0));
    });
  });
}
