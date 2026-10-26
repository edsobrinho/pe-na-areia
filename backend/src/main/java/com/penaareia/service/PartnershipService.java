package com.penaareia.service;

import com.penaareia.dto.PartnershipDtos.ConfigurationRequest;
import com.penaareia.dto.PartnershipDtos.OfferResponse;
import com.penaareia.dto.PartnershipDtos.OperatorPartnershipResponse;
import com.penaareia.dto.PartnershipDtos.PricingPreview;
import com.penaareia.dto.PartnershipDtos.PreviewRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.KioskPartnership;
import com.penaareia.model.Order;
import com.penaareia.model.Partnership;
import com.penaareia.model.User;
import com.penaareia.repository.KioskPartnershipRepository;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.PartnershipRepository;
import com.penaareia.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

import com.penaareia.dto.PartnershipDtos.PreviewItemRequest;

@Service
@RequiredArgsConstructor
public class PartnershipService {

    private static final ZoneId BUSINESS_TIME_ZONE = ZoneId.of("America/Sao_Paulo");
    private static final BigDecimal MAX_COMMISSION_PERCENT = new BigDecimal("30");

    private final PartnershipRepository partnershipRepository;
    private final KioskPartnershipRepository kioskPartnershipRepository;
    private final KioskRepository kioskRepository;
    private final UserRepository userRepository;
    private final PartnershipPricingService pricingService;

    public List<Partnership> listActivePartnerships() {
        return partnershipRepository.findByActiveTrue();
    }

    public List<OperatorPartnershipResponse> listForOperator(String operatorId) {
        Kiosk kiosk = ownedKiosk(operatorId);
        List<OperatorPartnershipResponse> result = new ArrayList<>();
        for (Partnership partnership : listActivePartnerships()) {
            KioskPartnership configuration = kioskPartnershipRepository
                    .findByKioskIdAndPartnershipId(kiosk.getId(), partnership.getId())
                    .orElseGet(() -> defaultConfiguration(kiosk.getId(), partnership.getId()));
            result.add(operatorResponse(partnership, configuration, kiosk));
        }
        return result;
    }

    public OperatorPartnershipResponse updateForOperator(
            String operatorId, String partnershipId, ConfigurationRequest request) {
        Kiosk kiosk = ownedKiosk(operatorId);
        Partnership partnership = partnershipRepository.findById(partnershipId)
                .filter(Partnership::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Parceria indisponível."));
        validateConfiguration(kiosk, request);

        KioskPartnership configuration = kioskPartnershipRepository
                .findByKioskIdAndPartnershipId(kiosk.getId(), partnershipId)
                .orElseGet(() -> defaultConfiguration(kiosk.getId(), partnershipId));
        configuration.setActive(request.active());
        configuration.setCommissionPercent(request.commissionPercent());
        configuration.setDeliveryFee(PartnershipPricingService.money(request.deliveryFee()));
        configuration.setDeliveryFeePayer(request.deliveryFeePayer());
        configuration.setMinimumOrder(PartnershipPricingService.money(request.minimumOrder()));
        configuration.setMaxItemsPerOrder(request.maxItemsPerOrder());
        configuration.setAcceptFrom(request.acceptFrom());
        configuration.setAcceptUntil(request.acceptUntil());
        configuration.setPrepMinutes(request.prepMinutes());
        List<String> requestedCategories = request.filters().categories() == null
                ? List.of() : request.filters().categories();
        configuration.setFilters(new KioskPartnership.Filters(
                requestedCategories.stream().distinct().toList(),
                request.filters().onlyReturnable()));
        configuration.setProductIds(request.productIds().stream().distinct().toList());

        KioskPartnership saved = kioskPartnershipRepository.save(configuration);
        return operatorResponse(partnership, saved, kiosk);
    }

    public List<OfferResponse> listOffersForKiosk(String kioskId) {
        Kiosk kiosk = kioskRepository.findById(kioskId)
                .filter(Kiosk::isAtivo)
                .orElseThrow(() -> new ResourceNotFoundException("Quiosque não encontrado."));
        return listActivePartnerships().stream()
                .map(partnership -> kioskPartnershipRepository
                        .findByKioskIdAndPartnershipId(kioskId, partnership.getId())
                        .map(configuration -> offerResponse(partnership, configuration, kiosk))
                        .orElse(null))
                .filter(Objects::nonNull)
                .toList();
    }

    public List<Kiosk> listKiosksForPartnership(String partnershipId) {
        Partnership partnership = partnershipRepository.findById(partnershipId)
                .filter(Partnership::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Parceria não encontrada."));
        return kioskPartnershipRepository.findByPartnershipIdAndActiveTrue(partnershipId).stream()
                .map(configuration -> kioskRepository.findById(configuration.getKioskId())
                        .filter(Kiosk::isAtivo)
                        .map(kiosk -> kioskWithEligibleProducts(kiosk, configuration)))
                .flatMap(java.util.Optional::stream)
                .filter(kiosk -> !kiosk.getCardapio().isEmpty())
                .toList();
    }

    public boolean isEligible(KioskPartnership configuration, Kiosk.MenuItem item) {
        if (!configuration.getProductIds().contains(item.getId())) {
            return false;
        }
        KioskPartnership.Filters filters = configuration.getFilters();
        if (filters != null && filters.getCategories() != null
                && !filters.getCategories().isEmpty()
                && !filters.getCategories().contains(
                        item.getCategory() == null ? "Outros" : item.getCategory())) {
            return false;
        }
        return filters == null || !filters.isOnlyReturnable() || item.isReturnablePackaging();
    }

    public KioskPartnership activeConfiguration(String kioskId, String partnershipId) {
        Partnership partnership = partnershipRepository.findById(partnershipId)
                .filter(Partnership::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Parceria não encontrada."));
        KioskPartnership configuration = kioskPartnershipRepository
                .findByKioskIdAndPartnershipId(kioskId, partnership.getId())
                .orElseThrow(() -> new ConflictException("Este quiosque não oferece essa parceria."));
        if (!configuration.isActive()) {
            throw new ConflictException("A parceria está pausada e não aceita novos pedidos.");
        }
        return configuration;
    }

    public boolean isWithinAcceptanceWindow(KioskPartnership configuration) {
        return isWithinWindowAt(
                LocalTime.now(BUSINESS_TIME_ZONE),
                configuration.getAcceptFrom(),
                configuration.getAcceptUntil());
    }

    public static boolean isWithinWindowAt(LocalTime now, LocalTime start, LocalTime end) {
        if (start.equals(end)) {
            return true;
        }
        if (start.isBefore(end)) {
            return !now.isBefore(start) && now.isBefore(end);
        }
        return !now.isBefore(start) || now.isBefore(end);
    }

    public PricingPreview preview(String operatorId, String partnershipId, PreviewRequest request) {
        Kiosk kiosk = ownedKiosk(operatorId);
        KioskPartnership configuration = kioskPartnershipRepository
                .findByKioskIdAndPartnershipId(kiosk.getId(), partnershipId)
                .orElseThrow(() -> new ResourceNotFoundException("Configure esta parceria antes da prévia."));
        List<Kiosk.MenuItem> menu = kiosk.getCardapio() == null ? List.of() : kiosk.getCardapio();
        long itemCount = request.items().stream().mapToLong(PreviewItemRequest::quantity).sum();
        if (itemCount > configuration.getMaxItemsPerOrder()) {
            throw new BusinessRuleException("O exemplo excede o máximo de itens por pedido.");
        }
        BigDecimal subtotal = BigDecimal.ZERO;
        for (PreviewItemRequest requested : request.items()) {
            Kiosk.MenuItem item = menu.stream()
                    .filter(candidate -> candidate.getId().equals(requested.menuItemId()))
                    .filter(Kiosk.MenuItem::isDisponivel)
                    .filter(candidate -> isEligible(configuration, candidate))
                    .findFirst()
                    .orElseThrow(() -> new BusinessRuleException(
                            "O exemplo contém um produto indisponível nesta parceria."));
            subtotal = subtotal.add(PartnershipPricingService.money(item.getPreco())
                    .multiply(BigDecimal.valueOf(requested.quantity())));
        }
        Order.PricingSnapshot snapshot = pricingService.calculate(subtotal, configuration);
        return new PricingPreview(
                snapshot.subtotal(),
                snapshot.commissionPercent(),
                snapshot.commissionAmount(),
                snapshot.deliveryFee(),
                configuration.getDeliveryFeePayer(),
                snapshot.customerTotal(),
                snapshot.kioskNet(),
                "Prévia estimada conforme as regras atuais; não representa cobrança ou repasse.");
    }

    private Kiosk ownedKiosk(String operatorId) {
        User operator = userRepository.findById(operatorId)
                .filter(user -> "KIOSK_OPERATOR".equals(user.getRole()))
                .filter(user -> user.getKioskId() != null && !user.getKioskId().isBlank())
                .orElseThrow(() -> new ForbiddenException("Usuário sem quiosque associado."));
        return kioskRepository.findById(operator.getKioskId())
                .orElseThrow(() -> new ResourceNotFoundException("Quiosque do operador não encontrado."));
    }

    private void validateConfiguration(Kiosk kiosk, ConfigurationRequest request) {
        if (request.commissionPercent().compareTo(BigDecimal.ZERO) < 0
                || request.commissionPercent().compareTo(MAX_COMMISSION_PERCENT) > 0) {
            throw new InvalidRequestException("A comissão deve estar entre 0% e 30%.");
        }
        Set<String> menuIds = new HashSet<>();
        Set<String> categories = new HashSet<>();
        if (kiosk.getCardapio() != null) {
            kiosk.getCardapio().forEach(item -> {
                menuIds.add(item.getId());
                categories.add(item.getCategory() == null ? "Outros" : item.getCategory());
            });
        }
        if (!menuIds.containsAll(request.productIds())) {
            throw new InvalidRequestException("Selecione apenas produtos deste quiosque.");
        }
        if (request.active() && request.productIds().isEmpty()) {
            throw new InvalidRequestException("Habilite ao menos um produto antes de ativar a parceria.");
        }
        List<String> requestedCategories = request.filters().categories() == null
                ? List.of() : request.filters().categories();
        if (!categories.containsAll(requestedCategories)) {
            throw new InvalidRequestException("Selecione apenas categorias do cardápio deste quiosque.");
        }
    }

    private KioskPartnership defaultConfiguration(String kioskId, String partnershipId) {
        KioskPartnership configuration = new KioskPartnership();
        configuration.setKioskId(kioskId);
        configuration.setPartnershipId(partnershipId);
        configuration.setFilters(new KioskPartnership.Filters(new ArrayList<>(), false));
        configuration.setProductIds(new ArrayList<>());
        return configuration;
    }

    private OperatorPartnershipResponse operatorResponse(
            Partnership partnership, KioskPartnership configuration, Kiosk kiosk) {
        List<Kiosk.MenuItem> products = kiosk.getCardapio() == null ? List.of() : kiosk.getCardapio();
        return new OperatorPartnershipResponse(
                partnership.getId(), partnership.getName(), partnership.getChannel(),
                configuration.getId() != null, configuration.isActive(),
                configuration.getCommissionPercent(), configuration.getDeliveryFee(),
                configuration.getDeliveryFeePayer(), configuration.getMinimumOrder(),
                configuration.getMaxItemsPerOrder(), configuration.getAcceptFrom(),
                configuration.getAcceptUntil(), configuration.getPrepMinutes(),
                configuration.getFilters(), configuration.getProductIds(), products);
    }

    private OfferResponse offerResponse(
            Partnership partnership, KioskPartnership configuration, Kiosk kiosk) {
        return new OfferResponse(
                partnership.getId(), partnership.getName(), partnership.getChannel(),
                configuration.isActive(), configuration.getCommissionPercent(),
                configuration.getDeliveryFee(), configuration.getDeliveryFeePayer(),
                configuration.getMinimumOrder(), configuration.getMaxItemsPerOrder(),
                configuration.getAcceptFrom(), configuration.getAcceptUntil(),
                configuration.getPrepMinutes(), eligibleProducts(kiosk, configuration));
    }

    private Kiosk kioskWithEligibleProducts(Kiosk kiosk, KioskPartnership configuration) {
        kiosk.setCardapio(eligibleProducts(kiosk, configuration));
        return kiosk;
    }

    private List<Kiosk.MenuItem> eligibleProducts(Kiosk kiosk, KioskPartnership configuration) {
        if (!configuration.isActive() || kiosk.getCardapio() == null) {
            return List.of();
        }
        return kiosk.getCardapio().stream()
                .filter(Kiosk.MenuItem::isDisponivel)
                .filter(item -> isEligible(configuration, item))
                .toList();
    }
}
