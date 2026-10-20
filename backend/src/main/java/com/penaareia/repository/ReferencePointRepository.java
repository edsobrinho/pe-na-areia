package com.penaareia.repository;

import com.penaareia.model.ReferencePoint;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ReferencePointRepository extends MongoRepository<ReferencePoint, String> {

    List<ReferencePoint> findByAtivoTrue();

    /** Usado para sugerir automaticamente o posto mais proximo do pin do cliente */
    GeoResults<ReferencePoint> findByLocalizacaoNear(GeoJsonPoint localizacao, Distance maxDistance);
}
