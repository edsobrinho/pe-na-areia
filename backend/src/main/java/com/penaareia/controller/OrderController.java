package com.penaareia.controller;

import com.penaareia.dto.ConfirmDeliveryRequest;
import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.dto.ErrorResponse;
import com.penaareia.dto.OrderCursorSlice;
import com.penaareia.dto.OrderResponse;
import com.penaareia.dto.OrderTrackingDtos.CourierLocationUpdateRequest;
import com.penaareia.dto.OrderTrackingDtos.OrderMessageRequest;
import com.penaareia.dto.OrderTrackingDtos.PixChargeResponse;
import com.penaareia.dto.StatusUpdateRequest;
import com.penaareia.model.Order;
import com.penaareia.service.BusinessRuleException;
import com.penaareia.service.OrderEventStreamService;
import com.penaareia.service.OrderService;
import com.penaareia.service.OrderWorkflowService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

@RestController
@RequestMapping("/orders")
@Validated
@Tag(name = "Pedidos", description = "Criacao e consulta de pedidos, incluindo pin de localizacao")
public class OrderController {

    private final OrderService orderService;
    private final OrderWorkflowService workflowService;
    private final OrderEventStreamService streamService;

    public OrderController(OrderService orderService, OrderWorkflowService workflowService) {
        this(orderService, workflowService, new OrderEventStreamService());
    }

    @Autowired
    public OrderController(OrderService orderService,
                           OrderWorkflowService workflowService,
                           @Autowired(required = false) OrderEventStreamService streamService) {
        this.orderService = orderService;
        this.workflowService = workflowService;
        this.streamService = streamService != null ? streamService : new OrderEventStreamService();
    }

    @GetMapping("/available")
    @Operation(summary = "Lista pedidos prontos que podem ser aceitos por um entregador",
            description = "Aceita size (1 a 100) e cursor retornado no header X-Next-Cursor.")
    public ResponseEntity<List<OrderResponse>> listarDisponiveis(
            Authentication authentication,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int size,
            @RequestParam(required = false) String cursor) {
        requireRole(authentication, "ROLE_COURIER");
        return cursorResponse(workflowService.listarDisponiveis(size, cursor));
    }

    @GetMapping("/courier/active")
    @Operation(summary = "Lista entregas em rota do entregador autenticado",
            description = "Aceita size (1 a 100) e cursor retornado no header X-Next-Cursor.")
    public ResponseEntity<List<OrderResponse>> listarEmRota(
            Authentication authentication,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int size,
            @RequestParam(required = false) String cursor) {
        requireRole(authentication, "ROLE_COURIER");
        return cursorResponse(workflowService.listarEmRota(authentication.getName(), size, cursor));
    }

    @GetMapping("/kiosk/me")
    @Operation(summary = "Lista pedidos do quiosque/restaurante do parceiro autenticado")
    public List<OrderResponse> listarPedidosDoQuiosque(
            Authentication authentication,
            @RequestParam(required = false, defaultValue = "ALL") String statusFilter) {
        requireRole(authentication, "ROLE_KIOSK_OPERATOR");
        com.penaareia.model.User user = orderService.buscarUsuario(authentication.getName());
        if (user.getKioskId() == null || user.getKioskId().isBlank()) {
            throw new BusinessRuleException("O usuário autenticado não possui um quiosque vinculado.");
        }
        return workflowService.listarPedidosDoQuiosque(user.getKioskId(), statusFilter);
    }

    private static ResponseEntity<List<OrderResponse>> cursorResponse(OrderCursorSlice slice) {
        List<OrderResponse> orders = slice.orders().stream()
                .map(OrderResponse::fromEntity)
                .toList();
        ResponseEntity.BodyBuilder response = ResponseEntity.ok();
        if (slice.nextCursor() != null) {
            response.header("X-Next-Cursor", slice.nextCursor());
        }
        return response.body(orders);
    }

    @PostMapping
    @Operation(summary = "Cria um pedido com pin de localizacao, itens e forma de pagamento",
            description = "Valida usuario, quiosque e posto de referencia (existentes e ativos), "
                    + "cada item do cardapio (existente, disponivel e com quantidade > 0) e calcula "
                    + "o valor total no servidor a partir dos precos do cardapio.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Pedido criado"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos (validacao em cascata, limites de lat/lng, descricao ate 140)",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "404", description = "Usuario, quiosque, item do cardapio ou posto nao encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "422", description = "Recurso inativo (usuario/quiosque/posto) ou item indisponivel",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<OrderResponse> criar(@Valid @RequestBody CreateOrderRequest request,
                                                Authentication authentication) {
        requireRole(authentication, "ROLE_CLIENT");
        if (!authentication.getName().equals(request.getUserId())) {
            throw new BusinessRuleException("O pedido só pode ser criado para o usuário autenticado.");
        }
        Order order = orderService.criarPedido(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(OrderResponse.fromEntity(order));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Busca um pedido pelo id")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Pedido encontrado"),
            @ApiResponse(responseCode = "404", description = "Pedido nao encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public OrderResponse buscar(@PathVariable String id, Authentication authentication) {
        Order order = orderService.buscarPorId(id);
        if (!authentication.getName().equals(order.getUserId())
                && !authentication.getName().equals(order.getCourierId())) {
            throw new BusinessRuleException("Você não tem acesso a este pedido.");
        }
        return OrderResponse.fromEntity(order);
    }

    @GetMapping(value = "/{id}/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @Operation(summary = "Stream SSE em tempo real de status e localização do entregador")
    public SseEmitter acompanharEmTempoReal(@PathVariable String id, Authentication authentication) {
        Order order = orderService.buscarPorId(id);
        if (!authentication.getName().equals(order.getUserId())
                && !authentication.getName().equals(order.getCourierId())) {
            throw new BusinessRuleException("Você não tem acesso a este pedido.");
        }
        return streamService.subscribe(order);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Atualiza o status do pedido respeitando as transições permitidas")
    public OrderResponse atualizarStatus(@PathVariable String id,
                                         @Valid @RequestBody StatusUpdateRequest request,
                                         Authentication authentication) {
        return OrderResponse.fromEntity(workflowService.atualizarStatus(
                id, request.status(), authentication.getName(), authentication.getAuthorities(), request.motivo()));
    }

    @PatchMapping("/{id}/courier-location")
    @Operation(summary = "Atualiza a coordenada GPS em tempo real do entregador na rota")
    public OrderResponse atualizarLocalizacaoEntregador(
            @PathVariable String id,
            @Valid @RequestBody CourierLocationUpdateRequest request,
            Authentication authentication) {
        requireRole(authentication, "ROLE_COURIER");
        return OrderResponse.fromEntity(workflowService.atualizarLocalizacaoEntregador(
                id, request.latitude(), request.longitude(), authentication.getName()));
    }

    @PostMapping("/{id}/messages")
    @Operation(summary = "Envia uma mensagem rápida no pedido durante a entrega")
    public OrderResponse enviarMensagem(@PathVariable String id,
                                        @Valid @RequestBody OrderMessageRequest request,
                                        Authentication authentication) {
        return OrderResponse.fromEntity(workflowService.enviarMensagemRapida(
                id, authentication.getName(), authentication.getAuthorities(), request.texto()));
    }

    @GetMapping("/{id}/messages")
    @Operation(summary = "Lista as mensagens rápidas trocadas durante a entrega")
    public List<Order.OrderMessage> listarMensagens(@PathVariable String id, Authentication authentication) {
        return workflowService.listarMensagens(id, authentication.getName());
    }

    @PostMapping("/{id}/pix-charge")
    @Operation(summary = "Gera ou recupera a cobrança Pix dinâmica do pedido")
    public PixChargeResponse gerarCobrancaPix(@PathVariable String id, Authentication authentication) {
        requireRole(authentication, "ROLE_CLIENT");
        return orderService.gerarCobrancaPix(id, authentication.getName());
    }

    @PostMapping("/{id}/confirm-delivery")
    @Operation(summary = "Confirma a entrega apenas quando o entregador está próximo ao pin")
    public OrderResponse confirmarEntrega(@PathVariable String id,
                                          @Valid @RequestBody ConfirmDeliveryRequest request,
                                          Authentication authentication) {
        requireRole(authentication, "ROLE_COURIER");
        return OrderResponse.fromEntity(workflowService.confirmarEntrega(
                id, request, authentication.getName()));
    }

    private void requireRole(Authentication authentication, String role) {
        if (authentication.getAuthorities().stream().noneMatch(authority ->
                role.equals(authority.getAuthority()))) {
            throw new BusinessRuleException("Esta operação não está disponível para o seu perfil.");
        }
    }
}
