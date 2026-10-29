package com.penaareia.dto;

import com.penaareia.model.OrderStatus;
import jakarta.validation.constraints.NotNull;

public record StatusUpdateRequest(
        @NotNull OrderStatus status,
        String motivo
) {
    public StatusUpdateRequest(@NotNull OrderStatus status) {
        this(status, null);
    }
}
