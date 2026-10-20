package com.penaareia.seed;

import com.penaareia.model.ReferencePoint;
import com.penaareia.repository.ReferencePointRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Component;

/**
 * Popula a colecao reference_points com alguns postos de salvamento da orla
 * de Santos na primeira execucao. Coordenadas aproximadas - ajuste com os
 * dados oficiais da Prefeitura de Santos antes de ir para producao.
 *
 * IMPORTANTE: este seeder so roda se a colecao estiver vazia, entao e seguro
 * reiniciar a aplicacao sem duplicar dados.
 */
@Component
@RequiredArgsConstructor
public class ReferencePointSeeder implements CommandLineRunner {

    private final ReferencePointRepository repository;

    @Override
    public void run(String... args) {
        if (repository.count() > 0) {
            return;
        }

        repository.saveAll(java.util.List.of(
                ponto(5, "Posto 5", "Gonzaga", -23.9689, -46.3336),
                ponto(6, "Posto 6", "Boqueirao", -23.9722, -46.3280),
                ponto(7, "Posto 7", "Boqueirao", -23.9755, -46.3230),
                ponto(8, "Posto 8", "Embare", -23.9788, -46.3180)
        ));
    }

    private ReferencePoint ponto(int numero, String nome, String trecho, double lat, double lng) {
        ReferencePoint ponto = new ReferencePoint();
        ponto.setNumero(numero);
        ponto.setNome(nome);
        ponto.setTrecho(trecho);
        // GeoJsonPoint espera (longitude, latitude), nessa ordem
        ponto.setLocalizacao(new GeoJsonPoint(lng, lat));
        ponto.setAtivo(true);
        return ponto;
    }
}
