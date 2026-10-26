package com.penaareia.service;

import com.penaareia.model.Kiosk;
import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Partnership;
import com.penaareia.model.User;
import com.penaareia.repository.KioskPartnershipRepository;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.PartnershipRepository;
import com.penaareia.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PartnershipServiceTest {

    @Mock
    private PartnershipRepository partnershipRepository;
    @Mock
    private KioskPartnershipRepository kioskPartnershipRepository;
    @Mock
    private KioskRepository kioskRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private PartnershipPricingService pricingService;

    @InjectMocks
    private PartnershipService service;

    @Test
    void emptyCategoryFilterAllowsEveryEnabledCategoryAndReturnableFilterExcludesOthers() {
        KioskPartnership configuration = configuration(List.of("m1", "m2"));
        Kiosk.MenuItem ordinary = new Kiosk.MenuItem("m1", "Suco", "", java.math.BigDecimal.ONE, true);
        ordinary.setCategory("Bebidas");
        Kiosk.MenuItem returnable = new Kiosk.MenuItem("m2", "Coco", "", java.math.BigDecimal.ONE, true);
        returnable.setCategory("Bebidas");
        returnable.setReturnablePackaging(true);

        assertThat(service.isEligible(configuration, ordinary)).isTrue();
        configuration.getFilters().setOnlyReturnable(true);
        assertThat(service.isEligible(configuration, ordinary)).isFalse();
        assertThat(service.isEligible(configuration, returnable)).isTrue();
    }

    @Test
    void categoryFilterLimitsEnabledProducts() {
        KioskPartnership configuration = configuration(List.of("m1", "m2"));
        configuration.getFilters().setCategories(List.of("Bebidas"));
        Kiosk.MenuItem food = new Kiosk.MenuItem("m1", "Salgado", "", java.math.BigDecimal.ONE, true);
        food.setCategory("Lanches");

        assertThat(service.isEligible(configuration, food)).isFalse();
    }

    @Test
    void activeConfigurationRequiresAnEnabledProduct() {
        User operator = new User();
        operator.setRole("KIOSK_OPERATOR");
        operator.setKioskId("k1");
        Kiosk kiosk = kioskWithProduct();
        Partnership partnership = new Partnership("p1", "Aplicativo", "APP", true);
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kiosk));
        when(partnershipRepository.findById("p1")).thenReturn(Optional.of(partnership));

        assertThatThrownBy(() -> service.updateForOperator("operator-1", "p1",
                new com.penaareia.dto.PartnershipDtos.ConfigurationRequest(
                        true, java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO,
                        KioskPartnership.DeliveryFeePayer.CLIENT, java.math.BigDecimal.ZERO,
                        10, LocalTime.MIN, LocalTime.MAX, 10,
                        new com.penaareia.dto.PartnershipDtos.FiltersRequest(List.of(), false),
                        List.of())))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("ao menos um produto");
    }

    @Test
    void operatorCanOnlySaveProductsFromItsAssignedKiosk() {
        User operator = new User();
        operator.setRole("KIOSK_OPERATOR");
        operator.setKioskId("k1");
        Kiosk kiosk = kioskWithProduct();
        Partnership partnership = new Partnership("p1", "Aplicativo", "APP", true);
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kiosk));
        when(partnershipRepository.findById("p1")).thenReturn(Optional.of(partnership));

        assertThatThrownBy(() -> service.updateForOperator("operator-1", "p1",
                new com.penaareia.dto.PartnershipDtos.ConfigurationRequest(
                        true, java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO,
                        KioskPartnership.DeliveryFeePayer.CLIENT, java.math.BigDecimal.ZERO,
                        10, LocalTime.MIN, LocalTime.MAX, 10,
                        new com.penaareia.dto.PartnershipDtos.FiltersRequest(List.of(), false),
                        List.of("other-kiosk-product"))))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("deste quiosque");

        verify(kioskPartnershipRepository, never()).save(any());
    }

    @Test
    void rejectsUsersWithoutKioskOperatorAssignment() {
        User user = new User();
        user.setRole("CLIENT");
        when(userRepository.findById("client-1")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.listForOperator("client-1"))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void windowHandlesOvernightAndUsesInclusiveStartExclusiveEnd() {
        assertThat(PartnershipService.isWithinWindowAt(
                LocalTime.of(23, 30), LocalTime.of(22, 0), LocalTime.of(2, 0))).isTrue();
        assertThat(PartnershipService.isWithinWindowAt(
                LocalTime.of(1, 59), LocalTime.of(22, 0), LocalTime.of(2, 0))).isTrue();
        assertThat(PartnershipService.isWithinWindowAt(
                LocalTime.of(2, 0), LocalTime.of(22, 0), LocalTime.of(2, 0))).isFalse();
        assertThat(PartnershipService.isWithinWindowAt(
                LocalTime.of(22, 0), LocalTime.of(22, 0), LocalTime.of(2, 0))).isTrue();
    }

    private KioskPartnership configuration(List<String> productIds) {
        KioskPartnership configuration = new KioskPartnership();
        configuration.setProductIds(productIds);
        configuration.setFilters(new KioskPartnership.Filters(List.of(), false));
        return configuration;
    }

    private Kiosk kioskWithProduct() {
        Kiosk kiosk = new Kiosk();
        kiosk.setId("k1");
        kiosk.setCardapio(List.of(new Kiosk.MenuItem("m1", "Suco", "", java.math.BigDecimal.ONE, true)));
        return kiosk;
    }
}
