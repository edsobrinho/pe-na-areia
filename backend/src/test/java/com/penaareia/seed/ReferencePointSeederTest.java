package com.penaareia.seed;

import com.penaareia.model.ReferencePoint;
import com.penaareia.repository.ReferencePointRepository;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ReferencePointSeederTest {

    @Test
    void seedsReferencePointsOnlyWhenCollectionIsEmpty() {
        ReferencePointRepository repository = mock(ReferencePointRepository.class);
        ReferencePointSeeder seeder = new ReferencePointSeeder(repository);
        when(repository.count()).thenReturn(0L);

        seeder.run();

        verify(repository).saveAll(org.mockito.ArgumentMatchers.<List<ReferencePoint>>argThat(points -> {
            assertThat(points).hasSize(4);
            assertThat(points).allSatisfy(point -> {
                assertThat(point.isAtivo()).isTrue();
                assertThat(point.getLocalizacao().getX()).isLessThan(0);
                assertThat(point.getLocalizacao().getY()).isLessThan(0);
            });
            assertThat(points).extracting(ReferencePoint::getNumero).containsExactly(5, 6, 7, 8);
            return true;
        }));

        when(repository.count()).thenReturn(1L);
        seeder.run();
        verify(repository, org.mockito.Mockito.times(1))
                .saveAll(org.mockito.ArgumentMatchers.<List<ReferencePoint>>any());
    }
}
