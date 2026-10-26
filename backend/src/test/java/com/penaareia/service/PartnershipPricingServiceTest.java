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
