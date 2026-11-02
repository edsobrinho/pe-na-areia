import '../http/api_exception.dart';

/// Converte um valor ISO-8601 do backend (Instant do Java) em [DateTime].
/// Tolerante: valores ausentes ou invalidos viram `null`.
DateTime? dateTimeFromJson(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

/// Mapeia uma lista JSON de objetos para modelos, convertendo qualquer
/// formato inesperado em [ApiParsingException] (erro tipado).
List<T> mapJsonObjectList<T>(
  List<dynamic> data,
  T Function(Map<String, dynamic> json) mapper,
  Uri uri,
) {
  try {
    return data
        .map((item) => mapper(item as Map<String, dynamic>))
        .toList(growable: false);
  } on TypeError catch (error) {
    throw ApiParsingException(uri, error);
  }
}
