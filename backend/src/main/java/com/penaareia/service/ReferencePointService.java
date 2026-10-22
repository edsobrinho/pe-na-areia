package com.penaareia.service;

import com.penaareia.model.ReferencePoint;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResult;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.NearQuery;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReferencePointService {

    private final MongoTemplate mongoTemplate;

    public ReferencePointService(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    public List<ReferencePoint> listarAtivos() {
        return mongoTemplate.find(
                Query.query(Criteria.where("ativo").is(true)),
                ReferencePoint.class);
    }

    /**
     * Sugere o posto de referencia mais proximo de um pin, usado na tela
     * de selecao de localizacao para pre-selecionar o chip mais provavel.
     * Postos inativos nunca sao sugeridos.
     */
    public List<ReferencePoint> sugerirProximos(double latitude, double longitude, double raioKm) {
        GeoJsonPoint ponto = new GeoJsonPoint(longitude, latitude);
        NearQuery nearQuery = NearQuery.near(ponto)
                .spherical(true)
                .maxDistance(new Distance(raioKm, Metrics.KILOMETERS))
                .query(Query.query(Criteria.where("ativo").is(true)));
        GeoResults<ReferencePoint> resultados = mongoTemplate.geoNear(nearQuery, ReferencePoint.class);

        return resultados.getContent().stream()
                .map(GeoResult::getContent)
                .toList();
    }
}
