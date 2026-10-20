package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexType;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import org.springframework.data.mongodb.core.mapping.Document;

/**
 * Postos de referencia oficiais da orla (postos de salvamento numerados).
 * Dado praticamente estatico, carregado via seed inicial no banco.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "reference_points")
public class ReferencePoint {

    @Id
    private String id;

    /** Numero oficial do posto, ex: 6 */
    private Integer numero;

    /** Nome de exibicao, ex: "Posto 6" */
    private String nome;

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint localizacao;

    /** Bairro/trecho da orla para facilitar busca, ex: "Gonzaga" */
    private String trecho;

    private boolean ativo = true;
}
