package com.penaareia.service;

import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.dto.OrderTrackingDtos.PixChargeResponse;
import com.penaareia.dto.OrderTrackingDtos.PixWebhookRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.model.PaymentMethod;
import com.penaareia.model.ReferencePoint;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.OrderRepository;
import com.penaareia.repository.ReferencePointRepository;
import com.penaareia.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class OrderService {

    private static final double MAX_DISTANCE_TO_REFERENCE_METERS = 500.0;

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final KioskRepository kioskRepository;
    private final ReferencePointRepository referencePointRepository;
    private final PartnershipPricingService pricingService;
    private final PartnershipService partnershipService;
    private final PixPaymentGateway pixPaymentGateway;
    private final OrderEventStreamService streamService;

    public OrderService(OrderRepository orderRepository,
                        UserRepository userRepository,
                        KioskRepository kioskRepository,
                        ReferencePointRepository referencePointRepository,
                        PartnershipPricingService pricingService,
                        PartnershipService partnershipService) {
        this(orderRepository, userRepository, kioskRepository, referencePointRepository,
                pricingService, partnershipService, new PixPaymentGateway(), new OrderEventStreamService());
    }

    @Autowired
    public OrderService(OrderRepository orderRepository,
                        UserRepository userRepository,
                        KioskRepository kioskRepository,
                        ReferencePointRepository referencePointRepository,
                        PartnershipPricingService pricingService,
                        PartnershipService partnershipService,
                        PixPaymentGateway pixPaymentGateway,
                        OrderEventStreamService streamService) {
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
        this.kioskRepository = kioskRepository;
        this.referencePointRepository = referencePointRepository;
        this.pricingService = pricingService;
        this.partnershipService = partnershipService;
        this.pixPaymentGateway = pixPaymentGateway != null ? pixPaymentGateway : new PixPaymentGateway();
        this.streamService = streamService != null ? streamService : new OrderEventStreamService();
    }

    /**
     * Cria um pedido com validacao em cascata:
     * usuario, quiosque e posto de referencia precisam existir e estar ativos;
     * cada item precisa existir no cardapio, estar disponivel e ter quantidade
     * maior que zero. O total e sempre calculado no servidor a partir dos
     * precos do cardapio - nunca confiando em valores enviados pelo cliente.
     */
    public Order criarPedido(CreateOrderRequest request) {
        User usuario = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado: " + request.getUserId()));
        if (!usuario.isAtivo()) {
            throw new BusinessRuleException("Usuario inativo: " + request.getUserId());
        }

        Kiosk kiosk = kioskRepository.findById(request.getKioskId())
                .orElseThrow(() -> new ResourceNotFoundException("Quiosque nao encontrado: " + request.getKioskId()));
        if (!kiosk.isAtivo()) {
            throw new BusinessRuleException("Quiosque inativo: " + request.getKioskId());
        }
        ReferencePoint posto = referencePointRepository.findById(request.getPontoReferenciaId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Posto de referencia nao encontrado: " + request.getPontoReferenciaId()));
        if (!posto.isAtivo()) {
            throw new BusinessRuleException("Posto de referencia inativo: " + request.getPontoReferenciaId());
        }
        if (request.getItens() == null || request.getItens().isEmpty()) {
            throw new InvalidRequestException("O pedido precisa ter ao menos um item");
        }
        if (request.getPinCliente() == null) {
            throw new InvalidRequestException("O pin do cliente e obrigatorio");
        }
        double distanceToReference = distanceMeters(
                request.getPinCliente().getLatitude(),
                request.getPinCliente().getLongitude(),
                posto.getLocalizacao().getY(),
                posto.getLocalizacao().getX());
        if (distanceToReference > MAX_DISTANCE_TO_REFERENCE_METERS) {
            throw new BusinessRuleException("O pin deve estar a no máximo 500 m do posto de referência.");
        }

        KioskPartnership configuration = partnershipService.activeConfiguration(
                kiosk.getId(), request.getPartnershipId());
        if (!partnershipService.isWithinAcceptanceWindow(configuration)) {
            throw new BusinessRuleException("A parceria está fora do horário de atendimento.");
        }

        Map<String, Kiosk.MenuItem> cardapioPorId = (kiosk.getCardapio() == null ? List.<Kiosk.MenuItem>of()
                : kiosk.getCardapio()).stream()
                .collect(Collectors.toMap(Kiosk.MenuItem::getId, item -> item, (a, b) -> a));

        long itemCount = request.getItens().stream()
                .filter(java.util.Objects::nonNull)
                .mapToLong(item -> item.getQuantidade() == null ? 0L : item.getQuantidade())
                .sum();
        if (itemCount > configuration.getMaxItemsPerOrder()) {
            throw new BusinessRuleException("O pedido excede o máximo de itens permitido nesta parceria.");
        }

        List<Order.OrderItem> itens = request.getItens().stream()
                .map(itemReq -> {
                    if (itemReq == null) {
                        throw new InvalidRequestException("O pedido nao pode conter itens nulos");
                    }
                    Integer quantidade = itemReq.getQuantidade();
                    if (quantidade == null || quantidade <= 0) {
                        throw new InvalidRequestException(
                                "Quantidade deve ser maior que zero para o item: " + itemReq.getMenuItemId());
                    }
                    Kiosk.MenuItem menuItem = cardapioPorId.get(itemReq.getMenuItemId());
                    if (menuItem == null) {
                        throw new ResourceNotFoundException(
                                "Item nao encontrado no cardapio: " + itemReq.getMenuItemId());
                    }
                    if (!menuItem.isDisponivel()) {
                        throw new BusinessRuleException(
                                "Item indisponivel no cardapio: " + itemReq.getMenuItemId());
                    }
                    if (!partnershipService.isEligible(configuration, menuItem)) {
                        throw new BusinessRuleException(
                                "Item não disponível nesta parceria: " + itemReq.getMenuItemId());
                    }
                    return new Order.OrderItem(
                            menuItem.getId(),
                            menuItem.getNome(),
                            quantidade,
                            PartnershipPricingService.money(menuItem.getPreco()),
                            menuItem.getCategory(),
                            menuItem.isReturnablePackaging()
                    );
                })
                .toList();

        BigDecimal subtotal = itens.stream()
                .map(item -> item.getPrecoUnitario().multiply(BigDecimal.valueOf(item.getQuantidade())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        subtotal = PartnershipPricingService.money(subtotal);
        Order.PricingSnapshot pricingSnapshot = pricingService.calculate(subtotal, configuration);
        if (pricingSnapshot.subtotal().compareTo(configuration.getMinimumOrder()) < 0) {
            throw new BusinessRuleException("O subtotal do pedido está abaixo do mínimo desta parceria.");
        }

        Order order = new Order();
        order.setUserId(usuario.getId());
        order.setKioskId(kiosk.getId());
        order.setPartnershipId(configuration.getPartnershipId());
        order.setItens(itens);
        order.setValorTotal(pricingSnapshot.customerTotal());
        order.setPricingSnapshot(pricingSnapshot);
        order.setFormaPagamento(request.getFormaPagamento());
        order.setEmbalagemSustentavel(request.isEmbalagemSustentavel());

        // GeoJsonPoint espera (longitude, latitude), nessa ordem
        order.setPinCliente(new GeoJsonPoint(
                request.getPinCliente().getLongitude(),
                request.getPinCliente().getLatitude()));
        order.setPontoReferenciaId(posto.getId());
        order.setDescricaoLocal(request.getDescricaoLocal());
        order.setFotoLocalUrl(request.getFotoLocalUrl());
        order.setReferenciaBarraca(request.getReferenciaBarraca());
        order.setComplementoLocal(request.getComplementoLocal());
        order.setFotoVisaoPostoUrl(request.getFotoVisaoPostoUrl());
        order.setFotoOutroReferencialUrl(request.getFotoOutroReferencialUrl());
        order.setContatoNome(request.getContatoNome() != null && !request.getContatoNome().isBlank()
                ? request.getContatoNome().trim()
                : usuario.getNome());
        order.setContatoTelefone(request.getContatoTelefone() != null && !request.getContatoTelefone().isBlank()
                ? request.getContatoTelefone().trim()
                : usuario.getTelefone());
        order.setEtiquetaLocal(request.getEtiquetaLocal());

        if (request.getFormaPagamento() == PaymentMethod.PIX) {
            PixPaymentGateway.PixCharge charge = pixPaymentGateway.gerarCobranca(order);
            order.setPixTxId(charge.txId());
            order.setPixCopiaECola(charge.copiaECola());
            order.setPixQrCodeBase64(charge.qrCodeBase64());
            order.setPixExpiracao(charge.expiracao());
        }

        order.transitionTo(OrderStatus.PAGO);
        order.transitionTo(OrderStatus.EM_PREPARO);

        return orderRepository.save(order);
    }

    public PixChargeResponse gerarCobrancaPix(String orderId, String callerId) {
        Order order = buscarPorId(orderId);
        if (!callerId.equals(order.getUserId())) {
            throw new BusinessRuleException("Somente o cliente deste pedido pode consultar a cobrança Pix.");
        }
        if (order.getPixCopiaECola() == null || order.getPixTxId() == null) {
            PixPaymentGateway.PixCharge charge = pixPaymentGateway.gerarCobranca(order);
            order.setPixTxId(charge.txId());
            order.setPixCopiaECola(charge.copiaECola());
            order.setPixQrCodeBase64(charge.qrCodeBase64());
            order.setPixExpiracao(charge.expiracao());
            order = orderRepository.save(order);
        }
        return new PixChargeResponse(
                order.getId(),
                order.getPixTxId(),
                order.getPixCopiaECola(),
                order.getPixQrCodeBase64(),
                order.getPixExpiracao(),
                order.isPago());
    }

    public Order confirmarPagamentoPixWebhook(PixWebhookRequest request) {
        Order order = null;
        if (request.orderId() != null && !request.orderId().isBlank()) {
            order = orderRepository.findById(request.orderId()).orElse(null);
        }
        if (order == null && request.txId() != null && !request.txId().isBlank()) {
            order = orderRepository.findByPixTxId(request.txId()).orElse(null);
        }
        if (order == null) {
            throw new ResourceNotFoundException("Pedido não encontrado para o txId informado: " + request.txId());
        }
        if (order.getStatus() == OrderStatus.CRIADO || !order.isPago()) {
            order.transitionTo(OrderStatus.PAGO);
            order.transitionTo(OrderStatus.EM_PREPARO);
            order = orderRepository.save(order);
            streamService.publish(order);
        }
        return order;
    }

    private static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
        double latDelta = Math.toRadians(lat2 - lat1);
        double lngDelta = Math.toRadians(lng2 - lng1);
        double a = Math.sin(latDelta / 2) * Math.sin(latDelta / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lngDelta / 2) * Math.sin(lngDelta / 2);
        return 6_371_000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    public Order buscarPorId(String id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido nao encontrado: " + id));
    }
}
