import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pe_na_areia_cliente/presentation/splash/splash_screen.dart';
import 'package:core_shared/core_shared.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('exibe elementos da marca sustentável de Santos e o novo logotipo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Logotipo oficial presente no emblema superior
      expect(find.byType(PeNaAreiaLogo), findsOneWidget);

      // Manchete e subtítulo da temática de Santos
      expect(find.text('Entrega\nSustentável na\nAreia de Santos'), findsOneWidget);
      expect(
        find.textContaining('embalagem 100% sustentável direto no seu guarda-sol'),
        findsOneWidget,
      );

      // Selos do ecossistema costeiro de Santos
      expect(find.text('ORLA DE SANTOS'), findsOneWidget);
      expect(find.text('Embalagem Sustentável'), findsOneWidget);
      expect(find.text('Direto na sua Canga'), findsOneWidget);
      expect(find.text('Entrega na Orla Santista'), findsOneWidget);

      // Botão CTA em pílula
      expect(find.text('Começar Agora'), findsOneWidget);
      expect(find.text('Já possui conta? Entrar ou Cadastrar'), findsOneWidget);
    });

    testWidgets('aciona callbacks de começar e login corretamente',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var startedPressed = false;
      var loginPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            onGetStarted: () => startedPressed = true,
            onLoginTap: () => loginPressed = true,
          ),
        ),
      );

      final ctaFinder = find.text('Começar Agora');
      await tester.ensureVisible(ctaFinder);
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();
      expect(startedPressed, isTrue);

      final loginFinder = find.text('Já possui conta? Entrar ou Cadastrar');
      await tester.ensureVisible(loginFinder);
      await tester.tap(loginFinder);
      await tester.pumpAndSettle();
      expect(loginPressed, isTrue);
    });
  });
}
