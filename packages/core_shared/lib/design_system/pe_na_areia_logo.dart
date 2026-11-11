import 'package:flutter/material.dart';

/// Logotipo vetorial oficial do Pé na Areia (Entrega na Praia de Santos, Brasil).
///
/// Especificação cromática e geométrica oficial (estilo flat, traços simples e arredondados):
/// - Guarda-sol estilizado com listras alternadas em vermelho (`#EA1D2C`) e branco (`#FFFFFF`);
/// - Haste simples arredondada fincada sobre uma faixa de areia bege (`#EFE2C4`);
/// - Sol amarelo-laranjado (`#FF9F1C`) no canto superior direito como ponto de destaque;
/// - Texto do nome e fundo escuro em azul-escuro (`#0B3B40`).
///
/// Suporta as 3 variações oficiais:
/// 1. Fundo branco (`isDark: false`, `showCardBackground: true`)
/// 2. Fundo azul-escuro `#0B3B40` com texto invertido para claro (`isDark: true`, `showCardBackground: true`)
/// 3. Símbolo quadrado para ícone de app com margem de segurança generosa (`asIcon: true`, `showText: false`)
class PeNaAreiaLogo extends StatelessWidget {
  const PeNaAreiaLogo({
    super.key,
    this.size = 64,
    this.showText = true,
    this.horizontal = false,
    this.isDark = false,
    this.asIcon = false,
    this.squareIcon = false,
    this.showCardBackground = false,
  });

  /// Paleta oficial da marca Pé na Areia.
  static const Color redStripe = Color(0xFFEA1D2C);
  static const Color whiteStripe = Color(0xFFFFFFFF);
  static const Color sandBeige = Color(0xFFEFE2C4);
  static const Color sunOrange = Color(0xFFFF9F1C);
  static const Color darkOcean = Color(0xFF0B3B40);

  /// Tamanho de referência do símbolo (largura e altura do ícone).
  final double size;

  /// Se deve exibir o nome da marca ("Pé na Areia") e subtítulo ("ENTREGA NA PRAIA").
  final bool showText;

  /// Se o alinhamento com texto é horizontal (lado a lado) ou vertical (empilhado).
  final bool horizontal;

  /// Modo escuro: fundo `#0B3B40` e texto invertido para claro.
  final bool isDark;

  /// Se o símbolo deve ser renderizado como ícone de app com margem de segurança generosa.
  final bool asIcon;

  /// Se o ícone de app deve preencher um quadrado completo (1:1) sem cantos recortados (para geração de AppIcon/mipmap).
  final bool squareIcon;

  /// Se deve desenhar o cartão de fundo (`#FFFFFF` ou `#0B3B40`) ao redor do logo completo.
  final bool showCardBackground;

  @override
  Widget build(BuildContext context) {
    final symbol = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PeNaAreiaLogoPainter(
          asIcon: asIcon,
          squareIcon: squareIcon,
          isDark: isDark || asIcon,
        ),
      ),
    );

    if (!showText) return symbol;

    final primaryTextColor = isDark ? whiteStripe : darkOcean;
    final secondaryTextColor = isDark ? sandBeige : darkOcean;

    final titleStyle = TextStyle(
      fontFamily: 'Roboto',
      color: primaryTextColor,
      fontSize: horizontal ? size * 0.44 : size * 0.28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.1,
    );

    final subtitleStyle = TextStyle(
      fontFamily: 'Roboto',
      color: secondaryTextColor,
      fontSize: horizontal ? size * 0.17 : size * 0.11,
      fontWeight: FontWeight.w700,
      letterSpacing: horizontal ? 2.8 : 2.4,
      height: 1.2,
    );

    Widget content;
    if (horizontal) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          symbol,
          SizedBox(width: size * 0.22),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pé na Areia', style: titleStyle),
              SizedBox(height: size * 0.04),
              Text('ENTREGA NA PRAIA', style: subtitleStyle),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          symbol,
          SizedBox(height: size * 0.12),
          Text('Pé na Areia', style: titleStyle, textAlign: TextAlign.center),
          SizedBox(height: size * 0.04),
          Text('ENTREGA NA PRAIA', style: subtitleStyle, textAlign: TextAlign.center),
        ],
      );
    }

    if (!showCardBackground) return content;

    return Container(
      padding: EdgeInsets.all(size * 0.24),
      decoration: BoxDecoration(
        color: isDark ? darkOcean : whiteStripe,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: content,
    );
  }
}

class PeNaAreiaLogoPainter extends CustomPainter {
  const PeNaAreiaLogoPainter({
    this.asIcon = false,
    this.squareIcon = false,
    this.isDark = false,
    this.whiteBackground = false,
  });

  final bool asIcon;
  final bool squareIcon;
  final bool isDark;
  final bool whiteBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (asIcon || whiteBackground) {
      final bgColor = whiteBackground
          ? PeNaAreiaLogo.whiteStripe
          : PeNaAreiaLogo.darkOcean;
      final bgPaint = Paint()..color = bgColor;
      if (squareIcon) {
        canvas.drawRect(Offset.zero & size, bgPaint);
      } else {
        final rrect = RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * 0.22),
        );
        canvas.drawRRect(rrect, bgPaint);
      }
    }

    canvas.save();

    // ViewBox base de 240x240 com margem de segurança generosa (0.72) para ícone de app
    final scale = asIcon ? (size.width / 240.0) * 0.72 : (size.width / 240.0);
    final dx = asIcon ? (size.width - 240 * scale) / 2 : 0.0;
    final dy = asIcon ? (size.height - 240 * scale) / 2 : 0.0;
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final onDarkBg = (asIcon && !whiteBackground) || (isDark && !whiteBackground);

    // 1. Sol amarelo-laranjado (#FF9F1C) no canto superior direito
    final sunPaint = Paint()
      ..color = PeNaAreiaLogo.sunOrange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(174, 58), 30, sunPaint);

    // 2. Haste simples arredondada do guarda-sol fincada na areia
    final polePaint = Paint()
      ..color = onDarkBg ? PeNaAreiaLogo.sandBeige : PeNaAreiaLogo.darkOcean
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(115, 108), const Offset(131, 188), polePaint);

    // 3. Faixa de areia bege (#EFE2C4) na base
    final sandPaint = Paint()
      ..color = PeNaAreiaLogo.sandBeige
      ..style = PaintingStyle.fill;
    final sandRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(44, 178, 152, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(sandRRect, sandPaint);
    if (!onDarkBg) {
      final sandBorderPaint = Paint()
        ..color = PeNaAreiaLogo.darkOcean
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRRect(sandRRect, sandBorderPaint);
    }

    // 4. Ponteira superior arredondada do guarda-sol
    final finialPaint = Paint()
      ..color = onDarkBg ? PeNaAreiaLogo.whiteStripe : PeNaAreiaLogo.darkOcean
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(106, 44), 5.5, finialPaint);

    // 5. Cúpula do Guarda-sol estilizado com 5 listras alternadas (#EA1D2C e #FFFFFF)
    final redPaint = Paint()
      ..color = PeNaAreiaLogo.redStripe
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = PeNaAreiaLogo.whiteStripe
      ..style = PaintingStyle.fill;

    // Gomo 1: Vermelho (#EA1D2C - Esquerda)
    final p1 = Path()
      ..moveTo(106, 46)
      ..cubicTo(88, 52, 64, 74, 42, 126)
      ..cubicTo(40, 131, 43, 138, 48, 138)
      ..cubicTo(55, 138, 64, 136, 70, 131)
      ..cubicTo(78, 88, 95, 58, 106, 46)
      ..close();

    // Gomo 2: Branco (#FFFFFF - Centro-Esquerda)
    final p2 = Path()
      ..moveTo(106, 46)
      ..cubicTo(95, 58, 78, 88, 70, 131)
      ..cubicTo(76, 135, 86, 136, 94, 136)
      ..cubicTo(99, 96, 104, 64, 106, 46)
      ..close();

    // Gomo 3: Vermelho (#EA1D2C - Centro)
    final p3 = Path()
      ..moveTo(106, 46)
      ..cubicTo(104, 64, 99, 96, 94, 136)
      ..cubicTo(104, 136, 122, 134, 134, 130)
      ..cubicTo(128, 90, 118, 62, 106, 46)
      ..close();

    // Gomo 4: Branco (#FFFFFF - Centro-Direita)
    final p4 = Path()
      ..moveTo(106, 46)
      ..cubicTo(118, 62, 128, 90, 134, 130)
      ..cubicTo(144, 126, 156, 122, 164, 116)
      ..cubicTo(150, 80, 132, 58, 106, 46)
      ..close();

    // Gomo 5: Vermelho (#EA1D2C - Direita)
    final p5 = Path()
      ..moveTo(106, 46)
      ..cubicTo(132, 58, 150, 80, 164, 116)
      ..cubicTo(172, 110, 184, 102, 188, 96)
      ..cubicTo(188, 94, 186, 90, 182, 82)
      ..cubicTo(166, 60, 140, 48, 106, 46)
      ..close();

    canvas.drawPath(p1, redPaint);
    canvas.drawPath(p2, whitePaint);
    canvas.drawPath(p3, redPaint);
    canvas.drawPath(p4, whitePaint);
    canvas.drawPath(p5, redPaint);

    // Em fundo claro, contorno arredondado azul-escuro (#0B3B40) garante leitura nítida dos gomos brancos
    if (!onDarkBg) {
      final canopyOutlinePaint = Paint()
        ..color = PeNaAreiaLogo.darkOcean
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final canopyOuter = Path()
        ..moveTo(106, 46)
        ..cubicTo(88, 52, 64, 74, 42, 126)
        ..cubicTo(40, 131, 43, 138, 48, 138)
        ..cubicTo(55, 138, 64, 136, 70, 131)
        ..cubicTo(76, 135, 86, 136, 94, 136)
        ..cubicTo(104, 136, 122, 134, 134, 130)
        ..cubicTo(144, 126, 156, 122, 164, 116)
        ..cubicTo(172, 110, 184, 102, 188, 96)
        ..cubicTo(188, 94, 186, 90, 182, 82)
        ..cubicTo(166, 60, 140, 48, 106, 46)
        ..close();
      canvas.drawPath(canopyOuter, canopyOutlinePaint);
    } else {
      // Em fundo escuro (#0B3B40), arremate ondulado branco arredondado na borda inferior
      final trimPaint = Paint()
        ..color = PeNaAreiaLogo.whiteStripe
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final trimPath = Path()
        ..moveTo(45, 137)
        ..cubicTo(55, 138, 64, 136, 70, 131)
        ..cubicTo(76, 135, 86, 136, 94, 136)
        ..cubicTo(104, 136, 122, 134, 134, 130)
        ..cubicTo(144, 126, 156, 122, 164, 116)
        ..cubicTo(172, 110, 184, 102, 188, 96);
      canvas.drawPath(trimPath, trimPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PeNaAreiaLogoPainter oldDelegate) =>
      oldDelegate.asIcon != asIcon ||
      oldDelegate.squareIcon != squareIcon ||
      oldDelegate.isDark != isDark ||
      oldDelegate.whiteBackground != whiteBackground;
}
