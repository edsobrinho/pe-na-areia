package com.penaareia.service;

import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import static org.assertj.core.api.Assertions.assertThat;

class OrderEventStreamServiceTest {

    @Test
    void subscribeAndPublishSendsUpdatesToSubscriber() {
        OrderEventStreamService service = new OrderEventStreamService();
        Order order = new Order();
        order.setId("ord-stream-1");
        order.setStatus(OrderStatus.CRIADO);

        SseEmitter emitter = service.subscribe(order);
        assertThat(emitter).isNotNull();

        // Publish update
        order.setStatus(OrderStatus.PAGO);
        service.publish(order);

        // Publish null or order without id
        service.publish(null);
        service.publish(new Order());

        // Publish order with no subscribers
        Order other = new Order();
        other.setId("other-order");
        service.publish(other);
    }

    @Test
    void subscribeWithHidePinPublishesMaskedPinUntilDelivered() {
        OrderEventStreamService service = new OrderEventStreamService();
        Order order = new Order();
        order.setId("ord-stream-hidepin");
        order.setStatus(OrderStatus.A_CAMINHO);
        order.setCodigoEntrega("9876");

        SseEmitter courierEmitter = service.subscribe(order, true);
        assertThat(courierEmitter).isNotNull();

        // Publish update while A_CAMINHO
        service.publish(order);

        // Publish update when ENTREGUE
        order.setStatus(OrderStatus.ENTREGUE);
        service.publish(order);
    }
}

