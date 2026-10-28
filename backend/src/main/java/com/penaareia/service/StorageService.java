package com.penaareia.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * Encapsula o provedor de storage de fotos (hoje Cloudinary).
 * O restante da aplicacao so conhece esta interface - trocar de provedor
 * significa apenas fornecer outra implementacao.
 */
public interface StorageService {

    /**
     * Valida e envia a foto do local do pedido.
     *
     * @param arquivo imagem recebida no multipart/form-data (campo "file")
     * @return URL publica (HTTPS) da imagem
     */
    String enviarFotoLocal(MultipartFile arquivo);

    /**
     * Valida e envia a foto de um item do cardapio.
     *
     * @param arquivo imagem recebida no multipart/form-data (campo "file")
     * @return URL publica (HTTPS) da imagem
     */
    String enviarFotoProduto(MultipartFile arquivo);
}
