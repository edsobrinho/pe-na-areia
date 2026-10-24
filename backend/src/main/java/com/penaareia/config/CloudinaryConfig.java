package com.penaareia.config;

import com.cloudinary.Cloudinary;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

import java.util.HashMap;
import java.util.Map;

/**
 * Cria o cliente Cloudinary a partir das credenciais configuradas.
 * Sem credenciais o bean ainda sobe (para desenvolvimento/testes); o
 * endpoint de upload responde 503 até as variáveis serem definidas.
 */
@Configuration
@EnableConfigurationProperties(CloudinaryProperties.class)
public class CloudinaryConfig {

    @Bean
    public Cloudinary cloudinary(CloudinaryProperties properties) {
        Map<String, Object> config = new HashMap<>();
        if (StringUtils.hasText(properties.getCloudName())) {
            config.put("cloud_name", properties.getCloudName());
        }
        if (StringUtils.hasText(properties.getApiKey())) {
            config.put("api_key", properties.getApiKey());
        }
        if (StringUtils.hasText(properties.getApiSecret())) {
            config.put("api_secret", properties.getApiSecret());
        }
        config.put("secure", true);
        return new Cloudinary(config);
    }
}
