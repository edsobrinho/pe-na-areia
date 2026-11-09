import 'dart:convert';

import 'package:core_shared/core_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pe_na_areia_cliente/app/routes.dart';
import 'package:pe_na_areia_cliente/presentation/auth/login_screen.dart';

class _MemorySessionStorage implements AuthSessionStorage {
  AuthSession? session;

  @override
  Future<void> save(AuthSession session) async => this.session = session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<String?> readToken() async => session?.token;

  @override
  Future<void> clear() async => session = null;
}

void main() {
  testWidgets(
    'cadastro do cliente oculta switch de entregador e envia role CLIENT fixo',
    (tester) async {
      Map<String, dynamic>? capturedPayload;
      final client = MockClient((request) async {
        if (request.url.path == '/auth/register') {
          capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'token': 'jwt-client',
              'userId': 'user-1',
              'name': 'Carlos Silva',
              'role': 'CLIENT',
            }),
            201,
          );
        }
        return http.Response('{}', 404);
      });

      final authRepo = AuthRepository(
        ApiClient(baseUrl: 'http://api.test', httpClient: client),
        _MemorySessionStorage(),
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (_) => LoginScreen(authRepository: authRepo),
            AppRoutes.customerHome: (_) =>
                const Scaffold(body: Text('HOME CLIENTE')),
          },
        ),
      );

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Sou entregador'), findsNothing);
      expect(find.byType(Switch), findsNothing);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Carlos Silva');
      await tester.enterText(fields.at(1), '13999999999');
      await tester.enterText(fields.at(2), 'carlos@example.com');
      await tester.enterText(fields.at(3), '123456');

      final submitBtn = find.widgetWithText(FilledButton, 'Criar conta');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['role'], 'CLIENT');
      expect(capturedPayload!['vehicle'], isNull);
      expect(find.text('HOME CLIENTE'), findsOneWidget);
    },
  );
}
