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

  test('erro HTTP inclui status e corpo da resposta não-JSON', () {
    final error = ApiHttpException(uri, 503, 'indisponivel');

    expect(error.statusCode, 503);
    expect(error.body, 'indisponivel');
    expect(error.message, 'Resposta inesperada do servidor (HTTP 503).');
  });

  test('erro HTTP extrai campo mensagem de JSON retornado pelo backend', () {
    const jsonBody = '{"timestamp":"2026-10-29T18:00:00Z","status":422,"mensagem":"O pin deve estar a no máximo 500 m do posto de referência."}';
    final error = ApiHttpException(uri, 422, jsonBody);

    expect(error.statusCode, 422);
    expect(error.message, 'O pin deve estar a no máximo 500 m do posto de referência.');
  });

  test('erro HTTP extrai campos de validação 400', () {
    const jsonBody = '{"timestamp":"2026-10-29T18:00:00Z","status":400,"mensagem":"Dados invalidos","campos":{"pinCliente.latitude":"Latitude deve estar entre -90 e 90"}}';
    final error = ApiHttpException(uri, 400, jsonBody);

    expect(error.message, 'Dados invalidos');
  });

  test('erro de parsing mantém a causa', () {
    const cause = FormatException('json inválido');
    final error = ApiParsingException(uri, cause);

    expect(error.cause, same(cause));
    expect(error.message, 'Resposta do servidor em formato inesperado.');
  });
}
