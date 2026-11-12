package com.penaareia.service;

import com.penaareia.dto.OrderResponse;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class OrderEventStreamService {

    private static final long SSE_TIMEOUT_MS = 10 * 60 * 1000L;
    private final Map<String, List<OrderSubscriber>> emittersByOrder = new ConcurrentHashMap<>();

    private record OrderSubscriber(SseEmitter emitter, boolean hidePin) {
    }

    public SseEmitter subscribe(Order initialOrder) {
        return subscribe(initialOrder, false);
    }

    public SseEmitter subscribe(Order initialOrder, boolean hidePin) {
        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);
        String orderId = initialOrder.getId();
        List<OrderSubscriber> list = emittersByOrder.computeIfAbsent(orderId, k -> new CopyOnWriteArrayList<>());
        OrderSubscriber subscriber = new OrderSubscriber(emitter, hidePin);
        list.add(subscriber);

        Runnable cleanup = () -> list.remove(subscriber);
        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(e -> cleanup.run());

        try {
            OrderResponse payload = hidePin && initialOrder.getStatus() != OrderStatus.ENTREGUE
                    ? OrderResponse.fromEntityForCourier(initialOrder, null)
                    : OrderResponse.fromEntity(initialOrder);
            emitter.send(SseEmitter.event()
                    .name("order-update")
                    .data(payload, MediaType.APPLICATION_JSON));
        } catch (IOException ignored) {
            cleanup.run();
        }
        return emitter;
    }

    public void publish(Order updatedOrder) {
        if (updatedOrder == null || updatedOrder.getId() == null) {
            return;
        }
        List<OrderSubscriber> list = emittersByOrder.get(updatedOrder.getId());
        if (list == null || list.isEmpty()) {
            return;
        }
        OrderResponse fullPayload = OrderResponse.fromEntity(updatedOrder);
        OrderResponse courierPayload = updatedOrder.getStatus() != OrderStatus.ENTREGUE
                ? OrderResponse.fromEntityForCourier(updatedOrder, null)
                : fullPayload;

        for (OrderSubscriber subscriber : list) {
            try {
                OrderResponse payload = subscriber.hidePin() ? courierPayload : fullPayload;
                subscriber.emitter().send(SseEmitter.event()
                        .name("order-update")
                        .data(payload, MediaType.APPLICATION_JSON));
            } catch (IOException e) {
                list.remove(subscriber);
            }
        }
    }
}
