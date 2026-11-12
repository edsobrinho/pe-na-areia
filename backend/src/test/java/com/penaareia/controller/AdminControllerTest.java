package com.penaareia.controller;

import com.penaareia.model.Partnership;
import com.penaareia.model.User;
import com.penaareia.service.AdminService;
import com.penaareia.service.ForbiddenException;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AdminControllerTest {

    private final AdminService service = mock(AdminService.class);
    private final AdminController controller = new AdminController(service);
    private final UsernamePasswordAuthenticationToken admin = new UsernamePasswordAuthenticationToken(
            "admin-1", null, List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));

    @Test
    void assignsOperatorAndReturnsAssignmentFields() {
        User user = new User();
        user.setId("user-1");
        user.setEmail("operator@example.test");
        user.setKioskId("kiosk-1");
        when(service.assignKioskOperator("operator@example.test", "kiosk-1")).thenReturn(user);

        AdminController.OperatorAssignmentResponse result = controller.assignOperator(
                new AdminController.OperatorAssignmentRequest("operator@example.test", "kiosk-1"), admin);

        assertThat(result.userId()).isEqualTo("user-1");
        assertThat(result.email()).isEqualTo("operator@example.test");
        assertThat(result.kioskId()).isEqualTo("kiosk-1");
    }

    @Test
    void rejectsMissingOrNonAdminAuthentication() {
        var request = new AdminController.OperatorAssignmentRequest("operator@example.test", "kiosk-1");
        assertThatThrownBy(() -> controller.assignOperator(request, null))
                .isInstanceOf(ForbiddenException.class);
        var client = new UsernamePasswordAuthenticationToken(
                "client-1", null, List.of(new SimpleGrantedAuthority("ROLE_CLIENT")));
        assertThatThrownBy(() -> controller.assignOperator(request, client))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> controller.createPartnership(
                new AdminController.CreatePartnershipRequest("Canal", "APP"), null))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void createsAndUpdatesPartnershipForAdmin() {
        Partnership created = new Partnership("p-1", "Canal", "APP", true);
        Partnership updated = new Partnership("p-1", "Canal", "APP", false);
        when(service.createPartnership("Canal", "APP")).thenReturn(created);
        when(service.setPartnershipActive("p-1", false)).thenReturn(updated);

        assertThat(controller.createPartnership(
                new AdminController.CreatePartnershipRequest("Canal", "APP"), admin)).isSameAs(created);
        assertThat(controller.updatePartnership(
                "p-1", new AdminController.UpdatePartnershipRequest(false), admin)).isSameAs(updated);
        verify(service).setPartnershipActive("p-1", false);
    }

    @Test
    void setsDestaquePopularForAdmin() {
        com.penaareia.service.KioskService kioskService = mock(com.penaareia.service.KioskService.class);
        AdminController adminControllerWithKiosk = new AdminController(service, kioskService);
        com.penaareia.model.Kiosk kiosk = new com.penaareia.model.Kiosk();
        kiosk.setId("kiosk-1");
        kiosk.setDestaquePopular(true);
        when(kioskService.setDestaquePopular("kiosk-1", true)).thenReturn(kiosk);

        com.penaareia.model.Kiosk res = adminControllerWithKiosk.setDestaquePopular(
                "kiosk-1", new AdminController.DestaquePopularRequest(true), admin);
        assertThat(res.isDestaquePopular()).isTrue();
    }

    @Test
    void setsDestaquePopularThrowsIfKioskServiceNotConfigured() {
        AdminController adminControllerNoKiosk = new AdminController(service);
        assertThatThrownBy(() -> adminControllerNoKiosk.setDestaquePopular(
                "kiosk-1", new AdminController.DestaquePopularRequest(true), admin))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("KioskService não configurado");
    }

    @Test
    void getPlatformMetricsWhenOrderRepositoryNullReturnsDefaults() {
        AdminController adminControllerNoRepo = new AdminController(service);
        var metrics = adminControllerNoRepo.getPlatformMetrics(admin);
        assertThat(metrics.totalOrders()).isEqualTo(0);
        assertThat(metrics.totalDelivered()).isEqualTo(0);
    }

    @Test
    void getPlatformMetricsComputesCorrectAggregations() {
        com.penaareia.repository.OrderRepository orderRepo = mock(com.penaareia.repository.OrderRepository.class);
        AdminController adminControllerWithRepo = new AdminController(service, null, orderRepo);

        com.penaareia.model.Order o1 = new com.penaareia.model.Order();
        o1.setStatus(com.penaareia.model.OrderStatus.ENTREGUE);
        o1.setAvaliacao(new com.penaareia.model.Order.OrderReview(4, 5, "Ótimo"));

        com.penaareia.model.Order o2 = new com.penaareia.model.Order();
        o2.setStatus(com.penaareia.model.OrderStatus.A_CAMINHO);

        when(orderRepo.count()).thenReturn(2L);
        when(orderRepo.findAll()).thenReturn(List.of(o1, o2));
        when(orderRepo.findByAvaliacaoIsNotNull()).thenReturn(List.of(o1));

        var metrics = adminControllerWithRepo.getPlatformMetrics(admin);
        assertThat(metrics.totalOrders()).isEqualTo(2);
        assertThat(metrics.totalDelivered()).isEqualTo(1);
        assertThat(metrics.totalReviews()).isEqualTo(1);
        assertThat(metrics.averageFoodRating()).isEqualByComparingTo("4.0");
        assertThat(metrics.averageDeliveryRating()).isEqualByComparingTo("5.0");
    }

    @Test
    void getRecentReviewsWhenOrderRepositoryNullReturnsEmpty() {
        AdminController adminControllerNoRepo = new AdminController(service);
        assertThat(adminControllerNoRepo.getRecentReviews(admin)).isEmpty();
    }

    @Test
    void getRecentReviewsReturnsMappedReviews() {
        com.penaareia.repository.OrderRepository orderRepo = mock(com.penaareia.repository.OrderRepository.class);
        AdminController adminControllerWithRepo = new AdminController(service, null, orderRepo);

        com.penaareia.model.Order o1 = new com.penaareia.model.Order();
        o1.setId("ord-rev-1");
        o1.setAvaliacao(new com.penaareia.model.Order.OrderReview(5, 5, "Perfeito"));

        when(orderRepo.findByAvaliacaoIsNotNull()).thenReturn(List.of(o1));

        var reviews = adminControllerWithRepo.getRecentReviews(admin);
        assertThat(reviews).hasSize(1);
        assertThat(reviews.get(0).getId()).isEqualTo("ord-rev-1");
    }

    @Test
    void nonAdminRejectedFromAllAdminEndpoints() {
        var client = new UsernamePasswordAuthenticationToken(
                "client-1", null, List.of(new SimpleGrantedAuthority("ROLE_CLIENT")));

        assertThatThrownBy(() -> controller.updatePartnership("p-1", new AdminController.UpdatePartnershipRequest(true), client))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> controller.setDestaquePopular("k-1", new AdminController.DestaquePopularRequest(true), client))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> controller.getPlatformMetrics(client))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> controller.getRecentReviews(client))
                .isInstanceOf(ForbiddenException.class);
    }
}
