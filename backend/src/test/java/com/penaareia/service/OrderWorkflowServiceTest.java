package com.penaareia.service;

import com.penaareia.dto.ConfirmDeliveryRequest;
import com.penaareia.dto.OrderCursor;
import com.penaareia.model.Courier;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.OrderRepository;
import com.mongodb.client.result.UpdateResult;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderWorkflowServiceTest {

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private CourierRepository courierRepository;
    @Mock
    private MongoTemplate mongoTemplate;

    private OrderWorkflowService service() {
        return new OrderWorkflowService(orderRepository, courierRepository, mongoTemplate, 60);
    }

    @Test
    void courierCanAcceptPreparedOrderAndStartsRoute() {
        Order order = orderAtStatus(OrderStatus.EM_PREPARO);
        Order claimedOrder = orderAtStatus(OrderStatus.A_CAMINHO);
        claimedOrder.setCourierId("courier-1");
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(claimedOrder);
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(Courier.class)))
                .thenReturn(UpdateResult.acknowledged(1, 1L, null));

        Order updated = service().atualizarStatus(
                "order-1",
                OrderStatus.A_CAMINHO,
                "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER")));

        assertThat(updated.getCourierId()).isEqualTo("courier-1");
        assertThat(updated.getStatus()).isEqualTo(OrderStatus.A_CAMINHO);
        ArgumentCaptor<Query> orderQuery = ArgumentCaptor.forClass(Query.class);
        verify(mongoTemplate).findAndModify(orderQuery.capture(), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class));
        assertThat(orderQuery.getValue().getQueryObject())
                .containsEntry("id", "order-1")
                .containsEntry("status", OrderStatus.EM_PREPARO)
                .containsEntry("courierId", null);
        verify(mongoTemplate).updateFirst(any(Query.class), any(Update.class), eq(Courier.class));
    }

    @Test
    void concurrentCourierClaimFailureDoesNotUpdateOrder() {
        Order order = orderAtStatus(OrderStatus.EM_PREPARO);
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(null);

        assertThatThrownBy(() -> service().atualizarStatus(
                "order-1",
                OrderStatus.A_CAMINHO,
                "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("aceito por outro");

        verify(mongoTemplate, never()).updateFirst(any(Query.class), any(Update.class), eq(Courier.class));
    }

    @Test
    void unavailableCourierCannotKeepClaimedOrder() {
        Order order = orderAtStatus(OrderStatus.EM_PREPARO);
        Order claimedOrder = orderAtStatus(OrderStatus.A_CAMINHO);
        claimedOrder.setCourierId("courier-1");
        Courier courier = new Courier();
        courier.setId("courier-1");
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(claimedOrder);
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(Courier.class)))
                .thenReturn(UpdateResult.acknowledged(0, 0L, null));
        when(courierRepository.findById("courier-1")).thenReturn(Optional.of(courier));

        assertThatThrownBy(() -> service().atualizarStatus(
                "order-1",
                OrderStatus.A_CAMINHO,
                "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("disponível");

        verify(mongoTemplate).findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class));
        verify(mongoTemplate).updateFirst(any(Query.class), any(Update.class), eq(Courier.class));
    }

    @Test
    void courierCannotConfirmOutsideConfiguredRadius() {
        Order order = orderAtStatus(OrderStatus.A_CAMINHO);
        order.setCourierId("courier-1");
        order.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));

        assertThatThrownBy(() -> service().confirmarEntrega(
                "order-1",
                new ConfirmDeliveryRequest("courier-1",
                        new ConfirmDeliveryRequest.CourierLocation(-23.97, -46.32)),
                "courier-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Aproxime-se");

        assertThat(order.getStatus()).isEqualTo(OrderStatus.A_CAMINHO);
        verify(mongoTemplate, never()).findAndModify(
                any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(Order.class));
    }

    @Test
    void courierWithinRadiusConfirmsDeliveryAndBecomesAvailable() {
        Order order = orderAtStatus(OrderStatus.A_CAMINHO);
        order.setCourierId("courier-1");
        order.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        Order deliveredOrder = orderAtStatus(OrderStatus.ENTREGUE);
        deliveredOrder.setCourierId("courier-1");
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(deliveredOrder);
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(Courier.class)))
                .thenReturn(UpdateResult.acknowledged(1, 1L, null));

        Order delivered = service().confirmarEntrega(
                "order-1",
                new ConfirmDeliveryRequest("courier-1",
                        new ConfirmDeliveryRequest.CourierLocation(-23.972, -46.328)),
                "courier-1");

        assertThat(delivered.getStatus()).isEqualTo(OrderStatus.ENTREGUE);
        verify(mongoTemplate).findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class));
        verify(mongoTemplate).updateFirst(any(Query.class), any(Update.class), eq(Courier.class));
    }

    @Test
    void cursorListFetchesOneExtraItemAndReturnsCursorForNextSlice() {
        Order first = orderWithDate("order-3", Instant.parse("2026-10-22T10:00:00Z"));
        Order second = orderWithDate("order-2", Instant.parse("2026-10-22T09:00:00Z"));
        Order extra = orderWithDate("order-1", Instant.parse("2026-10-22T08:00:00Z"));
        when(mongoTemplate.find(any(Query.class), eq(Order.class))).thenReturn(List.of(first, second, extra));

        var slice = service().listarDisponiveis(2, null);

        assertThat(slice.orders()).containsExactly(first, second);
        assertThat(slice.nextCursor()).isEqualTo(OrderCursor.encode(second));
        ArgumentCaptor<Query> query = ArgumentCaptor.forClass(Query.class);
        verify(mongoTemplate).find(query.capture(), eq(Order.class));
        assertThat(query.getValue().getLimit()).isEqualTo(3);
        assertThat(query.getValue().getSortObject()).containsEntry("timeline.criadoEm", -1);
        assertThat(query.getValue().getSortObject()).containsEntry("id", -1);
    }

    @Test
    void cursorIsAppliedAsSeekCriteria() {
        Order lastOrder = orderWithDate("order-2", Instant.parse("2026-10-22T09:00:00Z"));
        String cursor = OrderCursor.encode(lastOrder);
        when(mongoTemplate.find(any(Query.class), eq(Order.class))).thenReturn(List.of());

        service().listarDisponiveis(50, cursor);

        ArgumentCaptor<Query> query = ArgumentCaptor.forClass(Query.class);
        verify(mongoTemplate).find(query.capture(), eq(Order.class));
        assertThat(query.getValue().getQueryObject()).containsKey("$or");
    }

    @Test
    void invalidPageSizeIsRejectedBeforeQuery() {
        assertThatThrownBy(() -> service().listarDisponiveis(101, null))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("entre 1 e 100");
        assertThatThrownBy(() -> service().listarDisponiveis(0, null))
                .isInstanceOf(InvalidRequestException.class);
        verify(mongoTemplate, never()).find(any(Query.class), eq(Order.class));
    }

    @Test
    void invalidCursorIsRejectedBeforeQuery() {
        assertThatThrownBy(() -> service().listarDisponiveis(50, "not-a-valid-cursor"))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("Cursor");
        verify(mongoTemplate, never()).find(any(Query.class), eq(Order.class));
    }

    @Test
    void clientCanPayOwnOrderButCannotChangeAnotherUsersOrder() {
        Order order = orderAtStatus(OrderStatus.CRIADO);
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(orderRepository.save(order)).thenReturn(order);

        assertThat(service().atualizarStatus(
                "order-1", OrderStatus.PAGO, "client-1",
                List.of(new SimpleGrantedAuthority("ROLE_CLIENT"))).getStatus())
                .isEqualTo(OrderStatus.PAGO);

        Order otherOrder = orderAtStatus(OrderStatus.CRIADO);
        when(orderRepository.findById("other")).thenReturn(Optional.of(otherOrder));
        assertThatThrownBy(() -> service().atualizarStatus(
                "other", OrderStatus.PAGO, "another-client",
                List.of(new SimpleGrantedAuthority("ROLE_CLIENT"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Somente o cliente");
    }

    @Test
    void rejectsInvalidTransitionsAndUnauthorizedCourierTransitions() {
        Order created = orderAtStatus(OrderStatus.CRIADO);
        when(orderRepository.findById("created")).thenReturn(Optional.of(created));
        assertThatThrownBy(() -> service().atualizarStatus(
                "created", OrderStatus.ENTREGUE, "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Transição inválida");

        Order inRoute = orderAtStatus(OrderStatus.A_CAMINHO);
        inRoute.setCourierId("courier-1");
        when(orderRepository.findById("route")).thenReturn(Optional.of(inRoute));
        assertThatThrownBy(() -> service().atualizarStatus(
                "route", OrderStatus.CHEGOU_NO_LOCAL, "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_CLIENT"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Somente um entregador");

        Order assignedElsewhere = orderAtStatus(OrderStatus.EM_PREPARO);
        assignedElsewhere.setCourierId("courier-2");
        when(orderRepository.findById("assigned")).thenReturn(Optional.of(assignedElsewhere));
        assertThatThrownBy(() -> service().atualizarStatus(
                "assigned", OrderStatus.A_CAMINHO, "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("outro entregador");
    }

    @Test
    void courierCanMarkArrivalOnlyForTheirOwnOrder() {
        Order order = orderAtStatus(OrderStatus.A_CAMINHO);
        order.setCourierId("courier-1");
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(orderRepository.save(order)).thenReturn(order);

        assertThat(service().atualizarStatus(
                "order-1", OrderStatus.CHEGOU_NO_LOCAL, "courier-1",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))).getStatus())
                .isEqualTo(OrderStatus.CHEGOU_NO_LOCAL);

        Order unassigned = orderAtStatus(OrderStatus.A_CAMINHO);
        when(orderRepository.findById("unassigned")).thenReturn(Optional.of(unassigned));
        assertThatThrownBy(() -> service().atualizarStatus(
                "unassigned", OrderStatus.CHEGOU_NO_LOCAL, "courier-2",
                List.of(new SimpleGrantedAuthority("ROLE_COURIER"))))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("não pertence");
    }

    @Test
    void confirmsDeliveryOnlyForMatchingCourierAndActiveRoute() {
        ConfirmDeliveryRequest validRequest = new ConfirmDeliveryRequest(
                "courier-1", new ConfirmDeliveryRequest.CourierLocation(-23.972, -46.328));
        assertThatThrownBy(() -> service().confirmarEntrega("missing", validRequest, "courier-2"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("não corresponde");

        Order created = orderAtStatus(OrderStatus.CRIADO);
        when(orderRepository.findById("created")).thenReturn(Optional.of(created));
        assertThatThrownBy(() -> service().confirmarEntrega("created", validRequest, "courier-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("a caminho");

        Order assigned = orderAtStatus(OrderStatus.A_CAMINHO);
        assigned.setCourierId("courier-2");
        assigned.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        when(orderRepository.findById("assigned")).thenReturn(Optional.of(assigned));
        assertThatThrownBy(() -> service().confirmarEntrega("assigned", validRequest, "courier-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("não pertence");
    }

    @Test
    void concurrentDeliveryConfirmationAndUnavailableCourierAreRejected() {
        Order order = orderAtStatus(OrderStatus.CHEGOU_NO_LOCAL);
        order.setCourierId("courier-1");
        order.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(null);
        var request = new ConfirmDeliveryRequest(
                "courier-1", new ConfirmDeliveryRequest.CourierLocation(-23.972, -46.328));

        assertThatThrownBy(() -> service().confirmarEntrega("order-1", request, "courier-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("já foi confirmado");
    }

    @Test
    void deliveryFailureHandlesMissingAndNonRoutedCouriers() {
        Order order = orderAtStatus(OrderStatus.A_CAMINHO);
        order.setCourierId("courier-1");
        order.setPinCliente(new GeoJsonPoint(-46.328, -23.972));
        var request = new ConfirmDeliveryRequest(
                "courier-1", new ConfirmDeliveryRequest.CourierLocation(-23.972, -46.328));
        when(orderRepository.findById("order-1")).thenReturn(Optional.of(order));
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class),
                any(FindAndModifyOptions.class), eq(Order.class))).thenReturn(order);
        when(mongoTemplate.updateFirst(any(Query.class), any(Update.class), eq(Courier.class)))
                .thenReturn(UpdateResult.acknowledged(0, 0L, null));
        when(courierRepository.findById("courier-1")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service().confirmarEntrega("order-1", request, "courier-1"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Entregador não encontrado");

        when(courierRepository.findById("courier-1")).thenReturn(Optional.of(new Courier()));
        assertThatThrownBy(() -> service().confirmarEntrega("order-1", request, "courier-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("não está em rota");
    }

    @Test
    void listsCurrentCourierOrdersWithoutCreatingNextCursorForExactPage() {
        Order first = orderWithDate("order-2", Instant.parse("2026-10-22T09:00:00Z"));
        Order second = orderWithDate("order-1", Instant.parse("2026-10-22T08:00:00Z"));
        when(mongoTemplate.find(any(Query.class), eq(Order.class))).thenReturn(List.of(first, second));

        var slice = service().listarEmRota("courier-1", 2, null);

        assertThat(slice.orders()).containsExactly(first, second);
        assertThat(slice.nextCursor()).isNull();
        verify(mongoTemplate).find(any(Query.class), eq(Order.class));
    }

    private static Order orderAtStatus(OrderStatus status) {
        Order order = new Order();
        order.setId("order-1");
        order.setUserId("client-1");
        order.transitionTo(status);
        return order;
    }

    private static Order orderWithDate(String id, Instant createdAt) {
        Order order = orderAtStatus(OrderStatus.EM_PREPARO);
        order.setId(id);
        order.getTimeline().setCriadoEm(createdAt);
        return order;
    }
}
