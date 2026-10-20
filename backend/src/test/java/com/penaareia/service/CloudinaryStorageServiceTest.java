package com.penaareia.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.Uploader;
import com.penaareia.config.CloudinaryProperties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes de unidade do CloudinaryStorageService: validacao local do arquivo
 * (tipo/tamanho) antes de qualquer chamada externa, contrato de resposta
 * (secure_url) e mapeamento de falhas do provedor. O SDK e mockado - nenhuma
 * chamada real ao Cloudinary.
 */
@ExtendWith(MockitoExtension.class)
class CloudinaryStorageServiceTest {

    private static final byte[] PNG_VALIDO =
            {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n', 0, 0, 0, 0};

    @Mock
    private Cloudinary cloudinary;

    @Mock
    private Uploader uploader;

    private static CloudinaryProperties propertiesConfiguradas() {
        CloudinaryProperties properties = new CloudinaryProperties();
        properties.setCloudName("demo");
        properties.setApiKey("123456");
        properties.setApiSecret("segredo");
        return properties;
    }

    private static MockMultipartFile png() {
        return new MockMultipartFile("file", "foto.png", "image/png", PNG_VALIDO);
    }

    @Test
    void enviaPngValidoERetornaSecureUrl() throws IOException {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());
        when(cloudinary.uploader()).thenReturn(uploader);
        when(uploader.upload(any(), anyMap())).thenReturn(
                Map.of("secure_url", "https://res.cloudinary.com/demo/image/upload/foto.png"));

        String url = service.enviarFotoLocal(png());

        assertThat(url).isEqualTo("https://res.cloudinary.com/demo/image/upload/foto.png");
        // A imagem vai para a pasta dedicada de fotos de local
        verify(uploader).upload(any(), argThat(opcoes ->
                "pe-na-areia/fotos-local".equals(opcoes.get("folder"))));
    }

    @Test
    void arquivoVazioLanca400SemChamarProvedor() {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());
        MockMultipartFile vazio = new MockMultipartFile("file", "foto.png", "image/png", new byte[0]);

        assertThatThrownBy(() -> service.enviarFotoLocal(vazio))
                .isInstanceOfSatisfying(InvalidRequestException.class,
                        ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void arquivoAusenteLanca400() {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());

        assertThatThrownBy(() -> service.enviarFotoLocal(null))
                .isInstanceOf(InvalidRequestException.class);
    }

    @Test
    void formatoNaoSuportadoLanca400SemChamarProvedor() {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());
        MockMultipartFile texto = new MockMultipartFile(
                "file", "nota.txt", "text/plain", "isto nao e uma imagem!".getBytes());

        assertThatThrownBy(() -> service.enviarFotoLocal(texto))
                .isInstanceOf(InvalidRequestException.class)
                .hasMessageContaining("Formato invalido");
    }

    @Test
    void arquivoAcimaDe5MbLanca413SemChamarProvedor() {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());
        byte[] grande = new byte[(int) CloudinaryStorageService.TAMANHO_MAXIMO_BYTES + 1];
        MockMultipartFile arquivo = new MockMultipartFile("file", "foto.png", "image/png", grande);

        assertThatThrownBy(() -> service.enviarFotoLocal(arquivo))
                .isInstanceOfSatisfying(ApiException.class,
                        ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE));
    }

    @Test
    void semCredenciaisLanca503SemChamarProvedor() {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, new CloudinaryProperties());

        assertThatThrownBy(() -> service.enviarFotoLocal(png()))
                .isInstanceOfSatisfying(ApiException.class,
                        ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }

    @Test
    void falhaDeIoDoProvedorLanca502() throws IOException {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());
        when(cloudinary.uploader()).thenReturn(uploader);
        when(uploader.upload(any(), anyMap())).thenThrow(new IOException("timeout"));

        assertThatThrownBy(() -> service.enviarFotoLocal(png()))
                .isInstanceOfSatisfying(ApiException.class,
                        ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY));
    }

    @Test
    void respostaSemSecureUrlLanca502() throws IOException {
        CloudinaryStorageService service =
                new CloudinaryStorageService(cloudinary, propertiesConfiguradas());
        when(cloudinary.uploader()).thenReturn(uploader);
        when(uploader.upload(any(), anyMap())).thenReturn(Map.of());

        assertThatThrownBy(() -> service.enviarFotoLocal(png()))
                .isInstanceOfSatisfying(ApiException.class,
                        ex -> assertThat(ex.getStatus()).isEqualTo(HttpStatus.BAD_GATEWAY));
    }
}
