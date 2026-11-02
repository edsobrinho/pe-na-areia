package com.penaareia.service;

import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Order;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PartnershipPricingServiceTest {

    private final PartnershipPricingService service = new PartnershipPricingService();

    @Test
    void roundsCommissionHalfUpToTwoDecimalsAndAddsClientDeliveryFee() {
        KioskPartnership configuration = configuration();
        configuration.setCommissionPercent(new BigDecimal("10"));
        configuration.setDeliveryFee(new BigDecimal("2.50"));
        configuration.setDeliveryFeePayer(KioskPartnership.DeliveryFeePayer.CLIENT);

        Order.PricingSnapshot pricing = service.calculate(new BigDecimal("32.25"), configuration);

        assertThat(pricing.subtotal()).isEqualByComparingTo("32.25");
        assertThat(pricing.commissionAmount()).isEqualByComparingTo("3.23");
        assertThat(pricing.customerTotal()).isEqualByComparingTo("34.75");
        assertThat(pricing.kioskNet()).isEqualByComparingTo("29.02");
    }

    @Test
    void deductsKioskPaidDeliveryFeeFromKioskNet() {
        KioskPartnership configuration = configuration();
        configuration.setCommissionPercent(new BigDecimal("10"));
        configuration.setDeliveryFee(new BigDecimal("2.50"));
        configuration.setDeliveryFeePayer(KioskPartnership.DeliveryFeePayer.KIOSK);

        Order.PricingSnapshot pricing = service.calculate(new BigDecimal("32.25"), configuration);

        assertThat(pricing.customerTotal()).isEqualByComparingTo("32.25");
        assertThat(pricing.kioskNet()).isEqualByComparingTo("26.52");
    }

    @Test
    void handlesNullFiltersAndNullProductIds() {
        KioskPartnership configuration = configuration();
        configuration.setFilters(null);
        configuration.setProductIds(null);

        Order.PricingSnapshot pricing = service.calculate(new BigDecimal("20.00"), configuration);

        assertThat(pricing.filterCategories()).isEmpty();
        assertThat(pricing.enabledProductIds()).isEmpty();
        assertThat(pricing.onlyReturnable()).isFalse();
    }

    @Test
    void appliesActiveFiltersWithCategoriesAndReturnable() {
        KioskPartnership configuration = configuration();
        configuration.setFilters(new KioskPartnership.Filters(List.of("Bebidas", "Porções"), true));
        configuration.setProductIds(List.of("p-1", "p-2"));

        Order.PricingSnapshot pricing = service.calculate(new BigDecimal("50.00"), configuration);

        assertThat(pricing.filterCategories()).containsExactly("Bebidas", "Porções");
        assertThat(pricing.enabledProductIds()).containsExactly("p-1", "p-2");
        assertThat(pricing.onlyReturnable()).isTrue();
    }

    private KioskPartnership configuration() {
        KioskPartnership configuration = new KioskPartnership();
        configuration.setCommissionPercent(BigDecimal.ZERO);
        configuration.setDeliveryFee(BigDecimal.ZERO);
        configuration.setDeliveryFeePayer(KioskPartnership.DeliveryFeePayer.CLIENT);
        configuration.setMinimumOrder(BigDecimal.ZERO);
        configuration.setMaxItemsPerOrder(10);
        configuration.setAcceptFrom(LocalTime.of(9, 0));
        configuration.setAcceptUntil(LocalTime.of(18, 0));
        configuration.setPrepMinutes(20);
        configuration.setProductIds(List.of());
        return configuration;
    }
}
