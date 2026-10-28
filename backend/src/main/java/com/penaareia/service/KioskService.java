package com.penaareia.service;

import com.penaareia.dto.KioskMenuDtos.CreateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.UpdateMenuItemRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class KioskService {

    private final KioskRepository repository;
    private final UserRepository userRepository;

    public List<Kiosk> listarAtivos() {
        return repository.findByAtivoTrue();
    }

    public List<Kiosk> listarPorPostoReferencia(String pontoReferenciaId) {
        return repository.findByPontoReferenciaIdAndAtivoTrue(pontoReferenciaId);
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
                request.fotoUrl() != null && !request.fotoUrl().isBlank() ? request.fotoUrl().trim() : null
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
                request.fotoUrl() != null && !request.fotoUrl().isBlank() ? request.fotoUrl().trim() : null
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
