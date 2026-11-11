import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/routes.dart';
import 'package:core_shared/core_shared.dart';
import 'beach_radar_widget.dart';

/// App Mobile do Entregador / Runner de Praia unificado ao Design System
/// "Brisa Minimalista — Sage & Apricot" (Tela 05 `Order Details`).
class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({
    super.key,
    required this.authRepository,
    required this.orderRepository,
    required this.locationService,
  });

  final AuthRepository authRepository;
  final OrderRepository orderRepository;
  final LocationService locationService;

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  static const List<String> _quickCourierMessages = [
    'Estou descendo para a faixa de areia!',
    'Ative o Sinalizador Laranja no celular para eu te ver',
    'Estou próximo ao ponto de referência informado',
  ];

  List<Order> _available = const [];
  List<Order> _active = const [];
  bool _loading = true;
  String? _error;
  double? _courierLat;
  double? _courierLng;
  Timer? _liveTrackingTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _startPeriodicLiveTracking();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (_available.isNotEmpty || _active.isNotEmpty)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _liveTrackingTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicLiveTracking() {
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_active.isNotEmpty && !_loading) {
        _syncCourierGpsToActiveOrders(silent: true);
      }
    });
  }

  Future<void> _syncCourierGpsToActiveOrders({bool silent = false}) async {
    try {
      final pos = await widget.locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _courierLat = pos.latitude;
        _courierLng = pos.longitude;
      });
      for (final order in _active) {
        if (order.status == OrderStatus.aCaminho ||
            order.status == OrderStatus.chegouNoLocal) {
          await widget.orderRepository.updateCourierLocation(
            orderId: order.id,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        }
      }
      if (!silent) {
        await _refresh();
      }
    } catch (error) {
      if (!silent && mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.orderRepository.fetchAvailableOrders(),
        widget.orderRepository.fetchActiveCourierOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _available = results[0];
        _active = results[1];
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(Order order) async {
    await _runAction(() => widget.orderRepository.updateStatus(
          order.id,
          OrderStatus.aCaminho,
        ));
    await _syncCourierGpsToActiveOrders(silent: true);
  }

  Future<void> _markArrived(Order order) async {
    await _runAction(() => widget.orderRepository.updateStatus(
          order.id,
          OrderStatus.chegouNoLocal,
        ));
  }

  Future<void> _sendQuickMessage(Order order, String text) async {
    await _runAction(() => widget.orderRepository.sendOrderMessage(
          orderId: order.id,
          texto: text,
        ));
  }

  Future<void> _confirmDelivery(Order order) async {
    try {
      final courierId = order.courierId;
      if (courierId == null || courierId.isEmpty) {
        throw const FormatException(
          'O pedido não está associado a um entregador autenticado.',
        );
      }
      final position = await widget.locationService.getCurrentPosition();
      await _runAction(() => widget.orderRepository.confirmDelivery(
            orderId: order.id,
            courierId: courierId,
            latitude: position.latitude,
            longitude: position.longitude,
          ));
    } on LocationServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _runAction(Future<Order> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await widget.authRepository.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Entregas na Praia'),
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
            ),
            IconButton(
              tooltip: 'Sair',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: AppColors.ink700),
            ),
          ],
        ),
        body: _loading && _available.isEmpty && _active.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.sage500),
              )
            : RefreshIndicator(
                color: AppColors.sage500,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.danger500.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'MINHAS ENTREGAS EM ROTA',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_active.isEmpty)
                      _buildEmptyCard('Você não tem entregas em rota.')
                    else
                      ..._active.map(_buildActiveOrder),
                    const SizedBox(height: 22),
                    const Text(
                      'PEDIDOS PRONTOS NOS QUIOSQUES',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_available.isEmpty)
                      _buildEmptyCard('Nenhum pedido disponível no momento.')
                    else
                      ..._available.map(_buildAvailableOrder),
                  ],
                ),
              ),
      );

  Widget _buildEmptyCard(String message) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.ink500, fontSize: 13.5),
        ),
      );

  Widget _buildAvailableOrder(Order order) {
    final isReadyAtRestaurant = order.status == OrderStatus.prontoEntrega ||
        order.status == OrderStatus.aCaminho;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: order.isDelayed()
              ? AppColors.danger500.withValues(alpha: 0.6)
              : isReadyAtRestaurant
                  ? AppColors.sage600
                  : AppColors.line,
          width: isReadyAtRestaurant || order.isDelayed() ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'CÓDIGO DO PEDIDO #${order.codigoCurtoPedido}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTimerBadge(order),
                ],
              ),
              Text(
                'R\$ ${order.valorTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.apricot400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isReadyAtRestaurant
                  ? AppColors.sage100
                  : AppColors.apricot100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isReadyAtRestaurant
                      ? Icons.check_circle_outline_rounded
                      : Icons.restaurant_rounded,
                  size: 16,
                  color: isReadyAtRestaurant
                      ? AppColors.sage700
                      : AppColors.apricot700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.status == OrderStatus.aCaminho
                        ? 'Liberado pelo restaurante — confirmar início da entrega'
                        : isReadyAtRestaurant
                            ? 'Pedido pronto no restaurante — retirar para entrega'
                            : order.status.courierLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isReadyAtRestaurant
                          ? AppColors.sage700
                          : AppColors.apricot700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (order.isDelayed()) ...[
            const SizedBox(height: 10),
            _buildDelayedAlertBanner(order),
          ],
          const SizedBox(height: 10),
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Destino na Faixa de Areia',
            value: _locationSummary(order),
          ),
          if (order.localizacao != null) ...[
            const SizedBox(height: 12),
            _buildDestinationMap(order),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _loading ? null : () => _accept(order),
            child: Text(
              isReadyAtRestaurant
                  ? 'RETIRAR NO RESTAURANTE E INICIAR ENTREGA'
                  : 'ACEITAR ENTREGA',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrder(Order order) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: order.isDelayed()
                ? AppColors.danger500.withValues(alpha: 0.6)
                : AppColors.line,
            width: order.isDelayed() ? 1.5 : 1.0,
          ),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'CÓDIGO DO PEDIDO #${order.codigoCurtoPedido}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTimerBadge(order),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sage100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.courierLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sage700,
                    ),
                  ),
                ),
              ],
            ),
            if (order.isDelayed()) ...[
              const SizedBox(height: 10),
              _buildDelayedAlertBanner(order),
            ],
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.pin_drop_outlined,
              label: 'Ponto de Encontro',
              value: _locationSummary(order),
            ),
            BeachRadarWidget(
              order: order,
              courierLatitude: _courierLat,
              courierLongitude: _courierLng,
              onUpdateGps: () => _syncCourierGpsToActiveOrders(silent: false),
            ),
            if (order.localizacao != null) _buildDestinationMap(order),
            const SizedBox(height: 12),
            _buildQuickContactSection(order),
            const SizedBox(height: 14),
            if (order.status == OrderStatus.aCaminho)
              OutlinedButton(
                onPressed: _loading ? null : () => _markArrived(order),
                child: const Text('CHEGUEI NO GUARDA-SOL'),
              )
            else
              FilledButton(
                onPressed: _loading ? null : () => _confirmDelivery(order),
                child: const Text('CONFIRMAR ENTREGA'),
              ),
          ],
        ),
      );

  Widget _buildTimerBadge(Order order) {
    final delayed = order.isDelayed();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: delayed ? const Color(0xFFFFE4E6) : AppColors.sage100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 13,
            color: delayed ? AppColors.danger500 : AppColors.sage700,
          ),
          const SizedBox(width: 4),
          Text(
            order.formatElapsed(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: delayed ? AppColors.danger500 : AppColors.sage700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayedAlertBanner(Order order) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.danger500.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pedido em atraso (${order.formatElapsed()} decorridos) — passou de 28 min! Priorize esta entrega.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.placeholder,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: AppColors.ink700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickContactSection(Order order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVISOS RÁPIDOS PARA O CLIENTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.ink500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickCourierMessages
                .map(
                  (msg) => ActionChip(
                    avatar: const Icon(
                      Icons.send_rounded,
                      size: 13,
                      color: AppColors.sage600,
                    ),
                    label: Text(msg, style: const TextStyle(fontSize: 11)),
                    onPressed: _loading
                        ? null
                        : () => _sendQuickMessage(order, msg),
                  ),
                )
                .toList(growable: false),
          ),
          if (order.mensagens.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.mensagens.reversed
                    .take(3)
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${m.senderRole == 'COURIER' ? 'Você' : 'Cliente'}: ${m.texto}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink700,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      );

  Widget _buildDestinationMap(Order order) {
    final location = order.localizacao!;
    final destination = LatLng(location.latitude, location.longitude);
    final cLat = _courierLat ?? order.localizacaoEntregador?.latitude;
    final cLng = _courierLng ?? order.localizacaoEntregador?.longitude;
    final courierLatLng =
        (cLat != null && cLng != null) ? LatLng(cLat, cLng) : null;

    if (!GoogleMapsChecker.isReady) {
      return _buildMapFallback(order, location, courierLatLng);
    }

    final markers = <Marker>{
      Marker(
        markerId: MarkerId('destino-${order.id}'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: location.descricaoLocal.isEmpty
              ? 'Local de entrega'
              : location.descricaoLocal,
        ),
      ),
      if (courierLatLng != null)
        Marker(
          markerId: MarkerId('courier-${order.id}'),
          position: courierLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueCyan,
          ),
          infoWindow: const InfoWindow(title: 'Sua posição na areia'),
        ),
    };

    final polylines = <Polyline>{
      if (courierLatLng != null)
        Polyline(
          polylineId: PolylineId('radar-line-${order.id}'),
          points: [courierLatLng, destination],
          color: AppColors.sage500,
          width: 4,
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
        ),
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 185,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: destination, zoom: 16),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildMapFallback(
    Order order,
    OrderLocation location,
    LatLng? courierLatLng,
  ) {
    double? distance;
    if (courierLatLng != null) {
      distance = distanceMeters(
        GeoPoint(
          latitude: courierLatLng.latitude,
          longitude: courierLatLng.longitude,
        ),
        GeoPoint(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.apricot100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.beach_access_rounded,
                  color: AppColors.apricot600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destino na Faixa de Areia',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink800,
                      ),
                    ),
                    Text(
                      location.descricaoLocal.isEmpty
                          ? 'Santos - SP'
                          : location.descricaoLocal,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: distance <= 60
                        ? AppColors.sage100
                        : AppColors.sand200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(0)}m',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: distance <= 60
                          ? AppColors.sage700
                          : AppColors.ink700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.gps_fixed_rounded,
                  size: 14,
                  color: AppColors.sage700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.ink700,
                    ),
                  ),
                ),
                const Text(
                  'Orla Santos',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _locationSummary(Order order) {
    final location = order.localizacao;
    if (location == null) return 'Localização indisponível';
    final description = location.descricaoLocal.isEmpty
        ? 'Ponto de entrega'
        : location.descricaoLocal;
    return '$description (${location.latitude.toStringAsFixed(4)}, '
        '${location.longitude.toStringAsFixed(4)})';
  }
}
