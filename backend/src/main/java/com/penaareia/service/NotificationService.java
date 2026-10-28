package com.penaareia.service;

import com.penaareia.model.Order;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Slf4j
@Service
public class NotificationService {

    public record PushAlert(
            String orderId,
            String userId,
            String titulo,
            String mensagem,
            Instant disparadoEm
    ) {
    }

    private final List<PushAlert> historicoAlertas = new CopyOnWriteArrayList<>();

    public void notificarProximidadeAreia(Order order, double distanciaMetros) {
        String titulo = "Entregador na areia!";
        String mensagem = String.format(
                "🏖️ Seu entregador está na areia a %.0fm! Saia do mar e ative o Sinalizador.",
                Math.max(1.0, distanciaMetros));
        PushAlert alerta = new PushAlert(
                order.getId(),
                order.getUserId(),
                titulo,
                mensagem,
                Instant.now());
        historicoAlertas.add(alerta);
        log.info("Push Notification disparada para usuario={} pedido={}: {}",
                order.getUserId(), order.getId(), mensagem);
    }

    public List<PushAlert> listarAlertasPorPedido(String orderId) {
        return historicoAlertas.stream()
                .filter(alerta -> orderId.equals(alerta.orderId()))
                .toList();
    }
}

