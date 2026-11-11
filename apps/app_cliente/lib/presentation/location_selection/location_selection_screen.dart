import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:core_shared/core_shared.dart';
import 'location_selection_controller.dart';

/// Tela de seleção de localização no mapa (Pin Livre + Full Screen Zoom):
/// O cliente posiciona o Pin em qualquer ponto do mapa (com zoom livre em tela
/// cheia), sem depender de postos de entrega pré-cadastrados.
class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({
    super.key,
    required this.controller,
    this.initialPin,
    this.onlyPinPicker = false,
  });

  final LocationSelectionController controller;
  final GeoPoint? initialPin;
  final bool onlyPinPicker;

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _descricaoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  GoogleMapController? _mapController;
  late bool _isFullScreenMap;
  MapType _mapType = MapType.normal;

  LocationSelectionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _isFullScreenMap = widget.onlyPinPicker;
    _descricaoController.text = _controller.descricao;
    final initPin = widget.initialPin;
    if (initPin != null) {
      unawaited(_controller.movePin(initPin));
    }
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _recentrarNaLocalizacaoAtual() async {
    await _controller.recenterOnDeviceLocation();
    if (!mounted) {
      return;
    }
    final mapController = _mapController;
    if (mapController != null) {
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_toLatLng(_controller.pin), 18.5),
      );
    }
  }

  Future<void> _zoomIn() async {
    await _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    await _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _abrirOpcoesDeFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    await _capturarFoto(source);
  }

  Future<void> _capturarFoto(ImageSource source) async {
    try {
      final arquivo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (arquivo == null) {
        return;
      }
      final bytes = await arquivo.readAsBytes();
      if (!mounted) {
        return;
      }
      _controller.anexarFoto(bytes, filename: arquivo.name);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      final mensagem = error.code == 'camera_access_denied'
          ? 'Permissao de camera negada. Autorize o acesso nas configuracoes.'
          : 'Nao foi possivel obter a foto.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel obter a foto.')),
      );
    }
  }

  Future<void> _confirmarLocalizacao() async {
    if (widget.onlyPinPicker) {
      Navigator.of(context).pop(_controller.confirmarApenasPin());
      return;
    }
    final location = await _controller.confirmarLocalizacao();
    if (!mounted || location == null) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(location);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localizacao confirmada para o seu pedido.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          _isFullScreenMap
              ? 'Mapa em Tela Cheia · Ajuste com Zoom'
              : 'Selecionar Ponto no Mapa',
        ),
        actions: [
          if (!widget.onlyPinPicker)
            IconButton(
              tooltip: _isFullScreenMap
                  ? 'Mostrar formulário'
                  : 'Expandir mapa em tela cheia',
              onPressed: () =>
                  setState(() => _isFullScreenMap = !_isFullScreenMap),
              icon: Icon(
                _isFullScreenMap
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                color: AppColors.ink,
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isInitializing) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.sage500),
            );
          }
          if (_isFullScreenMap) {
            return _buildFullScreenMapBody();
          }
          return Column(
            children: [
              Expanded(flex: 5, child: _buildMapa(fullScreen: false)),
              Expanded(flex: 4, child: _buildFolhaDeSelecao()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFullScreenMapBody() {
    final pin = _controller.pin;
    return Stack(
      children: [
        Positioned.fill(
          child: _buildMapa(fullScreen: true),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.bottomSheetShadow,
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.sage600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pin fixado: ${pin.latitude.toStringAsFixed(5)}, ${pin.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (!widget.onlyPinPicker)
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _isFullScreenMap = false),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Descrição'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sage500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: widget.onlyPinPicker
                        ? _confirmarLocalizacao
                        : () => setState(() => _isFullScreenMap = false),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      widget.onlyPinPicker
                          ? 'CONFIRMAR PIN NESTE PONTO'
                          : 'USAR ESTE PONTO E CONTINUAR',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapa({required bool fullScreen}) {
    final pinLatLng = _toLatLng(_controller.pin);
    return Container(
      margin: fullScreen
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: fullScreen ? EdgeInsets.zero : const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius:
            fullScreen ? BorderRadius.zero : BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius:
            fullScreen ? BorderRadius.zero : BorderRadius.circular(18),
        child: Stack(
          children: [
            if (GoogleMapsChecker.isReady)
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: pinLatLng, zoom: 18),
                mapType: _mapType,
                onMapCreated: (controller) => _mapController = controller,
                onTap: (position) => unawaited(
                  _controller.movePin(
                    GeoPoint(
                      latitude: position.latitude,
                      longitude: position.longitude,
                    ),
                  ),
                ),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                myLocationEnabled: !_controller.usingFallbackLocation,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                minMaxZoomPreference: const MinMaxZoomPreference(3, 21),
                markers: {
                  Marker(
                    markerId: const MarkerId('pin-cliente'),
                    position: pinLatLng,
                    draggable: true,
                    onDragEnd: (position) => unawaited(
                      _controller.movePin(
                        GeoPoint(
                          latitude: position.latitude,
                          longitude: position.longitude,
                        ),
                      ),
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                },
              )
            else
              _buildMapFallback(pinLatLng),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: const Text(
                    'Dê zoom com 2 dedos, toque no mapa ou arraste o Pin para qualquer ponto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 64,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'toggle-fullscreen-map',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    onPressed: () =>
                        setState(() => _isFullScreenMap = !_isFullScreenMap),
                    tooltip: _isFullScreenMap
                        ? 'Reduzir mapa'
                        : 'Abrir mapa em tela cheia',
                    child: Icon(
                      _isFullScreenMap
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'toggle-map-type',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    onPressed: () => setState(() {
                      _mapType = _mapType == MapType.normal
                          ? MapType.hybrid
                          : MapType.normal;
                    }),
                    tooltip: 'Alternar visão satélite / mapa',
                    child: Icon(
                      _mapType == MapType.normal
                          ? Icons.satellite_alt_rounded
                          : Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom-in-map',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    onPressed: _zoomIn,
                    tooltip: 'Aproximar zoom (+)',
                    child: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom-out-map',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.ink,
                    onPressed: _zoomOut,
                    tooltip: 'Afastar zoom (-)',
                    child: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'recentrar-localizacao',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.sage600,
                    onPressed: _recentrarNaLocalizacaoAtual,
                    tooltip: 'Usar minha localizacao atual (GPS)',
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapFallback(LatLng pinLatLng) => Container(
        color: AppColors.sage100,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 44,
              color: AppColors.apricot500,
            ),
            const SizedBox(height: 8),
            Text(
              'Pin selecionado: ${pinLatLng.latitude.toStringAsFixed(5)}, '
              '${pinLatLng.longitude.toStringAsFixed(5)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );

  Widget _buildFolhaDeSelecao() {
    final pin = _controller.pin;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppTheme.bottomSheetShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.dragHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Onde você está?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _isFullScreenMap = true),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Tela cheia'),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Coordenadas do Pin: ${pin.latitude.toStringAsFixed(5)}, ${pin.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sage700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Posicione o Pin em qualquer ponto do mapa e descreva sua referência visual',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink500),
            ),
            if (_controller.usingFallbackLocation) ...[
              const SizedBox(height: 12),
              _buildAvisoDeFallback(),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _descricaoController,
              maxLength: LocationSelectionController.maxDescricaoLength,
              onChanged: _controller.atualizarDescricao,
              decoration: InputDecoration(
                hintText:
                    'Ex: guarda-sol listrado azul, perto da rede de vôlei',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSecaoDeFoto(),
            if (_controller.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _controller.errorMessage!,
                style: const TextStyle(color: AppColors.danger500, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            _buildBotaoConfirmar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvisoDeFallback() {
    final mensagem = _controller.locationMessage ??
        'Nao foi possivel obter sua localizacao do dispositivo.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 18,
            color: AppColors.ink700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$mensagem Toque no mapa ou arraste o pin para ajustar.',
              style: const TextStyle(fontSize: 12, color: AppColors.ink700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoDeFoto() {
    final bytes = _controller.fotoBytes;
    return Row(
      children: [
        if (bytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _abrirOpcoesDeFoto,
            icon: Icon(
              bytes == null
                  ? Icons.add_a_photo_outlined
                  : Icons.photo_camera_back_outlined,
              size: 18,
              color: AppColors.sage600,
            ),
            label: Text(
              bytes == null
                  ? 'Adicionar foto do local (opcional)'
                  : 'Trocar foto do local',
            ),
          ),
        ),
        if (bytes != null)
          IconButton(
            onPressed: _controller.removerFoto,
            tooltip: 'Remover foto',
            icon: const Icon(Icons.close),
            color: AppColors.ink700,
          ),
      ],
    );
  }

  Widget _buildBotaoConfirmar() {
    final confirmando = _controller.isConfirming;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _controller.podeConfirmar ? _confirmarLocalizacao : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.sage500,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
        ),
        child: confirmando
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _controller.temFoto ? 'ENVIANDO FOTO...' : 'CONFIRMANDO...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : const Text(
                'Confirmar localizacao',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
      ),
    );
  }

  LatLng _toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);
}
