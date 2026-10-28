package com.penaareia.config;

import io.micrometer.tracing.Span;
import io.micrometer.tracing.Tracer;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerMapping;

import java.io.IOException;
import java.util.UUID;
import java.util.regex.Pattern;

import static net.logstash.logback.argument.StructuredArguments.kv;

@Component
@Order(Ordered.LOWEST_PRECEDENCE)
public class HttpRequestLoggingFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(HttpRequestLoggingFilter.class);
    private static final String REQUEST_ID_HEADER = "X-Request-Id";
    private static final Pattern SAFE_REQUEST_ID = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$");

    private final ObjectProvider<Tracer> tracerProvider;

    public HttpRequestLoggingFilter(ObjectProvider<Tracer> tracerProvider) {
        this.tracerProvider = tracerProvider;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        String requestId = safeRequestId(request.getHeader(REQUEST_ID_HEADER));
        response.setHeader(REQUEST_ID_HEADER, requestId);
        String previousRequestId = MDC.get("requestId");
        String previousTraceId = MDC.get("traceId");
        String previousSpanId = MDC.get("spanId");
        MDC.put("requestId", requestId);
        MDC.put("traceId", UUID.randomUUID().toString().replace("-", ""));
        MDC.put("spanId", UUID.randomUUID().toString().replace("-", "").substring(16));

        long startNanos = System.nanoTime();
        String escapedExceptionType = null;
        try {
            filterChain.doFilter(request, response);
        } catch (IOException | ServletException | RuntimeException exception) {
            escapedExceptionType = exception.getClass().getSimpleName();
            throw exception;
        } finally {
            Tracer tracer = tracerProvider.getIfAvailable();
            Span currentSpan = tracer == null ? null : tracer.currentSpan();
            if (currentSpan != null) {
                MDC.put("traceId", currentSpan.context().traceId());
                MDC.put("spanId", currentSpan.context().spanId());
            }
            String route = matchedRoute(request);
            int status = escapedExceptionType != null && response.getStatus() < 500
                    ? 500 : response.getStatus();
            long durationMs = (System.nanoTime() - startNanos) / 1_000_000;
            Object[] fields = {
                    kv("httpMethod", request.getMethod()),
                    kv("httpPath", route),
                    kv("httpStatus", status),
                    kv("durationMs", durationMs)
            };

            if (status >= 500) {
                log.error("api_requisicao_falhou",
                        append(fields,
                                kv("motivo", "falha_interna"),
                                kv("error", escapedExceptionType == null
                                        ? "Http5xx" : escapedExceptionType)));
            } else if (status >= 400) {
                log.warn("api_requisicao_rejeitada", append(fields, kv("motivo", "requisicao_4xx")));
            } else {
                log.info("api_requisicao_concluida", fields);
            }
            restoreMdc("requestId", previousRequestId);
            restoreMdc("traceId", previousTraceId);
            restoreMdc("spanId", previousSpanId);
        }
    }

    private static String safeRequestId(String candidate) {
        if (candidate != null && SAFE_REQUEST_ID.matcher(candidate).matches()) {
            return candidate;
        }
        return UUID.randomUUID().toString();
    }

    private static String matchedRoute(HttpServletRequest request) {
        Object route = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
        return route instanceof String pattern ? pattern : "UNMATCHED";
    }

    private static void restoreMdc(String key, String previousValue) {
        if (previousValue == null) {
            MDC.remove(key);
        } else {
            MDC.put(key, previousValue);
        }
    }

    private static Object[] append(Object[] fields, Object... additionalFields) {
        Object[] result = java.util.Arrays.copyOf(fields, fields.length + additionalFields.length);
        System.arraycopy(additionalFields, 0, result, fields.length, additionalFields.length);
        return result;
    }
}
