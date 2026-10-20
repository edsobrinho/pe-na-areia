import 'package:geolocator/geolocator.dart';

import '../../domain/models/geo_point.dart';

/// Falha ao obter a localizacao do dispositivo (GPS desligado, permissao
/// negada, etc). Carrega uma mensagem pronta para exibicao (pt-BR).
class LocationServiceException implements Exception {
  LocationServiceException(this.message);

  final String message;

  @override
  String toString() => 'LocationServiceException: $message';
}

/// Encapsula o geolocator atras de uma API de dominio ([GeoPoint]), deixando
/// o controller testavel com um fake simples.
class LocationService {
  /// Pede permissao e retorna a posicao atual do dispositivo.
  /// Lanca [LocationServiceException] se o GPS estiver desligado ou a
  /// permissao for negada.
  Future<GeoPoint> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Ative o GPS para marcar sua localizacao na praia.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Permissao de localizacao negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Permissao de localizacao negada permanentemente. '
        'Ative nas configuracoes do app.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GeoPoint(latitude: position.latitude, longitude: position.longitude);
  }
}
