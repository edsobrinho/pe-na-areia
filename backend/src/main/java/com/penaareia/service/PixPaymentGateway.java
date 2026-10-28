package com.penaareia.service;

import com.penaareia.model.Order;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;

@Service
public class PixPaymentGateway {

    private static final Duration EXPIRACAO_PADRAO = Duration.ofMinutes(10);

    public record PixCharge(
            String txId,
            String copiaECola,
            String qrCodeBase64,
            Instant expiracao
    ) {
    }

    public PixCharge gerarCobranca(Order order) {
        String rawId = order.getId() != null ? order.getId() : UUID.randomUUID().toString();
        String sanitizedId = rawId.replaceAll("[^a-zA-Z0-9]", "");
        if (sanitizedId.isEmpty()) {
            sanitizedId = "PENAAREIA";
        }
        String txId = "PNA" + (sanitizedId.length() > 20 ? sanitizedId.substring(0, 20) : sanitizedId).toUpperCase(Locale.ROOT);
        BigDecimal valor = order.getValorTotal() != null ? order.getValorTotal() : BigDecimal.ZERO;
        String valorStr = String.format(Locale.US, "%.2f", valor);

        String copiaECola = "00020126580014br.gov.bcb.pix0136penaareia-santos@pix.com.br"
                + "52040000530398654" + String.format(Locale.US, "%02d", valorStr.length()) + valorStr
                + "5802BR5913PE NA AREIA6006SANTOS62"
                + String.format(Locale.US, "%02d", txId.length() + 4) + "05"
                + String.format(Locale.US, "%02d", txId.length()) + txId + "6304ABCD";

        String svgQr = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 120 120\" width=\"200\" height=\"200\">"
                + "<rect width=\"120\" height=\"120\" fill=\"#ffffff\"/>"
                + "<rect x=\"10\" y=\"10\" width=\"30\" height=\"30\" fill=\"#000000\"/>"
                + "<rect x=\"80\" y=\"10\" width=\"30\" height=\"30\" fill=\"#000000\"/>"
                + "<rect x=\"10\" y=\"80\" width=\"30\" height=\"30\" fill=\"#000000\"/>"
                + "<rect x=\"48\" y=\"48\" width=\"24\" height=\"24\" fill=\"#FF7A3D\"/>"
                + "</svg>";
        String qrCodeBase64 = Base64.getEncoder().encodeToString(svgQr.getBytes(StandardCharsets.UTF_8));
        Instant expiracao = Instant.now().plus(EXPIRACAO_PADRAO);

        return new PixCharge(txId, copiaECola, qrCodeBase64, expiracao);
    }
}

