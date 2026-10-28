package com.penaareia.controller;

import com.penaareia.dto.KioskMenuDtos.CreateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.MenuItemAvailabilityRequest;
import com.penaareia.dto.KioskMenuDtos.UpdateMenuItemRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.service.ForbiddenException;
import com.penaareia.service.KioskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping({"/kiosk/me/menu-items", "/kiosk/me/menu"})
@RequiredArgsConstructor
@Validated
@Tag(name = "Cardápio do Quiosque", description = "Gestão de itens do cardápio pelo operador do quiosque")
public class KioskMenuController {

    private final KioskService kioskService;

    @GetMapping
    @Operation(summary = "Lista todos os itens do cardápio do quiosque do operador autenticado")
    public List<Kiosk.MenuItem> list(Authentication authentication) {
        requireOperator(authentication);
        return kioskService.listMenuForOperator(authentication.getName());
    }

    @PostMapping
    @Operation(summary = "Cadastra um novo item no cardápio com foto opcional")
    public ResponseEntity<Kiosk.MenuItem> create(
            @Valid @RequestBody CreateMenuItemRequest request,
            Authentication authentication) {
        requireOperator(authentication);
        Kiosk.MenuItem created = kioskService.addMenuItem(authentication.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{itemId}")
    @Operation(summary = "Atualiza um item do cardápio")
    public Kiosk.MenuItem update(
            @PathVariable String itemId,
            @Valid @RequestBody UpdateMenuItemRequest request,
            Authentication authentication) {
        requireOperator(authentication);
        return kioskService.updateMenuItem(authentication.getName(), itemId, request);
    }

    @DeleteMapping("/{itemId}")
    @Operation(summary = "Remove um item do cardápio")
    public ResponseEntity<Void> delete(
            @PathVariable String itemId,
            Authentication authentication) {
        requireOperator(authentication);
        kioskService.deleteMenuItem(authentication.getName(), itemId);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{itemId}/availability")
    @Operation(summary = "Altera a disponibilidade de um item do cardápio (pausar/ativar venda)")
    public Kiosk.MenuItem setAvailability(
            @PathVariable String itemId,
            @RequestBody MenuItemAvailabilityRequest request,
            Authentication authentication) {
        requireOperator(authentication);
        return kioskService.setMenuItemAvailability(authentication.getName(), itemId, request.disponivel());
    }

    private static void requireOperator(Authentication authentication) {
        if (authentication == null || authentication.getAuthorities().stream()
                .noneMatch(authority -> "ROLE_KIOSK_OPERATOR".equals(authority.getAuthority()))) {
            throw new ForbiddenException("Esta operação não está disponível para o seu perfil.");
        }
    }
}
