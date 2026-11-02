import '../../domain/models/user.dart';
import 'json_helpers.dart';

/// Mapeamento JSON explicito de [User] (formato do backend Spring Boot).
abstract final class UserMapper {
  static User fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String? ?? '',
        telefone: json['telefone'] as String?,
        criadoEm: dateTimeFromJson(json['criadoEm']),
      );
}
