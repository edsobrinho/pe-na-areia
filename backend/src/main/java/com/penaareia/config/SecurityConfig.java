package com.penaareia.config;

import com.penaareia.security.JwtAuthFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;
import java.util.Arrays;

@Configuration
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    @Value("${app.cors.origins:http://localhost:*,http://127.0.0.1:*,http://localhost:8090,http://127.0.0.1:8090,http://localhost:5173,http://127.0.0.1:5173}")
    private String corsOrigins;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * CORS para clientes web (Flutter web em portas dinâmicas e painel React).
     * Suporta curingas de porta (ex.: http://localhost:*, http://127.0.0.1:*)
     * via allowedOriginPatterns, além de origens explícitas em APP_CORS_ORIGINS.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        List<String> origins = Arrays.stream(corsOrigins.split(","))
                .map(arg0 -> arg0.trim())
                .filter(origin -> !origin.isEmpty())
                .toList();
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(origins);
        config.setAllowedMethods(List.of("GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization", "X-Request-Id"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(t -> t.disable())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(errors -> errors.authenticationEntryPoint(
                        (request, response, exception) ->
                                response.sendError(org.springframework.http.HttpStatus.UNAUTHORIZED.value())))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(org.springframework.http.HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers("/docs/**", "/api-docs/**", "/swagger-ui/**",
                                "/swagger-ui.html", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/auth/**", "/webhooks/**").permitAll()
                        .requestMatchers("/reference-points/**", "/kiosks/**").permitAll()
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
