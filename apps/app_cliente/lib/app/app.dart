import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/customer/customer_home_screen.dart';
import '../presentation/location_selection/location_selection_screen.dart';
import '../presentation/splash/splash_screen.dart';
import 'dependencies.dart';
import 'routes.dart';

class PeNaAreiaClienteApp extends StatelessWidget {
  const PeNaAreiaClienteApp({super.key, required this.dependencies});

  static const String initialRoute = AppRoutes.splash;

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pé na Areia · Cliente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: buildAppRoutes(dependencies),
    );
  }
}

Map<String, WidgetBuilder> buildAppRoutes(AppDependencies dependencies) => {
      AppRoutes.splash: (context) => SplashScreen(
            onGetStarted: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            onLoginTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
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
      AppRoutes.locationSelection: (_) => LocationSelectionScreen(
            controller: dependencies.createLocationSelectionController(),
          ),
    };

