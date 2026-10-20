/// Erros tipados do cliente HTTP. As telas e controllers tratam cada caso
/// separadamente sem inspecionar strings de excecao genericas.
sealed class ApiException implements Exception {
  const ApiException(this.uri);

  /// Endpoint que originou a falha.
  final Uri uri;

  /// Mensagem legivel (pt-BR) para exibicao ou log.
  String get message;

  @override
  String toString() => '$runtimeType: $message ($uri)';
}

/// O servidor nao respondeu dentro do timeout configurado.
final class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.uri, this.timeout);

  final Duration timeout;

  @override
  String get message =>
      'Tempo de resposta esgotado (${timeout.inSeconds}s). Verifique sua conexao.';
}

/// Falha de transporte: sem rede, DNS, conexao recusada, etc.
final class ApiNetworkException extends ApiException {
  const ApiNetworkException(super.uri, this.cause);

  final Object cause;

  @override
  String get message => 'Falha de conexao com o servidor.';
}

/// O servidor respondeu, mas com um status HTTP inesperado para o contrato.
final class ApiHttpException extends ApiException {
  const ApiHttpException(super.uri, this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String get message => 'Resposta inesperada do servidor (HTTP $statusCode).';
}

/// O corpo da resposta nao e o JSON esperado pelo contrato.
final class ApiParsingException extends ApiException {
  const ApiParsingException(super.uri, this.cause);

  final Object cause;

  @override
  String get message => 'Resposta do servidor em formato inesperado.';
}
