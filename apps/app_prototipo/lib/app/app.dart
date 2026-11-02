import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';

import '../presentation/auth/login_screen.dart';
import '../presentation/prototype/prototype_screen.dart';
import '../presentation/splash/splash_screen.dart';
import 'dependencies.dart';
import 'routes.dart';

class PeNaAreiaPrototipoApp extends StatelessWidget {
  const PeNaAreiaPrototipoApp({super.key, required this.dependencies});

  static const String initialRoute = AppRoutes.prototype;

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pé na Areia · Protótipo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: buildAppRoutes(dependencies),
    );
  }
}

Map<String, WidgetBuilder> buildAppRoutes(AppDependencies dependencies) => {
      AppRoutes.prototype: (context) => PrototypeScreen(
            onLoginTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
      AppRoutes.splash: (context) => SplashScreen(
            onGetStarted: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.prototype),
            onLoginTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
      AppRoutes.login: (_) => LoginScreen(
            authRepository: dependencies.authRepository,
          ),
    };

