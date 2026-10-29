package com.penaareia.e2e;

import com.penaareia.controller.PixWebhookController;
import com.penaareia.dto.ConfirmDeliveryRequest;
import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.dto.OrderResponse;
import com.penaareia.dto.OrderTrackingDtos.PixWebhookRequest;
import com.penaareia.model.Courier;
import com.penaareia.model.Kiosk;
import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.model.PaymentMethod;
import com.penaareia.model.ReferencePoint;
import com.penaareia.model.User;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.OrderRepository;
import com.penaareia.repository.ReferencePointRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.service.BusinessRuleException;
import com.penaareia.service.NotificationService;
import com.penaareia.service.OrderEventStreamService;
import com.penaareia.service.OrderService;
import com.penaareia.service.OrderWorkflowService;
import com.penaareia.service.PartnershipPricingService;
import com.penaareia.service.PartnershipService;
import com.penaareia.service.PixPaymentGateway;
import com.mongodb.client.result.UpdateResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * Teste End-to-End (E2E) que simula o ciclo de vida completo de um pedido na praia:
 * 1. Realização do pedido com Pin do cliente na areia e Posto de Salvamento (CRIADO/EM_PREPARO).
 * 2. Confirmação do pagamento Pix via Webhook (PAGO).
 * 3. Preparo do pedido pelo Quiosque (EM_PREPARO).
 * 4. Aceite pelo entregador de praia / runner (A_CAMINHO).
 * 5. Deslocamento do entregador com atualização de GPS e alerta de proximidade aos 60m.
 * 6. Chegada ao local exato do guarda-sol/barraca (CHEGOU_NO_LOCAL).
 * 7. Confirmação da entrega com validação geográfica do raio de proximidade (ENTREGUE).
 * 8. Fluxos alternativos: cancelamento pelo quiosque com justificativa (CANCELADO) e cliente ausente (NAO_ENCONTRADO).
 */
@ExtendWith(MockitoExtension.class)
class OrderLifecycleE2ETest {

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
    private PartnershipService partnershipService;
    @Mock
    private MongoTemplate mongoTemplate;

    private OrderService orderService;
    private OrderWorkflowService workflowService;
    private PixWebhookController pixWebhookController;
    private NotificationService notificationService;
    private OrderEventStreamService streamService;

    // Coordenadas simuladas na orla de Santos
    // Posto 5: lat -23.9689, lng -46.3336
    private static final double POSTO_5_LAT = -23.9689;
    private static final double POSTO_5_LNG = -46.3336;
    // Guarda-sol do cliente na areia a ~50 metros do Posto 5
    private static final double CLIENTE_PIN_LAT = -23.9692;
    private static final double CLIENTE_PIN_LNG = -46.3338;

    private User cliente;
    private Kiosk quiosque;
    private ReferencePoint posto5;
    private KioskPartnership partnershipConfig;
    private Courier entregador;

    @BeforeEach
    void setUp() {
        PartnershipPricingService pricingService = new PartnershipPricingService();
        notificationService = new NotificationService();
        streamService = new OrderEventStreamService();

        orderService = new OrderService(
                orderRepository,
                userRepository,
                kioskRepository,
                referencePointRepository,
                pricingService,
                partnershipService,
                new PixPaymentGateway(),
                streamService
        );

        workflowService = new OrderWorkflowService(
                orderRepository,
                courierRepository,
                mongoTemplate,
                60.0, // raio de proximidade de entrega: 60 metros
                notificationService,
                streamService
        );

        pixWebhookController = new PixWebhookController(orderService, "webhook-secret-token");

        // Monta os dados do cenário
        cliente = new User();
        cliente.setId("client-ednilson");
        cliente.setNome("Ednilson Sobrinho");
        cliente.setTelefone("13999998888");
        cliente.setAtivo(true);

        posto5 = new ReferencePoint();
        posto5.setId("posto-5");
        posto5.setNome("Posto 5");
        posto5.setNumero(5);
        posto5.setTrecho("Gonzaga");
        posto5.setLocalizacao(new GeoJsonPoint(POSTO_5_LNG, POSTO_5_LAT));
        posto5.setAtivo(true);

        Kiosk.MenuItem itemIsca = new Kiosk.MenuItem();
        itemIsca.setId("item-isca-peixe");
        itemIsca.setNome("Isca de Peixe na Areia 500g");
        itemIsca.setPreco(new BigDecimal("68.00"));
        itemIsca.setDisponivel(true);
        itemIsca.setCategory("Porções");
        itemIsca.setReturnablePackaging(true);

        quiosque = new Kiosk();
        quiosque.setId("kiosk-burgman");
        quiosque.setNome("Burgman Canal 5");
        quiosque.setAtivo(true);
        quiosque.setCardapio(List.of(itemIsca));

        partnershipConfig = new KioskPartnership();
        partnershipConfig.setKioskId("kiosk-burgman");
        partnershipConfig.setPartnershipId("pe-na-areia-app");
        partnershipConfig.setActive(true);
        partnershipConfig.setAcceptFrom(LocalTime.MIN);
        partnershipConfig.setAcceptUntil(LocalTime.MAX);
        partnershipConfig.setMaxItemsPerOrder(10);
        partnershipConfig.setMinimumOrder(new BigDecimal("20.00"));
        partnershipConfig.setDeliveryFee(new BigDecimal("5.00"));
        partnershipConfig.setCommissionPercent(new BigDecimal("10.00"));
        partnershipConfig.setProductIds(List.of("item-isca-peixe"));

        entregador = new Courier();
        entregador.setId("courier-marcos");
        entregador.setNome("Marcos Runner");
        entregador.setTelefone("13977776666");
        entregador.setStatus(Courier.CourierStatus.DISPONIVEL);
    }

    private CreateOrderRequest.PinClienteRequest pin(double lat, double lng) {
        CreateOrderRequest.PinClienteRequest p = new CreateOrderRequest.PinClienteRequest();
        p.setLatitude(lat);
        p.setLongitude(lng);
        return p;
    }

    private CreateOrderRequest.ItemRequest item(String id, int qtd) {
        CreateOrderRequest.ItemRequest i = new CreateOrderRequest.ItemRequest();
        i.setMenuItemId(id);
        i.setQuantidade(qtd);
        return i;
    }

    @Test
    @DisplayName("E2E: Simulação Completa da Entrega na Areia (CRIADO -> PAGO -> EM_PREPARO -> A_CAMINHO -> CHEGOU_NO_LOCAL -> ENTREGUE)")
    void fluxoCompletoDeEntregaPontaAPonta() {
        // Mock de busca de entidades para criação do pedido
        when(userRepository.findById("client-ednilson")).thenReturn(Optional.of(cliente));
        when(kioskRepository.findById("kiosk-burgman")).thenReturn(Optional.of(quiosque));
        when(referencePointRepository.findById("posto-5")).thenReturn(Optional.of(posto5));
        when(partnershipService.activeConfiguration("kiosk-burgman", "pe-na-areia-app")).thenReturn(partnershipConfig);
        when(partnershipService.isWithinAcceptanceWindow(partnershipConfig)).thenReturn(true);
        when(partnershipService.isEligible(eq(partnershipConfig), any(Kiosk.MenuItem.class))).thenReturn(true);

        // Simulador de persistência do OrderRepository
        Order[] storedOrder = new Order[1];
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> {
            Order o = inv.getArgument(0);
            if (o.getId() == null) {
                o.setId("ord-e2e-1001");
            }
            storedOrder[0] = o;
            return o;
        });
        lenient().when(orderRepository.findById("ord-e2e-1001")).thenAnswer(inv -> Optional.ofNullable(storedOrder[0]));

        // =========================================================================
        // PASSO 1: O Cliente faz o pedido no App com o Pin e Posto de Salvamento
        // =========================================================================
        CreateOrderRequest request = new CreateOrderRequest();
        request.setUserId("client-ednilson");
        request.setKioskId("kiosk-burgman");
        request.setPartnershipId("pe-na-areia-app");
        request.setPontoReferenciaId("posto-5");
        request.setFormaPagamento(PaymentMethod.PIX);
        request.setEmbalagemSustentavel(true);
        request.setReferenciaBarraca("Guarda-sol azul marinho");
        request.setComplementoLocal("Em frente à rede de futevôlei");
        request.setContatoNome("Ednilson Sobrinho");
        request.setContatoTelefone("+55 13 99999-8888");
        request.setPinCliente(pin(CLIENTE_PIN_LAT, CLIENTE_PIN_LNG));
        request.setItens(List.of(item("item-isca-peixe", 1)));

        Order criado = orderService.criarPedido(request);

        assertThat(criado.getTimeline().getCriadoEm()).isNotNull();
        assertThat(criado.getPixTxId()).isNotBlank();
        assertThat(criado.getPinCliente().getY()).isEqualTo(CLIENTE_PIN_LAT);
        assertThat(criado.getPinCliente().getX()).isEqualTo(CLIENTE_PIN_LNG);
        assertThat(criado.getValorTotal()).isGreaterThan(new BigDecimal("68.00"));

        // =========================================================================
        // PASSO 2: Confirmação do pagamento Pix via Webhook (PAGO -> EM_PREPARO)
        // =========================================================================
        PixWebhookRequest webhookReq = new PixWebhookRequest(criado.getPixTxId(), criado.getId(), "CONCLUIDA");
        OrderResponse pago = pixWebhookController.receberConfirmacao("webhook-secret-token", webhookReq);

        assertThat(pago.isPago()).isTrue();
        assertThat(pago.getStatus()).isEqualTo(OrderStatus.EM_PREPARO);
        assertThat(storedOrder[0].getTimeline().getPagoEm()).isNotNull();
        assertThat(storedOrder[0].getTimeline().getEmPreparoEm()).isNotNull();

        // =========================================================================
        // PASSO 3: O Entregador aceita o pedido em preparo e sai em rota (A_CAMINHO)
        // =========================================================================
        storedOrder[0].setStatus(OrderStatus.EM_PREPARO);
        storedOrder[0].setCourierId(null);

        Order emRotaOrder = new Order();
        emRotaOrder.setId("ord-e2e-1001");
        emRotaOrder.setStatus(OrderStatus.A_CAMINHO);
        emRotaOrder.setCourierId("courier-marcos");
        emRotaOrder.setPinCliente(new GeoJsonPoint(CLIENTE_PIN_LNG, CLIENTE_PIN_LAT));

        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(emRotaOrder);
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(Courier.class)))
                .thenReturn(UpdateResult.acknowledged(1, 1L, null));

        Order aCaminho = workflowService.atualizarStatus(
                "ord-e2e-1001",
                OrderStatus.A_CAMINHO,
                "courier-marcos",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))
        );

        storedOrder[0] = aCaminho;
        assertThat(aCaminho.getStatus()).isEqualTo(OrderStatus.A_CAMINHO);
        assertThat(aCaminho.getCourierId()).isEqualTo("courier-marcos");

        // =========================================================================
        // PASSO 4: Entregador se desloca na areia e atualiza geolocalização em tempo real
        // =========================================================================
        // a) Entregador ainda a ~200 metros de distância do cliente
        workflowService.atualizarLocalizacaoEntregador("ord-e2e-1001", -23.9710, -46.3338, "courier-marcos");
        assertThat(storedOrder[0].isAlertaProximidadeEnviado()).isFalse();

        // b) Entregador se aproxima a ~25 metros do guarda-sol do cliente (< 60m)
        Order proximo = workflowService.atualizarLocalizacaoEntregador("ord-e2e-1001", -23.9694, -46.3338, "courier-marcos");
        assertThat(proximo.isAlertaProximidadeEnviado()).isTrue();
        assertThat(notificationService.listarAlertasPorPedido("ord-e2e-1001")).hasSize(1);
        assertThat(notificationService.listarAlertasPorPedido("ord-e2e-1001").get(0).mensagem())
                .contains("Sinalizador");

        // =========================================================================
        // PASSO 5: Entregador chega ao guarda-sol (CHEGOU_NO_LOCAL)
        // =========================================================================
        storedOrder[0].setStatus(OrderStatus.A_CAMINHO);
        Order chegou = workflowService.atualizarStatus(
                "ord-e2e-1001",
                OrderStatus.CHEGOU_NO_LOCAL,
                "courier-marcos",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))
        );

        assertThat(chegou.getStatus()).isEqualTo(OrderStatus.CHEGOU_NO_LOCAL);
        assertThat(chegou.getTimeline().getChegouNoLocalEm()).isNotNull();

        // =========================================================================
        // PASSO 6: Entregador tenta confirmar entrega longe do pin -> Rejeitado
        // =========================================================================
        ConfirmDeliveryRequest longeRequest = new ConfirmDeliveryRequest(
                "courier-marcos",
                new ConfirmDeliveryRequest.CourierLocation(-23.9750, -46.3338) // ~640 metros de distancia
        );
        assertThatThrownBy(() -> workflowService.confirmarEntrega("ord-e2e-1001", longeRequest, "courier-marcos"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Aproxime-se do pin do cliente");

        // =========================================================================
        // PASSO 7: Entregador confirma entrega no local exato do Pin (< 60m) -> ENTREGUE
        // =========================================================================
        ConfirmDeliveryRequest entregaNoLocalRequest = new ConfirmDeliveryRequest(
                "courier-marcos",
                new ConfirmDeliveryRequest.CourierLocation(CLIENTE_PIN_LAT, CLIENTE_PIN_LNG) // exatamente no pin
        );

        Order deliveredResult = new Order();
        deliveredResult.setId("ord-e2e-1001");
        deliveredResult.setStatus(OrderStatus.ENTREGUE);
        deliveredResult.setCourierId("courier-marcos");

        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(deliveredResult);

        Order entregue = workflowService.confirmarEntrega("ord-e2e-1001", entregaNoLocalRequest, "courier-marcos");

        assertThat(entregue.getStatus()).isEqualTo(OrderStatus.ENTREGUE);
        assertThat(entregue.getCourierId()).isEqualTo("courier-marcos");
    }

    @Test
    @DisplayName("E2E: Validação do Raio de 500m - Rejeita pedido se o pin estiver fora da praia/posto")
    void rejeitaCriacaoSePinEstiverAcimaDe500MetrosDoPosto() {
        when(userRepository.findById("client-ednilson")).thenReturn(Optional.of(cliente));
        when(kioskRepository.findById("kiosk-burgman")).thenReturn(Optional.of(quiosque));
        when(referencePointRepository.findById("posto-5")).thenReturn(Optional.of(posto5));

        CreateOrderRequest request = new CreateOrderRequest();
        request.setUserId("client-ednilson");
        request.setKioskId("kiosk-burgman");
        request.setPartnershipId("pe-na-areia-app");
        request.setPontoReferenciaId("posto-5");
        request.setFormaPagamento(PaymentMethod.PIX);
        request.setItens(List.of(item("item-isca-peixe", 1)));

        // Pin em São Paulo / fora de Santos (> 50 km de distância do Posto 5)
        request.setPinCliente(pin(-23.5505, -46.6333));

        assertThatThrownBy(() -> orderService.criarPedido(request))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("O pin deve estar a no máximo 500 m do posto de referência.");
    }

    @Test
    @DisplayName("E2E: Fluxo Alternativo - Quiosque cancela pedido com justificativa")
    void quiosquePodeCancelarPedidoComMotivo() {
        Order order = new Order();
        order.setId("ord-cancel-1");
        order.setKioskId("kiosk-burgman");
        order.setStatus(OrderStatus.EM_PREPARO);

        User operadorUser = new User();
        operadorUser.setId("operator-1");
        operadorUser.setKioskId("kiosk-burgman");

        when(orderRepository.findById("ord-cancel-1")).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(mongoTemplate.findById("operator-1", User.class)).thenReturn(operadorUser);

        Order cancelado = workflowService.atualizarStatus(
                "ord-cancel-1",
                OrderStatus.CANCELADO,
                "operator-1",
                List.of(new SimpleGrantedAuthority("ROLE_KIOSK_OPERATOR")),
                "Acabou o estoque de frutos do mar"
        );

        assertThat(cancelado.getStatus()).isEqualTo(OrderStatus.CANCELADO);
        assertThat(cancelado.getMotivoCancelamento()).isEqualTo("Acabou o estoque de frutos do mar");
    }

    @Test
    @DisplayName("E2E: Fluxo Alternativo - Entregador reporta cliente não encontrado na areia")
    void entregadorReportaClienteNaoEncontrado() {
        Order order = new Order();
        order.setId("ord-nao-enc-1");
        order.setCourierId("courier-marcos");
        order.setStatus(OrderStatus.CHEGOU_NO_LOCAL);

        when(orderRepository.findById("ord-nao-enc-1")).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        Order naoEncontrado = workflowService.atualizarStatus(
                "ord-nao-enc-1",
                OrderStatus.NAO_ENCONTRADO,
                "courier-marcos",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER")),
                "Cliente não estava no guarda-sol informado após 15 minutos de espera"
        );

        assertThat(naoEncontrado.getStatus()).isEqualTo(OrderStatus.NAO_ENCONTRADO);
        assertThat(naoEncontrado.getTimeline().getNaoEncontradoEm()).isNotNull();
        assertThat(naoEncontrado.getMotivoCancelamento()).contains("Cliente não estava no guarda-sol");
    }
}
