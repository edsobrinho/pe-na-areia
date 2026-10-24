import 'package:flutter_test/flutter_test.dart';
import 'package:pe_na_areia/data/http/api_exception.dart';

void main() {
  final uri = Uri(scheme: 'https', host: 'api.test', path: '/orders');

  test('timeout descreve o limite configurado', () {
    final error = ApiTimeoutException(uri, const Duration(seconds: 8));

    expect(error.message, contains('8s'));
    expect(error.toString(), 'ApiTimeoutException: ${error.message} ($uri)');
  });

  test('falha de rede mantém causa e mensagem legível', () {
    final error = ApiNetworkException(uri, 'offline');

    expect(error.cause, 'offline');
    expect(error.message, 'Falha de conexao com o servidor.');
  });

  test('erro HTTP inclui status e corpo da resposta', () {
    final error = ApiHttpException(uri, 503, 'indisponivel');

    expect(error.statusCode, 503);
    expect(error.body, 'indisponivel');
    expect(error.message, 'Resposta inesperada do servidor (HTTP 503).');
  });

  test('erro de parsing mantém a causa', () {
    const cause = FormatException('json inválido');
    final error = ApiParsingException(uri, cause);

    expect(error.cause, same(cause));
    expect(error.message, 'Resposta do servidor em formato inesperado.');
  });
}
