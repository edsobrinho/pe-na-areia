package com.penaareia.service;

import com.penaareia.dto.ConfirmDeliveryRequest;
import com.penaareia.model.Courier;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Set;
import java.util.Collection;

@Service
public class OrderWorkflowService {

    private static final Map<OrderStatus, Set<OrderStatus>> ALLOWED_TRANSITIONS = Map.of(
            OrderStatus.CRIADO, Set.of(OrderStatus.PAGO, OrderStatus.CANCELADO),
            OrderStatus.PAGO, Set.of(OrderStatus.EM_PREPARO, OrderStatus.CANCELADO),
            OrderStatus.EM_PREPARO, Set.of(OrderStatus.A_CAMINHO, OrderStatus.CANCELADO),
            OrderStatus.A_CAMINHO, Set.of(OrderStatus.CHEGOU_NO_LOCAL),
            OrderStatus.CHEGOU_NO_LOCAL, Set.of(),
            OrderStatus.ENTREGUE, Set.of(),
            OrderStatus.CANCELADO, Set.of()
    );

    private final OrderRepository orderRepository;
    private final CourierRepository courierRepository;
    private final double deliveryRadiusMeters;

    public OrderWorkflowService(OrderRepository orderRepository,
                                CourierRepository courierRepository,
                                @Value("${app.delivery.confirmation-radius-meters:60}") double deliveryRadiusMeters) {
        this.orderRepository = orderRepository;
        this.courierRepository = courierRepository;
        this.deliveryRadiusMeters = deliveryRadiusMeters;
    }

    public Order atualizarStatus(String orderId,
                                 OrderStatus newStatus,
                                 String callerId,
                                 Collection<? extends GrantedAuthority> authorities) {
        Order order = findOrder(orderId);
        if (!ALLOWED_TRANSITIONS.getOrDefault(order.getStatus(), Set.of()).contains(newStatus)) {
            throw new BusinessRuleException(
                    "Transição inválida: " + order.getStatus() + " -> " + newStatus);
        }
        boolean courierRole = hasRole(authorities, "ROLE_COURIER");
        boolean clientRole = hasRole(authorities, "ROLE_CLIENT");

        if (newStatus == OrderStatus.A_CAMINHO || newStatus == OrderStatus.CHEGOU_NO_LOCAL) {
            if (!courierRole) {
                throw new BusinessRuleException("Somente um entregador pode iniciar a entrega.");
            }
            if (order.getCourierId() != null && !order.getCourierId().equals(callerId)) {
                throw new BusinessRuleException("Este pedido já foi aceito por outro entregador.");
            }
            if (newStatus == OrderStatus.A_CAMINHO) {
                Courier courier = courierRepository.findById(callerId)
                        .orElseThrow(() -> new ResourceNotFoundException(
                                "Entregador não encontrado: " + callerId));
                if (courier.getStatus() != Courier.CourierStatus.DISPONIVEL) {
                    throw new BusinessRuleException(
                            "O entregador precisa estar disponível para aceitar pedidos.");
                }
                order.setCourierId(callerId);
                courier.setStatus(Courier.CourierStatus.EM_ROTA);
                courierRepository.save(courier);
            } else if (!callerId.equals(order.getCourierId())) {
                throw new BusinessRuleException("Este pedido não pertence a este entregador.");
            }
        } else {
            if (!clientRole || !order.getUserId().equals(callerId)) {
                throw new BusinessRuleException("Somente o cliente deste pedido pode alterar este status.");
            }
            if (newStatus == OrderStatus.ENTREGUE) {
                throw new BusinessRuleException("A entrega deve ser confirmada com geolocalização.");
            }
        }

        order.transitionTo(newStatus);
        return orderRepository.save(order);
    }

    public Order confirmarEntrega(String orderId, ConfirmDeliveryRequest request, String courierId) {
        if (!courierId.equals(request.courierId())) {
            throw new BusinessRuleException("O entregador informado não corresponde ao usuário autenticado.");
        }
        Order order = findOrder(orderId);
        if (order.getStatus() != OrderStatus.A_CAMINHO
                && order.getStatus() != OrderStatus.CHEGOU_NO_LOCAL) {
            throw new BusinessRuleException("Só é possível confirmar pedidos a caminho.");
        }
        if (!courierId.equals(order.getCourierId())) {
            throw new BusinessRuleException("Este pedido não pertence a este entregador.");
        }

        Courier courier = courierRepository.findById(courierId)
                .orElseThrow(() -> new ResourceNotFoundException("Entregador não encontrado: " + courierId));
        ConfirmDeliveryRequest.CourierLocation location = request.courierLocation();
        double distance = distanceMeters(
                order.getPinCliente().getY(), order.getPinCliente().getX(),
                location.lat(), location.lng());
        if (distance > deliveryRadiusMeters) {
            throw new BusinessRuleException("Aproxime-se do pin do cliente para confirmar a entrega (máximo "
                    + Math.round(deliveryRadiusMeters) + " m).");
        }

        courier.setLocalizacaoAtual(new org.springframework.data.mongodb.core.geo.GeoJsonPoint(
                location.lng(), location.lat()));
        courier.setStatus(Courier.CourierStatus.DISPONIVEL);
        courierRepository.save(courier);
        order.transitionTo(OrderStatus.ENTREGUE);
        return orderRepository.save(order);
    }

    public java.util.List<Order> listarDisponiveis(Pageable pageable) {
        return orderRepository.findByStatus(OrderStatus.EM_PREPARO, pageable);
    }

    public java.util.List<Order> listarEmRota(String courierId, Pageable pageable) {
        return orderRepository.findByCourierIdAndStatusIn(
                courierId, Set.of(OrderStatus.A_CAMINHO, OrderStatus.CHEGOU_NO_LOCAL), pageable);
    }

    private Order findOrder(String orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido não encontrado: " + orderId));
    }

    private static boolean hasRole(Collection<? extends GrantedAuthority> authorities, String role) {
        return authorities.stream().anyMatch(authority -> role.equals(authority.getAuthority()));
    }

    private static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
        double earthRadiusMeters = 6_371_000;
        double latDelta = Math.toRadians(lat2 - lat1);
        double lngDelta = Math.toRadians(lng2 - lng1);
        double a = Math.sin(latDelta / 2) * Math.sin(latDelta / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lngDelta / 2) * Math.sin(lngDelta / 2);
        return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
