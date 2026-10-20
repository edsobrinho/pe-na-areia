package com.penaareia.dto;

import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.model.PaymentMethod;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {

    private String id;
    private String userId;
    private String kioskId;
    /** Nulo ate um entregador aceitar o pedido */
    private String courierId;
    private List<Order.OrderItem> itens;
    private BigDecimal valorTotal;
    private boolean embalagemSustentavel;
    private PaymentMethod formaPagamento;
    private boolean pago;
    /** Pin do cliente em formato GeoJSON: {"type":"Point","coordinates":[longitude,latitude]} */
    private GeoJsonPoint pinCliente;
    private String pontoReferenciaId;
    private String descricaoLocal;
    private String fotoLocalUrl;
    private OrderStatus status;
    private Order.StatusTimeline timeline;

    public static OrderResponse fromEntity(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getUserId(),
                order.getKioskId(),
                order.getCourierId(),
                order.getItens(),
                order.getValorTotal(),
                order.isEmbalagemSustentavel(),
                order.getFormaPagamento(),
                order.isPago(),
                order.getPinCliente(),
                order.getPontoReferenciaId(),
                order.getDescricaoLocal(),
                order.getFotoLocalUrl(),
                order.getStatus(),
                order.getTimeline()
        );
    }
}
