package com.penaareia.controller;

import com.penaareia.dto.OrderResponse;
import com.penaareia.dto.OrderTrackingDtos.PixWebhookRequest;
import com.penaareia.service.ForbiddenException;
import com.penaareia.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/webhooks/pix")
@Tag(name = "Webhooks Pix", description = "Recebimento de notificacoes de pagamento Pix")
public class PixWebhookController {

    private final OrderService orderService;
    private final String expectedToken;

    public PixWebhookController(OrderService orderService,
                                @Value("${app.pix.webhook-token:}") String expectedToken) {
        this.orderService = orderService;
        this.expectedToken = expectedToken == null ? "" : expectedToken.trim();
    }

    @PostMapping
    @Operation(summary = "Confirma o pagamento Pix de um pedido via webhook")
    public OrderResponse receberConfirmacao(
            @RequestHeader(value = "X-Pix-Webhook-Token", required = false) String token,
            @Valid @RequestBody PixWebhookRequest request) {
        if (!expectedToken.isEmpty() && !expectedToken.equals(token)) {
            throw new ForbiddenException("Token de webhook Pix inválido.");
        }
        return OrderResponse.fromEntity(orderService.confirmarPagamentoPixWebhook(request));
    }
}

