/// Coordenada geografica imutavel usada pelas camadas de dominio e
/// apresentacao, sem dependencia de plugins de mapa ou de localizacao.
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
