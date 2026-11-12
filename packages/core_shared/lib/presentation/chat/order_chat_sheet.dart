import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/http/api_exception.dart';
import '../../data/repositories/order_repository.dart';
import '../../design_system/app_colors.dart';
import '../../domain/models/order.dart';

/// BottomSheet de chat em tempo real entre Cliente e Entregador durante a entrega na praia.
///
/// Segue o Design System "Brisa Minimalista — Sage & Apricot":
/// - Ativo exclusivamente em `OrderStatus.prontoEntrega`, `OrderStatus.aCaminho` e `OrderStatus.chegouNoLocal`.
/// - Ao transicionar para `OrderStatus.entregue`, `OrderStatus.cancelado` ou `OrderStatus.naoEncontrado`,
///   a sessão expira e o envio de novas mensagens é bloqueado.
class OrderChatBottomSheet extends StatefulWidget {
  const OrderChatBottomSheet({
    super.key,
    required this.order,
    required this.orderRepository,
    required this.currentUserRole,
    this.currentUserId,
    this.onOrderUpdated,
  });

  final Order order;
  final OrderRepository orderRepository;

  /// Papel do usuário logado nesta tela: `'CLIENT'` ou `'COURIER'`.
  final String currentUserRole;
  final String? currentUserId;
  final ValueChanged<Order>? onOrderUpdated;

  static Future<void> show(
    BuildContext context, {
    required Order order,
    required OrderRepository orderRepository,
    required String currentUserRole,
    String? currentUserId,
    ValueChanged<Order>? onOrderUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderChatBottomSheet(
        order: order,
        orderRepository: orderRepository,
        currentUserRole: currentUserRole,
        currentUserId: currentUserId,
        onOrderUpdated: onOrderUpdated,
      ),
    );
  }

  @override
  State<OrderChatBottomSheet> createState() => _OrderChatBottomSheetState();
}

class _OrderChatBottomSheetState extends State<OrderChatBottomSheet> {
  late Order _order;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollOrder();
    });
  }

  Future<void> _pollOrder() async {
    if (!mounted || _sending) return;
    try {
      final updated = await widget.orderRepository.fetchOrderById(_order.id);
      if (!mounted) return;
      final msgChanged = updated.mensagens.length != _order.mensagens.length;
      final statusChanged = updated.status != _order.status;
      setState(() {
        _order = updated;
      });
      if (msgChanged || statusChanged) {
        widget.onOrderUpdated?.call(updated);
        if (msgChanged) {
          _scrollToBottom();
        }
      }
    } catch (_) {
      // Polling silencioso de background
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending || !_order.isChatActive) return;

    setState(() {
      _sending = true;
      _sendError = null;
    });

    try {
      final updated = await widget.orderRepository.sendOrderMessage(
        orderId: _order.id,
        texto: trimmed,
      );
      _textController.clear();
      if (mounted) {
        setState(() {
          _order = updated;
        });
        widget.onOrderUpdated?.call(updated);
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _sendError = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendError = 'Erro ao enviar mensagem: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  List<String> get _quickChips {
    final role = widget.currentUserRole.toUpperCase();
    if (role == 'COURIER') {
      return const [
        'Estou a caminho da sua barraca! 🏖️',
        'Cheguei no ponto indicado!',
        'Qual a cor do seu guarda-sol?',
        'Estou próximo ao canal',
      ];
    }
    return const [
      'Estou de guarda-sol azul! 🏖️',
      'Estou próximo ao canal',
      'Acabei de ligar o Farol Visual 🚨',
      'Pode vir, estou aguardando',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      margin: EdgeInsets.only(bottom: viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.sand200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat do Pedido ${_order.codigoFormatado}',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ponto de entrega: ${_order.descricaoLocal.isEmpty ? "Praia de Santos" : _order.descricaoLocal}',
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
                _buildStatusChip(),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Fechar chat',
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink700),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.line),

          // Status Banner (Ativo vs Expirado)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _buildLifecycleBanner(),
          ),

          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.danger500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _sendError!,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.danger500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Message history
          Expanded(
            child: _order.mensagens.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: _order.mensagens.length,
                    itemBuilder: (context, index) {
                      final msg = _order.mensagens[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // Quick chips
          if (_order.isChatActive)
            Container(
              height: 42,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chipText = _quickChips[index];
                  return ActionChip(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.sage300),
                    label: Text(
                      chipText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.sage700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _sending ? null : () => _sendMessage(chipText),
                  );
                },
              ),
            ),

          // Input field and send button
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final label = _order.status.courierLabel;
    final isSage = _order.isChatActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSage ? AppColors.sage100 : AppColors.placeholder,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSage ? AppColors.sage700 : AppColors.ink700,
        ),
      ),
    );
  }

  Widget _buildLifecycleBanner() {
    if (_order.isChatActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sage100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sage300),
        ),
        child: const Row(
          children: [
            Text('●', style: TextStyle(color: AppColors.sage700, fontSize: 13)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '● Chat em tempo real ativo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sage700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_order.isChatExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.apricot100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.apricot400.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Text('🔒', style: TextStyle(fontSize: 13)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '🔒 Sessão de chat expirada. O pedido foi finalizado.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.ink500),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chat liberado quando o pedido estiver pronto ou a caminho.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sage100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 28,
                  color: AppColors.sage600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nenhuma mensagem ainda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Envie uma mensagem rápida ou selecione um aviso para combinar a entrega na areia.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.ink500),
              ),
            ],
          ),
        ),
      );

  Widget _buildMessageBubble(OrderMessage msg) {
    final isMe = msg.senderRole.toUpperCase() ==
        widget.currentUserRole.toUpperCase();
    final senderLabel = isMe
        ? 'Você'
        : (msg.senderRole.toUpperCase() == 'COURIER'
            ? 'Entregador'
            : 'Cliente');

    final timeFormatted = msg.enviadoEm != null
        ? '${msg.enviadoEm!.hour.toString().padLeft(2, '0')}:${msg.enviadoEm!.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.sage500 : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white70 : AppColors.ink500,
                  ),
                ),
                if (timeFormatted.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    timeFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white60 : AppColors.ink400,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              msg.texto,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isExpired = _order.isChatExpired;
    final canSend = _order.isChatActive && !_sending;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: canSend,
                textInputAction: TextInputAction.send,
                onSubmitted: canSend ? _sendMessage : null,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: isExpired
                      ? 'Chat encerrado'
                      : canSend
                          ? 'Mensagem sobre a entrega...'
                          : 'Chat temporariamente indisponível',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink400,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: canSend
                      ? AppColors.background
                      : AppColors.placeholder.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.sage500,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColors.line.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: canSend ? AppColors.sage500 : AppColors.placeholder,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Enviar mensagem',
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                onPressed: canSend
                    ? () => _sendMessage(_textController.text)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
