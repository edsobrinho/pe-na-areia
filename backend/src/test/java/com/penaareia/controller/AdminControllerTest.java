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
}
