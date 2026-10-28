import 'package:flutter_test/flutter_test.dart';
import 'package:pe_na_areia/data/mappers/kiosk_mapper.dart';
import 'package:pe_na_areia/data/mappers/order_location_mapper.dart';
import 'package:pe_na_areia/domain/models/geo_point.dart';
import 'package:pe_na_areia/domain/models/order.dart';
import 'package:pe_na_areia/domain/models/order_location.dart';
import 'package:pe_na_areia/domain/models/order_status.dart';
import 'package:pe_na_areia/domain/models/partnership.dart';
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

  group('Storefront & Ponto na Praia v2.1 (6 Telas Costeiras)', () {
    test('mapeia Kiosk com vitrine, fotoCapaUrl, destaquePopular e MenuItem.destaque', () {
      final kiosk = KioskMapper.fromJson({
        'id': 'k-santos-1',
        'nome': 'Quiosque Sol & Mar',
        'pontoReferenciaId': 'posto-4',
        'aceitaEmbalagemSustentavel': true,
        'ativo': true,
        'fotoCapaUrl': 'https://cdn.local/capa.jpg',
        'logoUrl': 'https://cdn.local/logo.jpg',
        'descricaoCurta': 'Frutos do Mar e Porções',
        'avaliacaoMedia': 4.9,
        'destaquePopular': true,
        'cardapio': [
          {
            'id': 'm1',
            'nome': 'Camarão na Moranga',
            'descricao': 'Porção 500g',
            'preco': 64.9,
            'disponivel': true,
            'category': 'Frutos do Mar',
            'returnablePackaging': true,
            'fotoUrl': 'https://cdn.local/camarao.jpg',
            'destaque': true,
          },
        ],
      });

      expect(kiosk.fotoCapaUrl, 'https://cdn.local/capa.jpg');
      expect(kiosk.logoUrl, 'https://cdn.local/logo.jpg');
      expect(kiosk.descricaoCurta, 'Frutos do Mar e Porções');
      expect(kiosk.avaliacaoMedia, 4.9);
      expect(kiosk.destaquePopular, isTrue);
      expect(kiosk.imagemDestaqueUrl, 'https://cdn.local/capa.jpg');
      expect(kiosk.categoriasDisponiveis, ['Frutos do Mar']);
      expect(kiosk.cardapio.first.destaque, isTrue);
    });

    test('serializa e desserializa OrderLocation com campos detalhados do Ponto na Praia', () {
      const spot = OrderLocation(
        latitude: -23.9722,
        longitude: -46.3280,
        pontoReferenciaId: 'posto-4',
        descricaoLocal: 'Guarda-sol azul marinho · Em frente à rede',
        fotoLocalUrl: 'https://cdn.local/guarda-sol.jpg',
        referenciaBarraca: 'Guarda-sol azul marinho',
        complementoLocal: 'Em frente à rede',
        fotoVisaoPostoUrl: 'https://cdn.local/posto.jpg',
        fotoOutroReferencialUrl: 'https://cdn.local/cooler.jpg',
        contatoNome: 'Marina Santos',
        contatoTelefone: '+55 (13) 99876-5432',
        etiquetaLocal: 'MEU_GUARDA_SOL',
      );

      expect(spot.etiquetaAmigavel, 'Meu Guarda-sol');

      final wire = OrderLocationMapper.toOrderFields(spot);
      expect(wire['referenciaBarraca'], 'Guarda-sol azul marinho');
      expect(wire['complementoLocal'], 'Em frente à rede');
      expect(wire['fotoVisaoPostoUrl'], 'https://cdn.local/posto.jpg');
      expect(wire['contatoNome'], 'Marina Santos');
      expect(wire['etiquetaLocal'], 'MEU_GUARDA_SOL');

      final parsed = OrderLocationMapper.tryFromOrderJson({
        ...wire,
        'pinCliente': {
          'type': 'Point',
          'coordinates': [-46.3280, -23.9722],
        },
      });
      expect(parsed, isNotNull);
      expect(parsed!.referenciaBarraca, 'Guarda-sol azul marinho');
      expect(parsed.contatoNome, 'Marina Santos');
      expect(parsed.etiquetaAmigavel, 'Meu Guarda-sol');
    });

    test('calcula customerDeliveryFee e estimatedTimeRangeLabel em KioskPartnershipOffer', () {
      final offerClientPays = KioskPartnershipOffer.fromJson({
        'partnershipId': 'pe-na-areia-app',
        'name': 'App Pé na Areia',
        'channel': 'APP',
        'deliveryFee': 6.5,
        'deliveryFeePayer': 'CLIENT',
        'minimumOrder': 20.0,
        'prepMinutes': 15,
      });
      expect(offerClientPays.customerDeliveryFee, 6.5);
      expect(offerClientPays.isFreeDelivery, isFalse);
      expect(offerClientPays.estimatedTimeRangeLabel, '15 a 25 min');

      final offerKioskPays = KioskPartnershipOffer.fromJson({
        'partnershipId': 'pe-na-areia-app',
        'name': 'App Pé na Areia',
        'channel': 'APP',
        'deliveryFee': 6.5,
        'deliveryFeePayer': 'KIOSK',
        'minimumOrder': 15.0,
        'prepMinutes': 20,
      });
      expect(offerKioskPays.customerDeliveryFee, 0.0);
      expect(offerKioskPays.isFreeDelivery, isTrue);
      expect(offerKioskPays.estimatedTimeRangeLabel, '20 a 30 min');
    });
  });
}
