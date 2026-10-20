/// Cliente do app (usuario que faz pedidos na praia).
///
/// Modelo de dominio imutavel; o mapeamento JSON fica em UserMapper (camada data).
class User {
  const User({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.criadoEm,
  });

  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final DateTime? criadoEm;
}
