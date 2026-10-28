import 'package:flutter_test/flutter_test.dart';
import 'package:pe_na_areia/domain/models/geo_point.dart';
import 'package:pe_na_areia/domain/models/order.dart';
import 'package:pe_na_areia/domain/models/order_location.dart';
import 'package:pe_na_areia/domain/models/order_status.dart';
import 'package:pe_na_areia/domain/models/payment_method.dart';
import 'package:pe_na_areia/domain/utils/beach_compass.dart';

void main() {
  group('BeachCompass (Modo Bússola / Radar na Areia)', () {
    test('calcula distância em metros e direção cardeal corretamente', () {
      const lat1 = -23.9700;
      const lng1 = -46.3280;
      // Ponto ao Sul (~44m)
      const lat2 = -23.9704;
      const lng2 = -46.3280;

      final dist = BeachCompass.distanceMeters(lat1, lng1, lat2, lng2);
      expect(dist, closeTo(44.5, 2.0));

      final bearing = BeachCompass.bearingDegrees(lat1, lng1, lat2, lng2);
      expect(bearing, closeTo(180.0, 1.0));
      expect(BeachCompass.cardinalDirectionPtBr(bearing), equals('Sul'));

      final instruction = BeachCompass.formatRadarInstruction(
        courierLat: lat1,
        courierLng: lng1,
        pinLat: lat2,
        pinLng: lng2,
        referenceLabel: 'Posto 6',
      );
      expect(instruction, contains('Sul (180°)'));
      expect(instruction, contains('Posto 6'));
    });

    test('converte ângulos para todas as 8 direções cardeais/colaterais', () {
      expect(BeachCompass.cardinalDirectionPtBr(0), 'Norte');
      expect(BeachCompass.cardinalDirectionPtBr(45), 'Nordeste');
      expect(BeachCompass.cardinalDirectionPtBr(90), 'Leste');
      expect(BeachCompass.cardinalDirectionPtBr(135), 'Sudeste');
      expect(BeachCompass.cardinalDirectionPtBr(180), 'Sul');
      expect(BeachCompass.cardinalDirectionPtBr(225), 'Sudoeste');
      expect(BeachCompass.cardinalDirectionPtBr(270), 'Oeste');
      expect(BeachCompass.cardinalDirectionPtBr(315), 'Noroeste');
    });
  });

  group('Order.podeAtivarSinalizador (Regra do Farol Visual)', () {
    const pinCliente = OrderLocation(
      latitude: -23.9720,
      longitude: -46.3280,
      pontoReferenciaId: 'rp1',
      descricaoLocal: 'Guarda-sol azul',
    );

    test('permite ativar quando status for CHEGOU_NO_LOCAL', () {
      const order = Order(
        id: 'o1',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 25.0,
        formaPagamento: PaymentMethod.pix,
        localizacao: pinCliente,
        status: OrderStatus.chegouNoLocal,
      );
      expect(order.podeAtivarSinalizador, isTrue);
    });

    test('bloqueia quando A_CAMINHO mas entregador está a mais de 60m', () {
      const orderLonge = Order(
        id: 'o1',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 25.0,
        formaPagamento: PaymentMethod.pix,
        localizacao: pinCliente,
        localizacaoEntregador: GeoPoint(
          latitude: -23.9700, // ~222m de distância
          longitude: -46.3280,
        ),
        status: OrderStatus.aCaminho,
      );
      expect(orderLonge.podeAtivarSinalizador, isFalse);
    });

    test('permite ativar quando A_CAMINHO e entregador está a menos de 60m', () {
      const orderPerto = Order(
        id: 'o1',
        userId: 'u1',
        kioskId: 'k1',
        valorTotal: 25.0,
        formaPagamento: PaymentMethod.pix,
        localizacao: pinCliente,
        localizacaoEntregador: GeoPoint(
          latitude: -23.9718, // ~22m de distância
          longitude: -46.3280,
        ),
        status: OrderStatus.aCaminho,
      );
      expect(orderPerto.podeAtivarSinalizador, isTrue);
    });
  });
}

