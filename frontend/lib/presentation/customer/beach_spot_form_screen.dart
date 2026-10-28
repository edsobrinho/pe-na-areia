import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/forms/formatters.dart';
import '../../core/forms/validators.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/order_location.dart';
import '../../domain/models/reference_point.dart';
import '../location_selection/location_selection_controller.dart';
import '../location_selection/location_selection_screen.dart';
import '../theme/app_colors.dart';

/// Tela 1 (v2.1): Cadastro e Edição Detalhada do "Ponto na Praia".
///
/// Combina mini-mapa com ajuste de pin, campos de referência da barraca/guarda-sol,
/// Guia de 3 Fotos na Areia, dados de contato do banhista e etiquetas ("Salvar ponto como").
class BeachSpotFormScreen extends StatefulWidget {
  const BeachSpotFormScreen({
    super.key,
    required this.controllerFactory,
    this.initialLocation,
    this.defaultContactName = '',
    this.defaultContactPhone = '',
  });

  final LocationSelectionController Function() controllerFactory;
  final OrderLocation? initialLocation;
  final String defaultContactName;
  final String defaultContactPhone;

  @override
  State<BeachSpotFormScreen> createState() => _BeachSpotFormScreenState();
}

class _BeachSpotFormScreenState extends State<BeachSpotFormScreen> {
  static const List<({String code, String label, IconData icon})> _spotTags = [
    (
      code: 'MEU_GUARDA_SOL',
      label: 'Meu Guarda-sol',
      icon: Icons.beach_access_outlined,
    ),
    (
      code: 'BARRACA_FAMILIA',
      label: 'Barraca da Família',
      icon: Icons.family_restroom_outlined,
    ),
    (
      code: 'POINT_SURF',
      label: 'Point do Surf',
      icon: Icons.surfing_outlined,
    ),
    (
      code: 'OUTRO',
      label: 'Outro',
      icon: Icons.place_outlined,
    ),
  ];

  late final LocationSelectionController _locationController;
  late final TextEditingController _barracaController;
  late final TextEditingController _complementoController;
  late final TextEditingController _nomeContatoController;
  late final TextEditingController _telefoneContatoController;

  bool _semGuardaSol = false;
  bool _semComplemento = false;
  String _selectedTag = 'MEU_GUARDA_SOL';

  String? _fotoGuardaSolUrl;
  String? _fotoVisaoPostoUrl;
  String? _fotoOutroUrl;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locationController = widget.controllerFactory();
    _locationController.addListener(_onControllerChanged);

    final initLoc = widget.initialLocation;
    _barracaController = TextEditingController(
      text: initLoc?.referenciaBarraca ?? initLoc?.descricaoLocal ?? '',
    );
    _complementoController = TextEditingController(
      text: initLoc?.complementoLocal ?? '',
    );
    _nomeContatoController = TextEditingController(
      text: initLoc?.contatoNome ?? widget.defaultContactName,
    );
    _telefoneContatoController = TextEditingController(
      text: initLoc?.contatoTelefone ?? widget.defaultContactPhone,
    );
    _fotoGuardaSolUrl = initLoc?.fotoLocalUrl;
    _fotoVisaoPostoUrl = initLoc?.fotoVisaoPostoUrl;
    _fotoOutroUrl = initLoc?.fotoOutroReferencialUrl;
    if (initLoc?.etiquetaLocal != null && initLoc!.etiquetaLocal!.isNotEmpty) {
      _selectedTag = initLoc.etiquetaLocal!;
    }

    _locationController.initialize();
  }

  @override
  void dispose() {
    _locationController.removeListener(_onControllerChanged);
    _locationController.dispose();
    _barracaController.dispose();
    _complementoController.dispose();
    _nomeContatoController.dispose();
    _telefoneContatoController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openPinAdjuster() async {
    final result = await Navigator.of(context).push<OrderLocation>(
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          controller: widget.controllerFactory(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (_barracaController.text.trim().isEmpty &&
          result.descricaoLocal.isNotEmpty) {
        _barracaController.text = result.descricaoLocal;
      }
      if (result.fotoLocalUrl != null) {
        _fotoGuardaSolUrl = result.fotoLocalUrl;
      }
    });
    await _locationController.movePin(
      GeoPoint(
        latitude: result.latitude,
        longitude: result.longitude,
      ),
    );
  }

  Future<void> _pickAndUploadSlotPhoto(int slotIndex) async {
    if (_uploadingPhoto) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _uploadingPhoto = true;
      _error = null;
    });
    try {
      final bytes = await picked.readAsBytes();
      final url = await _locationController.uploadRepository.uploadLocationPhoto(
        bytes: bytes,
        filename: picked.name.isEmpty ? 'ponto-praia-$slotIndex.jpg' : picked.name,
      );
      if (!mounted) return;
      setState(() {
        if (slotIndex == 0) {
          _fotoGuardaSolUrl = url;
        } else if (slotIndex == 1) {
          _fotoVisaoPostoUrl = url;
        } else {
          _fotoOutroUrl = url;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível enviar a foto para o servidor.';
        });
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _resetForm() {
    setState(() {
      _barracaController.clear();
      _complementoController.clear();
      _semGuardaSol = false;
      _semComplemento = false;
      _fotoGuardaSolUrl = null;
      _fotoVisaoPostoUrl = null;
      _fotoOutroUrl = null;
      _selectedTag = 'MEU_GUARDA_SOL';
      _error = null;
    });
  }

  void _confirmSpot() {
    setState(() => _error = null);
    final posto = _locationController.postoSelecionado;
    final postoId = posto?.id ?? widget.initialLocation?.pontoReferenciaId ?? '';
    if (postoId.isEmpty) {
      setState(() {
        _error = 'Selecione ou aguarde a identificação do Posto de Salvamento mais próximo.';
      });
      return;
    }

    final barracaText = _semGuardaSol
        ? 'Sem guarda-sol (na faixa de areia)'
        : _barracaController.text.trim();
    if (barracaText.isEmpty) {
      setState(() {
        _error = 'Informe a cor do guarda-sol/barraca ou marque "Sem guarda-sol".';
      });
      return;
    }

    final complementoText = _semComplemento
        ? 'Sem complemento'
        : _complementoController.text.trim();
    if (!_semComplemento && complementoText.isEmpty) {
      setState(() {
        _error = 'Informe um complemento/ponto de encontro ou marque "Sem complemento".';
      });
      return;
    }

    final nome = _nomeContatoController.text.trim();
    if (nome.length < 2) {
      setState(() {
        _error = 'Informe o nome de quem vai receber o pedido na areia.';
      });
      return;
    }

    final telefone = _telefoneContatoController.text.trim();
    if (telefone.isNotEmpty) {
      final phoneErr = AppValidators.validatePhone(telefone);
      if (phoneErr != null) {
        setState(() => _error = phoneErr);
        return;
      }
    }

    final combined = _semComplemento
        ? barracaText
        : '$barracaText · $complementoText';
    final descricaoFinal = combined.length > OrderLocation.maxDescricaoLength
        ? combined.substring(0, OrderLocation.maxDescricaoLength)
        : combined;

    final pin = _locationController.pin;
    final location = OrderLocation(
      latitude: pin.latitude,
      longitude: pin.longitude,
      pontoReferenciaId: postoId,
      descricaoLocal: descricaoFinal,
      fotoLocalUrl: _fotoGuardaSolUrl,
      referenciaBarraca: barracaText,
      complementoLocal: complementoText,
      fotoVisaoPostoUrl: _fotoVisaoPostoUrl,
      fotoOutroReferencialUrl: _fotoOutroUrl,
      contatoNome: nome,
      contatoTelefone: telefone.isEmpty ? null : '+55 $telefone',
      etiquetaLocal: _selectedTag,
    );

    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final pin = _locationController.pin;
    final posto = _locationController.postoSelecionado;
    final distPosto = _locationController.distanciaSelecionadaMeters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.ocean900,
        foregroundColor: Colors.white,
        title: const Text('Ponto de entrega na praia'),
        actions: [
          IconButton(
            tooltip: 'Limpar campos',
            onPressed: _resetForm,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMiniMapHeader(pin, posto, distPosto),
          const SizedBox(height: 16),
          _buildBeachIdentificationSection(),
          const SizedBox(height: 20),
          _buildPhotoGuideSection(),
          const SizedBox(height: 20),
          _buildContactSection(),
          const SizedBox(height: 20),
          _buildSaveAsSection(),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mango500,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _uploadingPhoto ? null : _confirmSpot,
            child: const Text(
              'Confirmar ponto na areia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMapHeader(
    dynamic pin,
    ReferencePoint? posto,
    double? distPosto,
  ) {
    final target = LatLng(pin.latitude as double, pin.longitude as double);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 155,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('pin-ponto-praia'),
                        position: target,
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    liteModeEnabled: true,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 58),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ocean900.withValues(alpha: 0.92),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _openPinAdjuster,
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                      label: const Text('Ajustar local no mapa'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.waves, color: AppColors.ocean700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    posto != null
                        ? '${posto.nome} · ${posto.trecho}, Orla de Santos/SP'
                            '${distPosto != null ? ' (${distPosto.round()} m)' : ''}'
                        : 'Orla de Santos/SP · Pin (${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeachIdentificationSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _barracaController,
            enabled: !_semGuardaSol,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: 'Cor do guarda-sol / referência da barraca *',
              hintText: 'Ex: Guarda-sol azul marinho com 2 cadeiras brancas',
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.ocean700,
            value: _semGuardaSol,
            onChanged: (val) => setState(() => _semGuardaSol = val ?? false),
            title: const Text('Sem guarda-sol (estou na canga/cadeira na areia)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _complementoController,
            enabled: !_semComplemento,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: 'Complemento / Ponto de encontro *',
              hintText: 'Ex: Em frente à rede de futevôlei, perto da ducha',
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.ocean700,
            value: _semComplemento,
            onChanged: (val) => setState(() => _semComplemento = val ?? false),
            title: const Text('Sem complemento adicional'),
          ),
        ],
      );

  Widget _buildPhotoGuideSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guia de foto na areia',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Adicione fotos do seu ponto na praia para agilizar a entrega',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPhotoSlotCard(
                  index: 0,
                  label: 'Guarda-sol',
                  icon: Icons.beach_access_outlined,
                  imageUrl: _fotoGuardaSolUrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPhotoSlotCard(
                  index: 1,
                  label: 'Visão do Posto',
                  icon: Icons.tour_outlined,
                  imageUrl: _fotoVisaoPostoUrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPhotoSlotCard(
                  index: 2,
                  label: 'Outro item',
                  icon: Icons.add_a_photo_outlined,
                  imageUrl: _fotoOutroUrl,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildPhotoSlotCard({
    required int index,
    required String label,
    required IconData icon,
    required String? imageUrl,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickAndUploadSlotPhoto(index),
        child: Container(
          height: 112,
          decoration: BoxDecoration(
            color: AppColors.sand50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: imageUrl != null ? AppColors.seafoam500 : AppColors.sand100,
              width: imageUrl != null ? 2 : 1,
            ),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(icon, color: AppColors.ocean700),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28, color: AppColors.ocean700),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ocean900,
                      ),
                    ),
                  ],
                ),
        ),
      );

  Widget _buildContactSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contato na praia',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nomeContatoController,
            decoration: InputDecoration(
              labelText: 'Nome de quem vai receber *',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefoneContatoController,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Telefone / WhatsApp *',
              prefixText: '+55  ',
              hintText: '(13) 99999-9999',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );

  Widget _buildSaveAsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salvar ponto como',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _spotTags
                .map(
                  (tag) => ChoiceChip(
                    avatar: Icon(
                      tag.icon,
                      size: 16,
                      color: _selectedTag == tag.code
                          ? Colors.white
                          : AppColors.ocean900,
                    ),
                    label: Text(tag.label),
                    selected: _selectedTag == tag.code,
                    selectedColor: AppColors.ocean700,
                    labelStyle: TextStyle(
                      color: _selectedTag == tag.code
                          ? Colors.white
                          : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedTag = tag.code),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      );
}
