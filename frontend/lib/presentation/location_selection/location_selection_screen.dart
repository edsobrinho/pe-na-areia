import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/geo_point.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/reference_point.dart';
import '../theme/app_colors.dart';
import 'location_selection_controller.dart';

/// Tela 1 do fluxo do cliente: o cliente marca um pin no mapa em vez de
/// digitar um endereco, escolhe o posto de referencia mais proximo, descreve
/// o local e opcionalmente anexa uma foto. Confirma devolvendo um
/// [OrderLocation] completo (com a foto ja enviada para o storage).
///
/// A tela assume a posse do [controller] recebido e o descarta no dispose:
/// as rotas devem construir um controller novo por navegacao.
class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key, required this.controller});

  final LocationSelectionController controller;

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _descricaoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  GoogleMapController? _mapController;

  LocationSelectionController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _descricaoController.text = _controller.descricao;
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
        CameraUpdate.newLatLng(_toLatLng(_controller.pin)),
      );
    }
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
    final location = await _controller.confirmarLocalizacao();
    if (!mounted || location == null) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(location);
    } else {
      // A tela tambem roda como rota inicial (sem checkout acima para
      // receber o resultado); nesse caso confirma com um aviso.
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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isInitializing) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(flex: 3, child: _buildMapa()),
              Expanded(flex: 4, child: _buildFolhaDeSelecao()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapa() {
    final pinLatLng = _toLatLng(_controller.pin);
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: pinLatLng, zoom: 17),
          onMapCreated: (controller) => _mapController = controller,
          onTap: (position) => unawaited(
            _controller.movePin(
              GeoPoint(
                  latitude: position.latitude, longitude: position.longitude),
            ),
          ),
          myLocationEnabled: !_controller.usingFallbackLocation,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
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
                BitmapDescriptor.hueRed,
              ),
            ),
            ..._controller.postosProximos.map(_buildMarkerDePosto),
          },
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Toque no mapa ou arraste o pin ate o local exato',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'recentrar-localizacao',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ocean700,
            onPressed: _recentrarNaLocalizacaoAtual,
            tooltip: 'Usar minha localizacao atual',
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Marker _buildMarkerDePosto(ReferencePoint posto) {
    final selecionado = _controller.postoSelecionado?.id == posto.id;
    return Marker(
      markerId: MarkerId('posto-${posto.id}'),
      position: LatLng(posto.latitude, posto.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        selecionado ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
      ),
      infoWindow: InfoWindow(title: posto.nome),
    );
  }

  Widget _buildFolhaDeSelecao() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onde voce esta?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.ocean900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escolha o posto de referencia mais proximo e descreva o local',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            if (_controller.usingFallbackLocation) ...[
              const SizedBox(height: 12),
              _buildAvisoDeFallback(),
            ],
            const SizedBox(height: 16),
            _buildChipsDePostos(),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              maxLength: LocationSelectionController.maxDescricaoLength,
              onChanged: _controller.atualizarDescricao,
              decoration: InputDecoration(
                hintText:
                    'Ex: guarda-sol listrado azul, perto do quiosque do Ze',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSecaoDeFoto(),
            if (_controller.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _controller.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
        color: AppColors.sand100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined,
              size: 18, color: AppColors.ocean900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$mensagem Toque no mapa ou arraste o pin para ajustar.',
              style: const TextStyle(fontSize: 12, color: AppColors.ocean900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsDePostos() {
    if (_controller.isLoadingPostos && _controller.postosProximos.isEmpty) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Buscando postos proximos...',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      );
    }

    if (_controller.postosProximos.isEmpty) {
      return const Text(
        'Nenhum posto de referencia encontrado perto do pin. '
        'Tente arrastar para mais perto da orla.',
        style: TextStyle(fontSize: 12, color: Colors.black45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _controller.postosProximos.map((posto) {
            final selecionado = _controller.postoSelecionado?.id == posto.id;
            return ChoiceChip(
              label: Text(posto.nome),
              selected: selecionado,
              onSelected: (_) => _controller.selecionarPosto(posto),
              selectedColor: AppColors.ocean900,
              labelStyle: TextStyle(
                color: selecionado ? Colors.white : AppColors.ocean900,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              backgroundColor: AppColors.sand100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
        if (_controller.postoSelecionado != null &&
            _controller.distanciaSelecionadaMeters != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_controller.postoSelecionado!.nome} '
            '· a ${_formatarDistancia(_controller.distanciaSelecionadaMeters!)} '
            'do pin',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.ocean700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecaoDeFoto() {
    final bytes = _controller.fotoBytes;
    return Row(
      children: [
        if (bytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
            ),
            label: Text(
              bytes == null
                  ? 'Adicionar foto do local (opcional)'
                  : 'Trocar foto do local',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ocean700,
              side: BorderSide(
                color: AppColors.ocean500.withValues(alpha: 0.5),
              ),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (bytes != null)
          IconButton(
            onPressed: _controller.removerFoto,
            tooltip: 'Remover foto',
            icon: const Icon(Icons.close),
            color: AppColors.ocean900,
          ),
      ],
    );
  }

  Widget _buildBotaoConfirmar() {
    final confirmando = _controller.isConfirming;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _controller.podeConfirmar ? _confirmarLocalizacao : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mango500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                    _controller.temFoto ? 'Enviando foto...' : 'Confirmando...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : const Text(
                'Confirmar localizacao',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  LatLng _toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);

  String _formatarDistancia(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
