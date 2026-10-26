package com.penaareia.dto;

import com.penaareia.model.Kiosk;
import com.penaareia.model.KioskPartnership;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;

public final class PartnershipDtos {

    private PartnershipDtos() {
    }

    public record FiltersRequest(
            List<@NotBlank String> categories,
            boolean onlyReturnable
    ) {
    }

    public record ConfigurationRequest(
            boolean active,
            @NotNull @DecimalMin("0") @DecimalMax("30") BigDecimal commissionPercent,
            @NotNull @PositiveOrZero BigDecimal deliveryFee,
            @NotNull KioskPartnership.DeliveryFeePayer deliveryFeePayer,
            @NotNull @PositiveOrZero BigDecimal minimumOrder,
            @Positive int maxItemsPerOrder,
            @NotNull LocalTime acceptFrom,
            @NotNull LocalTime acceptUntil,
            @PositiveOrZero int prepMinutes,
            @NotNull @Valid FiltersRequest filters,
            @NotNull List<@NotBlank String> productIds
    ) {
    }

    public record OperatorPartnershipResponse(
            String partnershipId,
            String name,
            String channel,
            boolean configured,
            boolean active,
            BigDecimal commissionPercent,
            BigDecimal deliveryFee,
            KioskPartnership.DeliveryFeePayer deliveryFeePayer,
            BigDecimal minimumOrder,
            int maxItemsPerOrder,
            LocalTime acceptFrom,
            LocalTime acceptUntil,
            int prepMinutes,
            KioskPartnership.Filters filters,
            List<String> productIds,
            List<Kiosk.MenuItem> products
    ) {
    }

    public record OfferResponse(
            String partnershipId,
            String name,
            String channel,
            boolean active,
            BigDecimal commissionPercent,
            BigDecimal deliveryFee,
            KioskPartnership.DeliveryFeePayer deliveryFeePayer,
            BigDecimal minimumOrder,
            int maxItemsPerOrder,
            LocalTime acceptFrom,
            LocalTime acceptUntil,
            int prepMinutes,
            List<Kiosk.MenuItem> products
    ) {
    }

    public record PreviewItemRequest(
            @NotBlank String menuItemId,
            @NotNull @Positive Integer quantity
    ) {
    }

    public record PreviewRequest(
            @NotEmpty List<@NotNull @Valid PreviewItemRequest> items
    ) {
    }

    public record PricingPreview(
            BigDecimal subtotal,
            BigDecimal commissionPercent,
            BigDecimal commissionAmount,
            BigDecimal deliveryFee,
            KioskPartnership.DeliveryFeePayer deliveryFeePayer,
            BigDecimal customerTotal,
            BigDecimal kioskNet,
            String note
    ) {
    }
}
