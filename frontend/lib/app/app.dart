import 'package:flutter/material.dart';

import '../domain/models/auth_session.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/courier/courier_home_screen.dart';
import '../presentation/customer/customer_home_screen.dart';
import '../presentation/location_selection/location_selection_screen.dart';
import '../presentation/prototype/prototype_screen.dart';
import '../presentation/theme/app_colors.dart';
import 'dependencies.dart';
import 'routes.dart';

class PeNaAreiaApp extends StatelessWidget {
  const PeNaAreiaApp({super.key, required this.dependencies});

  /// A primeira tela apresenta o protótipo e permite abrir o app autenticado.
  static const String initialRoute = AppRoutes.prototype;

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pé na Areia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandRed,
          primary: AppColors.brandRed,
          secondary: AppColors.positive,
          surface: AppColors.surface,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: initialRoute,
      routes: buildAppRoutes(dependencies),
    );
  }
}

/// Rotas nomeadas do app. Exposta para testes garantirem que a tela de
/// selecao de localizacao tem rota valida e alcancavel.
Map<String, WidgetBuilder> buildAppRoutes(AppDependencies dependencies) => {
      AppRoutes.prototype: (context) => PrototypeScreen(
            onLoginTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
      AppRoutes.login: (_) => LoginScreen(
            authRepository: dependencies.authRepository,
          ),
      AppRoutes.customerHome: (context) {
        final session = ModalRoute.of(context)?.settings.arguments;
        if (session is! AuthSession || session.isCourier) {
          throw StateError(
            'A rota do cliente exige uma sessao autenticada de cliente.',
          );
        }
        return CustomerHomeScreen(
          session: session,
          authRepository: dependencies.authRepository,
          catalogRepository: dependencies.catalogRepository,
          orderRepository: dependencies.orderRepository,
          locationSelectionController:
              dependencies.createLocationSelectionController,
        );
      },
      AppRoutes.courierHome: (_) => CourierHomeScreen(
            authRepository: dependencies.authRepository,
            orderRepository: dependencies.orderRepository,
            locationService: dependencies.locationService,
          ),
      AppRoutes.locationSelection: (_) => LocationSelectionScreen(
            controller: dependencies.createLocationSelectionController(),
          ),
    };
