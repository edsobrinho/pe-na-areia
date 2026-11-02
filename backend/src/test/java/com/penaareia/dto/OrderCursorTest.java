package com.penaareia.dto;

import com.penaareia.model.Order;
import com.penaareia.service.InvalidRequestException;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class OrderCursorTest {

    @Test
    void encodesAndDecodesValidOrder() {
        Order order = new Order();
        order.setId("ord-123");
        order.getTimeline().setCriadoEm(Instant.parse("2026-10-31T12:00:00Z"));

        String encoded = OrderCursor.encode(order);
        assertThat(encoded).isNotBlank();

        Optional<OrderCursor> cursor = OrderCursor.decode(encoded);
        assertThat(cursor).isPresent();
        assertThat(cursor.get().orderId()).isEqualTo("ord-123");
        assertThat(cursor.get().createdAt()).isEqualTo(Instant.parse("2026-10-31T12:00:00Z"));
    }

    @Test
    void decodesEmptyOrBlankAsEmptyOptional() {
        assertThat(OrderCursor.decode(null)).isEmpty();
        assertThat(OrderCursor.decode("")).isEmpty();
        assertThat(OrderCursor.decode("   ")).isEmpty();
    }

    @Test
    void rejectsTooLongOrMalformedCursors() {
        assertThatThrownBy(() -> OrderCursor.decode("a".repeat(600)))
                .isInstanceOf(InvalidRequestException.class);

        assertThatThrownBy(() -> OrderCursor.decode("not-base-64!!!"))
                .isInstanceOf(InvalidRequestException.class);

        String noSeparator = Base64.getUrlEncoder().encodeToString("no-newline".getBytes(StandardCharsets.UTF_8));
        assertThatThrownBy(() -> OrderCursor.decode(noSeparator))
                .isInstanceOf(InvalidRequestException.class);

        String invalidDate = Base64.getUrlEncoder().encodeToString("not-a-date\nord-1".getBytes(StandardCharsets.UTF_8));
        assertThatThrownBy(() -> OrderCursor.decode(invalidDate))
                .isInstanceOf(InvalidRequestException.class);
    }

    @Test
    void encodeThrowsIfIdOrTimelineMissing() {
        Order order = new Order();
        assertThatThrownBy(() -> OrderCursor.encode(order))
                .isInstanceOf(IllegalStateException.class);
    }
}

