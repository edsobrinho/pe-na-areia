package com.penaareia.config;

import com.penaareia.controller.AdminController;
import com.penaareia.model.Partnership;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.PartnershipRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.service.AdminService;
import io.micrometer.tracing.Tracer;
import net.logstash.logback.encoder.LogstashEncoder;
import org.junit.jupiter.api.Test;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.extension.ExtendWith;

import java.nio.charset.StandardCharsets;
import java.lang.reflect.Method;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(OutputCaptureExtension.class)
class LayerLoggingAspectTest {

    @SuppressWarnings("unchecked")
    private final ObjectProvider<Tracer> tracerProvider = mock(ObjectProvider.class);
    private final LayerLoggingAspect aspect = new LayerLoggingAspect(tracerProvider);

    @Test
    void logsControllerServiceAndRepositoryMethodsWithoutArgumentsOrPayloads(CapturedOutput output) throws Throwable {
        PartnershipRepository repositoryMock = mock(PartnershipRepository.class);
        when(repositoryMock.save(any(Partnership.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        PartnershipRepository repository = repositoryMock;

        AdminService serviceTarget = new AdminService(
                mock(UserRepository.class), mock(KioskRepository.class), repository);
        AdminService service = serviceTarget;
        AdminController controller = new AdminController(service);
        var authentication = new UsernamePasswordAuthenticationToken(
                "admin-internal-id", null, List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));

        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        ListAppender<ILoggingEvent> appender = capture(root);
        MDC.put("requestId", "8f14e45f-ea5e-47d3-9c2a-0b1c2d3e4f50");
        MDC.put("traceId", "11223344556677889900aabbccddeeff");
        MDC.put("spanId", "1122334455667788");
        try {
            invokeLayer(controller, AdminController.class, "createPartnership",
                    new Class<?>[] {AdminController.CreatePartnershipRequest.class,
                            org.springframework.security.core.Authentication.class},
                    () -> controller.createPartnership(
                            new AdminController.CreatePartnershipRequest("Nome confidencial", "CANAL"),
                            authentication));
            invokeLayer(service, AdminService.class, "createPartnership",
                    new Class<?>[] {String.class, String.class},
                    () -> service.createPartnership("Nome confidencial", "CANAL"));
            Partnership savedPartnership = new Partnership();
            invokeLayer(repositoryMock, PartnershipRepository.class, "save",
                    new Class<?>[] {Object.class},
                    () -> repositoryMock.save(savedPartnership));
        } finally {
            root.detachAppender(appender);
            MDC.clear();
        }

        List<String> logs = appender.list.stream().map(event -> encode(event, root)).toList();
        assertThat(logs).anySatisfy(line -> assertThat(line)
                .contains("controller_admin_controller_create_partnership_iniciado"));
        assertThat(logs).anySatisfy(line -> assertThat(line)
                .contains("controller_admin_controller_create_partnership_concluido"));
        assertThat(logs).anySatisfy(line -> assertThat(line)
                .contains("service_admin_service_create_partnership_iniciado"));
        assertThat(logs).anySatisfy(line -> assertThat(line)
                .contains("service_admin_service_create_partnership_concluido"));
        assertThat(logs).anySatisfy(line -> assertThat(line)
                .contains("repository_partnership_repository_save_iniciado"));
        assertThat(logs).anySatisfy(line -> assertThat(line)
                .contains("repository_partnership_repository_save_concluido"));
        assertThat(String.join("\n", logs))
                .contains("\"service\":\"pe-na-areia-backend\"")
                .doesNotContain("Nome confidencial", "CANAL", "admin-internal-id");
        assertThat(logs).allSatisfy(line -> assertThat(line)
                .contains("\"requestId\"", "\"traceId\"", "\"spanId\""));
        assertThat(output.getOut()).doesNotContain("Nome confidencial", "CANAL", "admin-internal-id");
    }

    @Test
    void logsExpectedBusinessFailuresAsWarningsWithoutExceptionMessages(CapturedOutput output) {
        UserRepository userRepository = mock(UserRepository.class);
        KioskRepository kioskRepository = mock(KioskRepository.class);
        PartnershipRepository partnershipRepository = mock(PartnershipRepository.class);
        com.penaareia.model.User inactiveUser = new com.penaareia.model.User();
        inactiveUser.setAtivo(false);
        when(userRepository.findByEmail("person@example.test")).thenReturn(java.util.Optional.of(inactiveUser));
        when(kioskRepository.findById("kiosk-id")).thenReturn(java.util.Optional.of(new com.penaareia.model.Kiosk()));
        AdminService service = new AdminService(userRepository, kioskRepository, partnershipRepository);

        Logger logger = (Logger) LoggerFactory.getLogger(AdminService.class);
        ListAppender<ILoggingEvent> appender = capture(logger);
        try {
            org.assertj.core.api.Assertions.assertThatThrownBy(
                    () -> invokeLayer(service, AdminService.class, "assignKioskOperator",
                            new Class<?>[] {String.class, String.class},
                            () -> service.assignKioskOperator("person@example.test", "kiosk-id")))
                    .isInstanceOf(com.penaareia.service.BusinessRuleException.class);
        } finally {
            logger.detachAppender(appender);
        }

        assertThat(appender.list).hasSize(2);
        ILoggingEvent rejected = appender.list.getLast();
        assertThat(rejected.getLevel().toString()).isEqualTo("WARN");
        String json = encode(rejected, logger);
        assertThat(json)
                .contains("service_admin_service_assign_kiosk_operator_rejeitado")
                .contains("\"error\":\"BusinessRuleException\"")
                .doesNotContain("person@example.test", "kiosk-id", "inativo");
        assertThat(output.getOut()).doesNotContain("person@example.test", "kiosk-id", "inativo");
    }

    @Test
    void logsUnexpectedFailuresAsErrorsWithoutExceptionMessages(CapturedOutput output) {
        PartnershipRepository repositoryMock = mock(PartnershipRepository.class);
        when(repositoryMock.findByActiveTrue()).thenThrow(new IllegalStateException("private detail"));
        Logger logger = (Logger) LoggerFactory.getLogger(PartnershipRepository.class);
        ListAppender<ILoggingEvent> appender = capture(logger);
        try {
            org.assertj.core.api.Assertions.assertThatThrownBy(
                    () -> invokeLayer(repositoryMock, PartnershipRepository.class, "findByActiveTrue",
                            new Class<?>[0], repositoryMock::findByActiveTrue))
                    .isInstanceOf(IllegalStateException.class);
        } finally {
            logger.detachAppender(appender);
        }

        assertThat(appender.list).hasSize(2);
        ILoggingEvent failed = appender.list.getLast();
        assertThat(failed.getLevel().toString()).isEqualTo("ERROR");
        assertThat(encode(failed, logger))
                .contains("repository_partnership_repository_find_by_active_true_falhou")
                .contains("\"error\":\"IllegalStateException\"")
                .doesNotContain("private detail");
        assertThat(output.getOut()).doesNotContain("private detail");
    }

    private Object invokeLayer(
            Object target,
            Class<?> declaredType,
            String methodName,
            Class<?>[] parameterTypes,
            ProceedingCall call) throws Throwable {
        Method method = declaredType.getMethod(methodName, parameterTypes);
        MethodSignature signature = mock(MethodSignature.class);
        when(signature.getDeclaringType()).thenReturn(declaredType);
        when(signature.getMethod()).thenReturn(method);
        ProceedingJoinPoint joinPoint = mock(ProceedingJoinPoint.class);
        when(joinPoint.getSignature()).thenReturn(signature);
        when(joinPoint.getTarget()).thenReturn(target);
        when(joinPoint.getThis()).thenReturn(target);
        when(joinPoint.proceed()).thenAnswer(invocation -> call.proceed());
        return aspect.logLayerMethod(joinPoint);
    }

    @FunctionalInterface
    private interface ProceedingCall {
        Object proceed() throws Throwable;
    }

    private static ListAppender<ILoggingEvent> capture(Logger logger) {
        logger.setLevel(Level.INFO);
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
