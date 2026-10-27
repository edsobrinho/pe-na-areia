import 'package:flutter_test/flutter_test.dart';
import 'package:pe_na_areia/core/forms/formatters.dart';
import 'package:pe_na_areia/core/forms/validators.dart';

void main() {
  group('AppValidators - Validações do Ecossistema Brasileiro', () {
    test('Validação de CPF', () {
      // Identificador fictício com dígitos verificadores calculados para teste.
      expect(AppValidators.validateCPF('987.654.321-00'), isNull);
      expect(AppValidators.validateCPF('98765432100'), isNull);

      // Rejeição de sequências com dígitos repetidos
      expect(AppValidators.validateCPF('111.111.111-11'), 'CPF inválido');
      expect(AppValidators.validateCPF('000.000.000-00'), 'CPF inválido');

      // Rejeição de dígitos verificadores errados
      expect(AppValidators.validateCPF('987.654.321-01'), 'CPF inválido');

      // Campos vazios ou tamanho incorreto
      expect(AppValidators.validateCPF(''), 'CPF é obrigatório');
      expect(AppValidators.validateCPF('12345'), 'CPF deve conter 11 dígitos');
    });

    test('Validação de CNPJ', () {
      // Identificador fictício com dígitos verificadores calculados para teste.
      expect(AppValidators.validateCNPJ('12.345.678/0001-95'), isNull);
      expect(AppValidators.validateCNPJ('12345678000195'), isNull);

      // Rejeição de sequências repetidas e cálculo inválido
      expect(AppValidators.validateCNPJ('00.000.000/0000-00'), 'CNPJ inválido');
      expect(AppValidators.validateCNPJ('11.111.111/1111-11'), 'CNPJ inválido');
      expect(AppValidators.validateCNPJ('12.345.678/0001-96'), 'CNPJ inválido');

      // Campos vazios e tamanho
      expect(AppValidators.validateCNPJ(''), 'CNPJ é obrigatório');
      expect(AppValidators.validateCNPJ('12345'), 'CNPJ deve conter 14 dígitos');
    });

    test('Validação de Telefone e Celular', () {
      // Fixo (10 dígitos) e Celular (11 dígitos) válidos
      expect(AppValidators.validatePhone('(13) 3219-1000'), isNull);
      expect(AppValidators.validatePhone('(13) 99712-3456'), isNull);

      // Celular de 11 dígitos com 3º dígito inválido (diferente de 9)
      expect(
        AppValidators.validatePhone('(13) 89712-3456'),
        'Celular com 11 dígitos deve iniciar com o dígito 9',
      );

      // DDD inválido fora da faixa 11..99
      expect(AppValidators.validatePhone('(05) 99712-3456'), 'DDD inválido');

      // Campos vazios
      expect(AppValidators.validatePhone(''), 'Telefone é obrigatório');
    });

    test('Validação de CEP', () {
      expect(AppValidators.validateCEP('11055-300'), isNull);
      expect(AppValidators.validateCEP('00000-000'), 'CEP inválido');
      expect(AppValidators.validateCEP('1105'), 'CEP deve ter 8 dígitos');
      expect(AppValidators.validateCEP(''), 'CEP é obrigatório');
    });

    test('Validação de Datas e Anos Bissextos', () {
      // Ano bissexto válido
      expect(AppValidators.validateDateBR('29/02/2024'), isNull);

      // Ano não bissexto inválido
      expect(AppValidators.validateDateBR('29/02/2023'), 'Dia inválido para este mês');
      expect(AppValidators.validateDateBR('31/04/2024'), 'Dia inválido para este mês');

      // Data futura
      expect(AppValidators.validateDateBR('01/01/2099'), 'A data não pode ser futura');

      // Idade mínima de 18 anos
      expect(AppValidators.validateDateBR('15/05/1990', minAge: 18), isNull);
      expect(
        AppValidators.validateDateBR('15/05/2020', minAge: 18),
        'Você deve ter no mínimo 18 anos',
      );
    });

    test('Validação de E-mail', () {
      expect(AppValidators.validateEmail('contato@penaareia.com.br'), isNull);
      expect(AppValidators.validateEmail('usuario@dominio.com'), isNull);
      expect(AppValidators.validateEmail('invalido@'), 'E-mail inválido (ex: nome@dominio.com)');
      expect(AppValidators.validateEmail('usuario com espaco@dominio.com'), 'E-mail inválido (ex: nome@dominio.com)');
      expect(AppValidators.validateEmail(''), 'E-mail é obrigatório');
    });

    test('Validação de Nome Completo', () {
      expect(AppValidators.validateFullName('Carlos Eduardo'), isNull);
      expect(AppValidators.validateFullName('Carlos'), 'Informe seu nome e ao menos um sobrenome');
      expect(AppValidators.validateFullName(''), 'Nome é obrigatório');
    });
  });

  group('Formatters - Formatação de Entrada', () {
    test('PhoneInputFormatter formata celular de 11 dígitos', () {
      final formatter = PhoneInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '13997123456'),
      );
      expect(result.text, '(13) 99712-3456');
    });

    test('PhoneInputFormatter formata telefone fixo de 10 dígitos', () {
      final formatter = PhoneInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1332191000'),
      );
      expect(result.text, '(13) 3219-1000');
    });

    test('CurrencyBRLInputFormatter formata centavos para real', () {
      final formatter = CurrencyBRLInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '2550'),
      );
      expect(result.text, 'R\$ 25,50');
    });

    test('PatternInputFormatter formata CPF', () {
      final formatter = PatternInputFormatter(pattern: '###.###.###-##');
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '98765432100'),
      );
      expect(result.text, '987.654.321-00');
    });
  });
}
