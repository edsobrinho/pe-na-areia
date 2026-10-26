package com.penaareia.controller;

import com.penaareia.dto.PartnershipDtos.ConfigurationRequest;
import com.penaareia.dto.PartnershipDtos.OfferResponse;
import com.penaareia.dto.PartnershipDtos.OperatorPartnershipResponse;
import com.penaareia.dto.PartnershipDtos.PricingPreview;
import com.penaareia.dto.PartnershipDtos.PreviewRequest;
import com.penaareia.model.Partnership;
import com.penaareia.service.ForbiddenException;
import com.penaareia.service.PartnershipService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Tag(name = "Parcerias", description = "Canais de venda e ofertas por quiosque")
public class PartnershipController {

    private final PartnershipService partnershipService;

    @GetMapping("/partnerships")
    @Operation(summary = "Lista canais de venda ativos")
    public List<Partnership> listActive() {
        return partnershipService.listActivePartnerships();
    }

    @GetMapping("/kiosks/{kioskId}/partnerships")
    @Operation(summary = "Lista ofertas de parceria de um quiosque")
    public List<OfferResponse> listKioskOffers(@PathVariable String kioskId) {
        return partnershipService.listOffersForKiosk(kioskId);
    }

    @GetMapping("/kiosk/me/partnerships")
    @Operation(summary = "Lista parcerias disponíveis para o quiosque do operador")
    public List<OperatorPartnershipResponse> listMine(Authentication authentication) {
        requireRole(authentication, "ROLE_KIOSK_OPERATOR");
        return partnershipService.listForOperator(authentication.getName());
    }

    @PutMapping("/kiosk/me/partnerships/{partnershipId}")
    @Operation(summary = "Atualiza filtros, taxas e restrições de uma parceria")
    public OperatorPartnershipResponse updateMine(
            @PathVariable String partnershipId,
            @Valid @RequestBody ConfigurationRequest request,
            Authentication authentication) {
        requireRole(authentication, "ROLE_KIOSK_OPERATOR");
        return partnershipService.updateForOperator(authentication.getName(), partnershipId, request);
    }

    @PostMapping("/kiosk/me/partnerships/{partnershipId}/preview")
    @Operation(summary = "Calcula uma prévia de valores sem criar pedido ou cobrar pagamento")
    public PricingPreview preview(
            @PathVariable String partnershipId,
            @Valid @RequestBody PreviewRequest request,
            Authentication authentication) {
        requireRole(authentication, "ROLE_KIOSK_OPERATOR");
        return partnershipService.preview(authentication.getName(), partnershipId, request);
    }

    private static void requireRole(Authentication authentication, String role) {
        if (authentication == null || authentication.getAuthorities().stream()
                .noneMatch(authority -> role.equals(authority.getAuthority()))) {
            throw new ForbiddenException("Esta operação não está disponível para o seu perfil.");
        }
    }
}
