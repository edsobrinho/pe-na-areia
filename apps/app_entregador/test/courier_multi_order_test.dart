import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:core_shared/core_shared.dart';
import 'package:pe_na_areia_entregador/app/dependencies.dart';
import 'package:pe_na_areia_entregador/presentation/courier/courier_home_screen.dart';

class _FakeLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentPosition() async =>
      const GeoPoint(latitude: -23.9680, longitude: -46.3315);
}

void main() {
  group('CourierHomeScreen Multi-Order & Batching Tests', () {
    testWidgets('exibe carrossel com múltiplos pedidos ativos e badge de quiosque vizinho',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/orders/courier/active')) {
          return http.Response(
            '''[
              {"id":"ord-1","userId":"u1","kioskId":"kiosk-sol","status":"A_CAMINHO","codigoPedido":"#0001","numeroPedidoDiario":1,"valorTotal":25.0,"pinCliente":{"latitude":-23.9680,"longitude":-46.3310}},
              {"id":"ord-2","userId":"u2","kioskId":"kiosk-sol","status":"CHEGOU_NO_LOCAL","codigoPedido":"#0002","numeroPedidoDiario":2,"valorTotal":35.0,"pinCliente":{"latitude":-23.9690,"longitude":-46.3320}}
            ]''',
            200,
          );
        }
        if (request.url.path.contains('/orders/available')) {
          return http.Response(
            '''[
              {"id":"ord-3","userId":"u3","kioskId":"kiosk-sol","status":"PRONTO_ENTREGA","codigoPedido":"#0003","numeroPedidoDiario":3,"valorTotal":50.0,"pinCliente":{"latitude":-23.9685,"longitude":-46.3312}}
            ]''',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final deps = AppDependencies(
        apiClient: ApiClient(baseUrl: 'http://test.api', httpClient: mockClient),
        locationService: _FakeLocationService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CourierHomeScreen(
            authRepository: deps.authRepository,
            orderRepository: deps.orderRepository,
            locationService: deps.locationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Confirma identificadores nos cartões ativos
      expect(find.text('#0001'), findsWidgets);
      expect(find.text('#0002'), findsWidgets);

      // Confirma badge de Quiosque Vizinho na ordem disponível
      expect(
        find.text('QUIOSQUE VIZINHO (Próximo das suas entregas)'),
        findsOneWidget,
      );

      // Confirma botão de chat com o cliente presente no pedido em foco
      expect(find.text('CHAT COM O CLIENTE'), findsOneWidget);
    });

    testWidgets('trava limite de 5 pedidos ativos e exibe banner de capacidade maxima',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      // 5 pedidos ativos simultâneos
      final active5Json = List.generate(
        5,
        (i) =>
            '{"id":"ord-$i","userId":"u$i","kioskId":"kiosk-sol","status":"A_CAMINHO","codigoPedido":"#000${i + 1}","numeroPedidoDiario":${i + 1},"valorTotal":20.0,"pinCliente":{"latitude":-23.9680,"longitude":-46.3310}}',
      ).join(',');

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/orders/courier/active')) {
          return http.Response('[$active5Json]', 200);
        }
        if (request.url.path.contains('/orders/available')) {
          return http.Response(
            '''[
              {"id":"ord-99","userId":"u99","kioskId":"kiosk-outro","status":"PRONTO_ENTREGA","codigoPedido":"#0099","numeroPedidoDiario":99,"valorTotal":40.0,"pinCliente":{"latitude":-23.9685,"longitude":-46.3312}}
            ]''',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final deps = AppDependencies(
        apiClient: ApiClient(baseUrl: 'http://test.api', httpClient: mockClient),
        locationService: _FakeLocationService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CourierHomeScreen(
            authRepository: deps.authRepository,
            orderRepository: deps.orderRepository,
            locationService: deps.locationService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Banner de capacidade máxima atingida
      expect(
        find.text(
          'Capacidade máxima atingida: 5 pedidos ativos em rota. Conclua uma entrega para aceitar novos pedidos.',
        ),
        findsOneWidget,
      );

      // Botão de aceite desabilitado indicando o limite de 5
      expect(find.text('LIMITE DE 5 PEDIDOS ATINGIDO'), findsOneWidget);
    });
  });
}
