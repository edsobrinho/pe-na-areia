package com.penaareia.service;

import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.model.Order;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.OrderRepository;
import com.penaareia.repository.ReferencePointRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.support.Fixtures;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes de unidade do OrderService: validacao em cascata (existencia e
 * atividade de usuario/quiosque/posto, itens do cardapio, quantidade),
 * total calculado no servidor e conversao do pin para GeoJsonPoint.
 * Nenhum acesso a banco (Atlas) ou seeder.
 */
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private KioskRepository kioskRepository;
    @Mock
    private ReferencePointRepository referencePointRepository;

    @InjectMocks
    private OrderService service;

    private void stubFluxoValido() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.of(Fixtures.usuarioAtivo()));
        when(kioskRepository.findById(Fixtures.KIOSK_ID)).thenReturn(Optional.of(Fixtures.kioskAtivo()));
        when(referencePointRepository.findById(Fixtures.POSTO_ID)).thenReturn(Optional.of(Fixtures.postoAtivo()));
    }

    private void stubSave() {
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    // --- Caminho feliz ---

    @Test
    void criaPedidoValidoCalculaTotalNoServidor() {
        stubFluxoValido();
        stubSave();

        Order pedido = service.criarPedido(Fixtures.requestValido());

        // 2 x 12.50 + 1 x 7.25 = 32.25, com escala de moeda
        assertThat(pedido.getValorTotal()).isEqualByComparingTo(new BigDecimal("32.25"));
        assertThat(pedido.getValorTotal().scale()).isEqualTo(2);

        // Ids vem das entidades validadas, nunca do texto cru da requisicao
        assertThat(pedido.getUserId()).isEqualTo(Fixtures.USER_ID);
        assertThat(pedido.getKioskId()).isEqualTo(Fixtures.KIOSK_ID);
        assertThat(pedido.getPontoReferenciaId()).isEqualTo(Fixtures.POSTO_ID);

        // Itens copiam nome e preco do cardapio do quiosque
        assertThat(pedido.getItens()).hasSize(2);
        assertThat(pedido.getItens().get(0).getMenuItemId()).isEqualTo(Fixtures.MENU_ITEM_DISPONIVEL);
        assertThat(pedido.getItens().get(0).getNome()).isEqualTo("Agua de coco");
        assertThat(pedido.getItens().get(0).getQuantidade()).isEqualTo(2);
        assertThat(pedido.getItens().get(0).getPrecoUnitario())
                .isEqualByComparingTo(Fixtures.PRECO_DISPONIVEL);

        assertThat(pedido.isEmbalagemSustentavel()).isTrue();
        assertThat(pedido.getDescricaoLocal()).isEqualTo("Guarda-sol listrado azul");
        assertThat(pedido.isPago()).isTrue();
        assertThat(pedido.getStatus()).isEqualTo(
                com.penaareia.model.OrderStatus.EM_PREPARO);
        assertThat(pedido.getTimeline().getPagoEm()).isNotNull();
        assertThat(pedido.getTimeline().getEmPreparoEm()).isNotNull();

        verify(orderRepository).save(any(Order.class));
    }

    @Test
    void pinClienteViraGeoJsonPointComLongitudeLatitude() {
        stubFluxoValido();
        stubSave();

        Order pedido = service.criarPedido(Fixtures.requestValido());

        assertThat(pedido.getPinCliente()).isNotNull();
        assertThat(pedido.getPinCliente().getX()).isEqualTo(Fixtures.LONGITUDE);
        assertThat(pedido.getPinCliente().getY()).isEqualTo(Fixtures.LATITUDE);
        assertThat(pedido.getPinCliente().getCoordinates())
                .isEqualTo(List.of(Fixtures.LONGITUDE, Fixtures.LATITUDE));
    }

    @Test
    void pinMaisDeQuinhentosMetrosDoPostoEhRejeitado() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setPinCliente(Fixtures.pin(-23.97, -46.30));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("500 m");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void buscarPorIdExistenteRetornaPedido() {
        when(orderRepository.findById("o1")).thenReturn(Optional.of(Fixtures.orderEntity()));

        Order pedido = service.buscarPorId("o1");

        assertThat(pedido.getId()).isEqualTo("o1");
    }

    // --- Ausencias (404) ---

    @Test
    void buscarPorIdInexistenteLanca404() {
        when(orderRepository.findById("o99")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.buscarPorId("o99"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("o99");
    }

    @Test
    void usuarioInexistenteLanca404SemSalvar() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.criarPedido(Fixtures.requestValido()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Usuario");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void quiosqueInexistenteLanca404SemSalvar() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.of(Fixtures.usuarioAtivo()));
        when(kioskRepository.findById(Fixtures.KIOSK_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.criarPedido(Fixtures.requestValido()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Quiosque");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void postoInexistenteLanca404SemSalvar() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.of(Fixtures.usuarioAtivo()));
        when(kioskRepository.findById(Fixtures.KIOSK_ID)).thenReturn(Optional.of(Fixtures.kioskAtivo()));
        when(referencePointRepository.findById(Fixtures.POSTO_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.criarPedido(Fixtures.requestValido()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Posto de referencia");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void itemForaDoCardapioLanca404SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(List.of(Fixtures.item("m-inexistente", 1)));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("m-inexistente");
        verify(orderRepository, never()).save(any());
    }

    // --- Recursos inativos (422) ---

    @Test
    void usuarioInativoLanca422SemSalvar() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.of(Fixtures.usuarioInativo()));

        assertThatThrownBy(() -> service.criarPedido(Fixtures.requestValido()))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Usuario inativo");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void quiosqueInativoLanca422SemSalvar() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.of(Fixtures.usuarioAtivo()));
        when(kioskRepository.findById(Fixtures.KIOSK_ID)).thenReturn(Optional.of(Fixtures.kioskInativo()));

        assertThatThrownBy(() -> service.criarPedido(Fixtures.requestValido()))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Quiosque inativo");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void postoInativoLanca422SemSalvar() {
        when(userRepository.findById(Fixtures.USER_ID)).thenReturn(Optional.of(Fixtures.usuarioAtivo()));
        when(kioskRepository.findById(Fixtures.KIOSK_ID)).thenReturn(Optional.of(Fixtures.kioskAtivo()));
        when(referencePointRepository.findById(Fixtures.POSTO_ID)).thenReturn(Optional.of(Fixtures.postoInativo()));

        assertThatThrownBy(() -> service.criarPedido(Fixtures.requestValido()))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Posto de referencia inativo");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void itemIndisponivelLanca422SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(List.of(Fixtures.item(Fixtures.MENU_ITEM_INDISPONIVEL, 1)));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Item indisponivel");
        verify(orderRepository, never()).save(any());
    }

    // --- Quantidade e pin invalidos (400) ---

    @Test
    void quantidadeZeroLanca400SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(List.of(Fixtures.item(Fixtures.MENU_ITEM_DISPONIVEL, 0)));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("Quantidade");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void quantidadeNegativaLanca400SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(List.of(Fixtures.item(Fixtures.MENU_ITEM_DISPONIVEL, -3)));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("Quantidade");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void quantidadeNulaLanca400SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(List.of(Fixtures.item(Fixtures.MENU_ITEM_DISPONIVEL, null)));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("Quantidade");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void itemNuloLanca400SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(Collections.singletonList(null));

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("nulos");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void pedidoSemItensLanca400SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setItens(List.of());

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("ao menos um item");
        verify(orderRepository, never()).save(any());
    }

    @Test
    void pedidoSemPinLanca400SemSalvar() {
        stubFluxoValido();
        CreateOrderRequest request = Fixtures.requestValido();
        request.setPinCliente(null);

        assertThatThrownBy(() -> service.criarPedido(request))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("pin");
        verify(orderRepository, never()).save(any());
    }
}
