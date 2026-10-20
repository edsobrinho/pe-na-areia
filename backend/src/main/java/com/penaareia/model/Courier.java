package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexType;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "couriers")
public class Courier {

    @Id
    private String id;

    private String nome;

    @Indexed(unique = true)
    private String email;

    private String telefone;

    private String senhaHash;

    private VehicleType veiculo;

    private CourierStatus status = CourierStatus.OFFLINE;

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint localizacaoAtual;

    public enum VehicleType {
        A_PE,
        BICICLETA
    }

    public enum CourierStatus {
        OFFLINE,
        DISPONIVEL,
        EM_ROTA
    }
}
