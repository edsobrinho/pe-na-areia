import 'package:flutter/foundation.dart';

import '../../data/http/api_exception.dart';
import '../../data/repositories/reference_point_repository.dart';
import '../../data/repositories/upload_repository.dart';
import '../../data/services/location_service.dart';
import '../../domain/geo.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/reference_point.dart';

/// Estado da tela de selecao de localizacao (pin no mapa).
///
/// Responsabilidades:
/// - posicao do pin (posicao do dispositivo ou fallback de Santos) e
///   protecao contra respostas antigas quando o pin se move rapido;
/// - sugestao do posto de referencia mais proximo, com distancia calculada;
/// - descricao do local (ate 140 caracteres) e foto opcional;
/// - confirmacao: faz upload da foto (se houver) e devolve um
///   [OrderLocation] completo para o fluxo de checkout.
class LocationSelectionController extends ChangeNotifier {
  LocationSelectionController({
    required ReferencePointRepository referencePointRepository,
    required UploadRepository uploadRepository,
    required LocationService locationService,
    GeoPoint fallbackPosition = santosFallbackPosition,
  })  : _referencePointRepository = referencePointRepository,
        _uploadRepository = uploadRepository,
        _locationService = locationService,
        _fallbackPosition = fallbackPosition,
        _pin = fallbackPosition;

  /// Centro do Boqueirao, Santos: usado quando o GPS do dispositivo falha.
  static const GeoPoint santosFallbackPosition =
      GeoPoint(latitude: -23.9722, longitude: -46.3280);

  /// Limite de caracteres da descricao do local (contrato com o backend).
  static const int maxDescricaoLength = OrderLocation.maxDescricaoLength;

  final ReferencePointRepository _referencePointRepository;
  final UploadRepository _uploadRepository;
  final LocationService _locationService;
  final GeoPoint _fallbackPosition;

  GeoPoint _pin;
  List<ReferencePoint> _postosProximos = const [];
  ReferencePoint? _postoSelecionado;
  double? _distanciaSelecionadaMeters;
  String _descricao = '';
  Uint8List? _fotoBytes;
  String? _fotoFilename;

  bool _isInitializing = false;
  bool _isLoadingPostos = false;
  bool _isConfirming = false;
  bool _usingFallbackLocation = false;
  String? _locationMessage;
  String? _errorMessage;

  int _nearbyRequestSeq = 0;
  bool _initialized = false;
  bool _pinMovedByUser = false;
  bool _disposed = false;

  GeoPoint get pin => _pin;

  List<ReferencePoint> get postosProximos => _postosProximos;

  ReferencePoint? get postoSelecionado => _postoSelecionado;

  /// Distancia em metros entre o pin e o posto selecionado.
  double? get distanciaSelecionadaMeters => _distanciaSelecionadaMeters;

  String get descricao => _descricao;

  Uint8List? get fotoBytes => _fotoBytes;

  bool get temFoto => _fotoBytes != null;

  bool get isInitializing => _isInitializing;

  bool get isLoadingPostos => _isLoadingPostos;

  bool get isConfirming => _isConfirming;

  /// `true` quando a posicao do dispositivo nao pode ser obtida e o pin
  /// comeca no fallback de Santos.
  bool get usingFallbackLocation => _usingFallbackLocation;

  /// Explicacao (pt-BR) de por que o fallback esta em uso.
  String? get locationMessage => _locationMessage;

  String? get errorMessage => _errorMessage;

  /// Carrega a posicao do dispositivo (com fallback) e a primeira lista de
  /// postos proximos. Idempotente: so executa uma vez por instancia.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _isInitializing = true;
    _notify();

    await _atualizarComLocalizacaoDoDispositivo(force: false);

    _isInitializing = false;
    _notify();
    await refreshPostosProximos();
  }

  /// Tenta centralizar o pin na posicao atual do dispositivo (botao "minha
  /// localizacao") e recarrega os postos proximos.
  Future<void> recenterOnDeviceLocation() async {
    await _atualizarComLocalizacaoDoDispositivo(force: true);
    await refreshPostosProximos();
  }

  /// Move o pin (toque no mapa ou fim do arrasto) e re-sugere o posto mais
  /// proximo. Respostas de requisicoes antigas sao descartadas.
  Future<void> movePin(GeoPoint position) async {
    _pinMovedByUser = true;
    _pin = position;
    _notify();
    await refreshPostosProximos();
  }

  /// Recarrega a sugestao de postos proximos ao pin atual.
  Future<void> refreshPostosProximos() async {
    final sequencia = ++_nearbyRequestSeq;
    _isLoadingPostos = true;
    _errorMessage = null;
    _notify();

    try {
      final postos = await _referencePointRepository.fetchNearby(
        lat: _pin.latitude,
        lng: _pin.longitude,
      );
      if (_disposed || sequencia != _nearbyRequestSeq) {
        // Resposta antiga (o pin ja se moveu de novo): descartar.
        return;
      }
      _postosProximos = _ordenarPorDistancia(postos);
      _postoSelecionado = _postosProximos.isEmpty ? null : _postosProximos.first;
      _distanciaSelecionadaMeters = _postoSelecionado == null
          ? null
          : distanceMeters(_pin, _geoPointDoPosto(_postoSelecionado!));
    } on ApiException {
      if (_disposed || sequencia != _nearbyRequestSeq) {
        return;
      }
      _errorMessage = 'Nao foi possivel carregar os postos de referencia.';
    } finally {
      if (!_disposed && sequencia == _nearbyRequestSeq) {
        _isLoadingPostos = false;
        _notify();
      }
    }
  }

  /// Seleciona um posto manualmente (toque em um chip da lista).
  void selecionarPosto(ReferencePoint posto) {
    _postoSelecionado = posto;
    _distanciaSelecionadaMeters = distanceMeters(_pin, _geoPointDoPosto(posto));
    _notify();
  }

  /// Atualiza a descricao do local conforme o usuario digita.
  void atualizarDescricao(String valor) {
    if (valor == _descricao) {
      return;
    }
    _descricao = valor;
    _notify();
  }

  /// Anexa a foto do local (bytes ja lidos do arquivo escolhido).
  void anexarFoto(Uint8List bytes, {String? filename}) {
    _fotoBytes = bytes;
    _fotoFilename = filename;
    _notify();
  }

  /// Remove a foto anexada.
  void removerFoto() {
    if (_fotoBytes == null) {
      return;
    }
    _fotoBytes = null;
    _fotoFilename = null;
    _notify();
  }

  /// Regra do botao "Confirmar localizacao": exige posto selecionado e
  /// descricao nao vazia de ate 140 caracteres, e nao permite duplo envio.
  bool get podeConfirmar =>
      _postoSelecionado != null &&
      _descricao.trim().isNotEmpty &&
      _descricao.length <= maxDescricaoLength &&
      !_isConfirming;

  /// Confirma a localizacao: envia a foto do local para o backend (quando
  /// houver) e devolve um [OrderLocation] completo. Em falha, devolve `null`
  /// e expoe [errorMessage].
  Future<OrderLocation?> confirmarLocalizacao() async {
    if (!podeConfirmar) {
      return null;
    }
    _isConfirming = true;
    _errorMessage = null;
    _notify();

    try {
      String? fotoUrl;
      final bytes = _fotoBytes;
      if (bytes != null) {
        fotoUrl = await _uploadRepository.uploadLocationPhoto(
          bytes: bytes,
          filename: _fotoFilename ?? 'local.jpg',
        );
      }

      return OrderLocation(
        latitude: _pin.latitude,
        longitude: _pin.longitude,
        pontoReferenciaId: _postoSelecionado!.id,
        descricaoLocal: _descricao.trim(),
        fotoLocalUrl: fotoUrl,
      );
    } on ApiException {
      _errorMessage =
          'Nao foi possivel enviar a foto do local. Verifique a conexao e tente novamente.';
      return null;
    } catch (_) {
      _errorMessage =
          'Nao foi possivel confirmar a localizacao. Tente novamente.';
      return null;
    } finally {
      _isConfirming = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _atualizarComLocalizacaoDoDispositivo({
    required bool force,
  }) async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (_disposed) {
        return;
      }
      // Protecao contra resposta antiga: se o usuario ja moveu o pin
      // manualmente, a posicao do dispositivo nao sobrescreve a escolha dele.
      if (force || !_pinMovedByUser) {
        _pin = position;
      }
      _usingFallbackLocation = false;
      _locationMessage = null;
    } on LocationServiceException catch (error) {
      if (_disposed) {
        return;
      }
      _usingFallbackLocation = true;
      _locationMessage = error.message;
    } catch (_) {
      if (_disposed) {
        return;
      }
      _usingFallbackLocation = true;
      _locationMessage =
          'Nao foi possivel obter sua localizacao atual. Usando o centro da orla '
          '(${_fallbackPosition.latitude.toStringAsFixed(4)}, '
          '${_fallbackPosition.longitude.toStringAsFixed(4)}).';
    }
    _notify();
  }

  List<ReferencePoint> _ordenarPorDistancia(List<ReferencePoint> postos) {
    final ordenados = List<ReferencePoint>.of(postos);
    ordenados.sort(
      (a, b) => distanceMeters(_pin, _geoPointDoPosto(a))
          .compareTo(distanceMeters(_pin, _geoPointDoPosto(b))),
    );
    return List.unmodifiable(ordenados);
  }

  GeoPoint _geoPointDoPosto(ReferencePoint posto) =>
      GeoPoint(latitude: posto.latitude, longitude: posto.longitude);

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
