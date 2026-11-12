package com.penaareia.service;

import com.penaareia.model.DailyOrderCounter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderSequenceServiceTest {

    @Mock
    private MongoTemplate mongoTemplate;

    private Clock fixedClock;
    private OrderSequenceService service;

    @BeforeEach
    void setUp() {
        // Fixed instant: 2026-11-12T14:30:00Z in America/Sao_Paulo (UTC-3: 11:30 -> 2026-11-12)
        Instant instant = Instant.parse("2026-11-12T14:30:00Z");
        fixedClock = Clock.fixed(instant, OrderSequenceService.ZONE_SAO_PAULO);
        service = new OrderSequenceService(mongoTemplate, fixedClock);
    }

    @Test
    void generatesFirstOrderCodeOfTheDay() {
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class)))
                .thenReturn(new DailyOrderCounter("order_seq_2026-11-12", 1L));

        OrderSequenceService.DailySequence sequence = service.gerarProximaSequencia();

        assertThat(sequence.codigoFormatado()).isEqualTo("#0001");
        assertThat(sequence.numeroDiario()).isEqualTo(1);

        ArgumentCaptor<Query> queryCaptor = ArgumentCaptor.forClass(Query.class);
        verify(mongoTemplate).findAndModify(queryCaptor.capture(), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class));
        assertThat(queryCaptor.getValue().getQueryObject().get("_id")).isEqualTo("order_seq_2026-11-12");
    }

    @Test
    void proximoCodigoPedidoReturnsFormattedCode() {
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class)))
                .thenReturn(new DailyOrderCounter("order_seq_2026-11-12", 1L));

        assertThat(service.proximoCodigoPedido()).isEqualTo("#0001");
    }

    @Test
    void generatesSequentialCodesThroughoutDay() {
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class)))
                .thenReturn(new DailyOrderCounter("order_seq_2026-11-12", 42L));

        OrderSequenceService.DailySequence sequence = service.gerarProximaSequencia();

        assertThat(sequence.codigoFormatado()).isEqualTo("#0042");
        assertThat(sequence.numeroDiario()).isEqualTo(42);
    }

    @Test
    void reachesLimitAt9999AndRolloversAt10000() {
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class)))
                .thenReturn(new DailyOrderCounter("order_seq_2026-11-12", 9999L))
                .thenReturn(new DailyOrderCounter("order_seq_2026-11-12", 10000L))
                .thenReturn(new DailyOrderCounter("order_seq_2026-11-12", 10001L));

        OrderSequenceService.DailySequence seq9999 = service.gerarProximaSequencia();
        assertThat(seq9999.codigoFormatado()).isEqualTo("#9999");
        assertThat(seq9999.numeroDiario()).isEqualTo(9999);

        OrderSequenceService.DailySequence seqRollover = service.gerarProximaSequencia();
        assertThat(seqRollover.codigoFormatado()).isEqualTo("#0001");
        assertThat(seqRollover.numeroDiario()).isEqualTo(1);

        OrderSequenceService.DailySequence seqNext = service.gerarProximaSequencia();
        assertThat(seqNext.codigoFormatado()).isEqualTo("#0002");
        assertThat(seqNext.numeroDiario()).isEqualTo(2);
    }

    @Test
    void handlesNullCounterGracefully() {
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class)))
                .thenReturn(null);

        OrderSequenceService.DailySequence sequence = service.gerarProximaSequencia();

        assertThat(sequence.codigoFormatado()).isEqualTo("#0001");
        assertThat(sequence.numeroDiario()).isEqualTo(1);
    }

    @Test
    void generatesForExplicitDate() {
        LocalDate date = LocalDate.of(2026, 12, 31);
        when(mongoTemplate.findAndModify(any(Query.class), any(Update.class), any(FindAndModifyOptions.class), eq(DailyOrderCounter.class)))
                .thenReturn(new DailyOrderCounter("order_seq_2026-12-31", 500L));

        OrderSequenceService.DailySequence sequence = service.gerarProximaSequencia(date);

        assertThat(sequence.codigoFormatado()).isEqualTo("#0500");
        assertThat(sequence.numeroDiario()).isEqualTo(500);
    }

    @Test
    void formatarCodigoStaticUtility() {
        assertThat(OrderSequenceService.formatarCodigo(1)).isEqualTo("#0001");
        assertThat(OrderSequenceService.formatarCodigo(9999)).isEqualTo("#9999");
        assertThat(OrderSequenceService.formatarCodigo(10000)).isEqualTo("#0001");
        assertThat(OrderSequenceService.formatarCodigo(10001)).isEqualTo("#0002");
    }

    @Test
    void defaultConstructorUsesSystemClock() {
        OrderSequenceService defaultService = new OrderSequenceService(mongoTemplate);
        assertThat(defaultService).isNotNull();

        OrderSequenceService nullClockService = new OrderSequenceService(mongoTemplate, null);
        assertThat(nullClockService).isNotNull();
    }
}
