package com.penaareia.service;

import com.penaareia.model.DailyOrderCounter;
import org.springframework.data.mongodb.core.FindAndModifyOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;

@Service
public class OrderSequenceService {

    public static final ZoneId ZONE_SAO_PAULO = ZoneId.of("America/Sao_Paulo");
    private static final int MAX_DAILY_SEQUENCE = 9999;

    private final MongoTemplate mongoTemplate;
    private final Clock clock;

    public OrderSequenceService(MongoTemplate mongoTemplate) {
        this(mongoTemplate, Clock.system(ZONE_SAO_PAULO));
    }

    public OrderSequenceService(MongoTemplate mongoTemplate, Clock clock) {
        this.mongoTemplate = mongoTemplate;
        this.clock = clock != null ? clock : Clock.system(ZONE_SAO_PAULO);
    }

    public record DailySequence(String codigoFormatado, int numeroDiario) {
    }

    public String proximoCodigoPedido() {
        return gerarProximaSequencia().codigoFormatado();
    }

    public DailySequence gerarProximaSequencia() {
        LocalDate today = LocalDate.now(clock.withZone(ZONE_SAO_PAULO));
        return gerarProximaSequencia(today);
    }

    public DailySequence gerarProximaSequencia(LocalDate date) {
        String dateKey = "order_seq_" + date.toString();
        DailyOrderCounter counter = mongoTemplate.findAndModify(
                Query.query(Criteria.where("_id").is(dateKey)),
                new Update().inc("seq", 1),
                FindAndModifyOptions.options().upsert(true).returnNew(true),
                DailyOrderCounter.class);

        long rawSeq = counter != null ? counter.getSeq() : 1L;
        int numeroDiario = (int) (((rawSeq - 1) % MAX_DAILY_SEQUENCE) + 1);
        String codigoFormatado = formatarCodigo(numeroDiario);
        return new DailySequence(codigoFormatado, numeroDiario);
    }

    public static String formatarCodigo(long numero) {
        long normalized = ((numero - 1) % MAX_DAILY_SEQUENCE) + 1;
        return String.format("#%04d", normalized);
    }
}
