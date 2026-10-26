package com.penaareia.seed;

import com.penaareia.model.Partnership;
import com.penaareia.repository.PartnershipRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class PartnershipSeeder implements CommandLineRunner {

    private static final String APP_PARTNERSHIP_ID = "pe-na-areia-app";

    private final PartnershipRepository repository;

    @Override
    public void run(String... args) {
        if (!repository.existsById(APP_PARTNERSHIP_ID)) {
            repository.save(new Partnership(APP_PARTNERSHIP_ID, "Pé na Areia", "APP", true));
        }
    }
}
