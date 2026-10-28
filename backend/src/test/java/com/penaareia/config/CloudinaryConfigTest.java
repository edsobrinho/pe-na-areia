package com.penaareia.config;

import com.penaareia.security.JwtAuthFilter;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class CloudinaryConfigTest {

    @Test
    void createsCloudinaryClientWithAndWithoutConfiguredCredentials() {
        CloudinaryConfig config = new CloudinaryConfig();
        CloudinaryProperties properties = new CloudinaryProperties();

        assertThat(config.cloudinary(properties)).isNotNull();

        properties.setCloudName("demo");
        properties.setApiKey("key");
        properties.setApiSecret("secret");
        assertThat(config.cloudinary(properties)).isNotNull();
    }

    @Test
    void buildsCorsConfigurationFromTrimmedNonEmptyOrigins() {
        SecurityConfig config = new SecurityConfig(mock(JwtAuthFilter.class));
        ReflectionTestUtils.setField(config, "corsOrigins", " https://example.test, ,http://localhost:5173 ");

        var source = (UrlBasedCorsConfigurationSource) config.corsConfigurationSource();
        var cors = source.getCorsConfiguration(
                new org.springframework.mock.web.MockHttpServletRequest("GET", "/orders"));

        Assertions.assertNotNull(cors);
        assertThat(cors.getAllowedOrigins()).containsExactly("https://example.test", "http://localhost:5173");
        assertThat(cors.getAllowedOriginPatterns()).containsExactly("https://example.test", "http://localhost:5173");
        assertThat(cors.getAllowedHeaders()).contains("X-Request-Id");
        assertThat(cors.getExposedHeaders()).contains("X-Request-Id");
    }
}
