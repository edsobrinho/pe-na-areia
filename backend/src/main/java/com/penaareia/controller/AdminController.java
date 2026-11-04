package com.penaareia.controller;

import com.penaareia.dto.OrderResponse;
import com.penaareia.dto.PlatformMetricsResponse;
import com.penaareia.model.Kiosk;
import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import com.penaareia.model.User;
import com.penaareia.model.Partnership;
import com.penaareia.repository.OrderRepository;
import com.penaareia.service.AdminService;
import com.penaareia.service.ForbiddenException;
import com.penaareia.service.KioskService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;

@RestController
@Validated
@RequestMapping("/admin")
public class AdminController {

    private final AdminService adminService;
    private final KioskService kioskService;
    private final OrderRepository orderRepository;

    public AdminController(AdminService adminService) {
        this(adminService, null, null);
    }

    public AdminController(AdminService adminService, KioskService kioskService) {
        this(adminService, kioskService, null);
    }

    @Autowired
    public AdminController(AdminService adminService,
                           @Autowired(required = false) KioskService kioskService,
                           @Autowired(required = false) OrderRepository orderRepository) {
        this.adminService = adminService;
        this.kioskService = kioskService;
        this.orderRepository = orderRepository;
    }

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

    @PatchMapping("/kiosks/{id}/destaque-popular")
    public Kiosk setDestaquePopular(
            @PathVariable String id,
            @Valid @RequestBody DestaquePopularRequest request,
            Authentication authentication) {
        requireAdmin(authentication);
        if (kioskService == null) {
            throw new IllegalStateException("KioskService não configurado.");
        }
        return kioskService.setDestaquePopular(id, request.destaquePopular());
    }

    @GetMapping("/metrics")
    public PlatformMetricsResponse getPlatformMetrics(Authentication authentication) {
        requireAdmin(authentication);
        if (orderRepository == null) {
            return new PlatformMetricsResponse(0, 0, BigDecimal.valueOf(5.0), BigDecimal.valueOf(5.0), 0);
        }
        long totalOrders = orderRepository.count();
        List<Order> reviews = orderRepository.findByAvaliacaoIsNotNull();
        long totalDelivered = orderRepository.findAll().stream()
                .filter(o -> o.getStatus() == OrderStatus.ENTREGUE)
                .count();

        double avgFood = reviews.stream()
                .filter(o -> o.getAvaliacao() != null && o.getAvaliacao().getNotaPedido() != null)
                .mapToInt(o -> o.getAvaliacao().getNotaPedido())
                .average()
                .orElse(5.0);

        double avgDelivery = reviews.stream()
                .filter(o -> o.getAvaliacao() != null && o.getAvaliacao().getNotaEntrega() != null)
                .mapToInt(o -> o.getAvaliacao().getNotaEntrega())
                .average()
                .orElse(5.0);

        return new PlatformMetricsResponse(
                totalOrders,
                totalDelivered,
                BigDecimal.valueOf(Math.round(avgFood * 10.0) / 10.0),
                BigDecimal.valueOf(Math.round(avgDelivery * 10.0) / 10.0),
                reviews.size()
        );
    }

    @GetMapping("/reviews")
    public List<OrderResponse> getRecentReviews(Authentication authentication) {
        requireAdmin(authentication);
        if (orderRepository == null) {
            return List.of();
        }
        return orderRepository.findByAvaliacaoIsNotNull().stream()
                .map(OrderResponse::fromEntity)
                .toList();
    }

    public record DestaquePopularRequest(boolean destaquePopular) {
    }

    public record UpdatePartnershipRequest(boolean active) {
    }
}
