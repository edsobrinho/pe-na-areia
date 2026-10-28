package com.penaareia.controller;

import com.penaareia.dto.KioskMenuDtos.CreateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.MenuItemAvailabilityRequest;
import com.penaareia.dto.KioskMenuDtos.UpdateMenuItemRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.service.ForbiddenException;
import com.penaareia.service.KioskService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class KioskMenuControllerTest {

    private final KioskService kioskService = mock(KioskService.class);
    private final KioskMenuController controller = new KioskMenuController(kioskService);
    private final UsernamePasswordAuthenticationToken operatorAuth = new UsernamePasswordAuthenticationToken(
            "operator-1", null, List.of(new SimpleGrantedAuthority("ROLE_KIOSK_OPERATOR")));
    private final UsernamePasswordAuthenticationToken clientAuth = new UsernamePasswordAuthenticationToken(
            "client-1", null, List.of(new SimpleGrantedAuthority("ROLE_CLIENT")));

    @Test
    void listRejeitaAcessoParaNaoOperador() {
        assertThatThrownBy(() -> controller.list(clientAuth))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void listDelegaParaServicoQuandoOperador() {
        List<Kiosk.MenuItem> menu = List.of(new Kiosk.MenuItem("item-1", "Açai", "500ml", new BigDecimal("18.00"), true));
        when(kioskService.listMenuForOperator("operator-1")).thenReturn(menu);

        List<Kiosk.MenuItem> result = controller.list(operatorAuth);

        assertThat(result).isSameAs(menu);
        verify(kioskService).listMenuForOperator("operator-1");
    }

    @Test
    void createAdicionaItemERetorna201() {
        CreateMenuItemRequest req = new CreateMenuItemRequest("Suco", "300ml", new BigDecimal("8.00"), true, "Bebidas", false, "https://foto.jpg");
        Kiosk.MenuItem criado = new Kiosk.MenuItem("item-2", "Suco", "300ml", new BigDecimal("8.00"), true, "Bebidas", false, "https://foto.jpg");
        when(kioskService.addMenuItem("operator-1", req)).thenReturn(criado);

        ResponseEntity<Kiosk.MenuItem> response = controller.create(req, operatorAuth);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(criado);
        verify(kioskService).addMenuItem("operator-1", req);
    }

    @Test
    void updateAtualizaItem() {
        UpdateMenuItemRequest req = new UpdateMenuItemRequest("Suco Natural", "300ml", new BigDecimal("9.00"), true, "Bebidas", false, "https://foto.jpg");
        Kiosk.MenuItem atualizado = new Kiosk.MenuItem("item-2", "Suco Natural", "300ml", new BigDecimal("9.00"), true, "Bebidas", false, "https://foto.jpg");
        when(kioskService.updateMenuItem("operator-1", "item-2", req)).thenReturn(atualizado);

        Kiosk.MenuItem result = controller.update("item-2", req, operatorAuth);

        assertThat(result).isSameAs(atualizado);
        verify(kioskService).updateMenuItem("operator-1", "item-2", req);
    }

    @Test
    void deleteRemoveItemERetorna204() {
        ResponseEntity<Void> response = controller.delete("item-2", operatorAuth);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(kioskService).deleteMenuItem("operator-1", "item-2");
    }

    @Test
    void setAvailabilityAlteraDisponibilidade() {
        MenuItemAvailabilityRequest req = new MenuItemAvailabilityRequest(false);
        Kiosk.MenuItem alterado = new Kiosk.MenuItem("item-2", "Suco", "300ml", new BigDecimal("8.00"), false);
        when(kioskService.setMenuItemAvailability("operator-1", "item-2", false)).thenReturn(alterado);

        Kiosk.MenuItem result = controller.setAvailability("item-2", req, operatorAuth);

        assertThat(result).isSameAs(alterado);
        verify(kioskService).setMenuItemAvailability("operator-1", "item-2", false);
    }
}

