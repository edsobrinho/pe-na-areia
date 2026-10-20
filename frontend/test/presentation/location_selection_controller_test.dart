import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pe_na_areia/data/http/api_exception.dart';
import 'package:pe_na_areia/data/repositories/reference_point_repository.dart';
import 'package:pe_na_areia/data/repositories/upload_repository.dart';
import 'package:pe_na_areia/data/services/location_service.dart';
import 'package:pe_na_areia/domain/geo.dart';
import 'package:pe_na_areia/domain/models/geo_point.dart';
import 'package:pe_na_areia/domain/models/reference_point.dart';
import 'package:pe_na_areia/presentation/location_selection/location_selection_controller.dart';

const _dispositivoPosition = GeoPoint(latitude: -23.9721, longitude: -46.3283);

const _postoProximo = ReferencePoint(
  id: 'posto-6',
  numero: 6,
  nome: 'Posto 6',
  latitude: -23.9720,
  longitude: -46.3285,
  trecho: 'Gonzaga',
);

const _postoDistante = ReferencePoint(
  id: 'posto-7',
  numero: 7,
  nome: 'Posto 7',
  latitude: -23.9640,
  longitude: -46.3360,
  trecho: 'Boqueirao',
);

class _NearbyCall {
  _NearbyCall({required this.lat, required this.lng});

  final double lat;
  final double lng;
  final Completer<List<ReferencePoint>> completer =
      Completer<List<ReferencePoint>>();
}

class _FakeReferencePointRepository implements ReferencePointRepository {
  final List<_NearbyCall> nearbyCalls = [];
  Object? errorToThrow;

  @override
  Future<List<ReferencePoint>> fetchAll() async => const [];

  @override
  Future<List<ReferencePoint>> fetchNearby({
    required double lat,
    required double lng,
    double raioKm = 1.5,
  }) {
    final call = _NearbyCall(lat: lat, lng: lng);
    nearbyCalls.add(call);
    final error = errorToThrow;
    if (error != null) {
      return Future<List<ReferencePoint>>.error(error);
    }
    return call.completer.future;
  }
}

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
  _TestHarness(this.controller, this.referencePoints, this.upload, this.location);

  final LocationSelectionController controller;
  final _FakeReferencePointRepository referencePoints;
  final _FakeUploadRepository upload;
  final _FakeLocationService location;
}

_TestHarness _buildHarness({
  GeoPoint? devicePosition = _dispositivoPosition,
  Object? locationError,
}) {
  final referencePoints = _FakeReferencePointRepository();
  final upload = _FakeUploadRepository();
  final location = _FakeLocationService()
    ..position = devicePosition
    ..errorToThrow = locationError;
  final controller = LocationSelectionController(
    referencePointRepository: referencePoints,
    uploadRepository: upload,
    locationService: location,
  );
  addTearDown(controller.dispose);
  return _TestHarness(controller, referencePoints, upload, location);
}

Future<_TestHarness> _harnessComPosto() async {
  final harness = _buildHarness();
  final initFuture = harness.controller.initialize();
  await pumpEventQueue();
  harness.referencePoints.nearbyCalls.single.completer.complete([_postoProximo]);
  await initFuture;
  return harness;
}

void main() {
  group('initialize', () {
    test('usa a posicao do dispositivo e seleciona o posto mais proximo',
        () async {
      final harness = _buildHarness();

      final initFuture = harness.controller.initialize();
      await pumpEventQueue();

      expect(harness.referencePoints.nearbyCalls, hasLength(1));
      expect(
        harness.referencePoints.nearbyCalls.single.lat,
        _dispositivoPosition.latitude,
      );
      expect(harness.controller.isInitializing, isFalse);
      expect(harness.controller.isLoadingPostos, isTrue);

      harness.referencePoints.nearbyCalls.single.completer.complete(
        [_postoDistante, _postoProximo],
      );
      await initFuture;

      expect(harness.controller.pin.latitude, _dispositivoPosition.latitude);
      expect(harness.controller.pin.longitude, _dispositivoPosition.longitude);
      expect(harness.controller.usingFallbackLocation, isFalse);
      expect(harness.controller.locationMessage, isNull);
      expect(
        harness.controller.postosProximos.map((posto) => posto.id),
        ['posto-6', 'posto-7'],
      );
      expect(harness.controller.postoSelecionado!.id, 'posto-6');
      expect(harness.controller.distanciaSelecionadaMeters, isNotNull);
      expect(harness.controller.distanciaSelecionadaMeters!, lessThan(200));
      expect(harness.controller.isLoadingPostos, isFalse);
    });

    test('usa o fallback de Santos quando o GPS falha', () async {
      final harness = _buildHarness(
        locationError: LocationServiceException('GPS desligado.'),
      );

      final initFuture = harness.controller.initialize();
      await pumpEventQueue();
      harness.referencePoints.nearbyCalls.single.completer.complete(const []);
      await initFuture;

      expect(
        harness.controller.pin.latitude,
        LocationSelectionController.santosFallbackPosition.latitude,
      );
      expect(
        harness.controller.pin.longitude,
        LocationSelectionController.santosFallbackPosition.longitude,
      );
      expect(
        harness.referencePoints.nearbyCalls.single.lat,
        LocationSelectionController.santosFallbackPosition.latitude,
      );
      expect(harness.controller.usingFallbackLocation, isTrue);
      expect(harness.controller.locationMessage, contains('GPS'));
      expect(harness.controller.postoSelecionado, isNull);
      expect(harness.controller.postosProximos, isEmpty);
    });

    test('e idempotente: uma unica rodada de carga por instancia', () async {
      final harness = await _harnessComPosto();

      await harness.controller.initialize();

      expect(harness.referencePoints.nearbyCalls, hasLength(1));
      expect(harness.location.calls, 1);
    });

    test('falha ao carregar postos expoe errorMessage sem travar', () async {
      final harness = _buildHarness();
      harness.referencePoints.errorToThrow = ApiNetworkException(
        Uri.parse('http://api.test/reference-points/nearby'),
        'sem rede',
      );

      await harness.controller.initialize();

      expect(
        harness.controller.errorMessage,
        'Nao foi possivel carregar os postos de referencia.',
      );
      expect(harness.controller.isLoadingPostos, isFalse);
    });
  });

  group('movePin', () {
    test('re-sugere o posto mais proximo da nova posicao', () async {
      final harness = await _harnessComPosto();

      final moveFuture = harness.controller.movePin(
        const GeoPoint(latitude: -23.9645, longitude: -46.3355),
      );
      await pumpEventQueue();

      expect(harness.referencePoints.nearbyCalls, hasLength(2));
      expect(harness.referencePoints.nearbyCalls[1].lat, -23.9645);

      harness.referencePoints.nearbyCalls[1].completer.complete(
        [_postoProximo, _postoDistante],
      );
      await moveFuture;

      expect(harness.controller.pin.latitude, -23.9645);
      expect(harness.controller.postoSelecionado!.id, 'posto-7');
    });

    test('descarta respostas antigas quando o pin se move rapido', () async {
      final harness = _buildHarness();

      final initFuture = harness.controller.initialize();
      await pumpEventQueue();
      expect(harness.referencePoints.nearbyCalls, hasLength(1));

      final moveFuture = harness.controller.movePin(
        const GeoPoint(latitude: -23.9645, longitude: -46.3355),
      );
      await pumpEventQueue();
      expect(harness.referencePoints.nearbyCalls, hasLength(2));

      // A resposta da requisicao mais nova chega primeiro.
      harness.referencePoints.nearbyCalls[1].completer.complete([_postoDistante]);
      await moveFuture;
      expect(harness.controller.postoSelecionado!.id, 'posto-7');

      // A resposta antiga chega depois e precisa ser descartada.
      harness.referencePoints.nearbyCalls[0].completer.complete([_postoProximo]);
      await initFuture;

      expect(harness.controller.postoSelecionado!.id, 'posto-7');
      expect(
        harness.controller.postosProximos.map((posto) => posto.id),
        ['posto-7'],
      );
      expect(harness.controller.isLoadingPostos, isFalse);
    });
  });

  group('selecionarPosto', () {
    test('recalcula a distancia para o posto escolhido manualmente', () async {
      final harness = await _harnessComPosto();

      harness.controller.selecionarPosto(_postoDistante);

      expect(harness.controller.postoSelecionado!.id, 'posto-7');
      final esperada = distanceMeters(
        harness.controller.pin,
        const GeoPoint(latitude: -23.9640, longitude: -46.3360),
      );
      expect(harness.controller.distanciaSelecionadaMeters, closeTo(esperada, 0.001));
      expect(esperada, greaterThan(1000));
    });
  });

  group('podeConfirmar', () {
    test('exige posto selecionado', () async {
      final harness = _buildHarness();
      final initFuture = harness.controller.initialize();
      await pumpEventQueue();
      harness.referencePoints.nearbyCalls.single.completer.complete(const []);
      await initFuture;

      expect(harness.controller.podeConfirmar, isFalse);
    });

    test('descricao vazia ou so espacos nao permite confirmar', () async {
      final harness = await _harnessComPosto();
      expect(harness.controller.podeConfirmar, isFalse);

      harness.controller.atualizarDescricao('   ');
      expect(harness.controller.podeConfirmar, isFalse);
    });

    test('aceita 140 caracteres e rejeita 141', () async {
      final harness = await _harnessComPosto();

      harness.controller.atualizarDescricao('a' * 140);
      expect(harness.controller.podeConfirmar, isTrue);

      harness.controller.atualizarDescricao('a' * 141);
      expect(harness.controller.podeConfirmar, isFalse);
    });
  });

  group('foto', () {
    test('anexar e remover foto atualizam o estado', () async {
      final harness = await _harnessComPosto();

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
    test('sem foto devolve OrderLocation completo sem chamar upload',
        () async {
      final harness = await _harnessComPosto();
      harness.controller.atualizarDescricao('  Guarda-sol azul  ');

      final location = await harness.controller.confirmarLocalizacao();

      expect(location, isNotNull);
      expect(location!.latitude, harness.controller.pin.latitude);
      expect(location.longitude, harness.controller.pin.longitude);
      expect(location.pontoReferenciaId, 'posto-6');
      expect(location.descricaoLocal, 'Guarda-sol azul');
      expect(location.fotoLocalUrl, isNull);
      expect(harness.upload.calls, isEmpty);
      expect(harness.controller.isConfirming, isFalse);
    });

    test('com foto faz upload e devolve a secureUrl', () async {
      final harness = await _harnessComPosto();
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

    test('falha no upload devolve null, mantem a foto e expoe erro', () async {
      final harness = await _harnessComPosto();
      harness.controller.atualizarDescricao('Guarda-sol azul');
      harness.controller.anexarFoto(Uint8List.fromList(const [1]));
      harness.upload.errorToThrow = ApiHttpException(
        Uri.parse('http://api.test/uploads/location-photo'),
        500,
        'erro interno',
      );

      final location = await harness.controller.confirmarLocalizacao();

      expect(location, isNull);
      expect(harness.controller.errorMessage, contains('foto'));
      expect(harness.controller.temFoto, isTrue);
      expect(harness.controller.isConfirming, isFalse);
    });

    test('bloqueia duplo envio enquanto a confirmacao esta em andamento',
        () async {
      final harness = await _harnessComPosto();
      harness.controller.atualizarDescricao('Guarda-sol azul');
      harness.controller.anexarFoto(Uint8List.fromList(const [1]));
      harness.upload.gate = Completer<String>();

      final first = harness.controller.confirmarLocalizacao();
      await pumpEventQueue();

      expect(harness.controller.isConfirming, isTrue);
      expect(harness.controller.podeConfirmar, isFalse);

      final second = await harness.controller.confirmarLocalizacao();
      expect(second, isNull);
      expect(harness.upload.calls, hasLength(1));

      harness.upload.gate!.complete('https://cdn.example.com/foto.jpg');
      final firstLocation = await first;

      expect(firstLocation, isNotNull);
      expect(firstLocation!.fotoLocalUrl, 'https://cdn.example.com/foto.jpg');
      expect(harness.controller.isConfirming, isFalse);
    });

    test('sem posto selecionado devolve null sem enviar nada', () async {
      final harness = _buildHarness();
      final initFuture = harness.controller.initialize();
      await pumpEventQueue();
      harness.referencePoints.nearbyCalls.single.completer.complete(const []);
      await initFuture;
      harness.controller.atualizarDescricao('Guarda-sol azul');

      final location = await harness.controller.confirmarLocalizacao();

      expect(location, isNull);
      expect(harness.upload.calls, isEmpty);
      expect(harness.controller.isConfirming, isFalse);
    });
  });

  group('recenterOnDeviceLocation', () {
    test('recupera a posicao do dispositivo quando o GPS volta', () async {
      final harness = _buildHarness(
        locationError: LocationServiceException('GPS desligado.'),
      );
      final initFuture = harness.controller.initialize();
      await pumpEventQueue();
      harness.referencePoints.nearbyCalls.single.completer.complete(const []);
      await initFuture;
      expect(harness.controller.usingFallbackLocation, isTrue);

      harness.location.errorToThrow = null;
      harness.location.position =
          const GeoPoint(latitude: -23.9730, longitude: -46.3200);

      final recenterFuture = harness.controller.recenterOnDeviceLocation();
      await pumpEventQueue();
      expect(harness.referencePoints.nearbyCalls, hasLength(2));
      harness.referencePoints.nearbyCalls[1].completer.complete([_postoProximo]);
      await recenterFuture;

      expect(harness.controller.pin.latitude, -23.9730);
      expect(harness.controller.usingFallbackLocation, isFalse);
      expect(harness.controller.locationMessage, isNull);
    });
  });
}
