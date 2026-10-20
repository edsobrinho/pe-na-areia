package com.penaareia.service;

import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.Order;
import com.penaareia.model.ReferencePoint;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.OrderRepository;
import com.penaareia.repository.ReferencePointRepository;
import com.penaareia.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private static final double MAX_DISTANCE_TO_REFERENCE_METERS = 500.0;

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final KioskRepository kioskRepository;
    private final ReferencePointRepository referencePointRepository;

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

        Map<String, Kiosk.MenuItem> cardapioPorId = (kiosk.getCardapio() == null ? List.<Kiosk.MenuItem>of()
                : kiosk.getCardapio()).stream()
                .collect(Collectors.toMap(Kiosk.MenuItem::getId, item -> item, (a, b) -> a));

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
                    return new Order.OrderItem(
                            menuItem.getId(),
                            menuItem.getNome(),
                            quantidade,
                            menuItem.getPreco()
                    );
                })
                .toList();

        BigDecimal valorTotal = itens.stream()
                .map(item -> item.getPrecoUnitario().multiply(BigDecimal.valueOf(item.getQuantidade())))
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);

        Order order = new Order();
        order.setUserId(usuario.getId());
        order.setKioskId(kiosk.getId());
        order.setItens(itens);
        order.setValorTotal(valorTotal);
        order.setFormaPagamento(request.getFormaPagamento());
        order.setEmbalagemSustentavel(request.isEmbalagemSustentavel());

        // GeoJsonPoint espera (longitude, latitude), nessa ordem
        order.setPinCliente(new GeoJsonPoint(
                request.getPinCliente().getLongitude(),
                request.getPinCliente().getLatitude()));
        order.setPontoReferenciaId(posto.getId());
        order.setDescricaoLocal(request.getDescricaoLocal());
        order.setFotoLocalUrl(request.getFotoLocalUrl());
        order.transitionTo(com.penaareia.model.OrderStatus.PAGO);
        order.transitionTo(com.penaareia.model.OrderStatus.EM_PREPARO);

        return orderRepository.save(order);
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
