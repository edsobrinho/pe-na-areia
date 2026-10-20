package com.penaareia.service;

import com.penaareia.model.ReferencePoint;
import com.penaareia.support.Fixtures;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResult;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.NearQuery;
import org.springframework.data.mongodb.core.query.Query;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Testes de unidade do ReferencePointService: consulta de ativos e sugestao de
 * proximos que nunca devolve postos inativos.
 */
@ExtendWith(MockitoExtension.class)
class ReferencePointServiceTest {

    @Mock
    private MongoTemplate mongoTemplate;

    @InjectMocks
    private ReferencePointService service;

    @Test
    void listarAtivosConsultaMongoComFiltroAtivo() {
        ReferencePoint ativo = Fixtures.postoAtivo();
        when(mongoTemplate.find(any(Query.class), eq(ReferencePoint.class))).thenReturn(List.of(ativo));

        List<ReferencePoint> resultado = service.listarAtivos();

        assertThat(resultado).containsExactly(ativo);
        ArgumentCaptor<Query> query = ArgumentCaptor.forClass(Query.class);
        verify(mongoTemplate).find(query.capture(), eq(ReferencePoint.class));
        assertThat(query.getValue().getQueryObject().get("ativo")).isEqualTo(true);
    }

    @Test
    void sugerirProximosExcluiPostosInativos() {
        ReferencePoint ativo = Fixtures.postoAtivo();
        ReferencePoint inativo = Fixtures.postoInativo();
        GeoResults<ReferencePoint> resultados = new GeoResults<>(List.of(
                new GeoResult<>(inativo, new Distance(0.3, Metrics.KILOMETERS)),
                new GeoResult<>(ativo, new Distance(0.8, Metrics.KILOMETERS))));
        when(mongoTemplate.geoNear(any(NearQuery.class), eq(ReferencePoint.class))).thenReturn(resultados);

        List<ReferencePoint> sugeridos =
                service.sugerirProximos(Fixtures.LATITUDE, Fixtures.LONGITUDE, 1.5);

        assertThat(sugeridos).containsExactly(ativo);
        verify(mongoTemplate).geoNear(any(NearQuery.class), eq(ReferencePoint.class));
    }

    @Test
    void sugerirProximosSemResultadosRetornaListaVazia() {
        when(mongoTemplate.geoNear(any(NearQuery.class), eq(ReferencePoint.class)))
                .thenReturn(new GeoResults<>(List.of()));

        List<ReferencePoint> sugeridos =
                service.sugerirProximos(Fixtures.LATITUDE, Fixtures.LONGITUDE, 1.5);

        assertThat(sugeridos).isEmpty();
    }
}
