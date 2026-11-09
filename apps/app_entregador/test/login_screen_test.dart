import 'dart:convert';

import 'package:core_shared/core_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pe_na_areia_entregador/app/routes.dart';
import 'package:pe_na_areia_entregador/presentation/auth/login_screen.dart';

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
    'cadastro do entregador remove switch de papel, mantem veiculo A pe por padrao e envia role COURIER',
    (tester) async {
      Map<String, dynamic>? capturedPayload;
      final client = MockClient((request) async {
        if (request.url.path == '/auth/register') {
          capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'token': 'jwt-courier',
              'userId': 'courier-1',
              'name': 'Marcos Entregador',
              'role': 'COURIER',
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
            AppRoutes.courierHome: (_) =>
                const Scaffold(body: Text('HOME ENTREGADOR')),
          },
        ),
      );

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Sou entregador'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('A pé'), findsOneWidget);
      expect(find.text('Bicicleta'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Marcos Entregador');
      await tester.enterText(fields.at(1), '13999999999');
      await tester.enterText(fields.at(2), 'marcos@example.com');
      await tester.enterText(fields.at(3), '123456');

      final submitBtn = find.widgetWithText(FilledButton, 'Criar conta');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['role'], 'COURIER');
      expect(capturedPayload!['vehicle'], 'PE');
      expect(find.text('HOME ENTREGADOR'), findsOneWidget);
    },
  );

  testWidgets(
    'cadastro do entregador permite selecionar Bicicleta e envia vehicle BIKE com role COURIER',
    (tester) async {
      Map<String, dynamic>? capturedPayload;
      final client = MockClient((request) async {
        if (request.url.path == '/auth/register') {
          capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'token': 'jwt-courier',
              'userId': 'courier-2',
              'name': 'Ana Bike',
              'role': 'COURIER',
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
            AppRoutes.courierHome: (_) =>
                const Scaffold(body: Text('HOME ENTREGADOR')),
          },
        ),
      );

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      final bikeOption = find.text('Bicicleta');
      await tester.ensureVisible(bikeOption);
      await tester.tap(bikeOption);
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ana Bike');
      await tester.enterText(fields.at(1), '13988887777');
      await tester.enterText(fields.at(2), 'ana.bike@example.com');
      await tester.enterText(fields.at(3), '123456');

      final submitBtn = find.widgetWithText(FilledButton, 'Criar conta');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['role'], 'COURIER');
      expect(capturedPayload!['vehicle'], 'BIKE');
      expect(find.text('HOME ENTREGADOR'), findsOneWidget);
    },
  );
}
