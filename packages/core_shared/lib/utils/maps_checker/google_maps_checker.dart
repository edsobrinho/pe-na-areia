import 'package:flutter/foundation.dart';

import 'google_maps_checker_stub.dart'
    if (dart.library.js_interop) 'google_maps_checker_web.dart';

/// Utilitário seguro para verificar disponibilidade da Google Maps SDK.
///
/// No Android e iOS nativos, retorna `true` (o Flutter renderiza via PlatformView nativa).
/// No Flutter Web, checa se `window.google` e `window.google.maps` foram carregados,
/// evitando o erro fatal `TypeError: Cannot read properties of undefined (reading 'maps')`.
class GoogleMapsChecker {
  const GoogleMapsChecker._();

  static bool get isReady {
    if (!kIsWeb) return true;
    return checkGoogleMapsWeb();
  }
}

