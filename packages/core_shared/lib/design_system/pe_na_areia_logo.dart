import 'package:flutter/material.dart';

/// Logotipo oficial do Pé na Areia (Entrega na Praia de Santos).
///
/// Reproduz fielmente o símbolo da marca:
/// - Guarda-sol estilizado com cúpula em 5 gomos alternados (vermelho e branco)
///   e arremate ondulado inferior branco;
/// - Haste inclinada fixada no monte de areia dourada;
/// - Sol nascente/poente no topo direito;
/// - Tipografia oficial "Pé na Areia" e subtítulo "ENTREGA NA PRAIA".
class PeNaAreiaLogo extends StatelessWidget {
  const PeNaAreiaLogo({
    super.key,
    this.size = 64,
    this.showText = true,
    this.horizontal = false,
    this.isDark = false,
    this.asIcon = false,
  });

  /// Tamanho de referência do símbolo (largura e altura do ícone).
  final double size;

  /// Se deve exibir o nome da marca ("Pé na Areia") e subtítulo ("ENTREGA NA PRAIA").
  final bool showText;

  /// Se o alinhamento com texto é horizontal (lado a lado) ou vertical (empilhado).
  final bool horizontal;

  /// Modo escuro: inverte cores de texto para tons de areia clara/creme.
  final bool isDark;

  /// Se o símbolo deve ser renderizado dentro do squircle azul-marinho oficial (Ícone de App).
  final bool asIcon;

  @override
  Widget build(BuildContext context) {
    final symbol = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PeNaAreiaLogoPainter(asIcon: asIcon),
      ),
    );

    if (!showText) return symbol;

    final primaryTextColor = isDark ? const Color(0xFFF4E8D1) : const Color(0xFF0B3B40);
    final secondaryTextColor = isDark ? const Color(0xFFE5D3B3) : const Color(0xFF0E5C63);

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

    if (horizontal) {
      return Row(
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
    }

    return Column(
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
}

class _PeNaAreiaLogoPainter extends CustomPainter {
  _PeNaAreiaLogoPainter({required this.asIcon});

  final bool asIcon;

  @override
  void paint(Canvas canvas, Size size) {
    if (asIcon) {
      final rrect = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.22),
      );
      final bgPaint = Paint()..color = const Color(0xFF0C383F);
      canvas.drawRRect(rrect, bgPaint);
    }

    canvas.save();

    // Normalização para o viewBox base de 240x240
    final scale = asIcon ? (size.width / 240.0) * 0.72 : (size.width / 240.0);
    final dx = asIcon ? (size.width - 240 * scale) / 2 : 0.0;
    final dy = asIcon ? (size.height - 240 * scale) / 2 : 0.0;
    canvas.translate(dx, dy);
    canvas.scale(scale);

    // 1. Sol Dourado
    final sunPaint = Paint()
      ..color = const Color(0xFFFFA500)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(172, 62), 32, sunPaint);

    // 2. Monte de Areia
    final sandPaint = Paint()
      ..color = const Color(0xFFE8D5B5)
      ..style = PaintingStyle.fill;
    final sandRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 180, 140, 26),
      const Radius.circular(13),
    );
    canvas.drawRRect(sandRRect, sandPaint);

    // 3. Haste do Guarda-Sol (inclinada)
    final polePaint = Paint()
      ..color = const Color(0xFF1C2E35)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(118, 108), const Offset(134, 190), polePaint);

    // 4. Ponteira / Finial do Topo
    final finialPaint = Paint()
      ..color = const Color(0xFF1C2E35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(106, 46), 4.5, finialPaint);

    // 5. Cúpula do Guarda-sol (5 gomos)
    final redPaint = Paint()
      ..color = const Color(0xFFE52E2D)
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Gomo 1: Vermelho (Esquerda)
    final p1 = Path()
      ..moveTo(106, 46)
      ..cubicTo(88, 52, 64, 74, 42, 126)
      ..cubicTo(40, 131, 43, 138, 48, 138)
      ..cubicTo(55, 138, 64, 136, 70, 131)
      ..cubicTo(78, 88, 95, 58, 106, 46)
      ..close();
    canvas.drawPath(p1, redPaint);

    // Gomo 2: Branco (Centro-Esquerda)
    final p2 = Path()
      ..moveTo(106, 46)
      ..cubicTo(95, 58, 78, 88, 70, 131)
      ..cubicTo(76, 135, 86, 136, 94, 136)
      ..cubicTo(99, 96, 104, 64, 106, 46)
      ..close();
    canvas.drawPath(p2, whitePaint);

    // Gomo 3: Vermelho (Centro)
    final p3 = Path()
      ..moveTo(106, 46)
      ..cubicTo(104, 64, 99, 96, 94, 136)
      ..cubicTo(104, 136, 122, 134, 134, 130)
      ..cubicTo(128, 90, 118, 62, 106, 46)
      ..close();
    canvas.drawPath(p3, redPaint);

    // Gomo 4: Branco (Centro-Direita)
    final p4 = Path()
      ..moveTo(106, 46)
      ..cubicTo(118, 62, 128, 90, 134, 130)
      ..cubicTo(144, 126, 156, 122, 164, 116)
      ..cubicTo(150, 80, 132, 58, 106, 46)
      ..close();
    canvas.drawPath(p4, whitePaint);

    // Gomo 5: Vermelho (Direita)
    final p5 = Path()
      ..moveTo(106, 46)
      ..cubicTo(132, 58, 150, 80, 164, 116)
      ..cubicTo(172, 110, 184, 102, 188, 96)
      ..cubicTo(188, 94, 186, 90, 182, 82)
      ..cubicTo(166, 60, 140, 48, 106, 46)
      ..close();
    canvas.drawPath(p5, redPaint);

    // 6. Arremate Ondulado Branco na Borda Inferior
    final trimPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trimPath = Path()
      ..moveTo(46, 136)
      ..quadraticBezierTo(58, 137, 70, 131)
      ..quadraticBezierTo(82, 136, 94, 136)
      ..quadraticBezierTo(114, 135, 134, 130)
      ..quadraticBezierTo(149, 124, 164, 116)
      ..quadraticBezierTo(176, 106, 188, 96);
    canvas.drawPath(trimPath, trimPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PeNaAreiaLogoPainter oldDelegate) =>
      oldDelegate.asIcon != asIcon;
}

