package com.penaareia.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private static final String SECRET = "0123456789abcdef0123456789abcdef";

    @Test
    void geraTokenComIdentidadeEmailEPerfil() {
        JwtService service = new JwtService(SECRET, 60_000);

        String token = service.generateToken("user-1", "ana@example.com", "CLIENT");
        Claims claims = service.parseToken(token);

        assertThat(claims.getSubject()).isEqualTo("user-1");
        assertThat(claims.get("email", String.class)).isEqualTo("ana@example.com");
        assertThat(claims.get("role", String.class)).isEqualTo("CLIENT");
        assertThat(claims.getExpiration()).isAfter(claims.getIssuedAt());
    }

    @Test
    void rejeitaSegredoComMenosDeTrintaEDoisBytes() {
        assertThatThrownBy(() -> new JwtService("curto", 60_000))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("JWT_SECRET deve conter pelo menos 32 bytes.");
    }

    @Test
    void rejeitaTokenComAssinaturaInvalida() {
        JwtService service = new JwtService(SECRET, 60_000);
        String token = service.generateToken("user-1", "ana@example.com", "CLIENT");

        assertThatThrownBy(() -> service.parseToken(token + "invalid"))
                .isInstanceOf(JwtException.class);
    }
}
