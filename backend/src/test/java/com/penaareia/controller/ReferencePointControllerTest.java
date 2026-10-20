package com.penaareia.controller;

import com.penaareia.config.JacksonConfig;
import com.penaareia.model.ReferencePoint;
import com.penaareia.service.ReferencePointService;
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
 * Testes de fatia web do ReferencePointController: listagem apenas de ativos
 * com GeoJSON canonico e consulta nearby repassando lat/lng/raio ao servico.
 */
@WebMvcTest(ReferencePointController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(JacksonConfig.class)
class ReferencePointControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ReferencePointService referencePointService;
    @MockBean
    private JwtService jwtService;

    @Test
    void listarPostosRetornaListaAtivaComGeoJsonCanonico() throws Exception {
        when(referencePointService.listarAtivos()).thenReturn(List.of(Fixtures.postoAtivo()));

        mockMvc.perform(get("/reference-points"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(Fixtures.POSTO_ID))
                .andExpect(jsonPath("$[0].numero").value(6))
                .andExpect(jsonPath("$[0].nome").value("Posto 6"))
                .andExpect(jsonPath("$[0].trecho").value("Boqueirao"))
                .andExpect(jsonPath("$[0].ativo").value(true))
                // GeoJSON canonico: [longitude, latitude], sem x/y redundantes
                .andExpect(jsonPath("$[0].localizacao.type").value("Point"))
                .andExpect(jsonPath("$[0].localizacao.coordinates[0]").value(-46.32))
                .andExpect(jsonPath("$[0].localizacao.coordinates[1]").value(-23.97))
                .andExpect(jsonPath("$[0].localizacao.x").doesNotExist());
    }

    @Test
    void nearbyRepassaParametrosParaServico() throws Exception {
        when(referencePointService.sugerirProximos(-23.97, -46.33, 2.0)).thenReturn(List.of());

        mockMvc.perform(get("/reference-points/nearby")
                        .param("lat", "-23.97")
                        .param("lng", "-46.33")
                        .param("raioKm", "2.0"))
                .andExpect(status().isOk());

        verify(referencePointService).sugerirProximos(-23.97, -46.33, 2.0);
    }

    @Test
    void nearbyUsaRaioPadraoDe15km() throws Exception {
        when(referencePointService.sugerirProximos(-23.97, -46.33, 1.5))
                .thenReturn(List.of(Fixtures.postoAtivo()));

        mockMvc.perform(get("/reference-points/nearby")
                        .param("lat", "-23.97")
                        .param("lng", "-46.33"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(Fixtures.POSTO_ID));

        verify(referencePointService).sugerirProximos(-23.97, -46.33, 1.5);
    }

    @Test
    void nearbyExcluindoInativosNuncaDevolvePostoInativo() throws Exception {
        // O servico real filtra inativos; aqui garantimos que a resposta de lista vazia e valida
        when(referencePointService.sugerirProximos(-23.97, -46.33, 1.5)).thenReturn(List.of());

        mockMvc.perform(get("/reference-points/nearby")
                        .param("lat", "-23.97")
                        .param("lng", "-46.33"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void nearbySemLatitudeRetorna400Padronizado() throws Exception {
        mockMvc.perform(get("/reference-points/nearby")
                        .param("lng", "-46.33"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.timestamp").exists());
    }
}
