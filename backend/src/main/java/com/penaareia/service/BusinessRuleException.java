package com.penaareia.service;

import org.springframework.http.HttpStatus;

/**
 * Violacao de regra de negócio com recurso existente, porem inutilizável
 * (ex: usuario/quiosque/posto inativo, item indisponível) -> HTTP 422.
 */
public class BusinessRuleException extends ApiException {

    public BusinessRuleException(String mensagem) {
        super(HttpStatus.UNPROCESSABLE_ENTITY, mensagem);
    }
}
