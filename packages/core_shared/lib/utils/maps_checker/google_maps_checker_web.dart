import 'dart:js_interop';

@JS('google')
external JSObject? get _google;

@JS('google.maps')
external JSObject? get _googleMaps;

bool checkGoogleMapsWeb() {
  try {
    if (_google == null) return false;
    return _googleMaps != null;
  } catch (_) {
    return false;
  }
}

