package com.penaareia.service;

import com.penaareia.dto.KioskMenuDtos.CreateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.PartnerOnboardingRequest;
import com.penaareia.dto.KioskMenuDtos.PartnerOnboardingResponse;
import com.penaareia.dto.KioskMenuDtos.UpdateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.UpdateStorefrontRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.ReferencePoint;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.ReferencePointRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.security.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class KioskService {

    private static final String DEFAULT_POSTO_ID = "6acfd917f737c71df923a343";
    private static final GeoJsonPoint DEFAULT_LOCATION = new GeoJsonPoint(-46.3336, -23.9689);

    private final KioskRepository repository;
    private final UserRepository userRepository;
    private final ReferencePointRepository referencePointRepository;
    private final JwtService jwtService;

    public KioskService(KioskRepository repository, UserRepository userRepository) {
        this(repository, userRepository, null, null);
    }

    @Autowired
    public KioskService(KioskRepository repository,
                        UserRepository userRepository,
                        ReferencePointRepository referencePointRepository,
                        JwtService jwtService) {
        this.repository = repository;
        this.userRepository = userRepository;
        this.referencePointRepository = referencePointRepository;
        this.jwtService = jwtService;
    }

    public List<Kiosk> listarAtivos() {
        return repository.findByAtivoTrue();
    }

    public List<Kiosk> listarPorPostoReferencia(String pontoReferenciaId) {
        return repository.findByPontoReferenciaIdAndAtivoTrue(pontoReferenciaId);
    }

    public Kiosk getStorefrontForOperator(String operatorId) {
        return ownedKiosk(operatorId);
    }

    public PartnerOnboardingResponse onboardPartner(String userId, PartnerOnboardingRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado."));

        Kiosk kiosk = null;
        if (user.getKioskId() != null && !user.getKioskId().isBlank()) {
            kiosk = repository.findById(user.getKioskId()).orElse(null);
        }
        if (kiosk == null) {
            kiosk = new Kiosk();
            kiosk.setId("kiosk-" + UUID.randomUUID().toString().substring(0, 8));
            kiosk.setCardapio(new ArrayList<>());
            kiosk.setAtivo(true);
            kiosk.setAvaliacaoMedia(5.0);
            kiosk.setLocalizacao(DEFAULT_LOCATION);
            kiosk.setPontoReferenciaId(DEFAULT_POSTO_ID);
        }

        applyOnboardingFields(kiosk, request);
        Kiosk savedKiosk = repository.save(kiosk);

        user.setRole("KIOSK_OPERATOR");
        user.setKioskId(savedKiosk.getId());
        userRepository.save(user);

        String token = jwtService != null
                ? jwtService.generateToken(user.getId(), user.getEmail(), "KIOSK_OPERATOR")
                : "";

        return new PartnerOnboardingResponse(
                token,
                user.getId(),
                user.getNome(),
                "KIOSK_OPERATOR",
                savedKiosk
        );
    }

    public Kiosk updateStorefront(String operatorId, UpdateStorefrontRequest request) {
        Kiosk kiosk = ownedKiosk(operatorId);
        if (request.nome() != null && !request.nome().isBlank()) {
            kiosk.setNome(request.nome().trim());
        }
        if (request.descricaoCurta() != null) {
            kiosk.setDescricaoCurta(request.descricaoCurta().trim());
        }
        if (request.fotoCapaUrl() != null) {
            kiosk.setFotoCapaUrl(request.fotoCapaUrl().isBlank() ? null : request.fotoCapaUrl().trim());
        }
        if (request.logoUrl() != null) {
            kiosk.setLogoUrl(request.logoUrl().isBlank() ? null : request.logoUrl().trim());
        }
        if (request.aceitaEmbalagemSustentavel() != null) {
            kiosk.setAceitaEmbalagemSustentavel(request.aceitaEmbalagemSustentavel());
        }
        if (request.destaquePopular() != null) {
            kiosk.setDestaquePopular(request.destaquePopular());
        }
        if (request.cnpj() != null) {
            kiosk.setCnpj(cleanOrNull(request.cnpj()));
        }
        if (request.cep() != null) {
            kiosk.setCep(cleanOrNull(request.cep()));
        }
        if (request.logradouro() != null) {
            kiosk.setLogradouro(cleanOrNull(request.logradouro()));
        }
        if (request.numero() != null) {
            kiosk.setNumero(cleanOrNull(request.numero()));
        }
        if (request.complemento() != null) {
            kiosk.setComplemento(cleanOrNull(request.complemento()));
        }
        if (request.bairro() != null) {
            kiosk.setBairro(cleanOrNull(request.bairro()));
        }
        if (request.cidade() != null && !request.cidade().isBlank()) {
            kiosk.setCidade(request.cidade().trim());
        }
        if (request.uf() != null && !request.uf().isBlank()) {
            kiosk.setUf(request.uf().trim().toUpperCase());
        }
        if (request.pontoReferenciaId() != null && !request.pontoReferenciaId().isBlank()) {
            updateReferencePointLocation(kiosk, request.pontoReferenciaId().trim());
        }
        return repository.save(kiosk);
    }

    private void applyOnboardingFields(Kiosk kiosk, PartnerOnboardingRequest request) {
        kiosk.setNome(request.nome().trim());
        if (request.descricaoCurta() != null) {
            kiosk.setDescricaoCurta(request.descricaoCurta().trim());
        }
        if (request.logoUrl() != null) {
            kiosk.setLogoUrl(cleanOrNull(request.logoUrl()));
        }
        if (request.fotoCapaUrl() != null) {
            kiosk.setFotoCapaUrl(cleanOrNull(request.fotoCapaUrl()));
        }
        if (request.aceitaEmbalagemSustentavel() != null) {
            kiosk.setAceitaEmbalagemSustentavel(request.aceitaEmbalagemSustentavel());
        }
        if (request.destaquePopular() != null) {
            kiosk.setDestaquePopular(request.destaquePopular());
        }
        if (request.cnpj() != null) {
            kiosk.setCnpj(cleanOrNull(request.cnpj()));
        }
        if (request.cep() != null) {
            kiosk.setCep(cleanOrNull(request.cep()));
        }
        if (request.logradouro() != null) {
            kiosk.setLogradouro(cleanOrNull(request.logradouro()));
        }
        if (request.numero() != null) {
            kiosk.setNumero(cleanOrNull(request.numero()));
        }
        if (request.complemento() != null) {
            kiosk.setComplemento(cleanOrNull(request.complemento()));
        }
        if (request.bairro() != null) {
            kiosk.setBairro(cleanOrNull(request.bairro()));
        }
        kiosk.setCidade(request.cidade() != null && !request.cidade().isBlank() ? request.cidade().trim() : "Santos");
        kiosk.setUf(request.uf() != null && !request.uf().isBlank() ? request.uf().trim().toUpperCase() : "SP");
        if (request.pontoReferenciaId() != null && !request.pontoReferenciaId().isBlank()) {
            updateReferencePointLocation(kiosk, request.pontoReferenciaId().trim());
        }
    }

    private void updateReferencePointLocation(Kiosk kiosk, String pontoReferenciaId) {
        kiosk.setPontoReferenciaId(pontoReferenciaId);
        if (referencePointRepository != null) {
            ReferencePoint point = referencePointRepository.findById(pontoReferenciaId).orElse(null);
            if (point != null && point.getLocalizacao() != null) {
                kiosk.setLocalizacao(point.getLocalizacao());
            }
        }
    }

    private static String cleanOrNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public List<Kiosk.MenuItem> listMenuForOperator(String operatorId) {
        Kiosk kiosk = ownedKiosk(operatorId);
        return kiosk.getCardapio() == null ? List.of() : kiosk.getCardapio();
    }

    public Kiosk.MenuItem addMenuItem(String operatorId, CreateMenuItemRequest request) {
        Kiosk kiosk = ownedKiosk(operatorId);
        List<Kiosk.MenuItem> cardapio = kiosk.getCardapio() != null
                ? new ArrayList<>(kiosk.getCardapio())
                : new ArrayList<>();

        String itemId = UUID.randomUUID().toString();
        Kiosk.MenuItem newItem = new Kiosk.MenuItem(
                itemId,
                request.nome().trim(),
                request.descricao() != null ? request.descricao().trim() : "",
                request.preco(),
                request.disponivel() != null ? request.disponivel() : true,
                request.category() != null && !request.category().isBlank() ? request.category().trim() : "Outros",
                request.returnablePackaging() != null ? request.returnablePackaging() : false,
                request.fotoUrl() != null && !request.fotoUrl().isBlank() ? request.fotoUrl().trim() : null,
                request.destaque() != null ? request.destaque() : false
        );

        cardapio.add(newItem);
        kiosk.setCardapio(cardapio);
        repository.save(kiosk);
        return newItem;
    }

    public Kiosk.MenuItem updateMenuItem(String operatorId, String itemId, UpdateMenuItemRequest request) {
        Kiosk kiosk = ownedKiosk(operatorId);
        if (kiosk.getCardapio() == null) {
            throw new ResourceNotFoundException("Item do cardápio não encontrado.");
        }

        List<Kiosk.MenuItem> cardapio = new ArrayList<>(kiosk.getCardapio());
        int index = -1;
        for (int i = 0; i < cardapio.size(); i++) {
            if (cardapio.get(i).getId().equals(itemId)) {
                index = i;
                break;
            }
        }
        if (index == -1) {
            throw new ResourceNotFoundException("Item do cardápio não encontrado: " + itemId);
        }

        Kiosk.MenuItem updated = new Kiosk.MenuItem(
                itemId,
                request.nome().trim(),
                request.descricao() != null ? request.descricao().trim() : "",
                request.preco(),
                request.disponivel() != null ? request.disponivel() : true,
                request.category() != null && !request.category().isBlank() ? request.category().trim() : "Outros",
                request.returnablePackaging() != null ? request.returnablePackaging() : false,
                request.fotoUrl() != null && !request.fotoUrl().isBlank() ? request.fotoUrl().trim() : null,
                request.destaque() != null ? request.destaque() : false
        );

        cardapio.set(index, updated);
        kiosk.setCardapio(cardapio);
        repository.save(kiosk);
        return updated;
    }

    public void deleteMenuItem(String operatorId, String itemId) {
        Kiosk kiosk = ownedKiosk(operatorId);
        if (kiosk.getCardapio() == null) {
            throw new ResourceNotFoundException("Item do cardápio não encontrado.");
        }
        List<Kiosk.MenuItem> cardapio = new ArrayList<>(kiosk.getCardapio());
        boolean removed = cardapio.removeIf(item -> item.getId().equals(itemId));
        if (!removed) {
            throw new ResourceNotFoundException("Item do cardápio não encontrado: " + itemId);
        }
        kiosk.setCardapio(cardapio);
        repository.save(kiosk);
    }

    public Kiosk.MenuItem setMenuItemAvailability(String operatorId, String itemId, boolean disponivel) {
        Kiosk kiosk = ownedKiosk(operatorId);
        if (kiosk.getCardapio() == null) {
            throw new ResourceNotFoundException("Item do cardápio não encontrado.");
        }
        List<Kiosk.MenuItem> cardapio = new ArrayList<>(kiosk.getCardapio());
        Kiosk.MenuItem target = null;
        for (Kiosk.MenuItem item : cardapio) {
            if (item.getId().equals(itemId)) {
                item.setDisponivel(disponivel);
                target = item;
                break;
            }
        }
        if (target == null) {
            throw new ResourceNotFoundException("Item do cardápio não encontrado: " + itemId);
        }
        kiosk.setCardapio(cardapio);
        repository.save(kiosk);
        return target;
    }

    private Kiosk ownedKiosk(String operatorId) {
        User operator = userRepository.findById(operatorId)
                .filter(user -> "KIOSK_OPERATOR".equals(user.getRole()))
                .filter(user -> user.getKioskId() != null && !user.getKioskId().isBlank())
                .orElseThrow(() -> new ForbiddenException("Usuário sem quiosque associado."));
        return repository.findById(operator.getKioskId())
                .orElseThrow(() -> new ResourceNotFoundException("Quiosque do operador não encontrado."));
    }
}
