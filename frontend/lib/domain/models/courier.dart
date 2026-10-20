import 'geo_point.dart';

/// Tipo de veiculo do entregador (contrato fechado com o backend).
enum VehicleType {
  aPe('A_PE'),
  bicicleta('BICICLETA');

  const VehicleType(this.wireValue);

  final String wireValue;

  static VehicleType fromWire(String value) => values.firstWhere(
        (tipo) => tipo.wireValue == value,
        orElse: () => throw ArgumentError.value(
          value,
          'veiculo',
          'Tipo de veiculo desconhecido',
        ),
      );
}

/// Status de trabalho do entregador (contrato fechado com o backend).
enum CourierStatus {
  offline('OFFLINE'),
  disponivel('DISPONIVEL'),
  emRota('EM_ROTA');

  const CourierStatus(this.wireValue);

  final String wireValue;

  static CourierStatus fromWire(String value) => values.firstWhere(
        (status) => status.wireValue == value,
        orElse: () => throw ArgumentError.value(
          value,
          'status',
          'Status de entregador desconhecido',
        ),
      );
}

/// Entregador parceiro. Hoje nao ha fluxo de consulta desse modelo no app;
/// ele existe para manter o contrato de dominio alinhado ao backend.
class Courier {
  const Courier({
    required this.id,
    required this.nome,
    this.email = '',
    this.veiculo,
    this.status = CourierStatus.offline,
    this.localizacao,
  });

  final String id;
  final String nome;
  final String email;
  final VehicleType? veiculo;
  final CourierStatus status;
  final GeoPoint? localizacao;
}
