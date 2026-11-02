class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.role,
  });

  final String token;
  final String userId;
  final String name;
  final String role;

  bool get isCourier => role == 'COURIER';

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final userId = json['userId'];
    final name = json['name'];
    final role = json['role'];
    if (token is! String ||
        userId is! String ||
        name is! String ||
        role is! String) {
      throw const FormatException('Dados de sessão ausentes ou inválidos.');
    }
    return AuthSession(token: token, userId: userId, name: name, role: role);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'name': name,
        'role': role,
      };
}
