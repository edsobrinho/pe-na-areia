package com.penaareia.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public final class OrderTrackingDtos {

    private OrderTrackingDtos() {
    }

    public record CourierLocationUpdateRequest(
            @NotNull(message = "A latitude é obrigatória")
            @DecimalMin(value = "-90.0", message = "Latitude deve estar entre -90 e 90")
            @DecimalMax(value = "90.0", message = "Latitude deve estar entre -90 e 90")
            Double latitude,

            @NotNull(message = "A longitude é obrigatória")
            @DecimalMin(value = "-180.0", message = "Longitude deve estar entre -180 e 180")
            @DecimalMax(value = "180.0", message = "Longitude deve estar entre -180 e 180")
            Double longitude
    ) {
    }

    public record OrderMessageRequest(
            @NotBlank(message = "A mensagem não pode estar vazia")
            @Size(max = 200, message = "A mensagem deve ter no máximo 200 caracteres")
            String texto
    ) {
    }

    public record PixChargeResponse(
            String orderId,
            String pixTxId,
            String pixCopiaECola,
            String pixQrCodeBase64,
            Instant pixExpiracao,
            boolean pago
    ) {
    }

    public record PixWebhookRequest(
            @NotBlank(message = "O txId do Pix é obrigatório")
            String txId,
            String orderId,
            String status
    ) {
    }
}

