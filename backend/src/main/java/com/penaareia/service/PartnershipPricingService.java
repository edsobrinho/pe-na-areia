package com.penaareia.service;

import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Order;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
public class PartnershipPricingService {

    private static final BigDecimal ONE_HUNDRED = new BigDecimal("100");

    public Order.PricingSnapshot calculate(BigDecimal subtotal, KioskPartnership configuration) {
        BigDecimal roundedSubtotal = money(subtotal);
        BigDecimal commission = money(roundedSubtotal
                .multiply(configuration.getCommissionPercent())
                .divide(ONE_HUNDRED));
        BigDecimal deliveryFee = money(configuration.getDeliveryFee());
        BigDecimal customerTotal = roundedSubtotal;
        BigDecimal kioskNet = roundedSubtotal.subtract(commission);
        if (configuration.getDeliveryFeePayer() == KioskPartnership.DeliveryFeePayer.CLIENT) {
            customerTotal = customerTotal.add(deliveryFee);
        } else {
            kioskNet = kioskNet.subtract(deliveryFee);
        }

        KioskPartnership.Filters filters = configuration.getFilters();
        List<String> categories = filters == null || filters.getCategories() == null
                ? List.of() : filters.getCategories();
        List<String> enabledProductIds = configuration.getProductIds() == null
                ? List.of() : configuration.getProductIds();
        return new Order.PricingSnapshot(
                configuration.getCommissionPercent(),
                commission,
                deliveryFee,
                configuration.getDeliveryFeePayer().name(),
                money(configuration.getMinimumOrder()),
                configuration.getMaxItemsPerOrder(),
                configuration.getAcceptFrom(),
                configuration.getAcceptUntil(),
                configuration.getPrepMinutes(),
                categories,
                filters != null && filters.isOnlyReturnable(),
                enabledProductIds,
                roundedSubtotal,
                money(customerTotal),
                money(kioskNet));
    }

    public static BigDecimal money(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.HALF_UP);
    }
}
