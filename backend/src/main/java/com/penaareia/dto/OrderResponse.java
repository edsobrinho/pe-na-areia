package com.penaareia.dto;

import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.model.PaymentMethod;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {

    private String id;
    private String userId;
    private String kioskId;
    private String partnershipId;
    /** Nulo ate um entregador aceitar o pedido */
    private String courierId;
    private List<Order.OrderItem> itens;
    private BigDecimal valorTotal;
    private Order.PricingSnapshot pricingSnapshot;
    private boolean embalagemSustentavel;
    private PaymentMethod formaPagamento;
    private boolean pago;
    private String pixTxId;
    private String pixCopiaECola;
    private String pixQrCodeBase64;
    private Instant pixExpiracao;
    /** Pin do cliente em formato GeoJSON: {"type":"Point","coordinates":[longitude,latitude]} */
    private GeoJsonPoint pinCliente;
    private String pontoReferenciaId;
    private String descricaoLocal;
    private String fotoLocalUrl;
    private String referenciaBarraca;
    private String complementoLocal;
    private String fotoVisaoPostoUrl;
    private String fotoOutroReferencialUrl;
    private String contatoNome;
    private String contatoTelefone;
    private String etiquetaLocal;
    private GeoJsonPoint localizacaoEntregador;
    private Instant atualizadoEntregadorEm;
    private boolean alertaProximidadeEnviado;
    private List<Order.OrderMessage> mensagens;
    private OrderStatus status;
    private String motivoCancelamento;
    private String courierNome;
    private String courierTelefone;
    private String courierVeiculo;
    private Order.StatusTimeline timeline;

    public static OrderResponse fromEntity(Order order) {
        return fromEntityWithCourier(order, null);
    }

    public static OrderResponse fromEntityWithCourier(Order order, com.penaareia.model.Courier courier) {
        String veiculoStr = null;
        if (courier != null && courier.getVeiculo() != null) {
            veiculoStr = courier.getVeiculo().name();
        }
        return new OrderResponse(
                order.getId(),
                order.getUserId(),
                order.getKioskId(),
                order.getPartnershipId(),
                order.getCourierId(),
                order.getItens(),
                order.getValorTotal(),
                order.getPricingSnapshot(),
                order.isEmbalagemSustentavel(),
                order.getFormaPagamento(),
                order.isPago(),
                order.getPixTxId(),
                order.getPixCopiaECola(),
                order.getPixQrCodeBase64(),
                order.getPixExpiracao(),
                order.getPinCliente(),
                order.getPontoReferenciaId(),
                order.getDescricaoLocal(),
                order.getFotoLocalUrl(),
                order.getReferenciaBarraca(),
                order.getComplementoLocal(),
                order.getFotoVisaoPostoUrl(),
                order.getFotoOutroReferencialUrl(),
                order.getContatoNome(),
                order.getContatoTelefone(),
                order.getEtiquetaLocal(),
                order.getLocalizacaoEntregador(),
                order.getAtualizadoEntregadorEm(),
                order.isAlertaProximidadeEnviado(),
                order.getMensagens() == null ? List.of() : List.copyOf(order.getMensagens()),
                order.getStatus(),
                order.getMotivoCancelamento(),
                courier != null ? courier.getNome() : null,
                courier != null ? courier.getTelefone() : null,
                veiculoStr,
                order.getTimeline()
        );
    }
}
