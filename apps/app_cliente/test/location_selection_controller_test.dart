import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:core_shared/core_shared.dart';
import 'package:pe_na_areia_cliente/presentation/location_selection/location_selection_controller.dart';

const _dispositivoPosition = GeoPoint(latitude: -23.9721, longitude: -46.3283);

class _UploadCall {
  _UploadCall({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}

class _FakeUploadRepository implements UploadRepository {
  final List<_UploadCall> calls = [];
  String secureUrl = 'https://cdn.example.com/foto.jpg';
  Object? errorToThrow;
  Completer<String>? gate;

  @override
  Future<String> uploadLocationPhoto({
    required List<int> bytes,
    required String filename,
  }) {
    calls.add(_UploadCall(bytes: bytes, filename: filename));
    final pending = gate;
    if (pending != null) {
      return pending.future;
    }
    final error = errorToThrow;
    if (error != null) {
      return Future<String>.error(error);
    }
    return Future<String>.value(secureUrl);
  }
}

class _FakeLocationService implements LocationService {
  GeoPoint? position;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<GeoPoint> getCurrentPosition() async {
    calls += 1;
    final error = errorToThrow;
    if (error != null) {
      throw error;
    }
    return position ?? LocationSelectionController.santosFallbackPosition;
  }
}

class _TestHarness {
  _TestHarness(this.controller, this.upload, this.location);

  final LocationSelectionController controller;
  final _FakeUploadRepository upload;
  final _FakeLocationService location;
}

_TestHarness _buildHarness({
  GeoPoint? devicePosition = _dispositivoPosition,
  Object? locationError,
}) {
  final upload = _FakeUploadRepository();
  final location = _FakeLocationService()
    ..position = devicePosition
    ..errorToThrow = locationError;
  final controller = LocationSelectionController(
    uploadRepository: upload,
    locationService: location,
  );
  addTearDown(controller.dispose);
  return _TestHarness(controller, upload, location);
}

void main() {
  group('initialize', () {
    test('usa a posicao do dispositivo sem buscar postos de entrega', () async {
      final harness = _buildHarness();

      await harness.controller.initialize();

      expect(harness.controller.isInitializing, isFalse);
      expect(harness.controller.pin.latitude, _dispositivoPosition.latitude);
      expect(harness.controller.pin.longitude, _dispositivoPosition.longitude);
      expect(harness.controller.usingFallbackLocation, isFalse);
      expect(harness.controller.locationMessage, isNull);
    });

    test('usa o fallback de Santos quando o GPS falha', () async {
      final harness = _buildHarness(
        locationError: LocationServiceException('GPS desligado.'),
      );

      await harness.controller.initialize();

      expect(
        harness.controller.pin.latitude,
        LocationSelectionController.santosFallbackPosition.latitude,
      );
      expect(
        harness.controller.pin.longitude,
        LocationSelectionController.santosFallbackPosition.longitude,
      );
      expect(harness.controller.usingFallbackLocation, isTrue);
      expect(harness.controller.locationMessage, contains('GPS'));
    });

    test('e idempotente: uma unica rodada de carga por instancia', () async {
      final harness = _buildHarness();

      await harness.controller.initialize();
      await harness.controller.initialize();

      expect(harness.location.calls, 1);
    });
  });

  group('movePin', () {
    test('permite posicionar o pin em qualquer ponto do mapa', () async {
      final harness = _buildHarness();
      await harness.controller.initialize();

      await harness.controller.movePin(
        const GeoPoint(latitude: -23.9500, longitude: -46.3100),
      );

      expect(harness.controller.pin.latitude, -23.9500);
      expect(harness.controller.pin.longitude, -46.3100);
    });
  });

  group('podeConfirmar', () {
    test('permite confirmar com descricao valida sem exigir posto', () async {
      final harness = _buildHarness();
      await harness.controller.initialize();

      expect(harness.controller.podeConfirmar, isFalse);

      harness.controller.atualizarDescricao('   ');
      expect(harness.controller.podeConfirmar, isFalse);

      harness.controller.atualizarDescricao('Guarda-sol listrado azul');
      expect(harness.controller.podeConfirmar, isTrue);
    });

    test('aceita 140 caracteres e rejeita 141', () async {
      final harness = _buildHarness();
      await harness.controller.initialize();

      harness.controller.atualizarDescricao('a' * 140);
      expect(harness.controller.podeConfirmar, isTrue);

      harness.controller.atualizarDescricao('a' * 141);
      expect(harness.controller.podeConfirmar, isFalse);
    });
  });

  group('foto', () {
    test('anexar e remover foto atualizam o estado', () async {
      final harness = _buildHarness();
      await harness.controller.initialize();

      harness.controller.anexarFoto(
        Uint8List.fromList(const [1, 2, 3]),
        filename: 'local.jpg',
      );
      expect(harness.controller.temFoto, isTrue);
      expect(harness.controller.fotoBytes, isNotNull);

      harness.controller.removerFoto();
      expect(harness.controller.temFoto, isFalse);
      expect(harness.controller.fotoBytes, isNull);
    });
  });

  group('confirmarLocalizacao', () {
    test('sem foto devolve OrderLocation apenas com geolocalizacao e descricao',
        () async {
      final harness = _buildHarness();
      await harness.controller.initialize();
      harness.controller.atualizarDescricao('  Guarda-sol azul  ');

      final location = await harness.controller.confirmarLocalizacao();

      expect(location, isNotNull);
      expect(location!.latitude, harness.controller.pin.latitude);
      expect(location.longitude, harness.controller.pin.longitude);
      expect(location.pontoReferenciaId, isEmpty);
      expect(location.descricaoLocal, 'Guarda-sol azul');
      expect(location.fotoLocalUrl, isNull);
      expect(harness.upload.calls, isEmpty);
      expect(harness.controller.isConfirming, isFalse);
    });

    test('com foto faz upload e devolve a secureUrl', () async {
      final harness = _buildHarness();
      await harness.controller.initialize();
      harness.controller.atualizarDescricao('Guarda-sol azul');
      harness.controller.anexarFoto(
        Uint8List.fromList(const [1, 2, 3]),
        filename: 'local.jpg',
      );

      final location = await harness.controller.confirmarLocalizacao();

      expect(harness.upload.calls, hasLength(1));
      expect(harness.upload.calls.single.bytes, const [1, 2, 3]);
      expect(harness.upload.calls.single.filename, 'local.jpg');
      expect(location, isNotNull);
      expect(location!.fotoLocalUrl, 'https://cdn.example.com/foto.jpg');
    });

    test('confirmarApenasPin devolve coordenadas do mapa full screen', () async {
      final harness = _buildHarness();
      await harness.controller.movePin(
        const GeoPoint(latitude: -23.9801, longitude: -46.3112),
      );

      final location = harness.controller.confirmarApenasPin();
      expect(location.latitude, -23.9801);
      expect(location.longitude, -46.3112);
    });
  });

  group('recenterOnDeviceLocation', () {
    test('recupera a posicao do dispositivo quando o GPS volta', () async {
      final harness = _buildHarness(
        locationError: LocationServiceException('GPS desligado.'),
      );
      await harness.controller.initialize();
      expect(harness.controller.usingFallbackLocation, isTrue);

      harness.location.errorToThrow = null;
      harness.location.position =
          const GeoPoint(latitude: -23.9730, longitude: -46.3200);

      await harness.controller.recenterOnDeviceLocation();

      expect(harness.controller.pin.latitude, -23.9730);
      expect(harness.controller.usingFallbackLocation, isFalse);
      expect(harness.controller.locationMessage, isNull);
    });
  });
}
