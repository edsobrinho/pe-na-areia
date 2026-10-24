package com.penaareia.service;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Excecao base de negocio/API. Carrega o {@link HttpStatus} que sera
 * devolvido no corpo padrao de erro ({@code com.penaareia.dto.ErrorResponse}).
 */
@Getter
public class ApiException extends RuntimeException {

    private final HttpStatus status;

    public ApiException(HttpStatus status, String mensagem) {
        super(mensagem);
        this.status = status;
    }

}
