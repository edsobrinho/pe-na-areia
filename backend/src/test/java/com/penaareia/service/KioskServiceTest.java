package com.penaareia.service;

import com.penaareia.model.Kiosk;
import com.penaareia.repository.KioskRepository;
import com.penaareia.support.Fixtures;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes de unidade do KioskService: a listagem usa as consultas que filtram
 * apenas quiosques ativos.
 */
@ExtendWith(MockitoExtension.class)
class KioskServiceTest {

    @Mock
    private KioskRepository repository;

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
}
