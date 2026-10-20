package com.penaareia.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.Map;

/**
 * Corpo padrao de erro de toda a API:
 * <pre>
 * {
 *   "timestamp": "2026-10-13T12:00:00Z",
 *   "status": 400,
 *   "mensagem": "Dados invalidos",
 *   "campos": { "pinCliente.latitude": "Latitude deve estar entre -90 e 90" }
 * }
 * </pre>
 * O campo {@code campos} so aparece em erros de validacao.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(String timestamp, int status, String mensagem, Map<String, String> campos) {
}
