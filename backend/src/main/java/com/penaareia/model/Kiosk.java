package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexType;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "kiosks")
public class Kiosk {

    @Id
    private String id;

    private String nome;

    /** Id do posto de referencia mais proximo deste quiosque */
    private String pontoReferenciaId;

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint localizacao;

    private List<MenuItem> cardapio;

    private boolean aceitaEmbalagemSustentavel = true;

    private boolean ativo = true;

    // --- Metadados de Vitrine (Storefront v2.1) ---
    private String fotoCapaUrl;
    private String logoUrl;
    private String descricaoCurta;
    private Double avaliacaoMedia = 4.8;
    private boolean destaquePopular = true;

    public Kiosk(String id,
                 String nome,
                 String pontoReferenciaId,
                 GeoJsonPoint localizacao,
                 List<MenuItem> cardapio,
                 boolean aceitaEmbalagemSustentavel,
                 boolean ativo) {
        this(id, nome, pontoReferenciaId, localizacao, cardapio,
                aceitaEmbalagemSustentavel, ativo, null, null, null, 4.8, true);
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MenuItem {
        private String id;
        private String nome;
        private String descricao;
        private BigDecimal preco;
        private boolean disponivel = true;
        private String category = "Outros";
        private boolean returnablePackaging;
        private String fotoUrl;
        private boolean destaque = false;

        public MenuItem(String id, String nome, String descricao, BigDecimal preco, boolean disponivel) {
            this(id, nome, descricao, preco, disponivel, "Outros", false, null, false);
        }

        public MenuItem(String id,
                        String nome,
                        String descricao,
                        BigDecimal preco,
                        boolean disponivel,
                        String category,
                        boolean returnablePackaging,
                        String fotoUrl) {
            this(id, nome, descricao, preco, disponivel, category, returnablePackaging, fotoUrl, false);
        }
    }
}
