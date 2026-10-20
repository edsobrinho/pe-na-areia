package com.penaareia.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public final class AuthDtos {

    private AuthDtos() {
    }

    public enum Role {
        CLIENT,
        COURIER
    }

    public record LoginRequest(
            @NotBlank @Email String email,
            @NotBlank String password
    ) {
    }

    public record RegisterRequest(
            @NotBlank String name,
            @NotBlank @Email String email,
            @NotBlank String phone,
            @NotBlank @Size(min = 6) String password,
            @NotBlank String role,
            String vehicle
    ) {
    }

    public record AuthResponse(String token, String userId, String name, String role) {
    }
}
