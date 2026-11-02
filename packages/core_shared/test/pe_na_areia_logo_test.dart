import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_shared/design_system/pe_na_areia_logo.dart';

void main() {
  group('PeNaAreiaLogo', () {
    testWidgets('renderiza o símbolo e os textos por padrão', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeNaAreiaLogo(size: 64),
          ),
        ),
      );

      expect(find.byType(PeNaAreiaLogo), findsOneWidget);
      expect(find.text('Pé na Areia'), findsOneWidget);
      expect(find.text('ENTREGA NA PRAIA'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('permite ocultar texto para uso apenas como ícone/marca', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeNaAreiaLogo(
              size: 48,
              showText: false,
              asIcon: true,
            ),
          ),
        ),
      );

      expect(find.byType(PeNaAreiaLogo), findsOneWidget);
      expect(find.text('Pé na Areia'), findsNothing);
      expect(find.text('ENTREGA NA PRAIA'), findsNothing);
    });

    testWidgets('renderiza em layout horizontal com texto ao lado', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeNaAreiaLogo(
              size: 50,
              showText: true,
              horizontal: true,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Pé na Areia'), findsOneWidget);
      expect(find.text('ENTREGA NA PRAIA'), findsOneWidget);
    });
  });
}

