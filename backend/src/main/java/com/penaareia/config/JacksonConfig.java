package com.penaareia.config;

import com.fasterxml.jackson.databind.Module;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.geo.GeoJsonModule;

/**
 * Serializacao canonica de GeoJSON nas respostas HTTP:
 * GeoJsonPoint vira {"type":"Point","coordinates":[longitude,latitude]},
 * sem os campos redundantes x/y do getter padrao.
 */
@Configuration
public class JacksonConfig {

    @Bean
    public Module geoJsonSerializersModule() {
        return GeoJsonModule.serializers();
    }
}
