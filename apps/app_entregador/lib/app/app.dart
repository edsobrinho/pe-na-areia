import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/courier/courier_home_screen.dart';
import 'dependencies.dart';
import 'routes.dart';

class PeNaAreiaEntregadorApp extends StatelessWidget {
  const PeNaAreiaEntregadorApp({super.key, required this.dependencies});

  static const String initialRoute = AppRoutes.login;

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pé na Areia · Entregador',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: buildAppRoutes(dependencies),
    );
  }
}

Map<String, WidgetBuilder> buildAppRoutes(AppDependencies dependencies) => {
      AppRoutes.login: (_) => LoginScreen(
            authRepository: dependencies.authRepository,
          ),
      AppRoutes.courierHome: (_) => CourierHomeScreen(
            authRepository: dependencies.authRepository,
            orderRepository: dependencies.orderRepository,
            locationService: dependencies.locationService,
          ),
    };

