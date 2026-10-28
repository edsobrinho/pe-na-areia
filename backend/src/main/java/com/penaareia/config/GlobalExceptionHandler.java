package com.penaareia.config;

import com.penaareia.dto.ErrorResponse;
import com.penaareia.service.ApiException;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import static net.logstash.logback.argument.StructuredArguments.kv;

/**
 * Padroniza todos os erros da API no corpo {@link ErrorResponse}:
 * <pre>{ "timestamp": ..., "status": ..., "mensagem": ..., "campos": {...} }</pre>
 * Erros de validacao (Bean Validation em cascata) retornam 400 com o mapa
 * de {@code campos}; excecoes de negocio vem de {@link ApiException} com o
 * status embutido; os demais erros do Spring MVC passam pelo mesmo envelope.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ErrorResponse> handleApi(ApiException ex) {
        return ResponseEntity.status(ex.getStatus())
                .body(new ErrorResponse(agora(), ex.getStatus().value(), ex.getMessage(), null));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException ex) {
        Map<String, String> campos = new LinkedHashMap<>();
        ex.getConstraintViolations().forEach(violacao ->
                campos.put(violacao.getPropertyPath().toString(), violacao.getMessage()));
        return ResponseEntity.badRequest()
                .body(new ErrorResponse(agora(), 400, "Dados invalidos", campos));
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> campos = new LinkedHashMap<>();
        for (FieldError erro : ex.getBindingResult().getFieldErrors()) {
            campos.put(erro.getField(), erro.getDefaultMessage());
        }
        return ResponseEntity.status(status)
                .body(new ErrorResponse(agora(), status.value(), "Dados invalidos", campos));
    }

    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(HttpMessageNotReadableException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        return ResponseEntity.status(status)
                .body(new ErrorResponse(agora(), status.value(),
                        "Corpo da requisicao invalido ou malformado", null));
    }

    /** Todos os demais erros do Spring MVC (parametro faltando, metodo errado etc.). */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception ex, Object body, HttpHeaders headers,
            HttpStatusCode statusCode, WebRequest request) {
        ErrorResponse padrao = new ErrorResponse(agora(), statusCode.value(), mensagemPadrao(statusCode), null);
        return super.handleExceptionInternal(ex, padrao, headers, statusCode, request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenerico(Exception ex) {
        log.error("api_unexpected_error", kv("error", ex.getClass().getSimpleName()));
        return ResponseEntity.internalServerError()
                .body(new ErrorResponse(agora(), 500, "Erro interno do servidor", null));
    }

    private static String agora() {
        return Instant.now().toString();
    }

    private static String mensagemPadrao(HttpStatusCode status) {
        return switch (status.value()) {
            case 400 -> "Requisicao invalida";
            case 404 -> "Nao encontrado";
            case 405 -> "Metodo HTTP nao suportado";
            case 413 -> "Imagem maior que o limite de 5MB";
            case 415 -> "Tipo de conteudo nao suportado";
            case 500 -> "Erro interno do servidor";
            default -> "Erro na requisicao";
        };
    }
}
