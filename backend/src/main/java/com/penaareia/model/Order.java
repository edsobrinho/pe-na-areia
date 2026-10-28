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
import java.util.ArrayList;
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
    private String partnershipId;

    private List<OrderItem> itens;
    private BigDecimal valorTotal;
    private PricingSnapshot pricingSnapshot;
    private boolean embalagemSustentavel;

    private PaymentMethod formaPagamento;
    private boolean pago = false;

    // --- Dados de Cobranca Pix Antecipada ---
    private String pixTxId;
    private String pixCopiaECola;
    private String pixQrCodeBase64;
    private Instant pixExpiracao;

    // --- Localizacao do pedido (o nucleo do diferencial do app) ---
    private GeoJsonPoint pinCliente;

    private String pontoReferenciaId;
    private String descricaoLocal;   // ex: "guarda-sol listrado azul, perto do quiosque do Ze"
    private String fotoLocalUrl;     // opcional (Guarda-sol / Barraca)

    // --- Metadados detalhados do Ponto na Praia (v2.1 - Tela 1) ---
    private String referenciaBarraca;       // ex: "Guarda-sol azul marinho" ou "Sem guarda-sol"
    private String complementoLocal;        // ex: "Em frente à rede de futevôlei"
    private String fotoVisaoPostoUrl;       // Guia de foto 2: Visão do Posto / Calçadão
    private String fotoOutroReferencialUrl; // Guia de foto 3: Outro referencial (cooler, bandeira)
    private String contatoNome;             // Nome de quem vai receber na praia
    private String contatoTelefone;         // Telefone/WhatsApp (+55) de quem vai receber
    private String etiquetaLocal;           // MEU_GUARDA_SOL, BARRACA_FAMILIA, POINT_SURF, OUTRO

    // --- Live Tracking do Entregador na Praia ---
    private GeoJsonPoint localizacaoEntregador;
    private Instant atualizadoEntregadorEm;
    private boolean alertaProximidadeEnviado = false;

    // --- Canal Rapido de Mensagens (A_CAMINHO / CHEGOU_NO_LOCAL) ---
    private List<OrderMessage> mensagens = new ArrayList<>();

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
        private String category;
        private boolean returnablePackaging;

        public OrderItem(String menuItemId, String nome, int quantidade, BigDecimal precoUnitario) {
            this(menuItemId, nome, quantidade, precoUnitario, "Outros", false);
        }
    }

    public record OrderMessage(
            String senderId,
            String senderRole,
            String texto,
            Instant enviadoEm
    ) {
    }

    public record PricingSnapshot(
            BigDecimal commissionPercent,
            BigDecimal commissionAmount,
            BigDecimal deliveryFee,
            String deliveryFeePayer,
            BigDecimal minimumOrder,
            Integer maxItemsPerOrder,
            java.time.LocalTime acceptFrom,
            java.time.LocalTime acceptUntil,
            Integer prepMinutes,
            java.util.List<String> filterCategories,
            boolean onlyReturnable,
            java.util.List<String> enabledProductIds,
            BigDecimal subtotal,
            BigDecimal customerTotal,
            BigDecimal kioskNet
    ) {
        public PricingSnapshot {
            filterCategories = java.util.List.copyOf(filterCategories);
            enabledProductIds = java.util.List.copyOf(enabledProductIds);
        }
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
