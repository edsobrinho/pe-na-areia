package com.penaareia.controller;

import com.penaareia.model.User;
import com.penaareia.model.Partnership;
import com.penaareia.service.AdminService;
import com.penaareia.service.ForbiddenException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@Validated
@RequestMapping("/admin")
public class AdminController {

    private final AdminService adminService;

    @PatchMapping("/kiosk-operators")
    public OperatorAssignmentResponse assignOperator(
            @Valid @RequestBody OperatorAssignmentRequest request,
            Authentication authentication) {
        if (authentication == null || authentication.getAuthorities().stream()
                .noneMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()))) {
            throw new ForbiddenException("Somente administradores podem atribuir operadores.");
        }
        User operator = adminService.assignKioskOperator(request.email(), request.kioskId());
        return new OperatorAssignmentResponse(operator.getId(), operator.getEmail(), operator.getKioskId());
    }

    @PostMapping("/partnerships")
    public Partnership createPartnership(
            @Valid @RequestBody CreatePartnershipRequest request,
            Authentication authentication) {
        requireAdmin(authentication);
        return adminService.createPartnership(request.name(), request.channel());
    }

    @PutMapping("/partnerships/{partnershipId}")
    public Partnership updatePartnership(
            @PathVariable String partnershipId,
            @Valid @RequestBody UpdatePartnershipRequest request,
            Authentication authentication) {
        requireAdmin(authentication);
        return adminService.setPartnershipActive(partnershipId, request.active());
    }

    private static void requireAdmin(Authentication authentication) {
        if (authentication == null || authentication.getAuthorities().stream()
                .noneMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()))) {
            throw new ForbiddenException("Somente administradores podem gerenciar canais.");
        }
    }

    public record OperatorAssignmentRequest(@NotBlank @Email String email, @NotBlank String kioskId) {
    }

    public record OperatorAssignmentResponse(String userId, String email, String kioskId) {
    }

    public record CreatePartnershipRequest(
            @NotBlank @jakarta.validation.constraints.Size(max = 100) String name,
            @NotBlank @jakarta.validation.constraints.Size(max = 50) String channel) {
    }

    public record UpdatePartnershipRequest(boolean active) {
    }
}
