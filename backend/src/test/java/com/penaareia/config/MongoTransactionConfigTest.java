package com.penaareia.config;

import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.MongoDatabaseFactory;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class MongoTransactionConfigTest {

    @Test
    void createsMongoTransactionManagerForConfiguredDatabaseFactory() {
        assertThat(new MongoTransactionConfig().transactionManager(mock(MongoDatabaseFactory.class)))
                .isNotNull();
    }
}
