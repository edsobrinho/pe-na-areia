package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "orders")
@CompoundIndexes({
        @CompoundIndex(name = "status_created_id_desc_idx",
                def = "{'status': 1, 'timeline.criadoEm': -1, '_id': -1}"),
        @CompoundIndex(name = "courier_status_created_id_desc_idx",
                def = "{'courierId': 1, 'status': 1, 'timeline.criadoEm': -1, '_id': -1}")
})
public class Order {

    @Id
    private String id;

    private String userId;
    private String kioskId;
    private String courierId; // nulo ate um entregador aceitar

    private List<OrderItem> itens;
    private BigDecimal valorTotal;
    private boolean embalagemSustentavel;

    private PaymentMethod formaPagamento;
    private boolean pago = false;

    // --- Localizacao do pedido (o nucleo do diferencial do app) ---
    private GeoJsonPoint pinCliente;

    private String pontoReferenciaId;
    private String descricaoLocal;   // ex: "guarda-sol listrado azul, perto do quiosque do Ze"
    private String fotoLocalUrl;     // opcional

    /** Uma vez PAGO, o pin nao pode mais ser alterado (trava, como no modelo Dominos) */
    private boolean localizacaoTravada = false;

    private OrderStatus status = OrderStatus.CRIADO;

    private StatusTimeline timeline = new StatusTimeline();

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OrderItem {
        private String menuItemId;
        private String nome;
        private int quantidade;
        private BigDecimal precoUnitario;
    }

    @Data
    @NoArgsConstructor
    public static class StatusTimeline {
        private Instant criadoEm = Instant.now();
        private Instant pagoEm;
        private Instant emPreparoEm;
        private Instant aCaminhoEm;
        private Instant chegouNoLocalEm;
        private Instant entregueEm;
    }

    public void transitionTo(OrderStatus newStatus) {
        this.status = newStatus;
        Instant now = Instant.now();
        switch (newStatus) {
            case PAGO -> {
                this.pago = true;
                this.localizacaoTravada = true;
                this.timeline.setPagoEm(now);
            }
            case EM_PREPARO -> this.timeline.setEmPreparoEm(now);
            case A_CAMINHO -> this.timeline.setACaminhoEm(now);
            case CHEGOU_NO_LOCAL -> this.timeline.setChegouNoLocalEm(now);
            case ENTREGUE -> this.timeline.setEntregueEm(now);
            case CRIADO, CANCELADO -> {
            }
        }
    }
}
