import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:core_shared/core_shared.dart';
import 'package:pe_na_areia_cliente/app/dependencies.dart';
import 'package:pe_na_areia_cliente/presentation/customer/customer_home_screen.dart';
import 'package:pe_na_areia_cliente/presentation/customer/order_details_sheet.dart';

class _FakeLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentPosition() async =>
      const GeoPoint(latitude: -23.9680, longitude: -46.3315);
}

void main() {
  group('Customer Order Details & PIN Labels Tests', () {
    late Order testOrder;

    setUp(() {
      testOrder = const Order(
        id: 'ord-cli-42',
        userId: 'user-cli',
        kioskId: 'kiosk-sol',
        valorTotal: 52.0,
        formaPagamento: PaymentMethod.pix,
        codigoPedido: '#0042',
        numeroPedidoDiario: 42,
        codigoEntrega: '8421',
        status: OrderStatus.aCaminho,
        localizacao: OrderLocation(
          latitude: -23.9680,
          longitude: -46.3315,
          pontoReferenciaId: 'posto-3',
          descricaoLocal: 'Guarda-sol azul próximo ao Canal 3',
        ),
        localizacaoEntregador: GeoPoint(
          latitude: -23.9690,
          longitude: -46.3325,
        ),
      );
    });

    testWidgets(
        'OrderDetailsSheet exibe identificador sequencial #0042 e PIN DE CONFIRMAÇÃO DE ENTREGA',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderDetailsSheet(order: testOrder),
          ),
        ),
      );

      await tester.pump();

      // Cabeçalho com sequencial diário desacoplado do PIN
      expect(find.text('Pedido #0042'), findsOneWidget);

      // Card de PIN com rotulagem explícita
      expect(
        find.text('PIN DE CONFIRMAÇÃO DE ENTREGA (4 DÍGITOS)'),
        findsOneWidget,
      );

      // Dígitos do PIN
      expect(find.text('8'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets(
        'CustomerHomeScreen exibe PEDIDO #0042, PIN DE ENTREGA: 8421, fallback de mapa e botão de chat',
        (tester) async {
      GoogleMapsChecker.debugOverrideIsReady = false;
      addTearDown(() => GoogleMapsChecker.debugOverrideIsReady = null);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/orders/ord-cli-42')) {
          return http.Response(
            '''{
              "id":"ord-cli-42",
              "userId":"user-cli",
              "kioskId":"kiosk-sol",
              "valorTotal":52.0,
              "formaPagamento":"PIX",
              "codigoPedido":"#0042",
              "numeroPedidoDiario":42,
              "codigoEntrega":"8421",
              "status":"A_CAMINHO",
              "pinCliente":{"latitude":-23.9680,"longitude":-46.3315,"pontoReferenciaId":"posto-3","descricaoLocal":"Guarda-sol azul"},
              "localizacaoEntregador":{"latitude":-23.9690,"longitude":-46.3325}
            }''',
            200,
          );
        }
        if (request.url.path.contains('/partnerships')) {
          return http.Response('[]', 200);
        }
        return http.Response('{}', 200);
      });

      final apiClient =
          ApiClient(baseUrl: 'http://test.api', httpClient: mockClient);
      final deps = AppDependencies(
        apiClient: apiClient,
        locationService: _FakeLocationService(),
      );

      const session = AuthSession(
        token: 'token-123',
        userId: 'user-cli',
        name: 'Cliente Teste',
        role: 'CLIENT',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerHomeScreen(
            session: session,
            authRepository: deps.authRepository,
            catalogRepository: deps.catalogRepository,
            orderRepository: deps.orderRepository,
            locationSelectionController: deps.createLocationSelectionController,
            initialOrder: testOrder,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PEDIDO #0042'), findsOneWidget);
      expect(find.text('PIN DE ENTREGA: 8421'), findsOneWidget);
      expect(find.text('Ponto na Areia (Santos - SP)'), findsOneWidget);
      expect(find.text('CHAT COM O ENTREGADOR'), findsOneWidget);
    });
  });
}
