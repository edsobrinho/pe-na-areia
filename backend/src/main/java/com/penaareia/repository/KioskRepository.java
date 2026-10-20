package com.penaareia.repository;

import com.penaareia.model.Kiosk;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface KioskRepository extends MongoRepository<Kiosk, String> {

    List<Kiosk> findByAtivoTrue();

    List<Kiosk> findByPontoReferenciaIdAndAtivoTrue(String pontoReferenciaId);

    GeoResults<Kiosk> findByLocalizacaoNear(GeoJsonPoint localizacao, Distance maxDistance);
}
