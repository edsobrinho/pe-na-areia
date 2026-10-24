package com.penaareia.service;

import org.springframework.http.HttpStatus;

/** Recurso não encontrado -> HTTP 404. */
public class ResourceNotFoundException extends ApiException {

    public ResourceNotFoundException(String mensagem) {
        super(HttpStatus.NOT_FOUND, mensagem);
    }
}
