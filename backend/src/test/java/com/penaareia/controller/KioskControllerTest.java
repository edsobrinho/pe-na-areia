package com.penaareia.controller;

import com.penaareia.config.JacksonConfig;
import com.penaareia.model.Kiosk;
import com.penaareia.service.KioskService;
import com.penaareia.security.JwtService;
import com.penaareia.support.Fixtures;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Testes de fatia web do KioskController: listagem ativa com GeoJSON canonico
 * (compativel com o modelo Flutter) e preco numerico no cardapio.
 */
@WebMvcTest(KioskController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(JacksonConfig.class)
class KioskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private KioskService kioskService;
    @MockBean
    private JwtService jwtService;

    @Test
    void listarQuiosquesRetornaListaAtivaComGeoJsonCanonico() throws Exception {
        when(kioskService.listarAtivos()).thenReturn(List.of(Fixtures.kioskAtivo()));

        mockMvc.perform(get("/kiosks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(Fixtures.KIOSK_ID))
                .andExpect(jsonPath("$[0].nome").value("Quiosque do Ze"))
                .andExpect(jsonPath("$[0].ativo").value(true))
                .andExpect(jsonPath("$[0].pontoReferenciaId").value(Fixtures.POSTO_ID))
                // GeoJSON canonico: [longitude, latitude], sem x/y redundantes
                .andExpect(jsonPath("$[0].localizacao.type").value("Point"))
                .andExpect(jsonPath("$[0].localizacao.coordinates[0]").value(-46.31))
                .andExpect(jsonPath("$[0].localizacao.coordinates[1]").value(-23.96))
                .andExpect(jsonPath("$[0].localizacao.x").doesNotExist())
                // cardapio com preco numerico decimal
                .andExpect(jsonPath("$[0].cardapio[0].id").value(Fixtures.MENU_ITEM_DISPONIVEL))
                .andExpect(jsonPath("$[0].cardapio[0].preco").value(12.5))
                .andExpect(jsonPath("$[0].cardapio[0].disponivel").value(true));
    }

    @Test
    void listarPorPostoDeReferenciaDelegaParaServico() throws Exception {
        when(kioskService.listarPorPostoReferencia(Fixtures.POSTO_ID))
                .thenReturn(List.of(Fixtures.kioskAtivo()));

        mockMvc.perform(get("/kiosks/by-reference-point/{id}", Fixtures.POSTO_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(Fixtures.KIOSK_ID));

        verify(kioskService).listarPorPostoReferencia(Fixtures.POSTO_ID);
    }

    @Test
    void listarSemQuiosquesAtivosRetornaListaVazia() throws Exception {
        when(kioskService.listarAtivos()).thenReturn(List.of());

        mockMvc.perform(get("/kiosks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    /** Garante que um Kiosk inativo devolvido pelo mock nao contradiz o filtro da consulta. */
    @Test
    void listagemUsaSomenteConsultaDeAtivos() throws Exception {
        Kiosk ativo = Fixtures.kioskAtivo();
        when(kioskService.listarAtivos()).thenReturn(List.of(ativo));

        mockMvc.perform(get("/kiosks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].ativo").value(true));

        verify(kioskService).listarAtivos();
    }
}
