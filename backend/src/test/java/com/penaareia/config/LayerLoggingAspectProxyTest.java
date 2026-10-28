package com.penaareia.config;

import com.penaareia.controller.AdminController;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.PartnershipRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.service.AdminService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.aop.support.AopUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith({SpringExtension.class, OutputCaptureExtension.class})
@ContextConfiguration(classes = LayerLoggingAspectProxyTest.TestConfig.class)
class LayerLoggingAspectProxyTest {

    @Autowired
    private AdminController controller;

    @Autowired
    private AdminService service;

    @Autowired
    private PartnershipRepository partnershipRepository;

    @Test
    void logsControllerAndServiceCallsThroughSpringProxies(CapturedOutput output) {
        assertThat(AopUtils.isAopProxy(controller)).isTrue();
        assertThat(AopUtils.isAopProxy(service)).isTrue();
        assertThat(AopUtils.isAopProxy(partnershipRepository)).isTrue();

        var authentication = new UsernamePasswordAuthenticationToken(
                "admin-internal-id", null, List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
        controller.createPartnership(
                new AdminController.CreatePartnershipRequest("Nome confidencial", "CANAL"),
                authentication);

        assertThat(output.getOut())
                .contains("controller_admin_controller_create_partnership_iniciado")
                .contains("controller_admin_controller_create_partnership_concluido")
                .contains("service_admin_service_create_partnership_iniciado")
                .contains("service_admin_service_create_partnership_concluido")
                .contains("repository_partnership_repository_save_iniciado")
                .contains("repository_partnership_repository_save_concluido")
                .doesNotContain("Nome confidencial", "CANAL", "admin-internal-id");
    }

    @Configuration(proxyBeanMethods = false)
    @EnableAspectJAutoProxy(proxyTargetClass = true)
    static class TestConfig {

        @Bean
        LayerLoggingAspect layerLoggingAspect(ObjectProvider<io.micrometer.tracing.Tracer> tracerProvider) {
            return new LayerLoggingAspect(tracerProvider);
        }

        @Bean
        UserRepository userRepository() {
            return mock(UserRepository.class);
        }

        @Bean
        KioskRepository kioskRepository() {
            return mock(KioskRepository.class);
        }

        @Bean
        PartnershipRepository partnershipRepository() {
            PartnershipRepository repository = mock(PartnershipRepository.class);
            when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
            return repository;
        }

        @Bean
        AdminService adminService(
                UserRepository users,
                KioskRepository kiosks,
                PartnershipRepository partnerships) {
            return new AdminService(users, kiosks, partnerships);
        }

        @Bean
        AdminController adminController(AdminService adminService) {
            return new AdminController(adminService);
        }
    }
}
