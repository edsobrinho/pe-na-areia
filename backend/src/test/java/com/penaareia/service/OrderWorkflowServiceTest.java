package com.penaareia.service;

import com.penaareia.dto.ConfirmDeliveryRequest;
import com.penaareia.model.Courier;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.OrderRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderWorkflowServiceTest {

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private CourierRepository courierRepository;

    private OrderWorkflowService service() {
        return new OrderWorkflowService(orderRepository, courierRepository, 60);
    }

    @Test
    void courierCanAcceptPreparedOrderAndStartsRoute() {
        Order order = orderAtStatus(OrderStatus.EM_PREPARO);
        Courier courier = new Courier();
        courier.setId("courier-1");
        courier.setStatus(Courier.CourierStatus.DISPONIVEL);
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(courierRepository.findById("courier-1")).thenReturn(Optional.of(courier));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Order updated = service().atualizarStatus(
                "order-1",
                OrderStatus.A_CAMINHO,
                "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER")));

        assertThat(updated.getCourierId()).isEqualTo("courier-1");
        assertThat(updated.getStatus()).isEqualTo(OrderStatus.A_CAMINHO);
        assertThat(courier.getStatus()).isEqualTo(Courier.CourierStatus.EM_ROTA);
    }

    @Test
    void courierCannotConfirmOutsideConfiguredRadius() {
        Order order = orderAtStatus(OrderStatus.A_CAMINHO);
        order.setCourierId("courier-1");
        order.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        Courier courier = new Courier();
        courier.setId("courier-1");
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(courierRepository.findById("courier-1")).thenReturn(Optional.of(courier));

        assertThatThrownBy(() -> service().confirmarEntrega(
                "order-1",
                new ConfirmDeliveryRequest("courier-1",
                        new ConfirmDeliveryRequest.CourierLocation(-23.97, -46.32)),
                "courier-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Aproxime-se");

        assertThat(order.getStatus()).isEqualTo(OrderStatus.A_CAMINHO);
    }

    @Test
    void courierWithinRadiusConfirmsDeliveryAndBecomesAvailable() {
        Order order = orderAtStatus(OrderStatus.A_CAMINHO);
        order.setCourierId("courier-1");
        order.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        Courier courier = new Courier();
        courier.setId("courier-1");
        courier.setStatus(Courier.CourierStatus.EM_ROTA);
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(courierRepository.findById("courier-1")).thenReturn(Optional.of(courier));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Order delivered = service().confirmarEntrega(
                "order-1",
                new ConfirmDeliveryRequest("courier-1",
                        new ConfirmDeliveryRequest.CourierLocation(-23.972, -46.328)),
                "courier-1");

        assertThat(delivered.getStatus()).isEqualTo(OrderStatus.ENTREGUE);
        assertThat(courier.getStatus()).isEqualTo(Courier.CourierStatus.DISPONIVEL);
        verify(courierRepository).save(courier);
    }

    private static Order orderAtStatus(OrderStatus status) {
        Order order = new Order();
        order.setId("order-1");
        order.setUserId("client-1");
        order.transitionTo(status);
        return order;
    }
}
