package com.penaareia.controller;

import com.penaareia.dto.AuthDtos.AuthResponse;
import com.penaareia.dto.AuthDtos.LoginRequest;
import com.penaareia.dto.AuthDtos.RegisterRequest;
import com.penaareia.service.AuthService;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuthControllerTest {

    @Test
    void delegatesRegistrationAndLogin() {
        AuthService service = mock(AuthService.class);
        AuthController controller = new AuthController(service);
        RegisterRequest registration = mock(RegisterRequest.class);
        LoginRequest login = mock(LoginRequest.class);
        AuthResponse registrationResponse = mock(AuthResponse.class);
        AuthResponse loginResponse = mock(AuthResponse.class);
        when(service.register(registration)).thenReturn(registrationResponse);
        when(service.login(login)).thenReturn(loginResponse);

        assertThat(controller.register(registration)).isSameAs(registrationResponse);
        assertThat(controller.login(login)).isSameAs(loginResponse);

        verify(service).register(registration);
        verify(service).login(login);
    }
}
