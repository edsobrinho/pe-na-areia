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

    /** Codigo de 4 digitos numericos para validacao verbal na areia */
    private String codigoEntrega;

    /** Avaliacao de 1 a 5 estrelas feita pelo cliente */
    private Order.OrderReview avaliacao;

    /** Identificador sequencial diario do pedido (#0001 a #9999) */
    private String codigoPedido;
    private Integer numeroPedidoDiario;

    /** Indica se a sessao de chat em tempo real esta ativa */
    private boolean chatAtivo;

    public static OrderResponse fromEntity(Order order) {
        return fromEntityWithCourier(order, null);
    }

    public static OrderResponse fromEntityWithCourier(Order order, com.penaareia.model.Courier courier) {
        String veiculoStr = null;
        if (courier != null && courier.getVeiculo() != null) {
            veiculoStr = courier.getVeiculo().name();
        }
        boolean chatAtivo = order.getStatus() == OrderStatus.PRONTO_ENTREGA
                || order.getStatus() == OrderStatus.A_CAMINHO
                || order.getStatus() == OrderStatus.CHEGOU_NO_LOCAL;
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
                order.getTimeline(),
                order.getCodigoEntrega(),
                order.getAvaliacao(),
                order.getCodigoPedido(),
                order.getNumeroPedidoDiario(),
                chatAtivo
        );
    }

    public static OrderResponse fromEntityForCourier(Order order, com.penaareia.model.Courier courier) {
        OrderResponse resp = fromEntityWithCourier(order, courier);
        if (order.getStatus() != OrderStatus.ENTREGUE) {
            resp.setCodigoEntrega(null);
        }
        return resp;
    }
}
