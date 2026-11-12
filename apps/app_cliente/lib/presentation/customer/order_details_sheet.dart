import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_shared/core_shared.dart';

/// Modal com os detalhes completos do pedido para o cliente,
/// destacando o Código de Entrega de 4 dígitos numéricos para falar ao entregador.
class OrderDetailsSheet extends StatelessWidget {
  const OrderDetailsSheet({
    super.key,
    required this.order,
    this.onReviewTap,
  });

  final Order order;
  final VoidCallback? onReviewTap;

  static Future<void> show(
    BuildContext context, {
    required Order order,
    VoidCallback? onReviewTap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDetailsSheet(
        order: order,
        onReviewTap: onReviewTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = order.codigoEntrega ?? '';
    final hasCode = code.trim().isNotEmpty;
    final isDelivered = order.status == OrderStatus.entregue;
    final review = order.avaliacao;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido ${order.codigoFormatado}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tempo decorrido: ${order.formatElapsed()} · ${order.status.customerLabel}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: order.isDelayed() ? FontWeight.w700 : FontWeight.w500,
                          color: order.isDelayed() ? AppColors.danger500 : AppColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.status),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink700),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.sand200),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. CARD DE DESTAQUE: CÓDIGO DE ENTREGA (4 DÍGITOS)
                if (hasCode && !isDelivered) ...[
                  _buildDeliveryCodeCard(context, code),
                  const SizedBox(height: 20),
                ],

                // Se já foi entregue e avaliado, exibe a avaliação
                if (isDelivered && review != null) ...[
                  _buildReviewDisplayCard(review),
                  const SizedBox(height: 20),
                ] else if (isDelivered && onReviewTap != null) ...[
                  _buildPendingReviewBanner(onReviewTap!),
                  const SizedBox(height: 20),
                ],

                // 2. ITENS DO PEDIDO
                _buildSectionTitle(Icons.receipt_long_rounded, 'Itens do Pedido'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sand200),
                  ),
                  child: Column(
                    children: [
                      ...order.itens.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sage100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.quantidade}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.sage700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.ink900,
                                    ),
                                  ),
                                ),
                                Text(
                                  'R\$ ${(item.precoUnitario * item.quantidade).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.ink900,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 20, color: AppColors.sand200),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pago (Pix)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.ink900,
                            ),
                          ),
                          Text(
                            'R\$ ${order.valorTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: AppColors.sage700,
                            ),
                          ),
                        ],
                      ),
                      if (order.embalagemSustentavel) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.eco_rounded, size: 16, color: AppColors.sage600),
                            SizedBox(width: 6),
                            Text(
                              'Embalagem Sustentável ♻️',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sage600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. PONTO DE ENTREGA NA PRAIA
                _buildSectionTitle(Icons.beach_access_rounded, 'Ponto de Entrega na Areia'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sand200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.localizacao != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 18, color: AppColors.apricot500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${order.localizacao!.etiquetaAmigavel} (${order.localizacao!.latitude.toStringAsFixed(5)}, ${order.localizacao!.longitude.toStringAsFixed(5)})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.ink900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.descricaoLocal.isNotEmpty
                              ? order.descricaoLocal
                              : 'Sem observações do guarda-sol.',
                          style: const TextStyle(fontSize: 13.5, color: AppColors.ink700),
                        ),
                        if (order.localizacao?.referenciaBarraca != null &&
                            order.localizacao!.referenciaBarraca!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Barraca: ${order.localizacao!.referenciaBarraca}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.ink500),
                          ),
                        ],
                      ] else ...[
                        const Text(
                          'Ponto registrado no mapa de Santos.',
                          style: TextStyle(fontSize: 13, color: AppColors.ink700),
                        ),
                      ],
                    ],
                  ),
                ),

                // 4. ENTREGADOR (se atribuído)
                if (order.courierNome != null && order.courierNome!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle(Icons.delivery_dining_rounded, 'Entregador na Faixa de Areia'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sand200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.sage100,
                          child: Icon(
                            order.courierVeiculo == 'BICICLETA'
                                ? Icons.pedal_bike_rounded
                                : Icons.directions_walk_rounded,
                            color: AppColors.sage700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.courierNome!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.ink900,
                                ),
                              ),
                              Text(
                                order.courierVeiculo == 'A_PE'
                                    ? 'Entrega a pé na areia'
                                    : order.courierVeiculo == 'BICICLETA'
                                        ? 'Entrega de bicicleta na orla'
                                        : 'Courier da Orla',
                                style: const TextStyle(fontSize: 12, color: AppColors.ink500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCodeCard(BuildContext context, String code) {
    final digits = code.padLeft(4, '0').split('');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.apricot500.withValues(alpha: 0.15),
            AppColors.sand100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.apricot500.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.pin_outlined, size: 20, color: AppColors.apricot600),
              SizedBox(width: 8),
              Text(
                'PIN DE CONFIRMAÇÃO DE ENTREGA (4 DÍGITOS)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.apricot700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: digits.map((d) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 52,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.apricot500, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.apricot500.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                d,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.apricot700,
                ),
              ),
            )).toList(growable: false),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fale este código de 4 dígitos para o entregador na hora em que ele chegar ao seu guarda-sol.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Código de entrega $code copiado!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.apricot600),
            label: const Text(
              'COPIAR CÓDIGO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.apricot700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDisplayCard(OrderReview review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sage100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage600.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text(
                'Sua Avaliação do Pedido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppColors.sage700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Qualidade do Pedido:', style: TextStyle(fontSize: 13, color: AppColors.ink700)),
              _buildStarRow(review.notaPedido),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Atendimento da Entrega:', style: TextStyle(fontSize: 13, color: AppColors.ink700)),
              _buildStarRow(review.notaEntrega),
            ],
          ),
          if (review.comentario != null && review.comentario!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${review.comentario}"',
                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.ink700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRow(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildPendingReviewBanner(VoidCallback onReviewTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.apricot100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.apricot500),
      ),
      child: Row(
        children: [
          const Icon(Icons.rate_review_rounded, color: AppColors.apricot600, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pedido Entregue! ⭐',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.apricot700),
                ),
                Text(
                  'Avalie a comida e a entrega na areia.',
                  style: TextStyle(fontSize: 12, color: AppColors.ink700),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.apricot500,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: onReviewTap,
            child: const Text('AVALIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.sage700),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case OrderStatus.entregue:
        bg = AppColors.sage100;
        fg = AppColors.sage700;
        label = 'Entregue';
        break;
      case OrderStatus.aCaminho:
        bg = AppColors.apricot100;
        fg = AppColors.apricot600;
        label = 'A Caminho';
        break;
      case OrderStatus.chegouNoLocal:
        bg = AppColors.apricot500;
        fg = Colors.white;
        label = 'Na Barraca';
        break;
      case OrderStatus.emPreparo:
        bg = AppColors.sand200;
        fg = AppColors.ink900;
        label = 'Em Preparo';
        break;
      case OrderStatus.prontoEntrega:
        bg = AppColors.sage100;
        fg = AppColors.sage700;
        label = 'Retirando no Local';
        break;
      case OrderStatus.pago:
        bg = AppColors.sage100;
        fg = AppColors.sage700;
        label = 'Pago';
        break;
      case OrderStatus.criado:
        bg = AppColors.sand100;
        fg = AppColors.ink700;
        label = 'Criado';
        break;
      case OrderStatus.cancelado:
        bg = const Color(0xFFFFE4E6);
        fg = AppColors.danger500;
        label = 'Cancelado';
        break;
      case OrderStatus.naoEncontrado:
        bg = const Color(0xFFFFE4E6);
        fg = AppColors.danger500;
        label = 'Não Encontrado';
        break;
      case OrderStatus.desconhecido:
        bg = AppColors.sand100;
        fg = AppColors.ink700;
        label = 'Em andamento';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

