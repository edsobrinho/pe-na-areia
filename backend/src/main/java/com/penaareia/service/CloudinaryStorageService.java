package com.penaareia.service;

import com.cloudinary.Cloudinary;
import com.penaareia.config.CloudinaryProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Implementacao do {@link StorageService} sobre o Cloudinary.
 * As credenciais vem das variaveis de ambiente CLOUDINARY_CLOUD_NAME,
 * CLOUDINARY_API_KEY e CLOUDINARY_API_SECRET (ver application.yml).
 */
@Service
@RequiredArgsConstructor
public class CloudinaryStorageService implements StorageService {

    /** Limite de 5MB por foto (mesmo limite configurado no multipart do Spring). */
    static final long TAMANHO_MAXIMO_BYTES = 5L * 1024 * 1024;

    /** Pasta no Cloudinary para separar as fotos de local dos demais assets. */
    static final String PASTA_FOTOS = "pe-na-areia/fotos-local";

    /** Pasta no Cloudinary para fotos de produtos do cardapio. */
    static final String PASTA_CARDAPIO = "pe-na-areia/cardapio";

    private final Cloudinary cloudinary;
    private final CloudinaryProperties properties;

    @Override
    public String enviarFotoLocal(MultipartFile arquivo) {
        return uploadParaPasta(arquivo, PASTA_FOTOS);
    }

    @Override
    public String enviarFotoProduto(MultipartFile arquivo) {
        return uploadParaPasta(arquivo, PASTA_CARDAPIO);
    }

    private String uploadParaPasta(MultipartFile arquivo, String pasta) {
        byte[] conteudo = validar(arquivo);

        if (!properties.configurado()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Upload de fotos indisponivel: Cloudinary nao configurado");
        }

        Map<String, Object> opcoes = new HashMap<>();
        opcoes.put("folder", pasta);

        try {
            Map<?, ?> resultado = cloudinary.uploader().upload(conteudo, opcoes);
            Object secureUrl = resultado.get("secure_url");
            if (secureUrl == null) {
                throw new ApiException(HttpStatus.BAD_GATEWAY,
                        "Cloudinary nao retornou a URL segura (secure_url) do upload");
            }
            return secureUrl.toString();
        } catch (IOException e) {
            throw new ApiException(HttpStatus.BAD_GATEWAY,
                    "Falha ao enviar a foto para o Cloudinary: " + e.getMessage());
        }
    }

    /**
     * Valida o arquivo antes de qualquer chamada externa:
     * presente, nao vazio, ate 5MB e com assinatura de imagem JPEG, PNG ou WebP.
     */
    private byte[] validar(MultipartFile arquivo) {
        if (arquivo == null || arquivo.isEmpty()) {
            throw new InvalidRequestException("Envie um arquivo de imagem no campo 'file'");
        }
        if (arquivo.getSize() > TAMANHO_MAXIMO_BYTES) {
            throw new ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "Imagem maior que o limite de 5MB");
        }

        byte[] conteudo;
        try {
            conteudo = arquivo.getBytes();
        } catch (IOException e) {
            throw new InvalidRequestException("Nao foi possivel ler o arquivo enviado");
        }

        if (!ehImagemSuportada(conteudo)) {
            throw new InvalidRequestException("Formato invalido: envie uma imagem JPEG, PNG ou WebP");
        }
        return conteudo;
    }

    /** Confere a assinatura (magic bytes) dos formatos suportados. */
    private static boolean ehImagemSuportada(byte[] b) {
        if (b == null || b.length < 12) {
            return false;
        }
        boolean jpeg = (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF;
        boolean png = (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G';
        boolean webp = b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P';
        return jpeg || png || webp;
    }
}
