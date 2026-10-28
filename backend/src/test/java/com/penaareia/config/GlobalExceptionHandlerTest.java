package com.penaareia.config;

import com.penaareia.service.ApiException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Path;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.bind.MethodArgumentNotValidException;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import net.logstash.logback.encoder.LogstashEncoder;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();
    private final HttpHeaders headers = new HttpHeaders();
    private final WebRequest request = mock(WebRequest.class);

    @Test
    void mapsApiAndConstraintValidationExceptions() {
        var apiResponse = handler.handleApi(new ApiException(HttpStatus.CONFLICT, "Conflict"));
        assertThat(apiResponse.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(apiResponse.getBody().mensagem()).isEqualTo("Conflict");

        @SuppressWarnings("unchecked")
        ConstraintViolation<Object> violation = mock(ConstraintViolation.class);
        Path path = mock(Path.class);
        when(path.toString()).thenReturn("request.name");
        when(violation.getPropertyPath()).thenReturn(path);
        when(violation.getMessage()).thenReturn("is required");
        var validationResponse = handler.handleConstraintViolation(
                new ConstraintViolationException(Set.of(violation)));
        assertThat(validationResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(validationResponse.getBody().campos()).containsEntry("request.name", "is required");
    }

    @Test
    void mapsBodyFieldAndMalformedJsonValidationErrors() {
        BindingResult bindingResult = mock(BindingResult.class);
        when(bindingResult.getFieldErrors()).thenReturn(
                java.util.List.of(new FieldError("request", "email", "must be valid")));
        MethodArgumentNotValidException invalid = mock(MethodArgumentNotValidException.class);
        when(invalid.getBindingResult()).thenReturn(bindingResult);
        var fieldResponse = handler.handleMethodArgumentNotValid(
                invalid, headers, HttpStatus.BAD_REQUEST, request);
        assertThat(fieldResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(((com.penaareia.dto.ErrorResponse) fieldResponse.getBody()).campos())
                .containsEntry("email", "must be valid");

        var malformedResponse = handler.handleHttpMessageNotReadable(
                mock(HttpMessageNotReadableException.class), headers, HttpStatus.BAD_REQUEST, request);
        assertThat(malformedResponse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(((com.penaareia.dto.ErrorResponse) malformedResponse.getBody()).mensagem())
                .isEqualTo("Corpo da requisicao invalido ou malformado");
    }

    @Test
    void mapsUnexpectedErrorsToSafeResponseAndDoesNotLogExceptionDetails() {
        Logger logger = (Logger) LoggerFactory.getLogger(GlobalExceptionHandler.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.setContext(logger.getLoggerContext());
        appender.start();
        logger.addAppender(appender);
        var response = handler.handleGenerico(new IllegalStateException("private detail"));
        logger.detachAppender(appender);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody().mensagem()).isEqualTo("Erro interno do servidor");
        LogstashEncoder encoder = new LogstashEncoder();
        encoder.setContext(logger.getLoggerContext());
        encoder.start();
        String json;
        try {
            json = new String(encoder.encode(appender.list.getFirst()), StandardCharsets.UTF_8);
        } finally {
            encoder.stop();
        }
        assertThat(json)
                .contains("api_unexpected_error")
                .contains("IllegalStateException")
                .doesNotContain("private detail");
    }

    @Test
    void mapsCommonMvcStatusesToFriendlyMessages() {
        assertThat(handler.handleExceptionInternal(
                new Exception(), null, headers, HttpStatus.NOT_FOUND, request).getBody().toString())
                .contains("Nao encontrado");
        assertThat(handler.handleExceptionInternal(
                new Exception(), null, headers, HttpStatus.METHOD_NOT_ALLOWED, request).getBody().toString())
                .contains("Metodo HTTP nao suportado");
        assertThat(handler.handleExceptionInternal(
                new Exception(), null, headers, HttpStatus.PAYLOAD_TOO_LARGE, request).getBody().toString())
                .contains("Imagem maior que o limite de 5MB");
        assertThat(handler.handleExceptionInternal(
                new Exception(), null, headers, HttpStatus.UNSUPPORTED_MEDIA_TYPE, request).getBody().toString())
                .contains("Tipo de conteudo nao suportado");
        assertThat(handler.handleExceptionInternal(
                new Exception(), null, headers, HttpStatus.INTERNAL_SERVER_ERROR, request).getBody().toString())
                .contains("Erro interno do servidor");
        assertThat(handler.handleExceptionInternal(
                new Exception(), null, headers, HttpStatus.FORBIDDEN, request).getBody().toString())
                .contains("Erro na requisicao");
    }
}
