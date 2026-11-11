import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_shared/design_system/pe_na_areia_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _renderAppIconPng(int dimension, {bool rounded = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(dimension.toDouble(), dimension.toDouble());
  final painter = PeNaAreiaLogoPainter(
    asIcon: true,
    squareIcon: !rounded,
    isDark: true,
  );
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(dimension, dimension);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<Uint8List> _renderLogoCardPng({
  required int width,
  required int height,
  required bool isDark,
  required String fontFamily,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(width.toDouble(), height.toDouble());

  final bgColor = isDark ? PeNaAreiaLogo.darkOcean : PeNaAreiaLogo.whiteStripe;
  final rrect = RRect.fromRectAndRadius(
    Offset.zero & size,
    const Radius.circular(48),
  );
  canvas.drawRRect(rrect, Paint()..color = bgColor);

  if (!isDark) {
    canvas.drawRRect(
      rrect.deflate(2),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  // Draw the central symbol (440x440) centered horizontally
  const symbolSize = 440.0;
  final symbolDx = (width - symbolSize) / 2.0;
  const symbolDy = 56.0;

  canvas.save();
  canvas.translate(symbolDx, symbolDy);
  final symbolPainter = PeNaAreiaLogoPainter(
    asIcon: false,
    squareIcon: false,
    isDark: isDark,
    whiteBackground: false,
  );
  symbolPainter.paint(canvas, const Size(symbolSize, symbolSize));
  canvas.restore();

  // Draw "Pé na Areia"
  final titlePainter = TextPainter(
    text: TextSpan(
      text: 'Pé na Areia',
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: 78,
        fontWeight: FontWeight.w800,
        color: isDark ? PeNaAreiaLogo.whiteStripe : PeNaAreiaLogo.darkOcean,
        letterSpacing: -1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: width.toDouble());

  titlePainter.paint(
    canvas,
    Offset((width - titlePainter.width) / 2.0, 520),
  );

  // Draw "ENTREGA NA PRAIA"
  final subtitlePainter = TextPainter(
    text: TextSpan(
      text: 'ENTREGA NA PRAIA',
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: isDark ? PeNaAreiaLogo.sandBeige : PeNaAreiaLogo.darkOcean,
        letterSpacing: 7.0,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: width.toDouble());

  subtitlePainter.paint(
    canvas,
    Offset((width - subtitlePainter.width) / 2.0, 622),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  group('PeNaAreiaLogo', () {
    testWidgets('renderiza o símbolo e os textos por padrão (Fundo Claro)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeNaAreiaLogo(size: 64, showCardBackground: true),
          ),
        ),
      );

      expect(find.byType(PeNaAreiaLogo), findsOneWidget);
      expect(find.text('Pé na Areia'), findsOneWidget);
      expect(find.text('ENTREGA NA PRAIA'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('permite ocultar texto para uso apenas como ícone quadrado de app', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeNaAreiaLogo(
              size: 48,
              showText: false,
              asIcon: true,
              squareIcon: true,
            ),
          ),
        ),
      );

      expect(find.byType(PeNaAreiaLogo), findsOneWidget);
      expect(find.text('Pé na Areia'), findsNothing);
      expect(find.text('ENTREGA NA PRAIA'), findsNothing);
    });

    testWidgets('renderiza em layout horizontal e modo escuro (#0B3B40)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PeNaAreiaLogo(
              size: 50,
              showText: true,
              horizontal: true,
              isDark: true,
              showCardBackground: true,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Pé na Areia'), findsOneWidget);
      expect(find.text('ENTREGA NA PRAIA'), findsOneWidget);
    });

    test('gera os ícones nativos Android/iOS e as 3 variações oficiais quando GENERATE_ICONS=true', () async {
      if (Platform.environment['GENERATE_ICONS'] != 'true') {
        return;
      }

      String fontFamily = 'Roboto';
      final winFont = File(r'C:\Windows\Fonts\segoeuib.ttf');
      if (winFont.existsSync()) {
        fontFamily = 'SegoeUIBold';
        final loader = FontLoader(fontFamily);
        final bytes = await winFont.readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await loader.load();
      }

      final repoRoot = Directory.current.parent.parent.path;
      final artifactDir = r'C:\Users\User\.gemini\antigravity\brain\f8a87a62-babc-4bee-af86-f068b5f814ba';

      // 1. Export the 3 variations in high resolution
      final var1White = await _renderLogoCardPng(
        width: 720,
        height: 740,
        isDark: false,
        fontFamily: fontFamily,
      );
      final var2Dark = await _renderLogoCardPng(
        width: 720,
        height: 740,
        isDark: true,
        fontFamily: fontFamily,
      );
      final var3SquareIcon = await _renderAppIconPng(1024, rounded: false);

      await File('$artifactDir/logo_variacao_1_fundo_branco.png').writeAsBytes(var1White);
      await File('$artifactDir/logo_variacao_2_fundo_azul_escuro.png').writeAsBytes(var2Dark);
      await File('$artifactDir/logo_variacao_3_icone_quadrado.png').writeAsBytes(var3SquareIcon);

      // 2. Generate Android mipmap PNGs and iOS AppIcon.appiconset PNGs for all 3 apps
      const apps = ['app_cliente', 'app_entregador', 'app_prototipo'];

      const androidDensities = <String, int>{
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
      };

      const iosIcons = <String, int>{
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
      };

      final cachedSquareIcons = <int, Uint8List>{};
      final cachedRoundedIcons = <int, Uint8List>{};

      for (final dim in {...androidDensities.values, ...iosIcons.values}) {
        cachedSquareIcons[dim] = await _renderAppIconPng(dim, rounded: false);
      }
      for (final dim in androidDensities.values) {
        cachedRoundedIcons[dim] = await _renderAppIconPng(dim, rounded: true);
      }

      for (final app in apps) {
        // Brand PNGs
        final brandDir = Directory('$repoRoot/apps/$app/assets/brand');
        if (brandDir.existsSync()) {
          await File('${brandDir.path}/logo-white.png').writeAsBytes(var1White);
          await File('${brandDir.path}/logo-dark.png').writeAsBytes(var2Dark);
          await File('${brandDir.path}/app-icon-1024.png').writeAsBytes(var3SquareIcon);
        }

        // Android mipmap-*
        for (final entry in androidDensities.entries) {
          final dir = Directory('$repoRoot/apps/$app/android/app/src/main/res/${entry.key}');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          await File('${dir.path}/ic_launcher.png').writeAsBytes(cachedRoundedIcons[entry.value]!);
        }

        // iOS AppIcon.appiconset
        final iosDir = Directory('$repoRoot/apps/$app/ios/Runner/Assets.xcassets/AppIcon.appiconset');
        if (iosDir.existsSync()) {
          for (final entry in iosIcons.entries) {
            await File('${iosDir.path}/${entry.key}').writeAsBytes(cachedSquareIcons[entry.value]!);
          }
        }
      }
    });
  });
}
