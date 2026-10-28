package com.penaareia.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class CloudinaryPropertiesTest {

    @Test
    void requiresAllNonBlankCredentials() {
        CloudinaryProperties properties = new CloudinaryProperties();
        assertThat(properties.configurado()).isFalse();

        properties.setCloudName("cloud");
        properties.setApiKey("key");
        properties.setApiSecret("secret");
        assertThat(properties.configurado()).isTrue();

        properties.setApiKey(" ");
        assertThat(properties.configurado()).isFalse();
    }
}
