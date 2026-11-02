/// Módulo central de validações e expressões regulares para o ecossistema brasileiro.
class AppValidators {
  AppValidators._();

  // Expressões regulares ancoradas exclusivas para formato sintático.
  static final RegExp regexCpfFormat = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');
  static final RegExp regexCnpjFormat = RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$');
  static final RegExp regexPhoneFormat = RegExp(r'^\(\d{2}\)\s\d{4,5}-\d{4}$');
  static final RegExp regexCepFormat = RegExp(r'^\d{5}-\d{3}$');
  static final RegExp regexDateFormat = RegExp(r'^\d{2}/\d{2}/\d{4}$');
  static final RegExp regexEmailFormat = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Remove qualquer caractere que não seja dígito numérico.
  static String stripNonDigits(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\D'), '');
  }

  /// Validador de CPF com cálculo dos 2 dígitos verificadores (Módulo 11).
  static String? validateCPF(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CPF é obrigatório';
    }
    final digits = stripNonDigits(value);
    if (digits.length != 11) {
      return 'CPF deve conter 11 dígitos';
    }
    // Rejeita sequências de dígitos iguais (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return 'CPF inválido';
    }

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * (10 - i);
    }
    int remainder = (sum * 10) % 11;
    final int d1 = (remainder == 10 || remainder == 11) ? 0 : remainder;
    if (d1 != int.parse(digits[9])) {
      return 'CPF inválido';
    }

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * (11 - i);
    }
    remainder = (sum * 10) % 11;
    final int d2 = (remainder == 10 || remainder == 11) ? 0 : remainder;
    if (d2 != int.parse(digits[10])) {
      return 'CPF inválido';
    }

    return null;
  }

  /// Validador de CNPJ com pesos oficiais da Receita Federal.
  static String? validateCNPJ(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNPJ é obrigatório';
    }
    final digits = stripNonDigits(value);
    if (digits.length != 14) {
      return 'CNPJ deve conter 14 dígitos';
    }
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return 'CNPJ inválido';
    }

    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * weights1[i];
    }
    int rem = sum % 11;
    final int d1 = rem < 2 ? 0 : 11 - rem;
    if (d1 != int.parse(digits[12])) return 'CNPJ inválido';

    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(digits[i]) * weights2[i];
    }
    rem = sum % 11;
    final int d2 = rem < 2 ? 0 : 11 - rem;
    if (d2 != int.parse(digits[13])) return 'CNPJ inválido';

    return null;
  }

  /// Validador de Telefone/Celular com verificação de DDD e 9º dígito móvel.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    final digits = stripNonDigits(value);
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos com DDD';
    }
    final int ddd = int.parse(digits.substring(0, 2));
    if (ddd < 11 || ddd > 99) {
      return 'DDD inválido';
    }
    if (digits.length == 11 && digits[2] != '9') {
      return 'Celular com 11 dígitos deve iniciar com o dígito 9';
    }
    return null;
  }

  /// Validador de CEP com verificação de 8 dígitos.
  static String? validateCEP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CEP é obrigatório';
    }
    final digits = stripNonDigits(value);
    if (digits.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    if (digits == '00000000') {
      return 'CEP inválido';
    }
    return null;
  }

  /// Validador de Data no padrão brasileiro dd/mm/aaaa com calendário real e idade mínima opcional.
  static String? validateDateBR(String? value, {int minAge = 0}) {
    if (value == null || value.trim().isEmpty) {
      return 'Data é obrigatória';
    }
    if (!regexDateFormat.hasMatch(value)) {
      return 'Data deve estar no formato dd/mm/aaaa';
    }
    final parts = value.split('/');
    final int day = int.parse(parts[0]);
    final int month = int.parse(parts[1]);
    final int year = int.parse(parts[2]);

    if (month < 1 || month > 12) return 'Mês inválido';

    final bool isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    final daysInMonth = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (day < 1 || day > daysInMonth[month - 1]) return 'Dia inválido para este mês';

    final parsedDate = DateTime(year, month, day);
    final now = DateTime.now();
    if (parsedDate.isAfter(now)) return 'A data não pode ser futura';

    if (minAge > 0) {
      int age = now.year - parsedDate.year;
      if (now.month < parsedDate.month ||
          (now.month == parsedDate.month && now.day < parsedDate.day)) {
        age--;
      }
      if (age < minAge) {
        return 'Você deve ter no mínimo $minAge anos';
      }
    }
    return null;
  }

  /// Validador de E-mail com regex e sanitização.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }
    final sanitized = value.trim().toLowerCase();
    if (!regexEmailFormat.hasMatch(sanitized)) {
      return 'E-mail inválido (ex: nome@dominio.com)';
    }
    return null;
  }

  /// Validador de Nome Completo (ao menos duas palavras).
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length < 2) {
      return 'Informe seu nome e ao menos um sobrenome';
    }
    return null;
  }
}

