package com.penaareia.config;

import io.micrometer.tracing.Span;
import io.micrometer.tracing.Tracer;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

import java.util.Locale;
import java.util.regex.Pattern;

import static net.logstash.logback.argument.StructuredArguments.kv;

@Aspect
@Component
public class LayerLoggingAspect {

    private static final Pattern CAMEL_CASE_BOUNDARY = Pattern.compile("([a-z0-9])([A-Z])");

    private final ObjectProvider<Tracer> tracerProvider;

    public LayerLoggingAspect(ObjectProvider<Tracer> tracerProvider) {
        this.tracerProvider = tracerProvider;
    }

    @Around("execution(public * com.penaareia.controller.AdminController.*(..))"
            + " || execution(public * com.penaareia.controller.AuthController.*(..))"
            + " || execution(public * com.penaareia.controller.KioskController.*(..))"
            + " || execution(public * com.penaareia.controller.OrderController.*(..))"
            + " || execution(public * com.penaareia.controller.PartnershipController.*(..))"
            + " || execution(public * com.penaareia.controller.ReferencePointController.*(..))"
            + " || execution(public * com.penaareia.controller.UploadController.*(..))"
            + " || execution(public * com.penaareia.service.AdminService.*(..))"
            + " || execution(public * com.penaareia.service.AuthService.*(..))"
            + " || execution(public * com.penaareia.service.CloudinaryStorageService.*(..))"
            + " || execution(public * com.penaareia.service.KioskService.*(..))"
            + " || execution(public * com.penaareia.service.OrderService.*(..))"
            + " || execution(public * com.penaareia.service.OrderWorkflowService.*(..))"
            + " || execution(public * com.penaareia.service.PartnershipPricingService.*(..))"
            + " || execution(public * com.penaareia.service.PartnershipService.*(..))"
            + " || execution(public * com.penaareia.service.ReferencePointService.*(..))"
            + " || execution(public * com.penaareia.security.JwtService.*(..))"
            + " || execution(public * com.penaareia.security.JwtAuthFilter.*(..))"
            + " || (execution(public * *(..)) && (this(com.penaareia.repository.UserRepository)"
            + " || this(com.penaareia.repository.KioskRepository)"
            + " || this(com.penaareia.repository.PartnershipRepository)"
            + " || this(com.penaareia.repository.ReferencePointRepository)"
            + " || this(com.penaareia.repository.CourierRepository)"
            + " || this(com.penaareia.repository.KioskPartnershipRepository)"
            + " || this(com.penaareia.repository.OrderRepository)))")
    public Object logLayerMethod(ProceedingJoinPoint joinPoint) throws Throwable {
        Class<?> declaredType = joinPoint.getSignature().getDeclaringType();
        Class<?> componentType = repositoryInterface(joinPoint, declaredType);
        String component = snakeCase(componentType.getSimpleName());
        String layer = layerOf(componentType);
        String operation = snakeCase(((MethodSignature) joinPoint.getSignature()).getMethod().getName());
        String eventPrefix = layer + "_" + component + "_" + operation;
        Logger logger = LoggerFactory.getLogger(componentType);
        long startNanos = System.nanoTime();

        updateTraceMdc();
        logger.info(eventPrefix + "_iniciado",
                kv("layer", layer),
                kv("component", component),
                kv("operation", operation));

        try {
            Object result = joinPoint.proceed();
            logger.info(eventPrefix + "_concluido",
                    kv("layer", layer),
                    kv("component", component),
                    kv("operation", operation),
                    kv("durationMs", elapsedMillis(startNanos)));
            return result;
        } catch (Throwable exception) {
            Object[] fields = {
                    kv("layer", layer),
                    kv("component", component),
                    kv("operation", operation),
                    kv("durationMs", elapsedMillis(startNanos)),
                    kv("error", exception.getClass().getSimpleName())
            };
            if (isExpectedClientFailure(exception)) {
                logger.warn(eventPrefix + "_rejeitado",
                        append(fields, kv("motivo", snakeCase(exception.getClass().getSimpleName()))));
            } else {
                logger.error(eventPrefix + "_falhou", fields);
            }
            throw exception;
        }
    }

    private void updateTraceMdc() {
        Tracer tracer = tracerProvider.getIfAvailable();
        Span span = tracer == null ? null : tracer.currentSpan();
        if (span != null) {
            MDC.put("traceId", span.context().traceId());
            MDC.put("spanId", span.context().spanId());
        }
    }

    private static boolean isExpectedClientFailure(Throwable exception) {
        return exception instanceof com.penaareia.service.ApiException apiException
                && apiException.getStatus().is4xxClientError();
    }

    private static String layerOf(Class<?> type) {
        String packageName = type.getPackageName();
        if (packageName.contains(".controller")) {
            return "controller";
        }
        if (packageName.contains(".repository")) {
            return "repository";
        }
        if (packageName.contains(".security")) {
            return "security";
        }
        return "service";
    }

    private static Class<?> repositoryInterface(ProceedingJoinPoint joinPoint, Class<?> declaredType) {
        Class<?> repositoryType = repositoryType(declaredType);
        if (repositoryType == null) {
            repositoryType = repositoryType(joinPoint.getThis().getClass());
        }
        return repositoryType == null ? joinPoint.getTarget().getClass() : repositoryType;
    }

    private static Class<?> repositoryType(Class<?> type) {
        if (type == null || type == Object.class) {
            return null;
        }
        if (type.isInterface() && type.getPackageName().startsWith("com.penaareia.repository")) {
            return type;
        }
        for (Class<?> implementedInterface : type.getInterfaces()) {
            Class<?> repositoryType = repositoryType(implementedInterface);
            if (repositoryType != null) {
                return repositoryType;
            }
        }
        Class<?> parentType = repositoryType(type.getSuperclass());
        if (parentType != null) {
            return parentType;
        }
        return type.getPackageName().startsWith("com.penaareia.repository") ? type : null;
    }

    private static String snakeCase(String value) {
        return CAMEL_CASE_BOUNDARY.matcher(value)
                .replaceAll("$1_$2")
                .replace('-', '_')
                .toLowerCase(Locale.ROOT);
    }

    private static long elapsedMillis(long startNanos) {
        return (System.nanoTime() - startNanos) / 1_000_000;
    }

    private static Object[] append(Object[] fields, Object field) {
        Object[] result = java.util.Arrays.copyOf(fields, fields.length + 1);
        result[fields.length] = field;
        return result;
    }
}
