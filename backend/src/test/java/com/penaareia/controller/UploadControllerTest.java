package com.penaareia.controller;

import com.penaareia.service.ApiException;
import com.penaareia.service.BusinessRuleException;
import com.penaareia.service.InvalidRequestException;
import com.penaareia.service.StorageService;
import com.penaareia.security.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Testes de fatia web do UploadController (POST /uploads/location-photo):
 * contrato multipart campo "file" -> JSON { "secureUrl": ... } e mapeamento
 * dos erros padronizados (400/413/503). O StorageService e mockado - nenhuma
 * chamada real ao Cloudinary.
 */
@WebMvcTest(UploadController.class)
@AutoConfigureMockMvc(addFilters = false)
class UploadControllerTest {

    private static final byte[] PNG_VALIDO =
            {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n', 0, 0, 0, 0};

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private StorageService storageService;
    @MockBean
    private JwtService jwtService;

    private static MockMultipartFile png() {
        return new MockMultipartFile("file", "foto.png", "image/png", PNG_VALIDO);
    }

    @Test
    void uploadRetorna200ComSecureUrl() throws Exception {
        when(storageService.enviarFotoLocal(any()))
                .thenReturn("https://res.cloudinary.com/demo/image/upload/foto-local.png");

        mockMvc.perform(multipart("/uploads/location-photo").file(png()))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.secureUrl")
                        .value("https://res.cloudinary.com/demo/image/upload/foto-local.png"));

        verify(storageService).enviarFotoLocal(any());
    }

    @Test
    void uploadSemArquivoRetorna400Padronizado() throws Exception {
        mockMvc.perform(multipart("/uploads/location-photo"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void formatoInvalidoRetorna400Padronizado() throws Exception {
        when(storageService.enviarFotoLocal(any()))
                .thenThrow(new InvalidRequestException("Formato invalido: envie uma imagem JPEG, PNG ou WebP"));

        mockMvc.perform(multipart("/uploads/location-photo").file(png()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.mensagem")
                        .value("Formato invalido: envie uma imagem JPEG, PNG ou WebP"));
    }

    @Test
    void arquivoAcimaDe5MbRetorna413Padronizado() throws Exception {
        when(storageService.enviarFotoLocal(any()))
                .thenThrow(new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "Imagem maior que o limite de 5MB"));

        mockMvc.perform(multipart("/uploads/location-photo").file(png()))
                .andExpect(status().isPayloadTooLarge())
                .andExpect(jsonPath("$.status").value(413));
    }

    @Test
    void cloudinaryNaoConfiguradoRetorna503() throws Exception {
        when(storageService.enviarFotoLocal(any()))
                .thenThrow(new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Upload de fotos indisponivel: Cloudinary nao configurado"));

        mockMvc.perform(multipart("/uploads/location-photo").file(png()))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.status").value(503));
    }

    /** Erros de negocio tambem passam pelo mesmo envelope padronizado. */
    @Test
    void erroDeNegocioRetornaEnvelopePadronizado() throws Exception {
        when(storageService.enviarFotoLocal(any()))
                .thenThrow(new BusinessRuleException("Regra de upload violada"));

        mockMvc.perform(multipart("/uploads/location-photo").file(png()))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.mensagem").value("Regra de upload violada"))
                .andExpect(jsonPath("$.timestamp").exists());
    }
}
