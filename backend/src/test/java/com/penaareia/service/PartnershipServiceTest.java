package com.penaareia.service;

import com.penaareia.model.Kiosk;
import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Order;
import com.penaareia.model.Partnership;
import com.penaareia.model.User;
import com.penaareia.dto.PartnershipDtos;
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
    void listsActivePartnershipsDirectlyFromRepository() {
        List<Partnership> partnerships = List.of(new Partnership("p1", "APP", "APP", true));
        when(partnershipRepository.findByActiveTrue()).thenReturn(partnerships);

        assertThat(service.listActivePartnerships()).isEqualTo(partnerships);
    }

    @Test
    void listsOperatorPartnershipsIncludingUnconfiguredDefaults() {
        User operator = operator();
        Kiosk kiosk = kioskWithProduct();
        Partnership partnership = new Partnership("p1", "APP", "APP", true);
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kiosk));
        when(partnershipRepository.findByActiveTrue()).thenReturn(List.of(partnership));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p1"))
                .thenReturn(Optional.empty());

        var result = service.listForOperator("operator-1");

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().configured()).isFalse();
        assertThat(result.getFirst().products()).hasSize(1);
    }

    @Test
    void savesValidOperatorConfigurationAndRemovesDuplicateFiltersAndProducts() {
        User operator = operator();
        Kiosk kiosk = kioskWithProduct();
        kiosk.getCardapio().getFirst().setCategory("Bebidas");
        Partnership partnership = new Partnership("p1", "APP", "APP", true);
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kiosk));
        when(partnershipRepository.findById("p1")).thenReturn(Optional.of(partnership));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p1"))
                .thenReturn(Optional.empty());
        when(kioskPartnershipRepository.save(org.mockito.ArgumentMatchers.any()))
                .thenAnswer(invocation -> {
                    KioskPartnership saved = invocation.getArgument(0);
                    saved.setId("configuration-1");
                    return saved;
                });

        PartnershipDtos.ConfigurationRequest request = configurationRequest(
                true, new java.math.BigDecimal("10.00"), List.of("Bebidas", "Bebidas"), List.of("m1", "m1"));
        var response = service.updateForOperator("operator-1", "p1", request);

        assertThat(response.active()).isTrue();
        assertThat(response.configured()).isTrue();
        assertThat(response.productIds()).containsExactly("m1");
        assertThat(response.filters().getCategories()).containsExactly("Bebidas");
        verify(kioskPartnershipRepository).save(org.mockito.ArgumentMatchers.argThat(saved ->
                saved.getDeliveryFee().compareTo(new java.math.BigDecimal("10.00")) == 0));
    }

    @Test
    void rejectsInactivePartnershipAndInvalidConfigurationValues() {
        User operator = operator();
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kioskWithProduct()));
        when(partnershipRepository.findById("inactive"))
                .thenReturn(Optional.of(new Partnership("inactive", "APP", "APP", false)));
        assertThatThrownBy(() -> service.updateForOperator(
                "operator-1", "inactive", configurationRequest(true,
                        java.math.BigDecimal.ZERO, List.of(), List.of("m1"))))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Parceria indisponível.");

        when(partnershipRepository.findById("p1"))
                .thenReturn(Optional.of(new Partnership("p1", "APP", "APP", true)));
        assertThatThrownBy(() -> service.updateForOperator(
                "operator-1", "p1", configurationRequest(false,
                        new java.math.BigDecimal("31"), List.of(), List.of("m1"))))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessage("A comissão deve estar entre 0% e 30%.");
        assertThatThrownBy(() -> service.updateForOperator(
                "operator-1", "p1", configurationRequest(false,
                        java.math.BigDecimal.ZERO, List.of(), List.of("not-owned"))))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessage("Selecione apenas produtos deste quiosque.");
        assertThatThrownBy(() -> service.updateForOperator(
                "operator-1", "p1", configurationRequest(true,
                        java.math.BigDecimal.ZERO, List.of(), List.of())))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessage("Habilite ao menos um produto antes de ativar a parceria.");
        assertThatThrownBy(() -> service.updateForOperator(
                "operator-1", "p1", configurationRequest(false,
                        java.math.BigDecimal.ZERO, List.of("Desconhecida"), List.of("m1"))))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessage("Selecione apenas categorias do cardápio deste quiosque.");
        verify(kioskPartnershipRepository, never()).save(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void listsOnlyOffersWithEligibleAvailableProducts() {
        Kiosk kiosk = kioskWithProduct();
        KioskPartnership active = configuration(List.of("m1"));
        active.setActive(true);
        KioskPartnership inactive = configuration(List.of("m1"));
        inactive.setActive(false);
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kiosk));
        when(partnershipRepository.findByActiveTrue()).thenReturn(List.of(
                new Partnership("p1", "APP", "APP", true),
                new Partnership("p2", "Partner", "PARTNER", true),
                new Partnership("p3", "Empty", "EMPTY", true)));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p1"))
                .thenReturn(Optional.of(active));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p2"))
                .thenReturn(Optional.of(inactive));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p3"))
                .thenReturn(Optional.empty());

        var offers = service.listOffersForKiosk("k1");

        assertThat(offers).hasSize(2);
        assertThat(offers.getFirst().products()).hasSize(1);
        assertThat(offers.get(1).products()).isEmpty();
    }

    @Test
    void rejectsMissingOrInactiveKiosksWhenListingOffers() {
        when(kioskRepository.findById("missing")).thenReturn(Optional.empty());
        Kiosk inactiveKiosk = new Kiosk();
        inactiveKiosk.setAtivo(false);
        when(kioskRepository.findById("inactive")).thenReturn(Optional.of(inactiveKiosk));
        assertThatThrownBy(() -> service.listOffersForKiosk("missing"))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> service.listOffersForKiosk("inactive"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void listsPartnershipKiosksAndSkipsMissingInactiveAndEmptyKiosks() {
        Partnership partnership = new Partnership("p1", "APP", "APP", true);
        KioskPartnership activeConfiguration = configuration(List.of("m1"));
        activeConfiguration.setKioskId("k1");
        activeConfiguration.setActive(true);
        KioskPartnership missingKioskConfiguration = configuration(List.of("m1"));
        missingKioskConfiguration.setKioskId("missing");
        KioskPartnership inactiveKioskConfiguration = configuration(List.of("m1"));
        inactiveKioskConfiguration.setKioskId("inactive");
        KioskPartnership noEligibleProductsConfiguration = configuration(List.of("not-available"));
        noEligibleProductsConfiguration.setKioskId("empty");
        noEligibleProductsConfiguration.setActive(true);
        Kiosk inactiveKiosk = kioskWithProduct();
        inactiveKiosk.setAtivo(false);

        when(partnershipRepository.findById("p1")).thenReturn(Optional.of(partnership));
        when(kioskPartnershipRepository.findByPartnershipIdAndActiveTrue("p1")).thenReturn(List.of(
                activeConfiguration, missingKioskConfiguration,
                inactiveKioskConfiguration, noEligibleProductsConfiguration));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kioskWithProduct()));
        when(kioskRepository.findById("missing")).thenReturn(Optional.empty());
        when(kioskRepository.findById("inactive")).thenReturn(Optional.of(inactiveKiosk));
        when(kioskRepository.findById("empty")).thenReturn(Optional.of(kioskWithProduct()));

        assertThat(service.listKiosksForPartnership("p1"))
                .extracting(Kiosk::getId)
                .containsExactly("k1");
    }

    @Test
    void rejectsUnavailablePartnershipWhenListingKiosks() {
        when(partnershipRepository.findById("missing")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.listKiosksForPartnership("missing"))
                .isInstanceOf(ResourceNotFoundException.class);
        when(partnershipRepository.findById("inactive"))
                .thenReturn(Optional.of(new Partnership("inactive", "APP", "APP", false)));
        assertThatThrownBy(() -> service.listKiosksForPartnership("inactive"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void resolvesActiveConfigurationAndRejectsMissingOrPausedOffers() {
        when(partnershipRepository.findById("missing")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.activeConfiguration("k1", "missing"))
                .isInstanceOf(ResourceNotFoundException.class);
        when(partnershipRepository.findById("p1"))
                .thenReturn(Optional.of(new Partnership("p1", "APP", "APP", true)));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p1"))
                .thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.activeConfiguration("k1", "p1"))
                .isInstanceOf(ConflictException.class);
        KioskPartnership paused = configuration(List.of("m1"));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p1"))
                .thenReturn(Optional.of(paused));
        assertThatThrownBy(() -> service.activeConfiguration("k1", "p1"))
                .isInstanceOf(ConflictException.class)
                .hasMessage("A parceria está pausada e não aceita novos pedidos.");
        paused.setActive(true);
        assertThat(service.activeConfiguration("k1", "p1")).isSameAs(paused);
    }

    @Test
    void previewsEligibleProductsAndRejectsMissingConfigurationExcessItemsAndUnavailableProducts() {
        User operator = operator();
        Kiosk kiosk = kioskWithProduct();
        KioskPartnership configuration = configuration(List.of("m1"));
        configuration.setMaxItemsPerOrder(2);
        configuration.setActive(true);
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator));
        when(kioskRepository.findById("k1")).thenReturn(Optional.of(kiosk));
        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "missing"))
                .thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.preview("operator-1", "missing", previewRequest("m1", 1)))
                .isInstanceOf(ResourceNotFoundException.class);

        when(kioskPartnershipRepository.findByKioskIdAndPartnershipId("k1", "p1"))
                .thenReturn(Optional.of(configuration));
        assertThatThrownBy(() -> service.preview("operator-1", "p1", previewRequest("m1", 3)))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("O exemplo excede o máximo de itens por pedido.");
        assertThatThrownBy(() -> service.preview("operator-1", "p1", previewRequest("missing", 1)))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("O exemplo contém um produto indisponível nesta parceria.");

        when(pricingService.calculate(
                new java.math.BigDecimal("1.00"), configuration))
                .thenReturn(new Order.PricingSnapshot(
                        java.math.BigDecimal.ZERO, java.math.BigDecimal.ZERO,
                        java.math.BigDecimal.ZERO, "CLIENT", java.math.BigDecimal.ZERO,
                        2, LocalTime.MIN, LocalTime.MAX, 0,
                        List.of(), false, List.of("m1"),
                        new java.math.BigDecimal("1.00"),
                        new java.math.BigDecimal("1.00"),
                        new java.math.BigDecimal("1.00")));
        var preview = service.preview("operator-1", "p1", previewRequest("m1", 1));
        assertThat(preview.subtotal()).isEqualByComparingTo("1.00");
        assertThat(preview.note()).contains("não representa cobrança");
    }

    @Test
    void rejectsOperatorWithoutAssignedKioskOrMissingKiosk() {
        when(userRepository.findById("missing")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.listForOperator("missing"))
                .isInstanceOf(ForbiddenException.class);
        User unassigned = new User();
        unassigned.setRole("KIOSK_OPERATOR");
        when(userRepository.findById("unassigned")).thenReturn(Optional.of(unassigned));
        assertThatThrownBy(() -> service.listForOperator("unassigned"))
                .isInstanceOf(ForbiddenException.class);
        when(userRepository.findById("operator-1")).thenReturn(Optional.of(operator()));
        when(kioskRepository.findById("k1")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.listForOperator("operator-1"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Quiosque do operador não encontrado.");
    }

    @Test
    void eligibilityHandlesNullFiltersAndMissingCategories() {
        KioskPartnership configuration = configuration(List.of("m1"));
        Kiosk.MenuItem uncategorized = new Kiosk.MenuItem("m1", "Suco", "", java.math.BigDecimal.ONE, true);
        uncategorized.setCategory(null);

        configuration.setFilters(null);
        assertThat(service.isEligible(configuration, uncategorized)).isTrue();
        configuration.setFilters(new KioskPartnership.Filters(null, false));
        assertThat(service.isEligible(configuration, uncategorized)).isTrue();
        configuration.setFilters(new KioskPartnership.Filters(List.of("Outros"), false));
        assertThat(service.isEligible(configuration, uncategorized)).isTrue();
        assertThat(service.isEligible(configuration,
                new Kiosk.MenuItem("other", "Suco", "", java.math.BigDecimal.ONE, true))).isFalse();
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

    private User operator() {
        User operator = new User();
        operator.setRole("KIOSK_OPERATOR");
        operator.setKioskId("k1");
        return operator;
    }

    private PartnershipDtos.ConfigurationRequest configurationRequest(
            boolean active, java.math.BigDecimal commissionPercent,
            List<String> categories, List<String> productIds) {
        return new PartnershipDtos.ConfigurationRequest(
                active, commissionPercent, new java.math.BigDecimal("10.00"),
                KioskPartnership.DeliveryFeePayer.CLIENT, java.math.BigDecimal.ZERO,
                10, LocalTime.MIN, LocalTime.MAX, 10,
                new PartnershipDtos.FiltersRequest(categories, false), productIds);
    }

    private PartnershipDtos.PreviewRequest previewRequest(String menuItemId, int quantity) {
        return new PartnershipDtos.PreviewRequest(List.of(
                new PartnershipDtos.PreviewItemRequest(menuItemId, quantity)));
    }
}
