import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:core_shared/core_shared.dart';

void main() {
  group('OrderChatBottomSheet Widget Tests', () {
    late Order baseActiveOrder;
    late Order baseExpiredOrder;

    setUp(() {
      baseActiveOrder = const Order(
        id: 'ord-100',
        userId: 'cli-1',
        kioskId: 'kiosk-sol',
        valorTotal: 30.0,
        formaPagamento: PaymentMethod.pix,
        codigoPedido: '#0042',
        numeroPedidoDiario: 42,
        codigoEntrega: '7777',
        status: OrderStatus.aCaminho,
        mensagens: [
          OrderMessage(
            senderId: 'cli-1',
            senderRole: 'CLIENT',
            texto: 'Estou no guarda-sol azul perto do canal 3',
          ),
          OrderMessage(
            senderId: 'cour-1',
            senderRole: 'COURIER',
            texto: 'Chegando na faixa de areia!',
          ),
        ],
      );

      baseExpiredOrder = baseActiveOrder.copyWith(
        status: OrderStatus.entregue,
      );
    });

    testWidgets('exibe cabeçalho com codigoFormatado e banner de chat ativo',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/orders/ord-100')) {
          return http.Response(
            '{"id":"ord-100","userId":"cli-1","kioskId":"kiosk-sol","status":"A_CAMINHO","codigoPedido":"#0042"}',
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
            body: OrderChatBottomSheet(
              order: baseActiveOrder,
              orderRepository: repo,
              currentUserRole: 'CLIENT',
            ),
          ),
        ),
      );

      await tester.pump();

      // Header com codigoFormatado
      expect(find.text('Chat do Pedido #0042'), findsOneWidget);

      // Banner de status ativo
      expect(find.text('● Chat em tempo real ativo'), findsOneWidget);

      // Mensagens no histórico
      expect(find.text('Estou no guarda-sol azul perto do canal 3'), findsOneWidget);
      expect(find.text('Chegando na faixa de areia!'), findsOneWidget);

      // Chips rápidos do cliente
      expect(find.text('Estou de guarda-sol azul! 🏖️'), findsOneWidget);

      // Campo de texto habilitado
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isTrue);
    });

    testWidgets('bloqueia envio e exibe aviso de expirado quando status for ENTREGUE',
        (tester) async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final repo = OrderRepository(
        ApiClient(baseUrl: 'http://test.api', httpClient: mockClient),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderChatBottomSheet(
              order: baseExpiredOrder,
              orderRepository: repo,
              currentUserRole: 'CLIENT',
            ),
          ),
        ),
      );

      await tester.pump();

      // Banner de trava de sessão expirada
      expect(
        find.text('🔒 Sessão de chat expirada. O pedido foi finalizado.'),
        findsOneWidget,
      );

      // Campo de texto desabilitado
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Botão de envio desabilitado
      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send_rounded),
      );
      expect(iconButton.onPressed, isNull);
    });
  });
}
