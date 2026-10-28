package com.penaareia.service;

import com.penaareia.dto.ConfirmDeliveryRequest;
import com.penaareia.dto.OrderCursor;
import com.penaareia.dto.OrderCursorSlice;
import com.penaareia.model.Courier;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.OrderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Service
public class OrderWorkflowService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final double PROXIMITY_ALERT_RADIUS_METERS = 60.0;
    private static final Sort ORDER_PAGE_SORT = Sort.by(
            Sort.Order.desc("timeline.criadoEm"),
            Sort.Order.desc("id"));

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
    private final MongoTemplate mongoTemplate;
    private final double deliveryRadiusMeters;
    private final NotificationService notificationService;
    private final OrderEventStreamService streamService;

    public OrderWorkflowService(OrderRepository orderRepository,
                                CourierRepository courierRepository,
                                MongoTemplate mongoTemplate,
                                double deliveryRadiusMeters) {
        this(orderRepository, courierRepository, mongoTemplate, deliveryRadiusMeters,
                new NotificationService(), new OrderEventStreamService());
    }

    @Autowired
    public OrderWorkflowService(OrderRepository orderRepository,
                                CourierRepository courierRepository,
                                MongoTemplate mongoTemplate,
                                @Value("${app.delivery.confirmation-radius-meters:60}") double deliveryRadiusMeters,
                                NotificationService notificationService,
                                OrderEventStreamService streamService) {
        this.orderRepository = orderRepository;
        this.courierRepository = courierRepository;
        this.mongoTemplate = mongoTemplate;
        this.deliveryRadiusMeters = deliveryRadiusMeters;
        this.notificationService = notificationService != null ? notificationService : new NotificationService();
        this.streamService = streamService != null ? streamService : new OrderEventStreamService();
    }

    @Transactional
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
                Instant now = Instant.now();
                Order claimedOrder = mongoTemplate.findAndModify(
                        Query.query(Criteria.where("id").is(orderId)
                                .and("status").is(OrderStatus.EM_PREPARO)
                                .and("courierId").is(null)),
                        new Update()
                                .set("courierId", callerId)
                                .set("status", OrderStatus.A_CAMINHO)
                                .set("timeline.aCaminhoEm", now),
                        FindAndModifyOptions.options().returnNew(true),
                        Order.class);
                if (claimedOrder == null) {
                    throw new BusinessRuleException(
                            "Este pedido já foi aceito por outro entregador.");
                }
                long courierUpdated = mongoTemplate.updateFirst(
                        Query.query(Criteria.where("id").is(callerId)
                                .and("status").is(Courier.CourierStatus.DISPONIVEL)),
                        new Update().set("status", Courier.CourierStatus.EM_ROTA),
                        Courier.class).getModifiedCount();
                if (courierUpdated != 1) {
                    courierRepository.findById(callerId)
                            .orElseThrow(() -> new ResourceNotFoundException(
                                    "Entregador não encontrado: " + callerId));
                    throw new BusinessRuleException(
                            "O entregador precisa estar disponível para aceitar pedidos.");
                }
                streamService.publish(claimedOrder);
                return claimedOrder;
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
        Order saved = orderRepository.save(order);
        streamService.publish(saved);
        return saved;
    }

    @Transactional
    public Order atualizarLocalizacaoEntregador(String orderId,
                                                double latitude,
                                                double longitude,
                                                String courierId) {
        Order order = findOrder(orderId);
        if (order.getStatus() != OrderStatus.A_CAMINHO
                && order.getStatus() != OrderStatus.CHEGOU_NO_LOCAL) {
            throw new BusinessRuleException(
                    "A localização em tempo real só pode ser enviada enquanto o pedido estiver a caminho.");
        }
        if (!courierId.equals(order.getCourierId())) {
            throw new BusinessRuleException("Este pedido não pertence a este entregador.");
        }

        GeoJsonPoint courierPoint = new GeoJsonPoint(longitude, latitude);
        order.setLocalizacaoEntregador(courierPoint);
        order.setAtualizadoEntregadorEm(Instant.now());

        if (order.getPinCliente() != null && !order.isAlertaProximidadeEnviado()) {
            double distance = distanceMeters(
                    order.getPinCliente().getY(),
                    order.getPinCliente().getX(),
                    latitude,
                    longitude);
            if (distance <= PROXIMITY_ALERT_RADIUS_METERS) {
                order.setAlertaProximidadeEnviado(true);
                notificationService.notificarProximidadeAreia(order, distance);
            }
        }

        Order saved = orderRepository.save(order);
        mongoTemplate.updateFirst(
                Query.query(Criteria.where("id").is(courierId)),
                new Update().set("localizacaoAtual", courierPoint),
                Courier.class);
        streamService.publish(saved);
        return saved;
    }

    @Transactional
    public Order enviarMensagemRapida(String orderId,
                                      String callerId,
                                      Collection<? extends GrantedAuthority> authorities,
                                      String texto) {
        Order order = findOrder(orderId);
        if (order.getStatus() != OrderStatus.A_CAMINHO
                && order.getStatus() != OrderStatus.CHEGOU_NO_LOCAL) {
            throw new BusinessRuleException(
                    "O canal de mensagens rápidas só fica disponível enquanto o entregador está a caminho.");
        }
        boolean isOrderClient = callerId.equals(order.getUserId());
        boolean isOrderCourier = callerId.equals(order.getCourierId());
        if (!isOrderClient && !isOrderCourier) {
            throw new BusinessRuleException("Você não participa desta entrega.");
        }

        String senderRole = isOrderCourier || hasRole(authorities, "ROLE_COURIER") ? "COURIER" : "CLIENT";
        if (order.getMensagens() == null) {
            order.setMensagens(new ArrayList<>());
        }
        order.getMensagens().add(new Order.OrderMessage(
                callerId,
                senderRole,
                texto.trim(),
                Instant.now()));

        Order saved = orderRepository.save(order);
        streamService.publish(saved);
        return saved;
    }

    public List<Order.OrderMessage> listarMensagens(String orderId, String callerId) {
        Order order = findOrder(orderId);
        if (!callerId.equals(order.getUserId()) && !callerId.equals(order.getCourierId())) {
            throw new BusinessRuleException("Você não tem acesso às mensagens deste pedido.");
        }
        return order.getMensagens() == null ? List.of() : List.copyOf(order.getMensagens());
    }

    @Transactional
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

        ConfirmDeliveryRequest.CourierLocation location = request.courierLocation();
        double distance = distanceMeters(
                order.getPinCliente().getY(), order.getPinCliente().getX(),
                location.lat(), location.lng());
        if (distance > deliveryRadiusMeters) {
            throw new BusinessRuleException("Aproxime-se do pin do cliente para confirmar a entrega (máximo "
                    + Math.round(deliveryRadiusMeters) + " m).");
        }

        Instant now = Instant.now();
        Order deliveredOrder = mongoTemplate.findAndModify(
                Query.query(Criteria.where("id").is(orderId)
                        .and("courierId").is(courierId)
                        .and("status").in(OrderStatus.A_CAMINHO, OrderStatus.CHEGOU_NO_LOCAL)),
                new Update()
                        .set("status", OrderStatus.ENTREGUE)
                        .set("timeline.entregueEm", now),
                FindAndModifyOptions.options().returnNew(true),
                Order.class);
        if (deliveredOrder == null) {
            throw new BusinessRuleException("Este pedido já foi confirmado ou não pertence a este entregador.");
        }
        long courierUpdated = mongoTemplate.updateFirst(
                Query.query(Criteria.where("id").is(courierId)
                        .and("status").is(Courier.CourierStatus.EM_ROTA)),
                new Update()
                        .set("localizacaoAtual", new GeoJsonPoint(location.lng(), location.lat()))
                        .set("status", Courier.CourierStatus.DISPONIVEL),
                Courier.class).getModifiedCount();
        if (courierUpdated != 1) {
            courierRepository.findById(courierId)
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Entregador não encontrado: " + courierId));
            throw new BusinessRuleException("O entregador não está em rota.");
        }
        streamService.publish(deliveredOrder);
        return deliveredOrder;
    }

    public OrderCursorSlice listarDisponiveis(int size, String cursorValue) {
        return listar(Query.query(Criteria.where("status").is(OrderStatus.EM_PREPARO)), size, cursorValue);
    }

    public OrderCursorSlice listarEmRota(String courierId, int size, String cursorValue) {
        Criteria criteria = new Criteria().andOperator(
                Criteria.where("courierId").is(courierId),
                Criteria.where("status").in(OrderStatus.A_CAMINHO, OrderStatus.CHEGOU_NO_LOCAL));
        return listar(Query.query(criteria), size, cursorValue);
    }

    private OrderCursorSlice listar(Query query, int size, String cursorValue) {
        if (size < 1 || size > MAX_PAGE_SIZE) {
            throw new InvalidRequestException("O tamanho da página deve estar entre 1 e " + MAX_PAGE_SIZE + ".");
        }
        Optional<OrderCursor> cursor = OrderCursor.decode(cursorValue);
        cursor.ifPresent(value -> query.addCriteria(new Criteria().orOperator(
                Criteria.where("timeline.criadoEm").lt(value.createdAt()),
                new Criteria().andOperator(
                        Criteria.where("timeline.criadoEm").is(value.createdAt()),
                        Criteria.where("id").lt(value.orderId())))));
        query.with(ORDER_PAGE_SORT).limit(size + 1);

        List<Order> orders = new ArrayList<>(mongoTemplate.find(query, Order.class));
        boolean hasNext = orders.size() > size;
        if (hasNext) {
            orders.remove(orders.size() - 1);
        }
        String nextCursor = hasNext ? OrderCursor.encode(orders.get(orders.size() - 1)) : null;
        return new OrderCursorSlice(orders, nextCursor);
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
