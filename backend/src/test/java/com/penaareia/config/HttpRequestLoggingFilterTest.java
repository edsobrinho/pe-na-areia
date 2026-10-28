package com.penaareia.config;

import io.micrometer.tracing.Tracer;
import io.micrometer.tracing.Span;
import io.micrometer.tracing.TraceContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.servlet.HandlerMapping;
import org.slf4j.MDC;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import net.logstash.logback.encoder.LogstashEncoder;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class HttpRequestLoggingFilterTest {

    private final Tracer tracer = mock(Tracer.class);
    @SuppressWarnings("unchecked")
    private final ObjectProvider<Tracer> tracerProvider = mock(ObjectProvider.class);
    private final HttpRequestLoggingFilter filter = new HttpRequestLoggingFilter(tracerProvider);

    @Test
    void echoesRequestIdAndLogsRouteTraceWithoutQueryData() throws Exception {
        String requestId = "8f14e45f-ea5e-47d3-9c2a-0b1c2d3e4f50";
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/orders/secret-order-id");
        request.addHeader("X-Request-Id", requestId);
        request.setQueryString("email=private@example.test&token=secret");
        request.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, "/orders/{id}");
        MockHttpServletResponse response = new MockHttpServletResponse();
        Logger logger = (Logger) LoggerFactory.getLogger(HttpRequestLoggingFilter.class);
        ListAppender<ILoggingEvent> appender = captureLogs(logger);
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(null);

        try {
            filter.doFilter(request, response, (incoming, outgoing) ->
                    ((MockHttpServletResponse) outgoing).setStatus(202));
        } finally {
            logger.detachAppender(appender);
        }

        assertThat(response.getHeader("X-Request-Id")).isEqualTo(requestId);
        assertThat(response.getStatus()).isEqualTo(202);
        String json = encode(appender.list.getFirst(), logger);
        assertThat(json)
                .contains("api_requisicao_concluida")
                .contains("\"httpPath\":\"/orders/{id}\"")
                .contains("\"httpMethod\":\"GET\"")
                .contains("\"httpStatus\":202")
                .contains("\"requestId\":\"" + requestId + "\"")
                .contains("\"traceId\"")
                .contains("\"spanId\"")
                .contains("\"service\":\"pe-na-areia-backend\"")
                .doesNotContain("private@example.test", "secret");
    }

    @Test
    void logsActiveTraceAndSpanIdentifiers() throws Exception {
        String requestId = "8f14e45f-ea5e-47d3-9c2a-0b1c2d3e4f50";
        String traceId = "11223344556677889900aabbccddeeff";
        String spanId = "1122334455667788";
        Span span = mock(Span.class);
        TraceContext context = mock(TraceContext.class);
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(span);
        when(span.context()).thenReturn(context);
        when(context.traceId()).thenReturn(traceId);
        when(context.spanId()).thenReturn(spanId);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/partnerships");
        request.addHeader("X-Request-Id", requestId);
        request.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, "/partnerships");

        Logger logger = (Logger) LoggerFactory.getLogger(HttpRequestLoggingFilter.class);
        ListAppender<ILoggingEvent> appender = captureLogs(logger);
        try {
            filter.doFilter(request, new MockHttpServletResponse(), (incoming, outgoing) -> { });
        } finally {
            logger.detachAppender(appender);
        }

        String json = encode(appender.list.getFirst(), logger);
        assertThat(json)
                .contains("\"traceId\":\"" + traceId + "\"")
                .contains("\"spanId\":\"" + spanId + "\"");
    }

    @Test
    void replacesUntrustedRequestIdsAndUsesUnmatchedRouteFallback() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/bad\r\nroute");
        request.addHeader("X-Request-Id", "email@example.test");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(null);

        filter.doFilter(request, response, (incoming, outgoing) -> { });

        assertThat(UUID.fromString(response.getHeader("X-Request-Id"))).isNotNull();
    }

    @Test
    void propagatesServletFailuresAfterCompletingTheFilter() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/auth/login");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(null);

        assertThatThrownBy(() -> filter.doFilter(request, response, (FilterChain) (incoming, outgoing) -> {
            throw new ServletException("expected test failure");
        })).isInstanceOf(ServletException.class);
    }

    @Test
    void acceptsNoRouteMappingWithoutFailing() throws IOException, ServletException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/unmapped");
        MockHttpServletResponse response = new MockHttpServletResponse();
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(null);

        filter.doFilter(request, response, (incoming, outgoing) -> { });

        assertThat(response.getHeader("X-Request-Id")).isNotBlank();
    }

    @Test
    void restoresExistingRequestCorrelationFromMdc() throws IOException, ServletException {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/partnerships");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MDC.put("requestId", "upstream-correlation");
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(null);

        try {
            filter.doFilter(request, response, (incoming, outgoing) -> { });
            assertThat(MDC.get("requestId")).isEqualTo("upstream-correlation");
        } finally {
            MDC.remove("requestId");
        }
    }

    @Test
    void logsClientErrorsAsWarningsAndServerErrorsAsErrors() throws Exception {
        Logger logger = (Logger) LoggerFactory.getLogger(HttpRequestLoggingFilter.class);
        ListAppender<ILoggingEvent> appender = captureLogs(logger);
        when(tracerProvider.getIfAvailable()).thenReturn(tracer);
        when(tracer.currentSpan()).thenReturn(null);

        try {
            MockHttpServletResponse clientResponse = new MockHttpServletResponse();
            filter.doFilter(new MockHttpServletRequest("POST", "/auth/login"), clientResponse,
                    (incoming, outgoing) -> ((MockHttpServletResponse) outgoing).setStatus(401));
            MockHttpServletResponse serverResponse = new MockHttpServletResponse();
            filter.doFilter(new MockHttpServletRequest("GET", "/orders"), serverResponse,
                    (incoming, outgoing) -> ((MockHttpServletResponse) outgoing).setStatus(503));
        } finally {
            logger.detachAppender(appender);
        }

        assertThat(appender.list).hasSize(2);
        assertThat(appender.list.get(0).getLevel().toString()).isEqualTo("WARN");
        assertThat(encode(appender.list.get(0), logger)).contains("api_requisicao_rejeitada");
        assertThat(appender.list.get(1).getLevel().toString()).isEqualTo("ERROR");
        assertThat(encode(appender.list.get(1), logger))
                .contains("api_requisicao_falhou")
                .contains("\"error\":\"Http5xx\"");
    }

    private static ListAppender<ILoggingEvent> captureLogs(Logger logger) {
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.setContext(logger.getLoggerContext());
        appender.start();
        logger.addAppender(appender);
        return appender;
    }

    private static String encode(ILoggingEvent event, Logger logger) {
        LogstashEncoder encoder = new LogstashEncoder();
        encoder.setContext(logger.getLoggerContext());
        encoder.setCustomFields("{\"service\":\"pe-na-areia-backend\"}");
        encoder.setIncludeMdc(true);
        encoder.start();
        try {
            return new String(encoder.encode(event), StandardCharsets.UTF_8);
        } finally {
            encoder.stop();
        }
    }
}
