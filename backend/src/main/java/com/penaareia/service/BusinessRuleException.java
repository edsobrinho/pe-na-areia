package com.penaareia.service;

import org.springframework.http.HttpStatus;

/**
 * Violacao de regra de negocio com recurso existente, porem inutilizavel
 * (ex: usuario/quiosque/posto inativo, item indisponivel) -> HTTP 422.
 */
public class BusinessRuleException extends ApiException {

    public BusinessRuleException(String mensagem) {
        super(HttpStatus.UNPROCESSABLE_ENTITY, mensagem);
    }
}
