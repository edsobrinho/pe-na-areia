import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:core_shared/core_shared.dart';
import 'package:pe_na_areia_entregador/app/app.dart';
import 'package:pe_na_areia_entregador/app/dependencies.dart';
import 'package:pe_na_areia_entregador/app/routes.dart';
import 'package:pe_na_areia_entregador/presentation/auth/login_screen.dart';

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
  group('App do Entregador', () {
    test('rota inicial aponta para login de entregador', () {
      expect(PeNaAreiaEntregadorApp.initialRoute, AppRoutes.login);
      expect(PeNaAreiaEntregadorApp.initialRoute, '/');
    });

    test('rotas registradas sao validas', () {
      final routes = buildAppRoutes(buildDependencies());
      expect(routes.containsKey(AppRoutes.login), isTrue);
      expect(routes.containsKey(AppRoutes.courierHome), isTrue);
    });

    testWidgets('renderiza tela de acesso inicial', (tester) async {
      await tester.pumpWidget(
        PeNaAreiaEntregadorApp(dependencies: buildDependencies()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Acesso'), findsOneWidget);
    });
  });
}

