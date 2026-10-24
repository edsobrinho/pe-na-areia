package com.penaareia.dto;

import com.penaareia.model.Order;
import com.penaareia.service.InvalidRequestException;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.Base64;
import java.util.Optional;

public record OrderCursor(Instant createdAt, String orderId) {

    private static final int MAX_CURSOR_LENGTH = 512;

    public static Optional<OrderCursor> decode(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        if (value.length() > MAX_CURSOR_LENGTH) {
            throw new InvalidRequestException("Cursor de paginação inválido.");
        }

        try {
            String decoded = new String(Base64.getUrlDecoder().decode(value), StandardCharsets.UTF_8);
            int separator = decoded.indexOf('\n');
            if (separator <= 0 || separator == decoded.length() - 1) {
                throw new IllegalArgumentException("Cursor incompleto");
            }
            Instant createdAt = Instant.parse(decoded.substring(0, separator));
            String orderId = decoded.substring(separator + 1);
            return Optional.of(new OrderCursor(createdAt, orderId));
        } catch (IllegalArgumentException | DateTimeParseException exception) {
            throw new InvalidRequestException("Cursor de paginação inválido.");
        }
    }

    public static String encode(Order order) {
        if (order.getId() == null || order.getTimeline() == null
                || order.getTimeline().getCriadoEm() == null) {
            throw new IllegalStateException("Não é possível criar cursor para pedido sem id ou data de criação.");
        }
        String value = order.getTimeline().getCriadoEm() + "\n" + order.getId();
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(value.getBytes(StandardCharsets.UTF_8));
    }
}
