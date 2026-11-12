import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:core_shared/core_shared.dart';
import 'package:pe_na_areia_entregador/presentation/courier/delivery_pin_dialog.dart';

class _FakeLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentPosition() async =>
      const GeoPoint(latitude: -23.9680, longitude: -46.3315);
}

void main() {
  group('DeliveryPinConfirmationDialog Widget Tests', () {
    late Order testOrder;

    setUp(() {
      testOrder = const Order(
        id: 'ord-pin-1',
        userId: 'user-1',
        kioskId: 'kiosk-1',
        courierId: 'courier-1',
        valorTotal: 45.0,
        formaPagamento: PaymentMethod.pix,
        codigoPedido: '#0001',
        numeroPedidoDiario: 1,
        codigoEntrega: '8421',
        status: OrderStatus.aCaminho,
        localizacao: OrderLocation(
          latitude: -23.9685,
          longitude: -46.3310,
          pontoReferenciaId: 'posto-3',
          descricaoLocal: 'Barraca Amarela Canal 3',
        ),
      );
    });

    testWidgets(
        'renderiza codigoFormatado #0001 e valida 4 dígitos numéricos',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/confirm-delivery')) {
          return http.Response(
            '{"id":"ord-pin-1","userId":"user-1","kioskId":"kiosk-1","status":"ENTREGUE"}',
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = OrderRepository(
        ApiClient(baseUrl: 'http://test.api', httpClient: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryPinConfirmationDialog(
              order: testOrder,
              courierId: 'courier-1',
              orderRepository: repo,
              locationService: _FakeLocationService(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Confirma que exibe o identificador sequencial diário #0001
      expect(find.text('#0001'), findsOneWidget);
      expect(find.text('Barraca Amarela Canal 3'), findsOneWidget);

      // Tenta submeter sem preencher o PIN
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pump();

      expect(
        find.text('Informe exatamente os 4 dígitos do código de entrega.'),
        findsOneWidget,
      );

      // Digita apenas 3 dígitos
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pump();

      expect(
        find.text('Informe exatamente os 4 dígitos do código de entrega.'),
        findsOneWidget,
      );

      // Digita os 4 dígitos e submete
      await tester.enterText(find.byType(TextField), '8421');
      await tester.tap(find.text('CONFIRMAR'));
      await tester.pump();
    });
  });
}
