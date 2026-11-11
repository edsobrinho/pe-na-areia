import 'package:flutter/foundation.dart';

import 'package:core_shared/core_shared.dart';

/// Estado da tela de selecao de localizacao (pin livre no mapa).
///
/// Responsabilidades:
/// - posicao livre do pin em qualquer ponto do mapa (posicao do dispositivo ou
///   fallback de Santos) sem depender de postos de entrega pre-cadastrados;
/// - descricao do local (ate 140 caracteres) e foto opcional;
/// - confirmacao: faz upload da foto (se houver) e devolve um
///   [OrderLocation] baseado exclusivamente na geolocalizacao, descricao e foto.
class LocationSelectionController extends ChangeNotifier {
  LocationSelectionController({
    ReferencePointRepository? referencePointRepository,
    required UploadRepository uploadRepository,
    required LocationService locationService,
    GeoPoint fallbackPosition = santosFallbackPosition,
  })  : _uploadRepository = uploadRepository,
        _locationService = locationService,
        _fallbackPosition = fallbackPosition,
        _pin = fallbackPosition;

  /// Centro do Boqueirao, Santos: usado quando o GPS do dispositivo falha.
  static const GeoPoint santosFallbackPosition =
      GeoPoint(latitude: -23.9722, longitude: -46.3280);

  /// Limite de caracteres da descricao do local (contrato com o backend).
  static const int maxDescricaoLength = OrderLocation.maxDescricaoLength;

  final UploadRepository _uploadRepository;
  final LocationService _locationService;
  final GeoPoint _fallbackPosition;

  GeoPoint _pin;
  String _descricao = '';
  Uint8List? _fotoBytes;
  String? _fotoFilename;

  bool _isInitializing = false;
  bool _isConfirming = false;
  bool _usingFallbackLocation = false;
  String? _locationMessage;
  String? _errorMessage;

  bool _initialized = false;
  bool _pinMovedByUser = false;
  bool _disposed = false;

  GeoPoint get pin => _pin;

  UploadRepository get uploadRepository => _uploadRepository;

  String get descricao => _descricao;

  Uint8List? get fotoBytes => _fotoBytes;

  bool get temFoto => _fotoBytes != null;

  bool get isInitializing => _isInitializing;

  bool get isConfirming => _isConfirming;

  /// `true` quando a posicao do dispositivo nao pode ser obtida e o pin
  /// comeca no fallback de Santos.
  bool get usingFallbackLocation => _usingFallbackLocation;

  /// Explicacao (pt-BR) de por que o fallback esta em uso.
  String? get locationMessage => _locationMessage;

  String? get errorMessage => _errorMessage;

  /// Carrega a posicao do dispositivo (com fallback) sem buscar postos.
  /// Idempotente: so executa uma vez por instancia.
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
  }

  /// Tenta centralizar o pin na posicao atual do dispositivo (botao "minha
  /// localizacao").
  Future<void> recenterOnDeviceLocation() async {
    await _atualizarComLocalizacaoDoDispositivo(force: true);
  }

  /// Move o pin livremente para qualquer ponto do mapa (toque, arrasto ou mira).
  Future<void> movePin(GeoPoint position) async {
    _pinMovedByUser = true;
    _pin = position;
    _errorMessage = null;
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

  /// Regra do botao "Confirmar localizacao": exige apenas descricao nao vazia
  /// de ate 140 caracteres (sem necessidade de posto pre-cadastrado).
  bool get podeConfirmar =>
      _descricao.trim().isNotEmpty &&
      _descricao.length <= maxDescricaoLength &&
      !_isConfirming;

  /// Confirma apenas a coordenada do pin (usado pelo seletor de mapa Full Screen).
  OrderLocation confirmarApenasPin() => OrderLocation(
        latitude: _pin.latitude,
        longitude: _pin.longitude,
        descricaoLocal: _descricao.trim(),
      );

  /// Confirma a localizacao: envia a foto do local para o backend (quando
  /// houver) e devolve um [OrderLocation] completo baseado na geolocalizacao.
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

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
