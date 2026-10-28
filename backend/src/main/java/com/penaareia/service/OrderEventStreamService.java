package com.penaareia.service;

import com.penaareia.dto.OrderResponse;
import com.penaareia.model.Order;
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
    private final Map<String, List<SseEmitter>> emittersByOrder = new ConcurrentHashMap<>();

    public SseEmitter subscribe(Order initialOrder) {
        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);
        String orderId = initialOrder.getId();
        List<SseEmitter> list = emittersByOrder.computeIfAbsent(orderId, k -> new CopyOnWriteArrayList<>());
        list.add(emitter);

        Runnable cleanup = () -> list.remove(emitter);
        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(e -> cleanup.run());

        try {
            emitter.send(SseEmitter.event()
                    .name("order-update")
                    .data(OrderResponse.fromEntity(initialOrder), MediaType.APPLICATION_JSON));
        } catch (IOException ignored) {
            cleanup.run();
        }
        return emitter;
    }

    public void publish(Order updatedOrder) {
        if (updatedOrder == null || updatedOrder.getId() == null) {
            return;
        }
        List<SseEmitter> list = emittersByOrder.get(updatedOrder.getId());
        if (list == null || list.isEmpty()) {
            return;
        }
        OrderResponse payload = OrderResponse.fromEntity(updatedOrder);
        for (SseEmitter emitter : list) {
            try {
                emitter.send(SseEmitter.event()
                        .name("order-update")
                        .data(payload, MediaType.APPLICATION_JSON));
            } catch (IOException e) {
                list.remove(emitter);
            }
        }
    }
}

