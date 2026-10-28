package com.penaareia.controller;

import com.penaareia.dto.PartnershipDtos;
import com.penaareia.model.Partnership;
import com.penaareia.service.ForbiddenException;
import com.penaareia.service.PartnershipService;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PartnershipControllerTest {

    private final PartnershipService service = mock(PartnershipService.class);
    private final PartnershipController controller = new PartnershipController(service);
    private final UsernamePasswordAuthenticationToken operator = new UsernamePasswordAuthenticationToken(
            "operator-1", null, List.of(new SimpleGrantedAuthority("ROLE_KIOSK_OPERATOR")));

    @Test
    void delegatesPublicPartnershipQueries() {
        List<Partnership> partnerships = List.of(new Partnership("p1", "APP", "APP", true));
        when(service.listActivePartnerships()).thenReturn(partnerships);
        when(service.listOffersForKiosk("k1")).thenReturn(List.of());

        assertThat(controller.listActive()).isSameAs(partnerships);
        assertThat(controller.listKioskOffers("k1")).isEmpty();
        verify(service).listOffersForKiosk("k1");
    }

    @Test
    void delegatesOperatorQueriesForAuthorizedUsers() {
        var response = new PartnershipDtos.PricingPreview(
                java.math.BigDecimal.ONE, java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO,
                java.math.BigDecimal.ZERO, com.penaareia.model.KioskPartnership.DeliveryFeePayer.CLIENT,
                java.math.BigDecimal.ONE, java.math.BigDecimal.ONE, "preview");
        var previewRequest = new PartnershipDtos.PreviewRequest(List.of(
                new PartnershipDtos.PreviewItemRequest("m1", 1)));
        when(service.preview("operator-1", "p1", previewRequest)).thenReturn(response);

        controller.listMine(operator);
        controller.updateMine("p1", null, operator);
        assertThat(controller.preview("p1", previewRequest, operator)).isSameAs(response);

        verify(service).listForOperator("operator-1");
        verify(service).updateForOperator("operator-1", "p1", null);
    }

    @Test
    void rejectsMissingOrNonOperatorAuthentication() {
        assertThatThrownBy(() -> controller.listMine(null)).isInstanceOf(ForbiddenException.class);
        var client = new UsernamePasswordAuthenticationToken(
                "client-1", null, List.of(new SimpleGrantedAuthority("ROLE_CLIENT")));
        assertThatThrownBy(() -> controller.listMine(client)).isInstanceOf(ForbiddenException.class);
    }
}
