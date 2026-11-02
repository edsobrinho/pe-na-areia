import 'package:flutter/services.dart';

/// Formatter dinâmico para telefone fixo (10 dígitos) ou celular (11 dígitos).
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits =
        digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    final buffer = StringBuffer();

    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (limitedDigits.length <= 10) {
        if (i == 6) buffer.write('-');
      } else {
        if (i == 7) buffer.write('-');
      }
      buffer.write(limitedDigits[i]);
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Formatter para moeda em Real (R$ 0,00) baseado no valor de centavos digitado.
class CurrencyBRLInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final cleanDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: 'R\$ 0,00',
        selection: TextSelection.collapsed(offset: 7),
      );
    }
    final double valueInUnits = int.parse(cleanDigits) / 100.0;
    final formatted = 'R\$ ${valueInUnits.toStringAsFixed(2).replaceAll('.', ',')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter genérico com base em padrão de caracteres (# = dígito numérico).
class PatternInputFormatter extends TextInputFormatter {
  PatternInputFormatter({required this.pattern});

  final String pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleanDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int digitIndex = 0;

    for (int i = 0; i < pattern.length && digitIndex < cleanDigits.length; i++) {
      if (pattern[i] == '#') {
        buffer.write(cleanDigits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(pattern[i]);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

