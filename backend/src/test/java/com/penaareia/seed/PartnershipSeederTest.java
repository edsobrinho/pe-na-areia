package com.penaareia.seed;

import com.penaareia.model.Partnership;
import com.penaareia.repository.PartnershipRepository;
import org.junit.jupiter.api.Test;

import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PartnershipSeederTest {

    @Test
    void createsDefaultPartnershipOnlyWhenMissing() {
        PartnershipRepository repository = mock(PartnershipRepository.class);
        PartnershipSeeder seeder = new PartnershipSeeder(repository);
        when(repository.existsById("pe-na-areia-app")).thenReturn(false);

        seeder.run();

        verify(repository).save(argThat(partnership ->
                "pe-na-areia-app".equals(partnership.getId())
                        && "Pé na Areia".equals(partnership.getName())
                        && "APP".equals(partnership.getChannel())
                        && partnership.isActive()));

        when(repository.existsById("pe-na-areia-app")).thenReturn(true);
        seeder.run();
        verify(repository).save(argThat(partnership -> "pe-na-areia-app".equals(partnership.getId())));
    }
}
