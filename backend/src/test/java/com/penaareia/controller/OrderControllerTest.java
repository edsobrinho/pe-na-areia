package com.penaareia.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.penaareia.config.JacksonConfig;
import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.security.JwtService;
import com.penaareia.service.BusinessRuleException;
import com.penaareia.service.OrderService;
import com.penaareia.service.OrderWorkflowService;
import com.penaareia.service.ResourceNotFoundException;
import com.penaareia.support.Fixtures;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Testes de fatia web do OrderController: contrato do 201 (todos os campos,
 * valorTotal numerico, pin em GeoJSON canonico) e mapeamento de erros
 * padronizados (400 de validacao em cascata, 404 e 422).
 * Sem banco (Atlas) e sem seeder: o OrderService e mockado.
 */
@WebMvcTest(OrderController.class)
@AutoConfigureMockMvc
@Import(JacksonConfig.class)
@WithMockUser(username = "u1", roles = "CLIENT")
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private OrderService orderService;
    @MockBean
    private OrderWorkflowService workflowService;
    @MockBean
    private JwtService jwtService;

    private String jsonValido() throws Exception {
        return objectMapper.writeValueAsString(Fixtures.requestValido());
    }

    private MockHttpServletRequestBuilder post() {
        return org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .post("/orders")
                .with(csrf());
    }

    @Test
    @WithMockUser(username = "courier-1", roles = "COURIER")
    void pedidosDisponiveisUsaPaginaPadraoLimitada() throws Exception {
        when(workflowService.listarDisponiveis(50, null))
                .thenReturn(new com.penaareia.dto.OrderCursorSlice(List.of(), null));

        mockMvc.perform(get("/orders/available"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        verify(workflowService).listarDisponiveis(50, null);
    }

    @Test
    @WithMockUser(username = "courier-1", roles = "COURIER")
    void pedidosDisponiveisEncaminhaTamanhoECursorEDevolveProximoCursor() throws Exception {
        String cursor = "cursor-atual";
        when(workflowService.listarDisponiveis(80, cursor))
                .thenReturn(new com.penaareia.dto.OrderCursorSlice(List.of(), "cursor-seguinte"));

        mockMvc.perform(get("/orders/available")
                        .param("size", "80")
                        .param("cursor", cursor))
                .andExpect(status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .header().string("X-Next-Cursor", "cursor-seguinte"));

        verify(workflowService).listarDisponiveis(80, cursor);
    }

    @Test
    @WithMockUser(username = "courier-1", roles = "COURIER")
    void pedidosDisponiveisRejeitaTamanhoAcimaDoLimite() throws Exception {
        mockMvc.perform(get("/orders/available").param("size", "101"))
                .andExpect(status().isBadRequest());
        verify(workflowService, never()).listarDisponiveis(any(Integer.class), any());
    }

    // --- 201 e contrato de resposta ---

    @Test
    void criaPedidoRetorna201ComContratoCompleto() throws Exception {
        when(orderService.criarPedido(any(CreateOrderRequest.class))).thenReturn(Fixtures.orderEntity());

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonValido()))
                .andExpect(status().isCreated())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value("o1"))
                .andExpect(jsonPath("$.userId").value(Fixtures.USER_ID))
                .andExpect(jsonPath("$.kioskId").value(Fixtures.KIOSK_ID))
                .andExpect(jsonPath("$.courierId").value(nullValue()))
                .andExpect(jsonPath("$.itens.length()").value(2))
                .andExpect(jsonPath("$.itens[0].menuItemId").value(Fixtures.MENU_ITEM_DISPONIVEL))
                .andExpect(jsonPath("$.itens[0].nome").value("Agua de coco"))
                .andExpect(jsonPath("$.itens[0].quantidade").value(2))
                .andExpect(jsonPath("$.itens[0].precoUnitario").value(12.5))
                // valorTotal numerico decimal (2 x 12.50 + 7.25 = 32.25)
                .andExpect(jsonPath("$.valorTotal").value(32.25))
                .andExpect(jsonPath("$.embalagemSustentavel").value(true))
                .andExpect(jsonPath("$.formaPagamento").value("PIX"))
                .andExpect(jsonPath("$.pago").value(true))
                // pin em GeoJSON canonico: [longitude, latitude], sem x/y redundantes
                .andExpect(jsonPath("$.pinCliente.type").value("Point"))
                .andExpect(jsonPath("$.pinCliente.coordinates[0]").value(Fixtures.LONGITUDE))
                .andExpect(jsonPath("$.pinCliente.coordinates[1]").value(Fixtures.LATITUDE))
                .andExpect(jsonPath("$.pinCliente.x").doesNotExist())
                .andExpect(jsonPath("$.pinCliente.y").doesNotExist())
                .andExpect(jsonPath("$.pontoReferenciaId").value(Fixtures.POSTO_ID))
                .andExpect(jsonPath("$.descricaoLocal").value("Guarda-sol listrado azul"))
                .andExpect(jsonPath("$.fotoLocalUrl")
                        .value("https://res.cloudinary.com/demo/image/upload/foto-local.png"))
                .andExpect(jsonPath("$.status").value("EM_PREPARO"))
                .andExpect(jsonPath("$.timeline.criadoEm").exists());
    }

    @Test
    void buscaPedidoRetorna200ComContrato() throws Exception {
        when(orderService.buscarPorId("o1")).thenReturn(Fixtures.orderEntity());

        mockMvc.perform(get("/orders/o1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("o1"))
                .andExpect(jsonPath("$.valorTotal").value(32.25))
                .andExpect(jsonPath("$.pinCliente.coordinates[0]").value(Fixtures.LONGITUDE));
    }

    @Test
    void buscaPedidoInexistenteRetorna404Padronizado() throws Exception {
        when(orderService.buscarPorId("o99"))
                .thenThrow(new ResourceNotFoundException("Pedido nao encontrado: o99"));

        mockMvc.perform(get("/orders/o99"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.mensagem").value("Pedido nao encontrado: o99"))
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.campos").doesNotExist());
    }

    // --- 400: validacao em cascata ---

    @Test
    void quantidadeZeroRetorna400ComCampoDetalhado() throws Exception {
        CreateOrderRequest request = Fixtures.requestValido();
        request.getItens().get(0).setQuantidade(0);

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.mensagem").value("Dados invalidos"))
                .andExpect(jsonPath("$.campos['itens[0].quantidade']")
                        .value("A quantidade deve ser maior que zero"));
    }

    @Test
    void quantidadeNulaRetorna400() throws Exception {
        CreateOrderRequest request = Fixtures.requestValido();
        request.getItens().get(0).setQuantidade(null);

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos['itens[0].quantidade']").exists());
    }

    /** Regressao: elemento nulo na lista de itens nao pode virar 500. */
    @Test
    void itemNuloNaListaRetorna400SemChamarServico() throws Exception {
        String jsonComItemNulo = """
                {
                  "userId": "u1",
                  "kioskId": "k1",
                  "itens": [null, {"menuItemId": "m1", "quantidade": 1}],
                  "formaPagamento": "PIX",
                  "embalagemSustentavel": false,
                  "pinCliente": {"latitude": -23.97, "longitude": -46.33},
                  "pontoReferenciaId": "rp1"
                }
                """;

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonComItemNulo))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.mensagem").value("Dados invalidos"))
                .andExpect(jsonPath("$.campos['itens[0]']").value("Item do pedido nao pode ser nulo"));

        verify(orderService, never()).criarPedido(any());
    }

    @Test
    void descricaoAcimaDe140Retorna400() throws Exception {
        CreateOrderRequest request = Fixtures.requestValido();
        request.setDescricaoLocal("x".repeat(141));

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos.descricaoLocal")
                        .value("A descricao do local deve ter no maximo 140 caracteres"));
    }

    @Test
    void latitudeForaDoIntervaloRetorna400() throws Exception {
        CreateOrderRequest request = Fixtures.requestValido();
        request.getPinCliente().setLatitude(91.0);

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos['pinCliente.latitude']")
                        .value("Latitude deve estar entre -90 e 90"));
    }

    @Test
    void longitudeForaDoIntervaloRetorna400() throws Exception {
        CreateOrderRequest request = Fixtures.requestValido();
        request.getPinCliente().setLongitude(-180.5);

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos['pinCliente.longitude']")
                        .value("Longitude deve estar entre -180 e 180"));
    }

    @Test
    void formaPagamentoInvalidaRetorna400Padronizado() throws Exception {
        String jsonInvalido = jsonValido().replace("\"PIX\"", "\"BOLETO\"");

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonInvalido))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.mensagem").value("Corpo da requisicao invalido ou malformado"));
    }

    // --- 404 e 422 propagados do servico ---

    @Test
    void usuarioInexistenteRetorna404Padronizado() throws Exception {
        when(orderService.criarPedido(any(CreateOrderRequest.class)))
                .thenThrow(new ResourceNotFoundException("Usuario nao encontrado: u1"));

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonValido()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.mensagem").value("Usuario nao encontrado: u1"));
    }

    @Test
    void recursoInativoRetorna422Padronizado() throws Exception {
        when(orderService.criarPedido(any(CreateOrderRequest.class)))
                .thenThrow(new BusinessRuleException("Quiosque inativo: k1"));

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonValido()))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.status").value(422))
                .andExpect(jsonPath("$.mensagem").value("Quiosque inativo: k1"));
    }

    @Test
    void itemIndisponivelRetorna422Padronizado() throws Exception {
        when(orderService.criarPedido(any(CreateOrderRequest.class)))
                .thenThrow(new BusinessRuleException("Item indisponivel no cardapio: m3"));

        mockMvc.perform(post()
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonValido()))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.mensagem").value("Item indisponivel no cardapio: m3"));
    }
}
