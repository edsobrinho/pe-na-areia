package com.penaareia.service;

import com.penaareia.controller.PixWebhookController;
import com.penaareia.dto.OrderResponse;
import com.penaareia.dto.OrderTrackingDtos.PixChargeResponse;
import com.penaareia.dto.OrderTrackingDtos.PixWebhookRequest;
import com.penaareia.model.Courier;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.model.PaymentMethod;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.OrderRepository;
import com.penaareia.repository.ReferencePointRepository;
import com.penaareia.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderBeachLogisticsAndPixTest {

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private CourierRepository courierRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private KioskRepository kioskRepository;
    @Mock
    private ReferencePointRepository referencePointRepository;
    @Mock
    private PartnershipPricingService pricingService;
    @Mock
    private PartnershipService partnershipService;
    @Mock
    private MongoTemplate mongoTemplate;

    @Test
    void entregadorAtualizaPosicaoEDisparaAlertaDeProximidadeQuandoEntraNos60Metros() {
        NotificationService notificationService = new NotificationService();
        OrderEventStreamService streamService = new OrderEventStreamService();
        OrderWorkflowService workflow = new OrderWorkflowService(
                orderRepository, courierRepository, mongoTemplate, 60.0, notificationService, streamService);

        Order order = new Order();
        order.setId("ord-beach-1");
        order.setUserId("client-1");
        order.setCourierId("courier-1");
        order.setStatus(OrderStatus.A_CAMINHO);
        order.setPinCliente(new GeoJsonPoint(-46.3280, -23.9720));

        when(orderRepository.findById("ord-beach-1")).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        // 1) Fora de 60m (~220m de distancia): nao dispara alerta
        Order longe = workflow.atualizarLocalizacaoEntregador("ord-beach-1", -23.9700, -46.3280, "courier-1");
        assertThat(longe.isAlertaProximidadeEnviado()).isFalse();
        assertThat(notificationService.listarAlertasPorPedido("ord-beach-1")).isEmpty();

        // 2) Dentro de 60m (~22m de distancia): dispara alerta unico
        Order perto = workflow.atualizarLocalizacaoEntregador("ord-beach-1", -23.9718, -46.3280, "courier-1");
        assertThat(perto.isAlertaProximidadeEnviado()).isTrue();
        assertThat(perto.getLocalizacaoEntregador().getY()).isEqualTo(-23.9718);
        assertThat(notificationService.listarAlertasPorPedido("ord-beach-1")).hasSize(1);
        assertThat(notificationService.listarAlertasPorPedido("ord-beach-1").get(0).mensagem())
                .contains("Sinalizador");

        // 3) Nova atualizacao dentro de 60m nao duplica alerta
        workflow.atualizarLocalizacaoEntregador("ord-beach-1", -23.9719, -46.3280, "courier-1");
        assertThat(notificationService.listarAlertasPorPedido("ord-beach-1")).hasSize(1);
        verify(mongoTemplate, org.mockito.Mockito.times(3))
                .updateFirst(any(Query.class), any(Update.class), eq(Courier.class));
    }

    @Test
    void canalDeMensagensRapidasFuncionaEntreClienteEEntregadorEmRota() {
        OrderWorkflowService workflow = new OrderWorkflowService(
                orderRepository, courierRepository, mongoTemplate, 60.0);

        Order order = new Order();
        order.setId("ord-msg-1");
        order.setUserId("client-1");
        order.setCourierId("courier-1");
        order.setStatus(OrderStatus.A_CAMINHO);

        when(orderRepository.findById("ord-msg-1")).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        workflow.enviarMensagemRapida(
                "ord-msg-1",
                "client-1",
                List.of(new SimpleGrantedAuthority("ROLE_CLIENT")),
                "A maré subiu, mudei alguns metros para trás");

        workflow.enviarMensagemRapida(
                "ord-msg-1",
                "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER")),
                "Estou chegando perto da barraca");

        List<Order.OrderMessage> msgs = workflow.listarMensagens("ord-msg-1", "client-1");
        assertThat(msgs).hasSize(2);
        assertThat(msgs.get(0).senderRole()).isEqualTo("CLIENT");
        assertThat(msgs.get(1).senderRole()).isEqualTo("COURIER");

        assertThatThrownBy(() -> workflow.listarMensagens("ord-msg-1", "intruso"))
                .isInstanceOf(BusinessRuleException.class);
    }

    @Test
    void geraCobrancaPixEConfirmaPagamentoViaWebhook() {
        OrderService orderService = new OrderService(
                orderRepository, userRepository, kioskRepository,
                referencePointRepository, pricingService, partnershipService,
                new PixPaymentGateway(), new OrderEventStreamService());

        Order order = new Order();
        order.setId("ord-pix-10");
        order.setUserId("client-1");
        order.setValorTotal(new BigDecimal("45.90"));
        order.setFormaPagamento(PaymentMethod.PIX);
        order.setPago(false);
        order.setStatus(OrderStatus.CRIADO);

        when(orderRepository.findById("ord-pix-10")).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        PixChargeResponse charge = orderService.gerarCobrancaPix("ord-pix-10", "client-1");
        assertThat(charge.pixTxId()).startsWith("PNA");
        assertThat(charge.pixCopiaECola()).contains("br.gov.bcb.pix");
        assertThat(charge.pixQrCodeBase64()).isNotBlank();

        PixWebhookController webhookController = new PixWebhookController(orderService, "segredo-webhook");
        OrderResponse confirmado = webhookController.receberConfirmacao(
                "segredo-webhook",
                new PixWebhookRequest(charge.pixTxId(), "ord-pix-10", "CONCLUIDA"));

        assertThat(confirmado.isPago()).isTrue();
        assertThat(confirmado.getStatus()).isEqualTo(OrderStatus.EM_PREPARO);

        assertThatThrownBy(() -> webhookController.receberConfirmacao(
                "token-invalido",
                new PixWebhookRequest(charge.pixTxId(), "ord-pix-10", "CONCLUIDA")))
                .isInstanceOf(ForbiddenException.class);
    }
}

