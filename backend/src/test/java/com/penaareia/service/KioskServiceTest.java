package com.penaareia.service;

import com.penaareia.dto.KioskMenuDtos.CreateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.UpdateMenuItemRequest;
import com.penaareia.dto.KioskMenuDtos.UpdateStorefrontRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.support.Fixtures;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class KioskServiceTest {

    @Mock
    private KioskRepository repository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private KioskService service;

    @Test
    void listarAtivosUsaConsultaSomenteDeAtivos() {
        Kiosk ativo = Fixtures.kioskAtivo();
        when(repository.findByAtivoTrue()).thenReturn(List.of(ativo));

        List<Kiosk> resultado = service.listarAtivos();

        assertThat(resultado).containsExactly(ativo);
        verify(repository).findByAtivoTrue();
    }

    @Test
    void listarPorPostoUsaConsultaDeAtivosDoPosto() {
        Kiosk ativo = Fixtures.kioskAtivo();
        when(repository.findByPontoReferenciaIdAndAtivoTrue(Fixtures.POSTO_ID)).thenReturn(List.of(ativo));

        List<Kiosk> resultado = service.listarPorPostoReferencia(Fixtures.POSTO_ID);

        assertThat(resultado).containsExactly(ativo);
        verify(repository).findByPontoReferenciaIdAndAtivoTrue(Fixtures.POSTO_ID);
    }

    private User createOperator(String id, String kioskId) {
        User operator = new User();
        operator.setId(id);
        operator.setNome("Operador");
        operator.setEmail("op@kiosk.com");
        operator.setRole("KIOSK_OPERATOR");
        operator.setKioskId(kioskId);
        return operator;
    }

    @Test
    void listMenuForOperatorRetornaCardapioDoQuiosque() {
        User operator = createOperator("op-1", "kiosk-1");
        Kiosk kiosk = Fixtures.kioskAtivo();
        when(userRepository.findById("op-1")).thenReturn(Optional.of(operator));
        when(repository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));

        List<Kiosk.MenuItem> menu = service.listMenuForOperator("op-1");

        assertThat(menu).isNotEmpty();
    }

    @Test
    void addMenuItemSalvaNovoItemComFoto() {
        User operator = createOperator("op-1", "kiosk-1");
        Kiosk kiosk = Fixtures.kioskAtivo();
        kiosk.setCardapio(new ArrayList<>());
        when(userRepository.findById("op-1")).thenReturn(Optional.of(operator));
        when(repository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));
        when(repository.save(any(Kiosk.class))).thenAnswer(inv -> inv.getArgument(0));

        CreateMenuItemRequest req = new CreateMenuItemRequest(
                "Isca de Peixe",
                "Porção crocante com molho tártaro",
                new BigDecimal("45.00"),
                true,
                "Porções",
                false,
                "https://res.cloudinary.com/demo/image/upload/v1/isca.jpg"
        );

        Kiosk.MenuItem criado = service.addMenuItem("op-1", req);

        assertThat(criado.getId()).isNotBlank();
        assertThat(criado.getNome()).isEqualTo("Isca de Peixe");
        assertThat(criado.getFotoUrl()).isEqualTo("https://res.cloudinary.com/demo/image/upload/v1/isca.jpg");
        assertThat(criado.getCategory()).isEqualTo("Porções");

        ArgumentCaptor<Kiosk> captor = ArgumentCaptor.forClass(Kiosk.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getCardapio()).hasSize(1);
    }

    @Test
    void updateMenuItemAtualizaCamposExistentes() {
        User operator = createOperator("op-1", "kiosk-1");
        Kiosk kiosk = Fixtures.kioskAtivo();
        when(userRepository.findById("op-1")).thenReturn(Optional.of(operator));
        when(repository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));

        String itemId = kiosk.getCardapio().get(0).getId();
        UpdateMenuItemRequest req = new UpdateMenuItemRequest(
                "Água de coco geladinha",
                "Coco fresco",
                new BigDecimal("10.00"),
                true,
                "Bebidas",
                true,
                "https://res.cloudinary.com/demo/image/upload/v1/coco.jpg"
        );

        Kiosk.MenuItem atualizado = service.updateMenuItem("op-1", itemId, req);

        assertThat(atualizado.getNome()).isEqualTo("Água de coco geladinha");
        assertThat(atualizado.getFotoUrl()).isEqualTo("https://res.cloudinary.com/demo/image/upload/v1/coco.jpg");
        verify(repository).save(kiosk);
    }

    @Test
    void deleteMenuItemRemoveItemDoCardapio() {
        User operator = createOperator("op-1", "kiosk-1");
        Kiosk kiosk = Fixtures.kioskAtivo();
        int initialSize = kiosk.getCardapio().size();
        String itemId = kiosk.getCardapio().get(0).getId();
        when(userRepository.findById("op-1")).thenReturn(Optional.of(operator));
        when(repository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));

        service.deleteMenuItem("op-1", itemId);

        assertThat(kiosk.getCardapio()).hasSize(initialSize - 1);
        verify(repository).save(kiosk);
    }

    @Test
    void setMenuItemAvailabilityAlteraDisponibilidade() {
        User operator = createOperator("op-1", "kiosk-1");
        Kiosk kiosk = Fixtures.kioskAtivo();
        String itemId = kiosk.getCardapio().get(0).getId();
        when(userRepository.findById("op-1")).thenReturn(Optional.of(operator));
        when(repository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));

        Kiosk.MenuItem modificado = service.setMenuItemAvailability("op-1", itemId, false);

        assertThat(modificado.isDisponivel()).isFalse();
        verify(repository).save(kiosk);
    }

    @Test
    void updateStorefrontAtualizaMetadadosDaVitrineDoQuiosque() {
        User operator = createOperator("op-1", "kiosk-1");
        Kiosk kiosk = Fixtures.kioskAtivo();
        when(userRepository.findById("op-1")).thenReturn(Optional.of(operator));
        when(repository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));
        when(repository.save(any(Kiosk.class))).thenAnswer(inv -> inv.getArgument(0));

        UpdateStorefrontRequest req = new UpdateStorefrontRequest(
                "Especialista em Frutos do Mar e Porções na Orla",
                "https://res.cloudinary.com/demo/image/upload/v1/capa.jpg",
                "https://res.cloudinary.com/demo/image/upload/v1/logo.jpg",
                true,
                true
        );

        Kiosk atualizado = service.updateStorefront("op-1", req);

        assertThat(atualizado.getDescricaoCurta()).isEqualTo("Especialista em Frutos do Mar e Porções na Orla");
        assertThat(atualizado.getFotoCapaUrl()).isEqualTo("https://res.cloudinary.com/demo/image/upload/v1/capa.jpg");
        assertThat(atualizado.getLogoUrl()).isEqualTo("https://res.cloudinary.com/demo/image/upload/v1/logo.jpg");
        assertThat(atualizado.isDestaquePopular()).isTrue();
        verify(repository).save(kiosk);
    }
}
