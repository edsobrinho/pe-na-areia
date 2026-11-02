import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:core_shared/core_shared.dart';
import 'package:pe_na_areia_prototipo/app/app.dart';
import 'package:pe_na_areia_prototipo/app/dependencies.dart';
import 'package:pe_na_areia_prototipo/app/routes.dart';
import 'package:pe_na_areia_prototipo/presentation/prototype/prototype_screen.dart';

class _NoopLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentPosition() async =>
      const GeoPoint(latitude: -23.9722, longitude: -46.3280);
}

AppDependencies buildDependencies() => AppDependencies(
      apiClient: ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      ),
      locationService: _NoopLocationService(),
    );

void main() {
  test('rota inicial aponta para o prototipo navegavel', () {
    expect(PeNaAreiaPrototipoApp.initialRoute, AppRoutes.prototype);
    expect(PeNaAreiaPrototipoApp.initialRoute, '/');
    expect(PeNaAreiaPrototipoApp.initialRoute.startsWith('/'), isTrue);
  });

  test('todas as rotas registradas sao nomeadas e validas', () {
    final routes = buildAppRoutes(buildDependencies());

    expect(routes, isNotEmpty);
    expect(routes.containsKey(AppRoutes.prototype), isTrue);
    expect(routes.containsKey(AppRoutes.splash), isTrue);
    expect(routes.containsKey(AppRoutes.login), isTrue);
    for (final rota in routes.keys) {
      expect(rota.startsWith('/'), isTrue, reason: 'rota invalida: $rota');
    }
  });

  testWidgets('prototipo alterna entre mapa, cliente e entregador',
      (tester) async {
    await tester.pumpWidget(
      PeNaAreiaPrototipoApp(dependencies: buildDependencies()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PrototypeScreen), findsOneWidget);
    expect(find.text('Mapa do fluxo'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Entregador'), findsOneWidget);

    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, praia!'), findsOneWidget);

    await tester.tap(find.text('Entregador'));
    await tester.pumpAndSettle();
    expect(find.text('Pedidos disponíveis'), findsOneWidget);
  });

  testWidgets('protótipo se ajusta à tela de celular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      PeNaAreiaPrototipoApp(dependencies: buildDependencies()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, praia!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card de entrada abre o fluxo do cliente', (tester) async {
    await tester.pumpWidget(
      PeNaAreiaPrototipoApp(dependencies: buildDependencies()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Um dia de praia mais leve'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, praia!'), findsOneWidget);
  });

  testWidgets('botão Entrar continua levando à autenticação real',
      (tester) async {
    await tester.pumpWidget(
      PeNaAreiaPrototipoApp(dependencies: buildDependencies()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Já tenho conta'), findsNothing);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('mapa do fluxo abre cliente e entregador nas telas escolhidas',
      (tester) async {
    await tester.pumpWidget(
      PeNaAreiaPrototipoApp(dependencies: buildDependencies()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Acompanhamento'));
    await tester.pumpAndSettle();
    expect(find.text('Seu pedido está a caminho'), findsOneWidget);

    await tester.dragFrom(
      const Offset(400, 520),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preciso de ajuda · Sinal'));
    await tester.pumpAndSettle();
    await tester.dragFrom(
      const Offset(400, 520),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar sinal à equipe'));
    await tester.pumpAndSettle();
    expect(
        find.text('A equipe recebeu seu pedido de contato.'), findsOneWidget);

    await tester.tap(find.text('Entregador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmação'));
    await tester.pumpAndSettle();
    expect(find.text('Confirme a entrega'), findsOneWidget);

    await tester.dragFrom(
      const Offset(400, 520),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar entrega'));
    await tester.pumpAndSettle();
    expect(find.text('Conversa com o cliente'), findsOneWidget);
  });
}
