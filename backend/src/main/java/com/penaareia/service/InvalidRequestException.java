package com.penaareia.service;

import org.springframework.http.HttpStatus;

/** Requisicao invalida fora do escopo do Bean Validation -> HTTP 400. */
public class InvalidRequestException extends ApiException {

    public InvalidRequestException(String mensagem) {
        super(HttpStatus.BAD_REQUEST, mensagem);
    }
}
